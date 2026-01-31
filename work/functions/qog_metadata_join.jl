# ==============================================================================
# QoG METADATA JOIN - PHASE 0
# 
# Robust pipeline for ingesting, normalizing, and validating metadata from
# disparate sources (Stata manifest, PDF codebook, Arrow data).
#
# Core Principle: Raw data immutability
# Language: Julia 1.10+
# Dependencies: DataFrames, CSV
# ==============================================================================

using DataFrames
using CSV

# ==============================================================================
# CONFIGURATION - CONTROL PLANE
# ==============================================================================

# --- File Paths ---

"""Stata manifest CSV with variable labels extracted from .dta file. Columns: [variable, label, prefix]."""
const PATH_STATA_SLUGS = "data/qog_metadata_manifest.csv"

"""PDF codebook extraction CSV with documentation, provenance, and temporal bounds. Columns: [slug, prefix, description, type, provenance, min_year, max_year]."""
const PATH_PDF_SLUGS = "data/qog_slugs_temporal.csv"

"""PDF export CSV for prefix/datasource metadata. Same normalization (lowercase, ligatures) as slugs. Columns: [prefix, datasource, source_name, citation, last_update, description, provenance]."""
const PATH_PDF_PREFIXES = "data/qog_prefixes.csv"

"""Arrow DataFrame slug extraction CSV with all column names. Columns: [slug, prefix, type]."""
const PATH_ARROW_SLUGS = "data/ggis_arrow_slugs.csv"

"""Output path for unified, joined metadata CSV."""
const PATH_METADATA_JOINED = "data/qog_metadata_joined.csv"

"""Output path for unified prefix-level metadata CSV."""
const PATH_PREFIX_JOINED = "data/qog_prefix_joined.csv"

"""Prefixes excluded from prefix unification output (e.g. 'base', 'missing')."""
const PREFIXES_EXCLUDED_FROM_UNIFICATION = ["base", "missing"]

# --- Logic Control & Exceptions ---

"""Slug prefixes to exclude from 3-way isomorphism validation (custom namespaces not in QoG native data)."""
const EXCLUDED_PREFIXES = ["ggis_"]

"""Prefixes that exist only in the PDF extract; rows with these prefixes are removed from pdf_df during ingest (not in Stata/Arrow)."""
const PDF_ONLY_PREFIXES = ["ens", "gdg", "jht", "qs20"]

"""
Manual corrections for slug typos discovered during verification.
Format: "typo_slug" => "correct_slug"
Applied globally during ingestion.
"""
const SLUG_CORRECTIONS = Dict{String, String}(
    # Add corrections here as discovered
    # "vdem_corr" => "vdem_cor",
)

"""
Slugs present in PDF but removed from Data (exclude from mismatch error).
"""
const DEPRECATED_SLUGS = Set{String}([
    "who_roadtrd",  # Cross section database only
])

"""
Slugs present in Data but missing from PDF (exclude from mismatch error).
E.g. whr_hap: included in .arrow/.dta but missed PDF codebook print deadline.
"""
const UNDOCUMENTED_SLUGS = Set{String}([
    "whr_hap",
])

"""
Metadata for custom ggis_ slugs not present in standard sources.
"""
const GGIS_METADATA = Dict{String, Dict{String, String}}(
    # "ggis_slug" => Dict("label" => "...", "description" => "...")
)

"""
Metadata for slugs in data but not in PDF (e.g. UNDOCUMENTED_SLUGS). Used to fill label/description in unify_and_join.
"""
const ADDITIONAL_SLUG_METADATA = Dict{String, Dict{String, String}}(
    "whr_hap" => Dict{String, String}(
        "label" => "Happiness Score / Cantril Ladder",
        "description" => "National average score of subjective well-being. Respondents rate best possible life as 10 and worst as 0 (Cantril Ladder). Source: Sustainable Development Solutions Network (SDSN), World Happiness Report; included in QoG data but missed PDF codebook print deadline.",
        "provenance" => "Sustainable Development Solutions Network (SDSN)",
    ),
)

"""
Identification variables requiring special handling.
"""
const ID_VARIABLES = [
    "ident_cname_qog", "ident_cname", "ident_year", "ident_ccodecow", 
    "ident_ccodealp", "ident_ccodealp_year", "ident_ccode_qog", 
    "ident_cname_year", "ident_ccode"
]


# ==============================================================================
# STEP 1: INGESTION, NORMALIZATION & PATCHING
# ==============================================================================

"""
Normalize typographic ligatures to ASCII so PDF-origin slugs match Stata/Arrow.
Replaces: ﬀ→ff, ﬁ→fi, ﬂ→fl, ﬃ→ffi, ﬄ→ffl (Unicode U+FB00–U+FB04).
"""
function normalize_ligatures(s::AbstractString)
    s = replace(s, '\uFB00' => "ff", '\uFB01' => "fi", '\uFB02' => "fl", '\uFB03' => "ffi", '\uFB04' => "ffl")
    return s
end

"""
Loads and normalizes metadata sources with lowercase, ligature normalization, and typo correction.

Arguments:
- None

Returns:
- stata_df: Normalized Stata manifest (slug, label, prefix)
- pdf_df: Normalized PDF extraction (slug, prefix, description, type, provenance, min_year, max_year); rows with prefix in PDF_ONLY_PREFIXES removed; temporal columns coerced to Int or missing
- arrow_df: Normalized Arrow slugs (slug, prefix, type)
- pdf_prefixes_df: Normalized PDF prefixes CSV (prefix, datasource, source_name, citation, last_update, description, provenance)

Rules:
- Lowercase ALL column names and ALL slug/prefix values
- Normalize typographic ligatures (ﬀ, ﬁ, ﬂ, etc.) to ASCII (ff, fi, fl) so PDF slugs match Stata/Arrow
- Rename Stata's 'variable' column to 'slug'
- Apply SLUG_CORRECTIONS to fix typos
- Remove from pdf_df rows whose prefix is in PDF_ONLY_PREFIXES (ens, gdg, jht, qs20); removal is clearly printed
- Load and normalize PATH_PDF_PREFIXES (qog_prefixes.csv) with same normalization as slugs

Usage:
    (stata_df, pdf_df, arrow_df, pdf_prefixes_df) = ingest_and_normalize()
    (stata_df, pdf_df, arrow_df) = ingest_and_normalize()  # 4th value ignored if not needed
"""
function ingest_and_normalize()
    # Load raw CSVs
    println("=" ^ 70)
    println("PHASE 0: QoG METADATA JOINING - INGESTION")
    println("=" ^ 70)
    
    println("\n>>> Loading source files...")
    stata_raw = CSV.read(PATH_STATA_SLUGS, DataFrame)
    pdf_raw = CSV.read(PATH_PDF_SLUGS, DataFrame)
    arrow_raw = CSV.read(PATH_ARROW_SLUGS, DataFrame)
    pdf_prefixes_raw = CSV.read(PATH_PDF_PREFIXES, DataFrame)
    
    println("    Stata manifest:  $(nrow(stata_raw)) rows")
    println("    PDF extraction:  $(nrow(pdf_raw)) rows")
    println("    Arrow slugs:     $(nrow(arrow_raw)) rows")
    println("    PDF prefixes:    $(nrow(pdf_prefixes_raw)) rows")
    
    # ===== STATA NORMALIZATION =====
    println("\n>>> Normalizing Stata manifest...")
    stata_df = copy(stata_raw)
    
    # Lowercase column names
    rename!(stata_df, lowercase.(string.(names(stata_df))))
    
    # Rename 'variable' to 'slug'
    if :variable in propertynames(stata_df)
        rename!(stata_df, :variable => :slug)
    elseif !(:slug in propertynames(stata_df))
        error("Stata manifest must have 'variable' or 'slug' column")
    end
    
    # Lowercase and normalize ligatures (ﬀ→ff, etc.) for slug and prefix
    stata_df.slug = normalize_ligatures.(lowercase.(string.(stata_df.slug)))
    if :prefix in propertynames(stata_df)
        stata_df.prefix = normalize_ligatures.(lowercase.(string.(stata_df.prefix)))
    end
    
    # Apply corrections
    stata_df.slug = [get(SLUG_CORRECTIONS, s, s) for s in stata_df.slug]
    
    println("    Normalized: $(nrow(stata_df)) slugs")
    
    # ===== PDF NORMALIZATION =====
    println("\n>>> Normalizing PDF extraction...")
    pdf_df = copy(pdf_raw)
    
    # Lowercase column names
    rename!(pdf_df, lowercase.(string.(names(pdf_df))))
    
    # Lowercase slug and prefix values
    if !(:slug in propertynames(pdf_df))
        error("PDF extraction must have 'slug' column")
    end
    pdf_df.slug = normalize_ligatures.(lowercase.(string.(pdf_df.slug)))
    if :prefix in propertynames(pdf_df)
        pdf_df.prefix = normalize_ligatures.(lowercase.(string.(pdf_df.prefix)))
    end
    
    # Apply corrections
    pdf_df.slug = [get(SLUG_CORRECTIONS, s, s) for s in pdf_df.slug]
    
    # Remove rows whose prefix is PDF-only (not in Stata/Arrow); output clearly
    n_pdf_before = nrow(pdf_df)
    mask_keep = .!(in.(pdf_df.prefix, Ref(Set(PDF_ONLY_PREFIXES))))
    pdf_df = pdf_df[mask_keep, :]
    n_removed = n_pdf_before - nrow(pdf_df)
    if n_removed > 0
        println("    Removed $n_removed rows from PDF (prefixes only in PDF: $(join(PDF_ONLY_PREFIXES, ", ")))")
    end
    println("    Normalized: $(nrow(pdf_df)) slugs (after PDF-only prefix removal)")
    
    # Coerce min_year / max_year to Union{Int, Missing} (empty string, "undefined", etc. → missing)
    _coerce_year(x) = (ismissing(x) && return missing; x isa Integer && return Int(x); s = string(x); (isempty(strip(s)) || lowercase(strip(s)) in ("undefined", "missing", "na", "")) && return missing; try; return parse(Int, s); catch; return missing; end)
    for col in [:min_year, :max_year]
        if col in propertynames(pdf_df)
            pdf_df[!, col] = [_coerce_year(x) for x in pdf_df[!, col]]
        else
            pdf_df[!, col] = fill(missing, nrow(pdf_df))
        end
    end
    n_temporal = count(r -> !ismissing(r.min_year) && !ismissing(r.max_year) && r.min_year <= r.max_year, eachrow(pdf_df))
    println("    PDF temporal: $(n_temporal) slugs with valid (min_year, max_year)")
    
    # ===== ARROW NORMALIZATION =====
    println("\n>>> Normalizing Arrow slugs...")
    arrow_df = copy(arrow_raw)
    
    # Lowercase column names
    rename!(arrow_df, lowercase.(string.(names(arrow_df))))
    
    # Lowercase slug and prefix values
    if !(:slug in propertynames(arrow_df))
        error("Arrow extraction must have 'slug' column")
    end
    arrow_df.slug = normalize_ligatures.(lowercase.(string.(arrow_df.slug)))
    if :prefix in propertynames(arrow_df)
        arrow_df.prefix = normalize_ligatures.(lowercase.(string.(arrow_df.prefix)))
    end
    
    # Apply corrections
    arrow_df.slug = [get(SLUG_CORRECTIONS, s, s) for s in arrow_df.slug]
    
    println("    Normalized: $(nrow(arrow_df)) slugs")
    
    # ===== PDF PREFIXES (same normalization as slugs: lowercase, ligatures) =====
    println("\n>>> Normalizing PDF prefixes file...")
    pdf_prefixes_df = copy(pdf_prefixes_raw)
    rename!(pdf_prefixes_df, lowercase.(string.(names(pdf_prefixes_df))))
    for col in names(pdf_prefixes_df)
        pdf_prefixes_df[!, col] = normalize_ligatures.(lowercase.(string.(pdf_prefixes_df[!, col])))
    end
    println("    Normalized: $(nrow(pdf_prefixes_df)) prefix rows")
    
    return (stata_df, pdf_df, arrow_df, pdf_prefixes_df)
end


# ==============================================================================
# STEP 2: IDENTIFICATION VARIABLE ALIGNMENT
# ==============================================================================

"""
Harmonizes identification variables across sources in-place.

Arguments:
- stata_df: Stata manifest DataFrame (modified in-place)
- pdf_df: PDF extraction DataFrame (modified in-place)
- arrow_df: Arrow slugs DataFrame (read-only)

Returns:
- Nothing (modifies stata_df and pdf_df in-place)

Rules:
- Stata Transformation: Identify rows where slug matches ID_VARIABLES targets (without ident_ prefix), set slug to ident_* and prefix to "ident" (e.g., cname → ident_cname, prefix → ident)
- PDF Transformation: Extract ID variable rows from Arrow DataFrame and vcat them into PDF DataFrame to fill the schema gap
- Modifies DataFrames in-place
- ID_VARIABLES defines the canonical list of ID slugs

Usage:
    align_id_variables!(stata_df, pdf_df, arrow_df)
"""
function align_id_variables!(stata_df::DataFrame, pdf_df::DataFrame, arrow_df::DataFrame)
    println("\n>>> Aligning identification variables...")
    
    # Build mapping: base name → ident_ name
    id_base_names = Set{String}()
    for id_var in ID_VARIABLES
        # Extract base name (strip ident_ prefix if present)
        base = replace(id_var, "ident_" => "")
        push!(id_base_names, base)
    end
    
    # ===== STATA: Add ident_ to slug and set prefix to ident where needed =====
    stata_transformed = 0
    for i in 1:nrow(stata_df)
        slug = stata_df.slug[i]
        # Check if slug is a base ID name without ident_ prefix
        if slug in id_base_names && !startswith(slug, "ident_")
            stata_df.slug[i] = "ident_" * slug
            if :prefix in propertynames(stata_df)
                stata_df.prefix[i] = "ident"
            end
            stata_transformed += 1
        end
    end
    println("    Stata: Prefixed $stata_transformed ID variables with 'ident_' (slug and prefix)")
    
    # ===== PDF: Extract ID variables from Arrow and add to PDF =====
    id_rows_arrow = filter(r -> r.slug in ID_VARIABLES, arrow_df)
    
    if nrow(id_rows_arrow) > 0
        # Create minimal schema for PDF
        id_rows_for_pdf = DataFrame(
            slug = id_rows_arrow.slug,
            prefix = fill("ident", nrow(id_rows_arrow)),
            description = ["Identification variable: " * s for s in id_rows_arrow.slug],
            type = fill("identifier", nrow(id_rows_arrow)),
            provenance = fill("QoG Standard", nrow(id_rows_arrow))
        )
        
        # Add missing columns from PDF schema if they exist
        for col in names(pdf_df)
            if !(col in names(id_rows_for_pdf))
                id_rows_for_pdf[!, col] = fill(missing, nrow(id_rows_for_pdf))
            end
        end
        
        # Align column order
        select!(id_rows_for_pdf, names(pdf_df))
        
        # Append to PDF
        append!(pdf_df, id_rows_for_pdf)
        println("    PDF: Added $(nrow(id_rows_arrow)) ID variables from Arrow")
    else
        println("    PDF: No ID variables found in Arrow to add")
    end
    
    return nothing
end


# ==============================================================================
# STEP 3: ISOMORPHISM VALIDATION (3-WAY CHECK)
# ==============================================================================

"""
Performs strict 3-way set comparison with exception handling.

Arguments:
- stata_df: Normalized Stata manifest DataFrame
- pdf_df: Normalized PDF extraction DataFrame
- arrow_df: Normalized Arrow slugs DataFrame
- check_column: Optional Symbol — :both (default) compare (slug, prefix) pairs;
  :slug compare only slug sets; :prefix compare only prefix sets

Returns:
- true if sets are isomorphic (accounting for exceptions)
- Throws error with diagnostics if validation fails

Rules:
- Filter Arrow to exclude EXCLUDED_PREFIXES
- When check_column is :both: Set{Tuple{String, String}} (slug, prefix) for each source
- When check_column is :slug or :prefix: Set of that column only (single-column comparison)
- Remove exceptions: DEPRECATED_SLUGS from PDF, UNDOCUMENTED_SLUGS from Stata/Arrow
- Calculate symmetric differences and print detailed diagnostics
- If validation fails, prints specific mismatches before throwing error

Usage:
    is_valid = validate_isomorphism(stata_df, pdf_df, arrow_df)
    is_valid = validate_isomorphism(stata_df, pdf_df, arrow_df; check_column=:slug)
    is_valid = validate_isomorphism(stata_df, pdf_df, arrow_df; check_column=:prefix)
"""
function validate_isomorphism(stata_df::DataFrame, pdf_df::DataFrame, arrow_df::DataFrame; check_column::Symbol=:both)
    if check_column ∉ (:both, :slug, :prefix)
        error("check_column must be :both, :slug, or :prefix, got :$(check_column)")
    end
    prefix_val(row) = coalesce(string(get(row, :prefix, missing)), "__missing__")

    println("\n" * "=" ^ 70)
    println("PHASE 0: ISOMORPHISM VALIDATION (3-WAY CHECK)")
    if check_column != :both
        println("    (check_column = :$(check_column))")
    end
    println("=" ^ 70)
    
    # ===== FILTER ARROW =====
    println("\n>>> Filtering Arrow to exclude custom prefixes...")
    arrow_filtered = copy(arrow_df)
    
    for prefix in EXCLUDED_PREFIXES
        mask = .!startswith.(arrow_filtered.slug, prefix)
        arrow_filtered = arrow_filtered[mask, :]
    end
    
    println("    Arrow before filtering: $(nrow(arrow_df)) slugs")
    println("    Arrow after filtering:  $(nrow(arrow_filtered)) slugs")
    println("    Excluded: $(nrow(arrow_df) - nrow(arrow_filtered)) slugs")
    
    # ===== BUILD SETS =====
    if check_column == :both
        println("\n>>> Building (slug, prefix) sets...")
        stata_set = Set([(row.slug, get(row, :prefix, missing)) for row in eachrow(stata_df)])
        pdf_set = Set([(row.slug, get(row, :prefix, missing)) for row in eachrow(pdf_df)])
        arrow_set = Set([(row.slug, get(row, :prefix, missing)) for row in eachrow(arrow_filtered)])
        set_label = "(slug, prefix) pairs"
    elseif check_column == :slug
        println("\n>>> Building slug sets...")
        stata_set = Set([row.slug for row in eachrow(stata_df)])
        pdf_set = Set([row.slug for row in eachrow(pdf_df)])
        arrow_set = Set([row.slug for row in eachrow(arrow_filtered)])
        set_label = "slugs"
    else  # :prefix
        println("\n>>> Building prefix sets...")
        stata_set = Set([prefix_val(row) for row in eachrow(stata_df)])
        pdf_set = Set([prefix_val(row) for row in eachrow(pdf_df)])
        arrow_set = Set([prefix_val(row) for row in eachrow(arrow_filtered)])
        set_label = "prefixes"
    end
    
    println("    Stata set:  $(length(stata_set)) unique $set_label")
    println("    PDF set:    $(length(pdf_set)) unique $set_label")
    println("    Arrow set:  $(length(arrow_set)) unique $set_label")
    
    # ===== APPLY EXCEPTIONS =====
    println("\n>>> Applying exception handling...")
    
    if check_column == :both
        if !isempty(DEPRECATED_SLUGS)
            pdf_set_filtered = Set(filter(t -> t[1] ∉ DEPRECATED_SLUGS, collect(pdf_set)))
            println("    Removed $(length(pdf_set) - length(pdf_set_filtered)) deprecated slugs from PDF set")
            pdf_set = pdf_set_filtered
        end
        if !isempty(UNDOCUMENTED_SLUGS)
            stata_set_filtered = Set(filter(t -> t[1] ∉ UNDOCUMENTED_SLUGS, collect(stata_set)))
            arrow_set_filtered = Set(filter(t -> t[1] ∉ UNDOCUMENTED_SLUGS, collect(arrow_set)))
            println("    Removed $(length(stata_set) - length(stata_set_filtered)) undocumented slugs from Stata set")
            println("    Removed $(length(arrow_set) - length(arrow_set_filtered)) undocumented slugs from Arrow set")
            stata_set = stata_set_filtered
            arrow_set = arrow_set_filtered
        end
    elseif check_column == :slug
        if !isempty(DEPRECATED_SLUGS)
            pdf_set_filtered = Set(filter(s -> s ∉ DEPRECATED_SLUGS, collect(pdf_set)))
            println("    Removed $(length(pdf_set) - length(pdf_set_filtered)) deprecated slugs from PDF set")
            pdf_set = pdf_set_filtered
        end
        if !isempty(UNDOCUMENTED_SLUGS)
            stata_set_filtered = Set(filter(s -> s ∉ UNDOCUMENTED_SLUGS, collect(stata_set)))
            arrow_set_filtered = Set(filter(s -> s ∉ UNDOCUMENTED_SLUGS, collect(arrow_set)))
            println("    Removed $(length(stata_set) - length(stata_set_filtered)) undocumented slugs from Stata set")
            println("    Removed $(length(arrow_set) - length(arrow_set_filtered)) undocumented slugs from Arrow set")
            stata_set = stata_set_filtered
            arrow_set = arrow_set_filtered
        end
    end
    # For :prefix we still exclude rows by slug so effective prefix sets match pipeline
    if check_column == :prefix
        if !isempty(DEPRECATED_SLUGS)
            pdf_set = Set(prefix_val(row) for row in eachrow(pdf_df) if row.slug ∉ DEPRECATED_SLUGS)
        end
        if !isempty(UNDOCUMENTED_SLUGS)
            stata_set = Set(prefix_val(row) for row in eachrow(stata_df) if row.slug ∉ UNDOCUMENTED_SLUGS)
            arrow_set = Set(prefix_val(row) for row in eachrow(arrow_filtered) if row.slug ∉ UNDOCUMENTED_SLUGS)
        end
    end
    
    # ===== CALCULATE SYMMETRIC DIFFERENCES =====
    println("\n>>> Computing symmetric differences...")
    
    stata_only = sort(collect(setdiff(stata_set, pdf_set)))
    pdf_only = sort(collect(setdiff(pdf_set, stata_set)))
    arrow_only = sort(collect(setdiff(arrow_set, stata_set)))
    stata_not_arrow = sort(collect(setdiff(stata_set, arrow_set)))
    pdf_arrow_only = sort(collect(setdiff(pdf_set, arrow_set)))
    arrow_not_pdf = sort(collect(setdiff(arrow_set, pdf_set)))
    
    # ===== DIAGNOSTICS =====
    all_aligned = isempty(stata_only) && isempty(pdf_only) && 
                  isempty(arrow_only) && isempty(stata_not_arrow) &&
                  isempty(pdf_arrow_only) && isempty(arrow_not_pdf)
    
    single_col = check_column != :both
    _fmt(x) = single_col ? string(x) : "($(x[1]), $(x[2]))"
    
    if all_aligned
        println("\n✅ SUCCESS: All sources are isomorphic!")
        println("    Aligned: $(length(stata_set)) $set_label")
        println("=" ^ 70)
        return true
    else
        println("\n❌ VALIDATION FAILED: Set mismatches detected")
        println("=" ^ 70)
        
        if !isempty(stata_only)
            println("\n📌 In Stata but NOT in PDF ($(length(stata_only))):")
            for x in first(stata_only, 15)
                println("    - ", _fmt(x))
            end
            length(stata_only) > 15 && println("    ... and $(length(stata_only) - 15) more")
        end
        if !isempty(pdf_only)
            println("\n📌 In PDF but NOT in Stata ($(length(pdf_only))):")
            for x in first(pdf_only, 15)
                println("    - ", _fmt(x))
            end
            length(pdf_only) > 15 && println("    ... and $(length(pdf_only) - 15) more")
        end
        if !isempty(arrow_only)
            println("\n📌 In Arrow but NOT in Stata ($(length(arrow_only))):")
            for x in first(arrow_only, 15)
                println("    - ", _fmt(x))
            end
            length(arrow_only) > 15 && println("    ... and $(length(arrow_only) - 15) more")
        end
        if !isempty(stata_not_arrow)
            println("\n📌 In Stata but NOT in Arrow ($(length(stata_not_arrow))):")
            for x in first(stata_not_arrow, 15)
                println("    - ", _fmt(x))
            end
            length(stata_not_arrow) > 15 && println("    ... and $(length(stata_not_arrow) - 15) more")
        end
        if !isempty(pdf_arrow_only)
            println("\n📌 In PDF but NOT in Arrow ($(length(pdf_arrow_only))):")
            for x in first(pdf_arrow_only, 15)
                println("    - ", _fmt(x))
            end
            length(pdf_arrow_only) > 15 && println("    ... and $(length(pdf_arrow_only) - 15) more")
        end
        if !isempty(arrow_not_pdf)
            println("\n📌 In Arrow but NOT in PDF ($(length(arrow_not_pdf))):")
            for x in first(arrow_not_pdf, 15)
                println("    - ", _fmt(x))
            end
            length(arrow_not_pdf) > 15 && println("    ... and $(length(arrow_not_pdf) - 15) more")
        end
        
        println("\n" * "=" ^ 70)
        error("Isomorphism validation failed. Review mismatches above and update exception constants.")
    end
end


# ==============================================================================
# STEP 3b: TWO-PHASE ISOMORPHISM (FULL vs TEMPORAL-ONLY) & COMPARISON
# ==============================================================================

"""
True iff row has both min_year and max_year non-missing, numeric, and min_year <= max_year.
Used to decide which PDF-only rows to keep in the temporal phase.
"""
function has_proper_temporal_data(row)
    my = get(row, :min_year, missing)
    xy = get(row, :max_year, missing)
    (ismissing(my) || ismissing(xy)) && return false
    (my isa Integer && xy isa Integer) || return false
    return my <= xy
end

"""
Returns the PDF subset for Phase 2 isomorphism: keep every row that is in Arrow; for rows
that are in PDF but not in Arrow (pdf_only), keep only those with proper temporal data.

Logic: step through each variable in PDF that is not in Arrow; remove it from the Phase 2
set if it has no temporal values. Variables that are in Arrow are always kept (whether or
not they have temporal data in the PDF). Uses same Arrow filtering as validate_isomorphism
(EXCLUDED_PREFIXES).
"""
function pdf_subset_for_temporal_phase(pdf_df::DataFrame, arrow_df::DataFrame)::DataFrame
    arrow_filtered = copy(arrow_df)
    for prefix in EXCLUDED_PREFIXES
        mask = .!startswith.(arrow_filtered.slug, prefix)
        arrow_filtered = arrow_filtered[mask, :]
    end
    arrow_slugs = Set(row.slug for row in eachrow(arrow_filtered))
    # Keep: (slug in Arrow) OR (slug not in Arrow but has temporal data)
    keep(row) = row.slug in arrow_slugs || has_proper_temporal_data(row)
    mask = [keep(row) for row in eachrow(pdf_df)]
    return pdf_df[mask, :]
end

"""
Runs two-phase isomorphism check and compares results.

Phase 1: validate_isomorphism(stata_df, pdf_df, arrow_df) — full PDF set (unchanged).
Phase 2: validate_isomorphism(stata_df, pdf_phase2, arrow_df) — PDF set with only one
  trim: each variable that is in PDF but not in Arrow is removed from the Phase 2 set
  if it has no temporal values (min_year/max_year). Variables in Arrow are always kept.

Does not throw on isomorphism failure; catches errors and records pass/fail so both phases can be compared.

Arguments:
- stata_df: Normalized Stata manifest DataFrame
- pdf_df: Normalized PDF extraction DataFrame (must include min_year, max_year)
- arrow_df: Normalized Arrow slugs DataFrame
- check_column: Optional Symbol — :both (default), :slug, or :prefix (passed to validate_isomorphism)
- max_slugs_listed: Maximum number of dropped slugs to list in output (default 30)

Returns:
- NamedTuple (phase1_ok::Bool, phase2_ok::Bool, n_pdf_full::Int, n_pdf_phase2::Int, n_dropped::Int, slugs_dropped::Vector{String})

Usage:
    cmp = compare_isomorphism_with_temporal(stata_df, pdf_df, arrow_df)
    cmp.phase1_ok
    cmp.slugs_dropped
"""
function compare_isomorphism_with_temporal(
    stata_df::DataFrame,
    pdf_df::DataFrame,
    arrow_df::DataFrame;
    check_column::Symbol=:both,
    max_slugs_listed::Int=30
)
    println("\n" * "=" ^ 70)
    println("PHASE 0: TWO-PHASE ISOMORPHISM (FULL vs TRIMMED PDF-ONLY)")
    println("=" ^ 70)
    
    n_pdf_full = nrow(pdf_df)
    pdf_phase2 = pdf_subset_for_temporal_phase(pdf_df, arrow_df)
    n_pdf_phase2 = nrow(pdf_phase2)
    n_dropped = n_pdf_full - n_pdf_phase2
    
    # Dropped = PDF-only slugs that had no temporal data (removed for Phase 2)
    full_slugs = Set(row.slug for row in eachrow(pdf_df))
    phase2_slugs = Set(row.slug for row in eachrow(pdf_phase2))
    slugs_dropped = sort(collect(setdiff(full_slugs, phase2_slugs)))
    
    println("\n>>> PDF set sizes:")
    println("    Full PDF:     $n_pdf_full slugs")
    println("    Phase 2:      $n_pdf_phase2 slugs (PDF-only without temporal data removed)")
    println("    Dropped:      $n_dropped slugs (PDF-only, no temporal values)")
    
    # Phase 1: full PDF
    println("\n>>> Phase 1: Isomorphism with full PDF set...")
    phase1_ok = try
        validate_isomorphism(stata_df, pdf_df, arrow_df; check_column=check_column)
        true
    catch e
        @warn "Phase 1 failed" exception=e
        println("    Phase 1: FAILED (see diagnostics above)")
        false
    end
    
    # Phase 2: PDF with PDF-only rows trimmed (only those without temporal data removed)
    println("\n>>> Phase 2: Isomorphism with trimmed PDF (PDF-only without temporal removed)...")
    phase2_ok = try
        validate_isomorphism(stata_df, pdf_phase2, arrow_df; check_column=check_column)
        true
    catch e
        @warn "Phase 2 failed" exception=e
        println("    Phase 2: FAILED (see diagnostics above)")
        false
    end
    
    # Comparison summary
    println("\n" * "=" ^ 70)
    println("COMPARISON SUMMARY")
    println("=" ^ 70)
    println("    Phase 1 (full PDF):     $(phase1_ok ? "PASS" : "FAIL")")
    println("    Phase 2 (trimmed PDF):  $(phase2_ok ? "PASS" : "FAIL")")
    println("    Slugs dropped (PDF-only, no temporal): $n_dropped")
    if n_dropped > 0
        n_show = min(n_dropped, max_slugs_listed)
        println("    First $n_show dropped slugs:")
        for s in slugs_dropped[1:n_show]
            println("      - $s")
        end
        n_dropped > max_slugs_listed && println("    ... and $(n_dropped - max_slugs_listed) more")
    end
    println("=" ^ 70)
    
    return (
        phase1_ok = phase1_ok,
        phase2_ok = phase2_ok,
        n_pdf_full = n_pdf_full,
        n_pdf_phase2 = n_pdf_phase2,
        n_dropped = n_dropped,
        slugs_dropped = slugs_dropped
    )
end


"""
Runs isomorphism checks from strictest to loosest until one succeeds; returns the three
isomorphic DataFrames for further processing (e.g. union on slug).

Phases (in order):
- Phase 1 (strictest): full PDF set — validate_isomorphism(stata_df, pdf_df, arrow_df).
- Phase 2: trimmed PDF — remove PDF-only rows without temporal data; then validate.

Returns the (stata_df, pdf_df, arrow_df) that achieved success. pdf_df is full for Phase 1
or the trimmed subset for Phase 2. Throws if no phase succeeds.

Arguments:
- stata_df: Normalized Stata manifest DataFrame
- pdf_df: Normalized PDF extraction DataFrame (must include min_year, max_year)
- arrow_df: Normalized Arrow slugs DataFrame
- check_column: Optional Symbol — :both (default), :slug, or :prefix (passed to validate_isomorphism)
- verbose: Optional Bool — if true (default), print which phase is tried and which succeeded

Returns:
- NamedTuple (stata_df::DataFrame, pdf_df::DataFrame, arrow_df::DataFrame, phase_used::Int)
  The three DataFrames are isomorphic (same set of slugs after exceptions). Ready for union on :slug.

Usage:
    result = run_isomorphism_cascade(stata_df, pdf_df, arrow_df)
    stata_df, pdf_df, arrow_df, phase = result.stata_df, result.pdf_df, result.arrow_df, result.phase_used
    # Next step: union on slug, e.g. meta = outerjoin(stata_df, pdf_df, on=:slug, makeunique=true)
    # then outerjoin(meta, arrow_df, on=:slug, makeunique=true)
"""
function run_isomorphism_cascade(
    stata_df::DataFrame,
    pdf_df::DataFrame,
    arrow_df::DataFrame;
    check_column::Symbol=:both,
    verbose::Bool=true
)
    # Phase 1: full PDF (strictest)
    if verbose
        println("\n" * "=" ^ 70)
        println("PHASE 0: ISOMORPHISM CASCADE (STRICTEST → LOOSEST)")
        println("=" ^ 70)
        println("\n>>> Trying Phase 1 (full PDF)...")
    end
    try
        validate_isomorphism(stata_df, pdf_df, arrow_df; check_column=check_column)
        if verbose
            println("\n✅ Phase 1 succeeded. Returning (stata_df, pdf_df, arrow_df) for further processing.")
            println("   Next step: union on slug (e.g. outerjoin(stata_df, pdf_df, on=:slug, makeunique=true), then join arrow_df).")
        end
        return (
            stata_df = stata_df,
            pdf_df = pdf_df,
            arrow_df = arrow_df,
            phase_used = 1
        )
    catch e
        if verbose
            println("    Phase 1 failed. Stepping down to Phase 2...")
        end
    end

    # Phase 2: trimmed PDF (drop PDF-only rows without temporal data)
    pdf_phase2 = pdf_subset_for_temporal_phase(pdf_df, arrow_df)
    if verbose
        println("\n>>> Trying Phase 2 (trimmed PDF: PDF-only without temporal removed)...")
    end
    try
        validate_isomorphism(stata_df, pdf_phase2, arrow_df; check_column=check_column)
        if verbose
            println("\n✅ Phase 2 succeeded. Returning (stata_df, pdf_phase2, arrow_df) for further processing.")
            println("   Next step: union on slug (e.g. outerjoin(stata_df, pdf_df, on=:slug, makeunique=true), then join arrow_df).")
        end
        return (
            stata_df = stata_df,
            pdf_df = pdf_phase2,
            arrow_df = arrow_df,
            phase_used = 2
        )
    catch e
        error("Isomorphism cascade failed: Phase 1 and Phase 2 both failed. Review exception constants and PDF temporal coverage.")
    end
end


# ==============================================================================
# STEP 4: UNIFICATION & JOINING
# ==============================================================================

"""
Performs outer join on slug column and joins with GGIS_METADATA.

Arguments:
- stata_df: Normalized Stata manifest DataFrame
- pdf_df: Normalized PDF extraction DataFrame
- arrow_df: Normalized Arrow slugs DataFrame

Returns:
- DataFrame with unified metadata containing columns: [slug, prefix, label, description, type, provenance, min_year, max_year]

Rules:
- Outer join ensures all slugs from all sources are included
- For ggis_ slugs (or EXCLUDED_PREFIXES), populate from GGIS_METADATA
- label prioritizes Stata
- description prioritizes PDF
- min_year, max_year come from PDF extract (missing where absent)
- Final schema: slug, prefix, label, description, type, provenance, min_year, max_year

Usage:
    metadata = unify_and_join(stata_df, pdf_df, arrow_df)
"""
function unify_and_join(stata_df::DataFrame, pdf_df::DataFrame, arrow_df::DataFrame)
    println("\n" * "=" ^ 70)
    println("PHASE 0: UNIFICATION & JOINING")
    println("=" ^ 70)
    
    # ===== MERGE: Stata + PDF =====
    println("\n>>> Merging Stata and PDF on slug...")
    
    # Start with Stata (authoritative for what's in data)
    metadata = copy(stata_df)
    
    # Outer join with PDF
    metadata = outerjoin(metadata, pdf_df, on=:slug, makeunique=true)
    
    println("    Merged: $(nrow(metadata)) total rows")
    
    # Widen string columns that may receive long text from joining (avoid String15/InlineString overflow)
    for col in [:label, :description, :provenance]
        if col in propertynames(metadata)
            metadata[!, col] = Vector{Union{Missing,String}}(metadata[!, col])
        end
    end
    
    # ===== JOINING: Handle ggis_ slugs =====
    if !isempty(GGIS_METADATA)
        println("\n>>> Joining with GGIS metadata...")
        
        joined_count = 0
        for i in 1:nrow(metadata)
            slug = metadata.slug[i]
            
            # Check if slug starts with any excluded prefix
            is_custom = any(startswith(slug, p) for p in EXCLUDED_PREFIXES)
            
            if is_custom && haskey(GGIS_METADATA, slug)
                custom_meta = GGIS_METADATA[slug]
                
                # Populate missing fields
                if ismissing(get(metadata[i, :], :label, missing)) && haskey(custom_meta, "label")
                    metadata[i, :label] = custom_meta["label"]
                end
                
                if ismissing(get(metadata[i, :], :description, missing)) && haskey(custom_meta, "description")
                    metadata[i, :description] = custom_meta["description"]
                end
                
                joined_count += 1
            end
        end
        
        println("    Joined $joined_count custom slugs with GGIS_METADATA")
    end
    
    # ===== JOINING: Slugs in data but not in PDF (ADDITIONAL_SLUG_METADATA) =====
    if !isempty(ADDITIONAL_SLUG_METADATA)
        joined_extra = 0
        for i in 1:nrow(metadata)
            slug = metadata.slug[i]
            haskey(ADDITIONAL_SLUG_METADATA, slug) || continue
            meta = ADDITIONAL_SLUG_METADATA[slug]
            if haskey(meta, "label") && (ismissing(metadata[i, :label]) || isempty(string(metadata[i, :label])))
                metadata[i, :label] = meta["label"]
                joined_extra += 1
            end
            if haskey(meta, "description") && (ismissing(metadata[i, :description]) || isempty(string(metadata[i, :description])))
                metadata[i, :description] = meta["description"]
            end
            if haskey(meta, "provenance") && (ismissing(metadata[i, :provenance]) || isempty(string(metadata[i, :provenance])))
                metadata[i, :provenance] = meta["provenance"]
            end
        end
        if joined_extra > 0
            println("    Joined $joined_extra slugs from ADDITIONAL_SLUG_METADATA (e.g. whr_hap)")
        end
    end
    
    # ===== ENSURE FINAL SCHEMA =====
    println("\n>>> Finalizing schema...")
    
    required_cols = [:slug, :prefix, :label, :description, :type, :provenance, :min_year, :max_year]
    for col in required_cols
        if !(col in propertynames(metadata))
            metadata[!, col] = fill(missing, nrow(metadata))
        end
    end
    
    # Coalesce duplicate columns from join (if makeunique created them)
    for col in [:prefix, :type, :min_year, :max_year]
        col_dup = Symbol(string(col) * "_1")
        if col_dup in propertynames(metadata)
            metadata[!, col] = coalesce.(metadata[!, col], metadata[!, col_dup])
            select!(metadata, Not(col_dup))
        end
    end
    
    # Select and order final columns
    final_cols = [:slug, :prefix, :label, :description, :type, :provenance, :min_year, :max_year]
    metadata = select(metadata, final_cols...)
    
    println("    Final schema: $(names(metadata))")
    println("    Total variables: $(nrow(metadata))")
    
    return metadata
end


# ==============================================================================
# STEP 5: PREFIX UNIFICATION
# ==============================================================================

"""
Unifies prefix-level metadata using the validated metadata slugs as the source of truth.

Isomorphic-safe approach: Uses the metadata DataFrame (from unify_and_join) to derive
the active prefix list, then decorates with extended documentation from PATH_PDF_PREFIXES.
This ensures no ggis_ or ident rows are lost, and no "ghost" prefixes from the PDF
(that are not in the modeling data) are included.

Arguments:
- metadata: DataFrame from unify_and_join with columns [slug, prefix, ...]
- pdf_prefixes_df: Normalized PDF prefixes DataFrame from ingest_and_normalize (columns:
  prefix, datasource, source_name, citation, last_update, description, provenance)

Returns:
- DataFrame with prefix-level metadata. Schema: [prefix, datasource, source_name, citation,
  last_update, description, provenance]. Rows for ident and ggis are manually injected
  (not in PDF); QoG prefixes are joined from the PDF documentation.

Rules:
- Active prefixes = unique(metadata.prefix) minus PREFIXES_EXCLUDED_FROM_UNIFICATION (base, missing)
- Left join on :prefix keeps ident and ggis even when absent from PDF
- Manual injection: ident → "Internal", "QoG/Project Identifiers"; ggis → "Project", "Custom GGIS Indicators"
- Widens string columns in pdf_prefixes to prevent String15/InlineString overflow

Usage:
    (stata_df, pdf_df, arrow_df, pdf_prefixes_df) = ingest_and_normalize()
    metadata = unify_and_join(stata_df, pdf_df, arrow_df)
    prefix_df = unify_prefixes(metadata, pdf_prefixes_df)
    CSV.write("data/qog_prefix_joined.csv", prefix_df)
"""
function unify_prefixes(metadata::DataFrame, pdf_prefixes_df::DataFrame)
    println("\n" * "=" ^ 70)
    println("PHASE 0: PREFIX UNIFICATION")
    println("=" ^ 70)

    # 1. Source of truth: unique prefixes from isomorphic metadata (exclude base, missing)
    exclude_set = Set(PREFIXES_EXCLUDED_FROM_UNIFICATION)
    active_prefixes = sort(collect(setdiff(Set(skipmissing(metadata.prefix)), exclude_set)))
    prefix_df = DataFrame(prefix = active_prefixes)

    println(">>> Found $(length(active_prefixes)) active prefixes (excluding: $(join(PREFIXES_EXCLUDED_FROM_UNIFICATION, ", ")))")

    # 2. Widen string-like columns to prevent InlineString overflow from long PDF text
    pdf_prefixes_wide = copy(pdf_prefixes_df)
    for col in names(pdf_prefixes_wide)
        pdf_prefixes_wide[!, col] = [ismissing(x) ? missing : string(x) for x in pdf_prefixes_wide[!, col]]
    end

    # 3. Left join: active list pulls documentation from PDF; ident/ggis preserved
    joined_prefixes = leftjoin(prefix_df, pdf_prefixes_wide, on=:prefix)

    # 4. Ensure PDF schema columns exist for manual injection
    for col in [:datasource, :source_name, :description]
        if !(col in propertynames(joined_prefixes))
            joined_prefixes[!, col] = fill(missing, nrow(joined_prefixes))
        end
    end

    # 5. Manual injection for non-QoG namespaces (ident, ggis)
    injected = 0
    for i in 1:nrow(joined_prefixes)
        p = joined_prefixes.prefix[i]

        if p == "ident"
            joined_prefixes[i, :datasource] = "Internal"
            joined_prefixes[i, :source_name] = "QoG/Project Identifiers"
            joined_prefixes[i, :description] = "Core identification variables (codes, years, names) harmonized for modeling."
            injected += 1

        elseif p == "ggis"
            joined_prefixes[i, :datasource] = "Project"
            joined_prefixes[i, :source_name] = "Custom GGIS Indicators"
            joined_prefixes[i, :description] = "Project-specific namespaces and engineered features."
            injected += 1
        end
    end

    if injected > 0
        println(">>> Injected metadata for $injected non-QoG prefix(es): ident, ggis")
    end

    # 6. Select and order columns (include all PDF columns that exist)
    pdf_cols = [:datasource, :source_name, :citation, :last_update, :description, :provenance]
    final_cols = [:prefix]
    for c in pdf_cols
        if c in propertynames(joined_prefixes)
            push!(final_cols, c)
        end
    end
    joined_prefixes = select(joined_prefixes, final_cols...)
    println(">>> Prefix unification complete. Schema: $(names(joined_prefixes))")
    return joined_prefixes
end


# ==============================================================================
# MAIN PIPELINE
# ==============================================================================

"""
Complete Phase 0 metadata joining pipeline.

Arguments:
- save: Whether to write output to CSV (default: true)
- output_path: Where to save joined metadata (default: PATH_METADATA_JOINED)

Returns:
- DataFrame with unified, joined metadata

Rules:
- Executes 5-step pipeline: (1) Ingest and normalize, (2) Align ID variables, (3) Validate isomorphism, (4) Unify and join, (5) Unify prefixes
- Halts pipeline if isomorphism validation fails
- When save=true, writes metadata to output_path and prefix-level data to PATH_PREFIX_JOINED
- Final output schema: [slug, prefix, label, description, type, provenance, min_year, max_year]

Usage:
    metadata = join_metadata()
    metadata = join_metadata(save=false)
    metadata = join_metadata(output_path="custom/path.csv")
"""
function join_metadata(; save::Bool=true, output_path::String=PATH_METADATA_JOINED)
    println("\n" * "=" ^ 70)
    println("QoG METADATA JOINING - PHASE 0")
    println("Lead Architect: Data Engineering Pipeline")
    println("=" ^ 70)
    
    # Step 1: Ingestion & Normalization
    (stata_df, pdf_df, arrow_df, pdf_prefixes_df) = ingest_and_normalize()

    # Step 2: ID Variable Alignment
    align_id_variables!(stata_df, pdf_df, arrow_df)

    # Step 3: Isomorphism Validation
    is_valid = validate_isomorphism(stata_df, pdf_df, arrow_df)

    if !is_valid
        error("Pipeline halted: Isomorphism validation failed")
    end

    # Step 4: Unification & Joining
    metadata = unify_and_join(stata_df, pdf_df, arrow_df)

    # Step 5: Prefix Unification
    prefix_df = unify_prefixes(metadata, pdf_prefixes_df)

    # Optional: Save to CSV
    if save
        println("\n>>> Saving joined metadata...")
        CSV.write(output_path, metadata)
        println("    ✅ Saved to: $output_path")
        CSV.write(PATH_PREFIX_JOINED, prefix_df)
        println("    ✅ Saved prefixes to: $PATH_PREFIX_JOINED")
    end
    
    println("\n" * "=" ^ 70)
    println("PHASE 0 COMPLETE")
    println("=" ^ 70)
    println("    Total variables: $(nrow(metadata))")
    println("    Output schema:   $(join(names(metadata), ", "))")
    
    return metadata
end


"""
Complete Phase 0 metadata joining pipeline using the isomorphism cascade.

Runs isomorphism checks from strictest to loosest until one succeeds, then unifies
on slug. Use this when full PDF isomorphism fails but trimmed PDF (PDF-only without
temporal removed) succeeds.

Arguments:
- save: Whether to write output to CSV (default: true)
- output_path: Where to save joined metadata (default: PATH_METADATA_JOINED)
- check_column: Optional Symbol — :both (default), :slug, or :prefix (passed to cascade)

Returns:
- DataFrame with unified, joined metadata (union on slug of the three isomorphic dfs)
Rules:
- Pipeline: (1) Ingest and normalize, (2) Align ID variables, (3) Run isomorphism cascade
  (Phase 1 full PDF → Phase 2 trimmed PDF), (4) Unify and join (union on slug), (5) Unify prefixes.
- Throws if no cascade phase succeeds.
- When save=true, writes metadata and prefix-level data to PATH_PREFIX_JOINED.
- Final output schema: [slug, prefix, label, description, type, provenance, min_year, max_year]

Usage:
    metadata = join_metadata_with_cascade()
    metadata = join_metadata_with_cascade(save=false)
"""
function join_metadata_with_cascade(; save::Bool=true, output_path::String=PATH_METADATA_JOINED, check_column::Symbol=:both)
    println("\n" * "=" ^ 70)
    println("QoG METADATA JOINING - PHASE 0 (CASCADE)")
    println("=" ^ 70)
    
    # Step 1: Ingestion & Normalization
    (stata_df, pdf_df, arrow_df, pdf_prefixes_df) = ingest_and_normalize()

    # Step 2: ID Variable Alignment
    align_id_variables!(stata_df, pdf_df, arrow_df)

    # Step 3: Isomorphism cascade (strictest → loosest until success)
    result = run_isomorphism_cascade(stata_df, pdf_df, arrow_df; check_column=check_column, verbose=true)
    stata_df, pdf_df, arrow_df = result.stata_df, result.pdf_df, result.arrow_df

    # Step 4: Union on slug and join
    metadata = unify_and_join(stata_df, pdf_df, arrow_df)

    # Step 5: Prefix Unification
    prefix_df = unify_prefixes(metadata, pdf_prefixes_df)

    if save
        println("\n>>> Saving joined metadata...")
        CSV.write(output_path, metadata)
        println("    ✅ Saved to: $output_path")
        CSV.write(PATH_PREFIX_JOINED, prefix_df)
        println("    ✅ Saved prefixes to: $PATH_PREFIX_JOINED")
    end
    
    println("\n" * "=" ^ 70)
    println("PHASE 0 COMPLETE (phase $(result.phase_used) succeeded)")
    println("=" ^ 70)
    println("    Total variables: $(nrow(metadata))")
    println("    Output schema:   $(join(names(metadata), ", "))")
    
    return metadata
end


# ==============================================================================
# CONVENIENCE FUNCTIONS FOR INTERACTIVE USE
# ==============================================================================

"""
Quick diagnostic check without running full pipeline.

Arguments:
- None

Returns:
- NamedTuple with: stata_rows, pdf_rows, arrow_rows, stata_cols, pdf_cols, arrow_cols

Rules:
- Loads raw CSV files without processing
- Prints file sizes and column names
- Returns basic counts for inspection

Usage:
    result = quick_check()
"""
function quick_check()
    println("=" ^ 70)
    println("QUICK DIAGNOSTIC CHECK")
    println("=" ^ 70)
    
    stata_raw = CSV.read(PATH_STATA_SLUGS, DataFrame)
    pdf_raw = CSV.read(PATH_PDF_SLUGS, DataFrame)
    arrow_raw = CSV.read(PATH_ARROW_SLUGS, DataFrame)
    
    println("\nFile sizes:")
    println("  Stata:  $(nrow(stata_raw)) rows, $(ncol(stata_raw)) columns")
    println("  PDF:    $(nrow(pdf_raw)) rows, $(ncol(pdf_raw)) columns")
    println("  Arrow:  $(nrow(arrow_raw)) rows, $(ncol(arrow_raw)) columns")
    
    println("\nStata columns:  $(join(names(stata_raw), ", "))")
    println("PDF columns:    $(join(names(pdf_raw), ", "))")
    println("Arrow columns:  $(join(names(arrow_raw), ", "))")
    
    println("\n" * "=" ^ 70)
    
    return (
        stata_rows = nrow(stata_raw),
        pdf_rows = nrow(pdf_raw),
        arrow_rows = nrow(arrow_raw),
        stata_cols = names(stata_raw),
        pdf_cols = names(pdf_raw),
        arrow_cols = names(arrow_raw)
    )
end


"""
Displays current exception configurations for review.

Arguments:
- None

Returns:
- NamedTuple with all exception configuration constants

Rules:
- Prints all EXCLUDED_PREFIXES, PDF_ONLY_PREFIXES, SLUG_CORRECTIONS, DEPRECATED_SLUGS, UNDOCUMENTED_SLUGS, ADDITIONAL_SLUG_METADATA, GGIS_METADATA, and ID_VARIABLES
- Truncates long lists to first 10 items
- Useful for debugging configuration issues

Usage:
    config = inspect_exceptions()
"""
function inspect_exceptions()
    println("=" ^ 70)
    println("EXCEPTION CONFIGURATION REVIEW")
    println("=" ^ 70)
    
    println("\nEXCLUDED_PREFIXES ($(length(EXCLUDED_PREFIXES)) items):")
    for p in EXCLUDED_PREFIXES
        println("  - $p")
    end
    
    println("\nPDF_ONLY_PREFIXES (removed from pdf_df on ingest, $(length(PDF_ONLY_PREFIXES)) items):")
    for p in PDF_ONLY_PREFIXES
        println("  - $p")
    end
    
    println("\nSLUG_CORRECTIONS ($(length(SLUG_CORRECTIONS)) items):")
    if isempty(SLUG_CORRECTIONS)
        println("  (none)")
    else
        for (wrong, correct) in SLUG_CORRECTIONS
            println("  - \"$wrong\" => \"$correct\"")
        end
    end
    
    println("\nDEPRECATED_SLUGS ($(length(DEPRECATED_SLUGS)) items):")
    if isempty(DEPRECATED_SLUGS)
        println("  (none)")
    else
        for s in sort(collect(DEPRECATED_SLUGS))[1:min(10, length(DEPRECATED_SLUGS))]
            println("  - $s")
        end
        if length(DEPRECATED_SLUGS) > 10
            println("  ... and $(length(DEPRECATED_SLUGS) - 10) more")
        end
    end
    
    println("\nUNDOCUMENTED_SLUGS ($(length(UNDOCUMENTED_SLUGS)) items):")
    if isempty(UNDOCUMENTED_SLUGS)
        println("  (none)")
    else
        for s in sort(collect(UNDOCUMENTED_SLUGS))[1:min(10, length(UNDOCUMENTED_SLUGS))]
            println("  - $s")
        end
        if length(UNDOCUMENTED_SLUGS) > 10
            println("  ... and $(length(UNDOCUMENTED_SLUGS) - 10) more")
        end
    end
    
    println("\nADDITIONAL_SLUG_METADATA ($(length(ADDITIONAL_SLUG_METADATA)) items):")
    if isempty(ADDITIONAL_SLUG_METADATA)
        println("  (none)")
    else
        for (slug, _) in ADDITIONAL_SLUG_METADATA
            println("  - $slug")
        end
    end
    
    println("\nGGIS_METADATA ($(length(GGIS_METADATA)) items):")
    if isempty(GGIS_METADATA)
        println("  (none)")
    else
        for (slug, meta) in GGIS_METADATA
            println("  - $slug")
        end
    end
    
    println("\nID_VARIABLES ($(length(ID_VARIABLES)) items):")
    for v in ID_VARIABLES
        println("  - $v")
    end
    
    println("\n" * "=" ^ 70)
    
    return (
        excluded_prefixes = EXCLUDED_PREFIXES,
        pdf_only_prefixes = PDF_ONLY_PREFIXES,
        slug_corrections = SLUG_CORRECTIONS,
        deprecated_slugs = DEPRECATED_SLUGS,
        undocumented_slugs = UNDOCUMENTED_SLUGS,
        additional_slug_metadata = ADDITIONAL_SLUG_METADATA,
        ggis_metadata = GGIS_METADATA,
        id_variables = ID_VARIABLES
    )
end


"""
Prints usage examples and documentation for the metadata joining pipeline.

Arguments:
- None

Returns:
- Nothing (prints documentation to console)

Rules:
- Displays comprehensive usage guide
- Shows quick start, diagnostic tools, step-by-step execution (including validate_isomorphism check_column=:slug/:prefix)
- Includes configuration, ligature normalization note, and troubleshooting
- Keep this function updated when pipeline steps or options change

Usage:
    show_usage()
"""
function show_usage()
    println("""
    ═══════════════════════════════════════════════════════════════════════════
    QoG METADATA JOINING - PHASE 0
    ═══════════════════════════════════════════════════════════════════════════
    
    QUICK START
    -----------
    
    ```julia
    # Load the module
    include("functions/qog_metadata_join.jl")
    
    # Run complete pipeline (single isomorphism check; fails if full PDF not isomorphic)
    metadata = join_metadata()
    
    # Or: run isomorphism cascade (strictest → loosest until success), then union on slug
    metadata = join_metadata_with_cascade()
    
    # Inspect results
    first(metadata, 10)
    ```
    
    DIAGNOSTIC TOOLS
    ----------------
    
    ```julia
    # Quick file check (without processing)
    quick_check()
    
    # Review exception configurations
    inspect_exceptions()
    ```
    
    STEP-BY-STEP EXECUTION
    ----------------------
    
    ```julia
    # Step 1: Ingest and normalize (lowercase, ligature→ASCII, SLUG_CORRECTIONS; PDF_ONLY_PREFIXES removed; returns 4th: pdf_prefixes_df)
    (stata_df, pdf_df, arrow_df, pdf_prefixes_df) = ingest_and_normalize()
    
    # Step 2: Align ID variables
    align_id_variables!(stata_df, pdf_df, arrow_df)
    
    # Step 3: Validate isomorphism (optional: check_column=:slug or :prefix for single-column check)
    validate_isomorphism(stata_df, pdf_df, arrow_df)
    validate_isomorphism(stata_df, pdf_df, arrow_df; check_column=:slug)   # slug-only
    validate_isomorphism(stata_df, pdf_df, arrow_df; check_column=:prefix) # prefix-only
    
    # Step 3b: Isomorphism cascade (strictest → loosest until success); returns 3 isomorphic dfs for union on slug
    result = run_isomorphism_cascade(stata_df, pdf_df, arrow_df)
    stata_df, pdf_df, arrow_df = result.stata_df, result.pdf_df, result.arrow_df
    
    # Step 4: Unify and join (union on slug)
    metadata = unify_and_join(stata_df, pdf_df, arrow_df)

    # Step 5: Unify prefixes (metadata-driven; joins with PDF docs; injects ident/ggis)
    prefix_df = unify_prefixes(metadata, pdf_prefixes_df)

    # Save manually
    CSV.write("data/metadata_output.csv", metadata)
    CSV.write("data/qog_prefix_joined.csv", prefix_df)
    ```
    
    CONFIGURATION
    -------------
    
    Edit constants at top of file:
    
    - PATH_STATA_SLUGS, PATH_PDF_SLUGS, PATH_PDF_PREFIXES, PATH_ARROW_SLUGS — input paths
    - PATH_METADATA_JOINED, PATH_PREFIX_JOINED — output paths
    - PREFIXES_EXCLUDED_FROM_UNIFICATION — prefixes excluded from prefix output (base, missing)
    - EXCLUDED_PREFIXES — prefixes to exclude from isomorphism check
    - PDF_ONLY_PREFIXES — prefixes removed from pdf_df on ingest (ens, gdg, jht, qs20)
    - SLUG_CORRECTIONS — typo fixes (Dict{"wrong" => "correct"})
    - DEPRECATED_SLUGS — slugs in PDF but removed from data
    - UNDOCUMENTED_SLUGS — slugs in data but not in PDF (e.g. whr_hap)
    - ADDITIONAL_SLUG_METADATA — label/description for UNDOCUMENTED_SLUGS (e.g. whr_hap)
    - GGIS_METADATA — metadata for custom slugs
    - ID_VARIABLES — identification variables requiring special handling
    
    TROUBLESHOOTING
    ---------------
    
    If isomorphism validation fails:
    
    1. Review printed diagnostics (shows specific mismatches)
    2. Slugs that look identical but differ (e.g. atop_offensive vs atop_oﬀensive) are usually
       typographic ligatures (ﬀ, ﬁ, ﬂ) from PDF — ingest_and_normalize() normalizes these to ASCII.
       Re-run from ingest; if you load CSVs elsewhere, apply normalize_ligatures() to slug/prefix.
    3. For other mismatches: typo → SLUG_CORRECTIONS; deprecated → DEPRECATED_SLUGS;
       undocumented → UNDOCUMENTED_SLUGS. Then re-run pipeline.
    
    ═══════════════════════════════════════════════════════════════════════════
    """)
end


# ==============================================================================
# INITIALIZATION MESSAGE
# ==============================================================================

println("""
╔══════════════════════════════════════════════════════════════════════════╗
║ QoG METADATA JOINING - PHASE 0 LOADED                                ║
╚══════════════════════════════════════════════════════════════════════════╝

Quick Start:
    metadata = join_metadata()              # Run full pipeline (single isomorphism check)
    metadata = join_metadata_with_cascade()  # Run cascade (strictest → loosest), then union on slug
    quick_check()                             # Diagnostic check
    inspect_exceptions()                      # Review configuration
    show_usage()                              # Detailed documentation

Pipeline Steps:
    1. ingest_and_normalize()            # Load & normalize sources (PDF = qog_slugs_temporal.csv; min_year/max_year ingested)
    2. align_id_variables!(...)          # Harmonize ID vars
    3. run_isomorphism_cascade(...)      # Strictest → loosest until success; returns (stata_df, pdf_df, arrow_df) for union on slug
    4. unify_and_join(...)             # Union on slug & join (output includes min_year, max_year)
    5. unify_prefixes(...)               # Prefix-level metadata from isomorphic slugs + PDF docs; injects ident/ggis

Configuration: Edit constants at top of file
    - File paths: PATH_STATA_SLUGS, PATH_PDF_SLUGS, etc.
    - Exceptions: SLUG_CORRECTIONS, DEPRECATED_SLUGS, etc.
    - Metadata: GGIS_METADATA, ID_VARIABLES

═══════════════════════════════════════════════════════════════════════════
""")
