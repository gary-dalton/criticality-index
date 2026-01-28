# ==============================================================================
# QoG METADATA ENRICHMENT
# 
# Verifies slug alignment across sources and enriches metadata with:
# - Temporal lifespan (birth/death years, gaps)
# - Temporal profile classification
# - Regional and global penetration metrics
# ==============================================================================

using DataFrames
using CSV
using Arrow
using Statistics
using StatsBase

# ==============================================================================
# CONSTANTS
# ==============================================================================

"""
Manual corrections for slug typos discovered during verification.
Format: "wrong_slug" => "correct_slug"
Applied during normalization before comparison.
"""
const SLUG_CORRECTIONS = Dict{String, String}(
    # Add corrections here as discovered
    # "vdem_corr" => "vdem_cor",
)

"""
Slugs known to exist only in PDF documentation (deprecated/removed from data).
These are excluded from mismatch reporting.
"""
const DEPRECATED_SLUGS = Set{String}([
    # Add as discovered
])

"""
Slugs known to exist only in data (undocumented in PDF).
These are excluded from mismatch reporting but flagged for review.
"""
const UNDOCUMENTED_SLUGS = Set{String}([
    # Add as discovered
])

"""
Columns to exclude from slug comparison (our namespaces, not QoG native).
"""
const EXCLUDED_PREFIXES = ["ident_", "ggis_"]

"""
Current year for temporal calculations.
"""
const CURRENT_YEAR = 2024

"""
Threshold for considering a variable "active" (years since last data point).
Variables with data within this many years of current year are considered active.
"""
const ACTIVE_LAG_YEARS = 4

"""
Data span for QoG Standard dataset.
"""
const DATA_START_YEAR = 1946

"""
Data span end year for QoG Standard dataset.
"""
const DATA_END_YEAR = 2024

"""
Temporal profile decision boundaries.
"""
const TEMPORAL_THRESHOLDS = (
    anchor = 0.97,
    experimental = 0.15,
    legacy = 0.50,
    recent_pct = 0.25
)

"""
Temporal gap tolerance (years).
Missing years within lifespan exceeding this triggers `ggis_temporal_gap = true`.
"""
const TEMPORAL_GAP_TOLERANCE = 5

"""
Coverage type classification thresholds.
Adjust to tune global vs regional distinction.
"""
const COVERAGE_THRESHOLDS = (
    global_min_penetration = 60.0,    # ≥60% global → candidate for :global
    global_max_variance = 25.0,       # Regional std ≤25% → :global (not regionally skewed)
    regional_min_penetration = 40.0,  # ≥40% in at least one region
    regional_max_regions = 3,         # High penetration in ≤3 regions → :regional
    sparse_max_penetration = 15.0     # <15% global → :sparse
)

"""
Path to Stata manifest CSV (variable labels extracted from .dta file).
"""
const PATH_STATA_SLUGS = "data/qog_metadata_manifest.csv"

"""
Path to PDF extraction CSV (documentation, provenance from codebook).
"""
const PATH_PDF_SLUGS = "data/qog_slugs.csv"

"""
Path to extracted Arrow slugs CSV (all columns from augmented DataFrame)."""
const PATH_ARROW_SLUGS = "data/ggis_arrow_slugs.csv"

"""
Path to enriched metadata output.
"""
const PATH_METADATA_ENRICHED = "data/qog_metadata_enriched.csv"


# ==============================================================================
# SLUG EXTRACTION
# ==============================================================================

"""
Extracts slugs from Stata manifest CSV.

Usage:
    slugs = load_stata_slugs(PATH_STATA_SLUGS)
    slugs = load_stata_slugs(manifest_df)

Returns:
- Vector{String} of lowercase slug names with ident_* mapping applied

Rules:
- Wrapper around `extract_manifest_slugs` from qog_augmented_standard.jl
- Applies IDENT_MAPPING (ccode → ident_ccode, year → ident_year, etc.)
- Applies SLUG_CORRECTIONS for typo fixes
"""
function load_stata_slugs(source::Union{DataFrame, AbstractString})
    # Use the core extraction function from qog_augmented_standard.jl
    slugs = extract_manifest_slugs(source)
    
    # Apply corrections for known typos
    slugs = [get(SLUG_CORRECTIONS, s, s) for s in slugs]
    
    return slugs
end


"""
Extracts slugs from PDF extraction DataFrame.
Usage:
    slugs = load_pdf_slugs(pdf_df)
    slugs = load_pdf_slugs("data/qog_slugs.csv")
Returns:
- Vector{String} of lowercase slug names
Rules:
- Expects column named `slug`
- Normalizes to lowercase
- Applies SLUG_CORRECTIONS
"""
function load_pdf_slugs(source::Union{DataFrame, AbstractString})
    df = source isa DataFrame ? source : CSV.read(source, DataFrame)
    
    if !(:slug in propertynames(df))
        error("PDF extraction must contain a `slug` column.")
    end
    
    slugs = lowercase.(string.(df.slug))
    
    # Apply corrections
    slugs = [get(SLUG_CORRECTIONS, s, s) for s in slugs]
    
    return slugs
end


"""
Extracts slugs from Arrow extraction CSV (saved by extract_arrow_slugs).

Usage:
    slugs = load_arrow_slugs(PATH_ARROW_SLUGS)

Returns:
- Vector{String} of lowercase slug names (ALL columns from DataFrame)

Rules:
- Loads CSV saved by `extract_arrow_slugs` in qog_augmented_standard.jl
- Includes ident_*, ggis_*, ht_region, and all analytical slugs
"""
function load_arrow_slugs(path::AbstractString)
    df = CSV.read(path, DataFrame)
    if !(:slug in propertynames(df))
        error("Arrow extraction CSV must contain a `slug` column. Found: $(names(df))")
    end
    return lowercase.(string.(df.slug))
end


# ==============================================================================
# SLUG VERIFICATION
# ==============================================================================

"""
Compares DataFrame column slugs against Stata manifest slugs (case-sensitive).

This is a low-level diagnostic, useful for quick checks. In most workflows,
prefer `verify_slug_alignment(stata_slugs, pdf_slugs, arrow_slugs)` which applies
the full comparison rules (mapping, exclusions, "pretend ident", etc.).

Usage:
    result = compare_slug_alignment(df_aug, manifest)
    result = compare_slug_alignment(df_aug, manifest; strict=false)

Returns:
- NamedTuple with:
  - `ok::Bool`
  - `only_in_df::Vector{String}`
  - `only_in_manifest::Vector{String}`

Rules:
- Compares `names(df_aug)` against `manifest.Variable`
- If `strict=true` (default), throws an error when mismatches exist
- Ensures both sides are internally unique before comparison
"""
function compare_slug_alignment(df_aug::DataFrame, manifest::DataFrame; strict::Bool=true)
    if !(:Variable in propertynames(manifest))
        error("Manifest must contain a `Variable` column.")
    end

    df_slugs = String.(names(df_aug))
    manifest_slugs = String.(manifest.Variable)

    # internal uniqueness checks (helps catch upstream issues early)
    # (keep local here—do not depend on augmentation internals)
    let
        counts_df = StatsBase.countmap(df_slugs)
        dups_df = sort([k for (k, v) in counts_df if v > 1])
        if !isempty(dups_df)
            error("Duplicate names detected (df_aug column slugs): " * join(dups_df, ", "))
        end

        counts_m = StatsBase.countmap(manifest_slugs)
        dups_m = sort([k for (k, v) in counts_m if v > 1])
        if !isempty(dups_m)
            error("Duplicate names detected (manifest.Variable slugs): " * join(dups_m, ", "))
        end
    end

    only_in_df = sort(collect(setdiff(Set(df_slugs), Set(manifest_slugs))))
    only_in_manifest = sort(collect(setdiff(Set(manifest_slugs), Set(df_slugs))))
    ok = isempty(only_in_df) && isempty(only_in_manifest)

    if strict && !ok
        msg = "Slug alignment failed (case-sensitive).\n" *
              "  - only_in_df ($(length(only_in_df))): $(only_in_df)\n" *
              "  - only_in_manifest ($(length(only_in_manifest))): $(only_in_manifest)"
        error(msg)
    end

    return (ok=ok, only_in_df=only_in_df, only_in_manifest=only_in_manifest)
end


"""
Performs three-way slug alignment verification.
Usage:
    report = verify_slug_alignment(stata_slugs, pdf_slugs, arrow_slugs)
    report = verify_slug_alignment(; stata_path, pdf_path, df)
Returns:
- NamedTuple with:
  - `ok::Bool` — true if all sources align
  - `all_three::Vector{String}` — slugs in all sources
  - `stata_only::Vector{String}` — in Stata but not PDF
  - `pdf_only::Vector{String}` — in PDF but not Stata
  - `arrow_stata_mismatch::Vector{String}` — Arrow differs from Stata (should be empty!)
Rules:
- Stata and Arrow should ALWAYS match (same source)
- Stata and PDF should match (documentation = data)
- Excludes DEPRECATED_SLUGS and UNDOCUMENTED_SLUGS from error reporting
"""
function verify_slug_alignment(
    stata_slugs::Vector{String},
    pdf_slugs::Vector{String},
    arrow_slugs::Vector{String}
)
    stata_set = Set(stata_slugs)
    pdf_set = Set(pdf_slugs)
    arrow_set = Set(arrow_slugs)
    
    # Three-way intersection
    all_three = sort(collect(stata_set ∩ pdf_set ∩ arrow_set))
    
    # Stata vs PDF
    stata_only = sort(collect(setdiff(stata_set, pdf_set)))
    pdf_only = sort(collect(setdiff(pdf_set, stata_set)))
    
    # Arrow vs Stata (should be empty!)
    arrow_not_stata = sort(collect(setdiff(arrow_set, stata_set)))
    stata_not_arrow = sort(collect(setdiff(stata_set, arrow_set)))
    arrow_stata_mismatch = vcat(arrow_not_stata, stata_not_arrow)
    
    # Filter out known exceptions
    stata_only_filtered = filter(s -> s ∉ UNDOCUMENTED_SLUGS, stata_only)
    pdf_only_filtered = filter(s -> s ∉ DEPRECATED_SLUGS, pdf_only)
    
    # Report
    println("=" ^ 60)
    println("SLUG ALIGNMENT VERIFICATION")
    println("=" ^ 60)
    println("\n>>> Sources:")
    println("    Stata manifest: $(length(stata_slugs)) slugs")
    println("    PDF extraction: $(length(pdf_slugs)) slugs")
    println("    Arrow data:     $(length(arrow_slugs)) slugs (includes ident_*, ggis_*, ht_region, analytical)")
    
    println("\n>>> Alignment:")
    println("    In all three sources: $(length(all_three))")
    
    if !isempty(arrow_stata_mismatch)
        println("\n    ❌ CRITICAL: Arrow ≠ Stata ($(length(arrow_stata_mismatch)) slugs)")
        println("       This should NEVER happen — same source file!")
        for s in first(arrow_stata_mismatch, 10)
            println("         - $s")
        end
        if length(arrow_stata_mismatch) > 10
            println("         ... and $(length(arrow_stata_mismatch) - 10) more")
        end
    else
        println("    ✓ Arrow matches Stata perfectly")
    end
    
    if !isempty(stata_only_filtered)
        println("\n    ⚠️  In Stata/Arrow but NOT in PDF ($(length(stata_only_filtered)) slugs):")
        println("       (Undocumented variables — check PDF extraction)")
        for s in first(stata_only_filtered, 10)
            println("         - $s")
        end
        if length(stata_only_filtered) > 10
            println("         ... and $(length(stata_only_filtered) - 10) more")
        end
    end
    
    if !isempty(pdf_only_filtered)
        println("\n    ⚠️  In PDF but NOT in Stata/Arrow ($(length(pdf_only_filtered)) slugs):")
        println("       (Documented but removed — possibly deprecated)")
        for s in first(pdf_only_filtered, 10)
            println("         - $s")
        end
        if length(pdf_only_filtered) > 10
            println("         ... and $(length(pdf_only_filtered) - 10) more")
        end
    end
    
    ok = isempty(arrow_stata_mismatch) && isempty(stata_only_filtered) && isempty(pdf_only_filtered)
    
    if ok
        println("\n✅ All slug sources are aligned.")
    else
        println("\n⚠️  Slug alignment issues detected — review before proceeding.")
    end
    println("=" ^ 60)
    
    return (
        ok = ok,
        all_three = all_three,
        stata_only = stata_only,
        pdf_only = pdf_only,
        arrow_stata_mismatch = arrow_stata_mismatch,
        stata_only_filtered = stata_only_filtered,
        pdf_only_filtered = pdf_only_filtered
    )
end


# ==============================================================================
# TEMPORAL PROFILE CLASSIFICATION
# ==============================================================================

"""
Classifies a variable's temporal profile based on its lifespan.
Usage:
    profile = classify_temporal_profile(birth_year, death_year)
Returns:
- Symbol: `:anchor`, `:current`, `:modern`, `:legacy`, `:historical`, `:experimental`
Rules:
- :anchor     — ≥97% of data span (core variables present throughout)
- :experimental — <15% of data span (short-lived regardless of when)
- :legacy     — inactive, ≥50% usage (widely used but discontinued)
- :historical — inactive, <50% usage (limited historical use)
- :current    — active, introduced in last 25% of data span
- :modern     — active, not anchor or current
"""
function classify_temporal_profile(
    birth_year::Int,
    death_year::Int;
    data_start::Int = DATA_START_YEAR,
    data_end::Int = DATA_END_YEAR,
    current_year::Int = CURRENT_YEAR,
    active_lag::Int = ACTIVE_LAG_YEARS,
    thresholds::NamedTuple = TEMPORAL_THRESHOLDS
)
    data_span = data_end - data_start + 1
    var_span = death_year - birth_year + 1
    usage_pct = var_span / data_span
    
    is_active = death_year >= (current_year - active_lag)
    recent_start = data_end - round(Int, data_span * thresholds.recent_pct)
    
    if usage_pct >= thresholds.anchor
        return :anchor
    elseif usage_pct < thresholds.experimental
        return :experimental
    elseif !is_active && usage_pct >= thresholds.legacy
        return :legacy
    elseif !is_active
        return :historical
    elseif is_active && birth_year >= recent_start
        return :current
    elseif is_active
        return :modern
    else
        return :unclassified
    end
end


# ==============================================================================
# LIFESPAN COMPUTATION
# ==============================================================================

"""
Computes temporal lifespan metrics for each slug in the data.
Usage:
    lifespan_df = compute_variable_lifespan(df, slugs)
Returns:
- DataFrame with columns:
  - `slug` — variable name
  - `ggis_birth_year` — first year with data
  - `ggis_death_year` — last year with data (current year if active)
  - `ggis_is_active` — true if data within last 4 years
  - `ggis_temporal_gap` — true if non-contiguous years
  - `ggis_temporal_profile` — classification symbol
Rules:
- Scans actual data for each slug
- Detects gaps in year coverage
- Requires `ident_year` column in df
"""
function compute_variable_lifespan(df::DataFrame, slugs::Vector{String})
    if !(:ident_year in propertynames(df))
        error("DataFrame must contain `ident_year` column.")
    end
    
    results = DataFrame(
        slug = String[],
        ggis_birth_year = Int[],
        ggis_death_year = Int[],
        ggis_is_active = Bool[],
        ggis_temporal_gap = Bool[],
        ggis_temporal_profile = Symbol[]
    )
    
    # Get valid years from data
    valid_years = sort(unique(skipmissing(df.ident_year)))
    
    for slug in slugs
        slug_sym = Symbol(slug)
        
        # Skip if column doesn't exist
        if !(slug_sym in propertynames(df))
            continue
        end
        
        # Find years where this slug has data
        col_data = df[!, slug_sym]
        years_with_data = Int[]
        
        for (i, val) in enumerate(col_data)
            if !ismissing(val) && !ismissing(df.ident_year[i])
                push!(years_with_data, df.ident_year[i])
            end
        end
        
        if isempty(years_with_data)
            # No data for this slug — skip
            continue
        end
        
        years_with_data = sort(unique(years_with_data))
        
        birth_year = minimum(years_with_data)
        death_year = maximum(years_with_data)
        is_active = death_year >= (CURRENT_YEAR - ACTIVE_LAG_YEARS)
        
        # Detect temporal gaps
        expected_years = Set(birth_year:death_year)
        actual_years = Set(years_with_data)
        missing_years = setdiff(expected_years, actual_years)
        has_gap = length(missing_years) > TEMPORAL_GAP_TOLERANCE
        
        profile = classify_temporal_profile(birth_year, death_year)
        
        push!(results, (
            slug = slug,
            ggis_birth_year = birth_year,
            ggis_death_year = death_year,
            ggis_is_active = is_active,
            ggis_temporal_gap = has_gap,
            ggis_temporal_profile = profile
        ))
    end
    
    println(">>> Computed lifespan for $(nrow(results)) variables")
    
    # Summary by profile
    profile_counts = combine(groupby(results, :ggis_temporal_profile), nrow => :count)
    sort!(profile_counts, :count, rev=true)
    println("    By temporal profile:")
    for row in eachrow(profile_counts)
        println("      :$(row.ggis_temporal_profile) — $(row.count)")
    end
    
    return results
end


# ==============================================================================
# PENETRATION COMPUTATION
# ==============================================================================

"""
Computes regional and global penetration for each slug.
Usage:
    penetration_df = compute_variable_penetration(df, lifespan_df)
Returns:
- DataFrame with columns:
  - `slug` — variable name
  - `ggis_penetration` — Dict{Int, Float64} (region → %, 99 = global pop-weighted)
Rules:
- Denominator: country-years within variable's lifespan only
- Regional: country-year count percentage
- Global (region 99): population-weighted percentage
- Uses `ggis_region` for regional assignment
- Uses internal population measure for weighting
"""
function compute_variable_penetration(
    df::DataFrame,
    lifespan_df::DataFrame;
    pop_column::Symbol = :wdi_pop  # or whatever QoG's population variable is
)
    if !(:ggis_region in propertynames(df))
        error("DataFrame must contain `ggis_region` column. Run standardize_regions first.")
    end
    
    has_pop = pop_column in propertynames(df)
    if !has_pop
        @warn "Population column $pop_column not found — global penetration will use country count instead."
    end
    
    results = DataFrame(
        slug = String[],
        ggis_penetration = Dict{Int, Float64}[]
    )
    
    for row in eachrow(lifespan_df)
        slug = row.slug
        birth = row.ggis_birth_year
        death = row.ggis_death_year
        
        slug_sym = Symbol(slug)
        if !(slug_sym in propertynames(df))
            continue
        end
        
        # Filter to lifespan years
        mask = coalesce.(df.ident_year .>= birth, false) .& 
               coalesce.(df.ident_year .<= death, false)
        df_span = df[mask, :]
        
        penetration = Dict{Int, Float64}()
        
        # Regional penetration (country-year count)
        for region in 1:10
            region_mask = coalesce.(df_span.ggis_region .== region, false)
            df_region = df_span[region_mask, :]
            
            if nrow(df_region) == 0
                penetration[region] = 0.0
                continue
            end
            
            n_with_data = count(!ismissing, df_region[!, slug_sym])
            n_total = nrow(df_region)
            penetration[region] = round(n_with_data / n_total * 100, digits=1)
        end
        
        # Global penetration (population-weighted)
        if has_pop
            # Population-weighted
            df_valid = filter(r -> !ismissing(r[slug_sym]) && !ismissing(r[pop_column]), df_span)
            df_total = filter(r -> !ismissing(r[pop_column]), df_span)
            
            pop_with_data = sum(skipmissing(df_valid[!, pop_column]))
            pop_total = sum(skipmissing(df_total[!, pop_column]))
            
            penetration[99] = pop_total > 0 ? round(pop_with_data / pop_total * 100, digits=1) : 0.0
        else
            # Country-year count fallback
            n_with_data = count(!ismissing, df_span[!, slug_sym])
            n_total = nrow(df_span)
            penetration[99] = n_total > 0 ? round(n_with_data / n_total * 100, digits=1) : 0.0
        end
        
        push!(results, (slug = slug, ggis_penetration = penetration))
    end
    
    println(">>> Computed penetration for $(nrow(results)) variables")
    
    return results
end


# ==============================================================================
# UNIFIED METADATA BUILDER
# ==============================================================================

"""
Builds unified metadata table from all sources.
Usage:
    metadata = build_unified_metadata(stata_df, pdf_df, df_augmented)
Returns:
- DataFrame with all metadata columns merged
Rules:
- Joins Stata manifest, PDF extraction, and computed metrics
- Adds verification flags
- Lowercase all slug names
"""
function build_unified_metadata(
    stata_df::DataFrame,
    pdf_df::DataFrame,
    df_augmented::DataFrame
)
    # 1. Extract and verify slugs
    stata_slugs = load_stata_slugs(stata_df)
    pdf_slugs = load_pdf_slugs(pdf_df)
    arrow_slugs = load_arrow_slugs(df_augmented)
    
    alignment = verify_slug_alignment(stata_slugs, pdf_slugs, arrow_slugs)
    
    if !isempty(alignment.arrow_stata_mismatch)
        error("Critical: Arrow and Stata slugs do not match. Cannot proceed.")
    end
    
    # 2. Build base from Stata (authoritative for what's in data)
    # Normalize column names
    stata_normalized = copy(stata_df)
    rename!(stata_normalized, lowercase.(string.(names(stata_normalized))))
    
    if !(:variable in propertynames(stata_normalized))
        error("Stata manifest must have 'variable' column")
    end
    
    stata_normalized.slug = lowercase.(string.(stata_normalized.variable))
    select!(stata_normalized, Not(:variable))
    
    # 3. Normalize PDF extraction
    pdf_normalized = copy(pdf_df)
    rename!(pdf_normalized, lowercase.(string.(names(pdf_normalized))))
    pdf_normalized.slug = lowercase.(string.(pdf_normalized.slug))
    
    # 4. Merge Stata and PDF
    metadata = leftjoin(stata_normalized, pdf_normalized, on=:slug, makeunique=true)
    
    # 5. Add verification flags
    stata_set = Set(stata_slugs)
    pdf_set = Set(pdf_slugs)
    arrow_set = Set(arrow_slugs)
    
    metadata.ggis_in_stata = [s in stata_set for s in metadata.slug]
    metadata.ggis_in_pdf = [s in pdf_set for s in metadata.slug]
    metadata.ggis_in_data = [s in arrow_set for s in metadata.slug]
    
    # 6. Compute lifespan
    println("\n>>> Computing variable lifespans...")
    lifespan = compute_variable_lifespan(df_augmented, metadata.slug)
    metadata = leftjoin(metadata, lifespan, on=:slug)
    
    # 7. Compute penetration
    println("\n>>> Computing variable penetration...")
    penetration = compute_variable_penetration(df_augmented, lifespan)
    metadata = leftjoin(metadata, penetration, on=:slug)
    
    # 8. Classify coverage type
    println("\n>>> Classifying coverage types...")
    metadata.ggis_coverage_type = map(eachrow(metadata)) do r
        if ismissing(r.ggis_penetration)
            return :unknown
        end
        global_pen = get(r.ggis_penetration, 99, 0.0)
        regional_pen = Dict(k => v for (k, v) in r.ggis_penetration if k != 99)
        classify_coverage_type(global_pen, regional_pen)
    end
    
    # Summary by coverage type
    coverage_counts = combine(groupby(metadata, :ggis_coverage_type), nrow => :count)
    sort!(coverage_counts, :count, rev=true)
    println("    By coverage type:")
    for row in eachrow(coverage_counts)
        println("      :$(row.ggis_coverage_type) — $(row.count)")
    end
    
    println("\n>>> Unified metadata built: $(nrow(metadata)) variables")
    
    return metadata
end


# ==============================================================================
# CONVENIENCE WRAPPER
# ==============================================================================

"""
Full metadata enrichment pipeline.
Usage:
    metadata = enrich_metadata(df_augmented, stata_path, pdf_path)
    metadata = enrich_metadata(df_augmented, stata_path, pdf_path; save_path="data/metadata.csv")
Returns:
- Fully enriched metadata DataFrame
Rules:
- Loads sources, verifies alignment, computes all metrics
- Optionally saves to CSV
"""
function enrich_metadata(
    df_augmented::DataFrame,
    stata_path::AbstractString,
    pdf_path::AbstractString;
    save_path::Union{AbstractString, Nothing} = nothing
)
    stata_df = CSV.read(stata_path, DataFrame)
    pdf_df = CSV.read(pdf_path, DataFrame)
    
    metadata = build_unified_metadata(stata_df, pdf_df, df_augmented)
    
    if save_path !== nothing
        # Note: Dict columns need special handling for CSV
        # Convert penetration Dict to JSON string for storage
        metadata_save = copy(metadata)
        if :ggis_penetration in propertynames(metadata_save)
            metadata_save.ggis_penetration = [ismissing(d) ? "" : string(d) for d in metadata_save.ggis_penetration]
        end
        CSV.write(save_path, metadata_save)
        println(">>> Saved metadata to: $save_path")
    end
    
    return metadata
end


# ==============================================================================
# COVERAGE TYPE CLASSIFICATION
# ==============================================================================

"""
Classifies a variable's geographic coverage type based on penetration metrics.
Usage:
    coverage_type = classify_coverage_type(global_pct, regional_dict)
Returns:
- Symbol: `:global`, `:regional`, `:sparse`, `:unclassified`
Rules:
- :global       — high global penetration with low regional variance
- :regional     — high in some regions, low in others
- :sparse       — low penetration everywhere
- :unclassified — does not fit above categories (explore manually)
"""
function classify_coverage_type(
    global_penetration::Float64,
    regional_penetration::Dict{Int, Float64};
    thresholds::NamedTuple = COVERAGE_THRESHOLDS
)
    # Extract regional values (keys 1-10 only)
    regional_values = [get(regional_penetration, r, 0.0) for r in 1:10]
    regional_std = std(regional_values)
    regional_max = maximum(regional_values)
    regions_above_threshold = count(v -> v >= thresholds.regional_min_penetration, regional_values)
    
    # Classification logic
    if global_penetration < thresholds.sparse_max_penetration
        return :sparse
    elseif global_penetration >= thresholds.global_min_penetration && 
           regional_std <= thresholds.global_max_variance
        return :global
    elseif regional_max >= thresholds.regional_min_penetration && 
           regions_above_threshold <= thresholds.regional_max_regions
        return :regional
    else
        return :unclassified
    end
end


# ==============================================================================
# EXAMPLES & METHODOLOGY
# ==============================================================================

"""
Comprehensive documentation of the metadata enrichment pipeline.

This function prints methodology and code examples for reference.
It does NOT execute any code — use it as a quick reference guide.

Usage:
    run_enrichment_examples()              # Print all documentation
    run_enrichment_examples(section=:all)  # Same as above
    run_enrichment_examples(section=:prereq)   # Prerequisites only
    run_enrichment_examples(section=:slugs)    # Slug extraction
    run_enrichment_examples(section=:align)    # Alignment verification
    run_enrichment_examples(section=:lifespan) # Temporal lifespan
    run_enrichment_examples(section=:penetration) # Penetration
    run_enrichment_examples(section=:coverage) # Coverage type
    run_enrichment_examples(section=:build)    # Build metadata
    run_enrichment_examples(section=:query)    # Query examples
    run_enrichment_examples(section=:jupyter)  # Jupyter workflow
    run_enrichment_examples(section=:summary)  # Minimal pipeline
"""
function run_enrichment_examples(; section::Symbol = :all, execute::Bool = false)
    
    if execute
        println("⚠️  execute=true is not implemented.")
        println("    This function is for documentation only.")
        println("    Copy code blocks to your REPL or notebook to run them.")
        return nothing
    end
    
    sections = Dict(
        :prereq => print_section_prerequisites,
        :slugs => print_section_slug_extraction,
        :align => print_section_alignment,
        :lifespan => print_section_lifespan,
        :penetration => print_section_penetration,
        :coverage => print_section_coverage,
        :build => print_section_build,
        :query => print_section_query,
        :jupyter => print_jupyter_workflow,
        :summary => print_section_summary
    )
    
    if section == :all
        println("=" ^ 70)
        println("QoG METADATA ENRICHMENT - Complete Pipeline Guide")
        println("=" ^ 70)
        println("\n📖 This is DOCUMENTATION ONLY — no code is executed.")
        println("   Copy code blocks to your REPL or notebook to run them.\n")
        
        for (_, printer) in sort(collect(sections), by = x -> string(x[1]))
            printer()
        end
        
        println("=" ^ 70)
        println("Documentation complete.")
        println("=" ^ 70)
    elseif haskey(sections, section)
        println("=" ^ 70)
        println("QoG METADATA ENRICHMENT - Section: $section")
        println("=" ^ 70)
        println("\n📖 DOCUMENTATION ONLY — copy code to REPL to execute.\n")
        sections[section]()
        println("=" ^ 70)
    else
        println("Unknown section: $section")
        println("Available sections: $(join(keys(sections), ", "))")
    end
    
    return nothing
end


# ==============================================================================
# SECTION PRINTERS (Documentation Only)
# ==============================================================================

function print_section_prerequisites()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ PREREQUISITES                                                           │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Before running metadata enrichment, you need:
    
    1. Augmented QoG data (from qog_augmented_standard.jl)
    2. Stata manifest (variable labels extracted from .dta file)
    3. PDF slug extraction (from extract_qog.jl)
    
    ```julia
    # Load dependencies
    using DataFrames, CSV, Arrow, Statistics
    
    # Load the augmentation functions
    include("functions/qog_augmented_standard.jl")
    include("functions/qog_metadata_enrichment.jl")
    
    # Prepare augmented data
    df = load_raw_ident(PATH_TS_RAW)
    df = rescue_historical_ccodes(df)
    df = standardize_regions(df)
    
    # Verify row count preserved
    @assert nrow(df) > 0 "Data loading failed"
    println("Loaded \$(nrow(df)) rows, \$(ncol(df)) columns")
    ```
    """)
end


function print_section_slug_extraction()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ SLUG EXTRACTION                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
    
    We have three sources of variable names (slugs):
    
    | Source | Constant | File |
    |--------|----------|------|
    | Stata manifest | PATH_STATA_SLUGS | data/qog_metadata_manifest.csv |
    | PDF extraction | PATH_PDF_SLUGS | data/qog_slugs.csv |
    | Arrow data | (from DataFrame) | qog_std_ts_jan25.arrow |
    
    ```julia
    # Extract slugs from each source
    stata_slugs = load_stata_slugs(PATH_STATA_SLUGS)
    pdf_slugs = load_pdf_slugs(PATH_PDF_SLUGS)
    arrow_slugs = load_arrow_slugs(df)
    
    # Quick counts
    println("Stata:  \$(length(stata_slugs)) slugs")
    println("PDF:    \$(length(pdf_slugs)) slugs")
    println("Arrow:  \$(length(arrow_slugs)) slugs (includes ident_*, ggis_*, ht_region, analytical)")
    ```
    
    Functions:
    - `load_stata_slugs(path)` — extracts from manifest CSV
    - `load_pdf_slugs(path)` — extracts from PDF extraction CSV
    - `load_arrow_slugs(df)` — extracts column names, excluding our namespaces
    """)
end


function print_section_alignment()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ SLUG ALIGNMENT VERIFICATION                                             │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Critical verification: all three sources should agree on variable names.
    
    Expected outcomes:
    - Arrow == Stata (ALWAYS — same source file)
    - Stata == PDF (should match — if not, investigate)
    
    ```julia
    alignment = verify_slug_alignment(stata_slugs, pdf_slugs, arrow_slugs)
    
    # Inspect results
    alignment.ok                     # true if perfect alignment
    length(alignment.all_three)      # slugs in all three sources
    alignment.stata_only             # in data but not documented (concern!)
    alignment.pdf_only               # documented but not in data (deprecated?)
    alignment.arrow_stata_mismatch   # should be EMPTY (critical error if not)
    ```
    
    Handling mismatches:
    
    ```julia
    # For typos, add to SLUG_CORRECTIONS constant:
    const SLUG_CORRECTIONS = Dict("wrong_name" => "correct_name")
    
    # For known undocumented slugs:
    const UNDOCUMENTED_SLUGS = Set(["slug1", "slug2"])
    
    # For known deprecated slugs:
    const DEPRECATED_SLUGS = Set(["old_slug1", "old_slug2"])
    ```
    """)
end


function print_section_lifespan()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ TEMPORAL LIFESPAN                                                       │
    └─────────────────────────────────────────────────────────────────────────┘
    
    For each slug, determine:
    - Birth year (first year with any data)
    - Death year (last year with data; current year if still active)
    - Whether it's still active (data within last 4 years)
    - Whether there are temporal gaps (>5 missing years within lifespan)
    - Temporal profile classification
    
    ```julia
    # Compute lifespan for all slugs
    lifespan_df = compute_variable_lifespan(df, arrow_slugs)
    
    # Inspect results
    first(lifespan_df, 10)
    
    # Check temporal profile distribution
    combine(groupby(lifespan_df, :ggis_temporal_profile), nrow => :count)
    ```
    
    Temporal profile meanings:
    
    | Profile | Criteria | Use Case |
    |---------|----------|----------|
    | :anchor | ≥97% of data span | Core variables, safe for long panels |
    | :modern | Active, not anchor/current | Good for recent analysis |
    | :current | Active, introduced in last 25% of span | New indicators |
    | :legacy | Inactive, ≥50% coverage | Historical analysis only |
    | :historical | Inactive, <50% coverage | Limited historical use |
    | :experimental | <15% of data span | Pilot/discontinued |
    
    Thresholds (adjustable via TEMPORAL_THRESHOLDS constant):
    ```julia
    TEMPORAL_THRESHOLDS = (
        anchor = 0.97,
        experimental = 0.15,
        legacy = 0.50,
        recent_pct = 0.25
    )
    ```
    """)
end


function print_section_penetration()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ PENETRATION COMPUTATION                                                 │
    └─────────────────────────────────────────────────────────────────────────┘
    
    For each slug, calculate:
    - Regional penetration (% of country-years with data, per region)
    - Global penetration (population-weighted %)
    
    ```julia
    # Compute penetration (requires lifespan_df from previous step)
    penetration_df = compute_variable_penetration(df, lifespan_df)
    
    # Inspect a single variable's penetration
    row = first(filter(r -> r.slug == "wdi_gdp", penetration_df))
    println("wdi_gdp penetration:")
    for (region, pct) in sort(collect(row.ggis_penetration))
        region_name = region == 99 ? "Global" : "Region \$region"
        println("  \$region_name: \$pct%")
    end
    ```
    
    Penetration dictionary structure:
    - Keys 1-10: Regional penetration (country-year count %)
    - Key 99: Global penetration (population-weighted %)
    
    Regional codes:
    
    | Code | Region |
    |------|--------|
    | 1 | Eastern Europe & post-Soviet |
    | 2 | Latin America |
    | 3 | MENA |
    | 4 | Sub-Saharan Africa |
    | 5 | Western Europe & North America |
    | 6 | East Asia |
    | 7 | Southeast Asia |
    | 8 | South Asia |
    | 9 | Pacific |
    | 10 | Caribbean |
    | 99 | Global (population-weighted) |
    
    Denominator: Country-years within the variable's lifespan only.
    """)
end


function print_section_coverage()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ COVERAGE TYPE CLASSIFICATION                                            │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Based on penetration patterns, classify each variable:
    
    | Type | Meaning |
    |------|---------|
    | :global | High penetration, low regional variance |
    | :regional | High in some regions, low in others |
    | :sparse | Low penetration everywhere |
    | :unclassified | Doesn't fit above — explore via clustering |
    
    ```julia
    # Classify a single variable
    global_pen = 85.0
    regional_pen = Dict(1 => 85.0, 2 => 78.0, 3 => 82.0, 4 => 75.0, 5 => 90.0,
                        6 => 88.0, 7 => 80.0, 8 => 77.0, 9 => 65.0, 10 => 70.0)
    coverage = classify_coverage_type(global_pen, regional_pen)
    println("Coverage type: \$coverage")  # Should be :global
    ```
    
    Thresholds (adjustable via COVERAGE_THRESHOLDS constant):
    ```julia
    COVERAGE_THRESHOLDS = (
        global_min_penetration = 60.0,   # ≥60% global for :global candidate
        global_max_variance = 25.0,      # Low regional std for :global
        regional_min_penetration = 40.0, # ≥40% in region to count
        regional_max_regions = 3,        # ≤3 high regions → :regional
        sparse_max_penetration = 15.0    # <15% global → :sparse
    )
    ```
    """)
end


function print_section_build()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ BUILD UNIFIED METADATA                                                  │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Combine all sources and computed metrics into one table:
    
    ```julia
    # Option 1: Full control
    stata_df = CSV.read(PATH_STATA_SLUGS, DataFrame)
    pdf_df = CSV.read(PATH_PDF_SLUGS, DataFrame)
    metadata = build_unified_metadata(stata_df, pdf_df, df)
    
    # Option 2: Convenience wrapper (loads CSVs for you)
    metadata = enrich_metadata(
        df,
        PATH_STATA_SLUGS,
        PATH_PDF_SLUGS;
        save_path = PATH_METADATA_ENRICHED
    )
    ```
    
    Result columns:
    
    | Column | Source | Description |
    |--------|--------|-------------|
    | slug | All | Variable name (lowercase) |
    | label | Stata | Human-readable description |
    | prefix | PDF | Data source prefix (wdi, vdem, etc.) |
    | description | PDF | Full documentation |
    | provenance | PDF | Data provenance type |
    | ggis_in_stata | Computed | Present in Stata manifest |
    | ggis_in_pdf | Computed | Present in PDF documentation |
    | ggis_in_data | Computed | Present in actual data |
    | ggis_birth_year | Computed | First year with data |
    | ggis_death_year | Computed | Last year with data |
    | ggis_is_active | Computed | Data within last 4 years |
    | ggis_temporal_gap | Computed | Non-contiguous years detected |
    | ggis_temporal_profile | Computed | :anchor, :modern, etc. |
    | ggis_penetration | Computed | Dict{Int,Float64} of penetration |
    | ggis_coverage_type | Computed | :global, :regional, :sparse, :unclassified |
    """)
end


function print_section_query()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ QUERY METADATA FOR VARIABLE SELECTION                                   │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Use the enriched metadata to select variables for analysis:
    
    ```julia
    # Find globally-available anchor variables (best for long-term global analysis)
    best_vars = filter(metadata) do r
        r.ggis_temporal_profile == :anchor &&
        get(r.ggis_penetration, 99, 0.0) >= 70.0
    end
    println("\$(nrow(best_vars)) high-quality global variables")
    
    # Find variables good for Sub-Saharan Africa (region 4)
    ssa_vars = filter(metadata) do r
        get(r.ggis_penetration, 4, 0.0) >= 50.0 &&
        r.ggis_is_active == true
    end
    println("\$(nrow(ssa_vars)) active variables with ≥50% SSA coverage")
    
    # Find modern variables (introduced recently, still active)
    modern_vars = filter(r -> r.ggis_temporal_profile == :current, metadata)
    println("\$(nrow(modern_vars)) recently-introduced variables")
    
    # Find variables from a specific source
    vdem_vars = filter(r -> startswith(r.slug, "vdem_"), metadata)
    println("\$(nrow(vdem_vars)) V-Dem variables")
    
    # Find variables with temporal gaps (need investigation)
    gapped_vars = filter(r -> coalesce(r.ggis_temporal_gap, false), metadata)
    println("\$(nrow(gapped_vars)) variables with temporal gaps")
    
    # Get selected slugs for subsetting data
    selected_slugs = best_vars.slug
    df_subset = select(df, vcat([:ident_ccode, :ident_year], Symbol.(selected_slugs)))
    ```
    """)
end


function print_section_summary()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ SUMMARY: MINIMAL COMPLETE PIPELINE                                      │
    └─────────────────────────────────────────────────────────────────────────┘
    
    ```julia
    # === COMPLETE PIPELINE IN ~10 LINES ===
    
    using DataFrames, CSV, Arrow, Statistics
    
    # 1. Load functions
    include("functions/qog_augmented_standard.jl")
    include("functions/qog_metadata_enrichment.jl")
    
    # 2. Augment data
    df = load_raw_ident(PATH_TS_RAW)
    df = rescue_historical_ccodes(df)
    df = standardize_regions(df)
    
    # 3. Enrich metadata (single call does everything)
    metadata = enrich_metadata(
        df,
        PATH_STATA_SLUGS,
        PATH_PDF_SLUGS;
        save_path = PATH_METADATA_ENRICHED
    )
    
    # 4. Select variables for your analysis
    my_vars = filter(metadata) do r
        r.ggis_is_active &&
        get(r.ggis_penetration, 99, 0.0) >= 50.0
    end
    
    println("Selected \$(nrow(my_vars)) variables for analysis")
    ```
    """)
end


"""
Prints the Jupyter workflow for exploring unclassified slugs via clustering.

This is DOCUMENTATION ONLY — copy code cells to a Jupyter notebook to execute.

Methodology:
1. Extract penetration vectors (10 dimensions, one per region)
2. Optionally normalize (row or z-score)
3. Apply K-means to find clusters
4. Use PCA to visualize clusters in 2D
5. Interpret clusters based on regional dominance
6. Assign new coverage types based on findings
"""
function print_jupyter_workflow()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ JUPYTER WORKFLOW: Clustering Unclassified Slugs                         │
    └─────────────────────────────────────────────────────────────────────────┘
    
    📖 Copy these cells to a Jupyter notebook to execute.
    
    Goal: Discover patterns in variables classified as :unclassified
    Method: K-means clustering on regional penetration vectors
    
    Required packages:
        Pkg.add(["Clustering", "MultivariateStats"])
    
    # -------------------------------------------------------------------------
    # Cell 1: Setup and Load Data
    # -------------------------------------------------------------------------
    ```julia
    using DataFrames, CSV, Statistics
    using Clustering           # K-means, hierarchical
    using MultivariateStats    # PCA
    
    # Load enriched metadata
    metadata = CSV.read("data/qog_metadata_enriched.csv", DataFrame)
    
    # Parse penetration dict from string if needed
    if eltype(metadata.ggis_penetration) <: AbstractString
        metadata.ggis_penetration = parse_penetration_dict.(metadata.ggis_penetration)
    end
    ```
    
    # -------------------------------------------------------------------------
    # Cell 2: Filter to Unclassified
    # -------------------------------------------------------------------------
    ```julia
    # Add coverage type if not present
    if !(:ggis_coverage_type in propertynames(metadata))
        metadata.ggis_coverage_type = map(eachrow(metadata)) do r
            pen = r.ggis_penetration
            global_pen = get(pen, 99, 0.0)
            regional_pen = Dict(k => v for (k,v) in pen if k != 99)
            classify_coverage_type(global_pen, regional_pen)
        end
    end
    
    unclassified = filter(r -> r.ggis_coverage_type == :unclassified, metadata)
    println("Exploring \$(nrow(unclassified)) unclassified variables")
    ```
    
    # -------------------------------------------------------------------------
    # Cell 3: Build Penetration Matrix
    # -------------------------------------------------------------------------
    ```julia
    pen_matrix, slug_labels = extract_penetration_matrix(unclassified; normalize=:none)
    println("Matrix: \$(size(pen_matrix)) (slugs × regions)")
    ```
    
    # -------------------------------------------------------------------------
    # Cell 4: K-means Clustering
    # -------------------------------------------------------------------------
    ```julia
    X = pen_matrix'  # Clustering.jl expects features × observations
    
    # Try k = 2 to 6
    for k in 2:6
        result = kmeans(X, k; maxiter=200)
        println("k=\$k: WCSS=\$(round(sum(result.costs), digits=1))")
    end
    
    # Select best k (elbow method)
    k_best = 4
    clusters = kmeans(X, k_best)
    unclassified.cluster = clusters.assignments
    ```
    
    # -------------------------------------------------------------------------
    # Cell 5: Interpret Clusters
    # -------------------------------------------------------------------------
    ```julia
    region_names = Dict(
        1 => "E.Europe", 2 => "LatAm", 3 => "MENA", 4 => "SSA",
        5 => "W.Europe/NA", 6 => "E.Asia", 7 => "SE.Asia",
        8 => "S.Asia", 9 => "Pacific", 10 => "Caribbean"
    )
    
    for c in 1:k_best
        center = clusters.centers[:, c]
        top = sortperm(center, rev=true)[1:3]
        println("Cluster \$c: Top regions = \$([region_names[i] for i in top])")
    end
    ```
    
    # -------------------------------------------------------------------------
    # Cell 6: PCA Visualization
    # -------------------------------------------------------------------------
    ```julia
    pca = fit(PCA, pen_matrix'; maxoutdim=2)
    coords = MultivariateStats.transform(pca, pen_matrix')'
    
    unclassified.pc1 = coords[:, 1]
    unclassified.pc2 = coords[:, 2]
    
    # Plot with your preferred library (VegaLite, Plots, etc.)
    ```
    
    # -------------------------------------------------------------------------
    # Cell 7: Assign Labels and Export
    # -------------------------------------------------------------------------
    ```julia
    CLUSTER_LABELS = Dict(1 => :oecd_centric, 2 => :developing, 3 => :post_soviet, 4 => :mixed)
    unclassified.proposed_type = [CLUSTER_LABELS[c] for c in unclassified.cluster]
    
    CSV.write("data/unclassified_review.csv", 
        select(unclassified, [:slug, :cluster, :proposed_type]))
    ```
    """)
end


# ==============================================================================
# CLUSTERING UTILITIES
# ==============================================================================

"""
Extracts penetration matrix from metadata DataFrame.

Usage:
    pen_matrix, slugs = extract_penetration_matrix(metadata)
    pen_matrix, slugs = extract_penetration_matrix(metadata; normalize=:row)

Arguments:
- `metadata` — DataFrame with `slug` and `ggis_penetration` columns
- `normalize` — Normalization method:
  - `:none`   — Raw percentages (default)
  - `:zscore` — Standardize each region column (mean=0, std=1)
  - `:row`    — Normalize each row to sum to 1 (proportional profile)

Returns:
- `pen_matrix` — Matrix (n_slugs × 10 regions)
- `slugs` — Vector of slug names (row labels)
"""
function extract_penetration_matrix(
    metadata::DataFrame;
    normalize::Symbol = :none
)
    # Filter to rows with penetration data
    has_pen = .!ismissing.(metadata.ggis_penetration)
    df_valid = metadata[has_pen, :]
    
    slugs = df_valid.slug
    n_slugs = length(slugs)
    
    # Build matrix (regions 1-10 only, exclude 99)
    pen_matrix = zeros(Float64, n_slugs, 10)
    for (i, pen_dict) in enumerate(df_valid.ggis_penetration)
        for r in 1:10
            pen_matrix[i, r] = get(pen_dict, r, 0.0)
        end
    end
    
    # Normalize
    if normalize == :zscore
        for r in 1:10
            col = pen_matrix[:, r]
            μ, σ = mean(col), std(col)
            pen_matrix[:, r] = σ > 0 ? (col .- μ) ./ σ : zeros(n_slugs)
        end
    elseif normalize == :row
        for i in 1:n_slugs
            row_sum = sum(pen_matrix[i, :])
            if row_sum > 0
                pen_matrix[i, :] ./= row_sum
            end
        end
    elseif normalize != :none
        error("Unknown normalize method: $normalize. Use :none, :zscore, or :row")
    end
    
    return pen_matrix, slugs
end


"""
    parse_penetration_dict(s::AbstractString) -> Dict{Int, Float64}

Parses a penetration dictionary from its string representation.

Used when loading metadata from CSV, where Dict columns are serialized as strings.

# Example
```julia
s = "Dict{Int64, Float64}(1 => 45.2, 2 => 33.1, 99 => 55.0)"
d = parse_penetration_dict(s)
# Dict{Int64, Float64} with 3 entries:
#   1  => 45.2
#   2  => 33.1
#   99 => 55.0
```
"""
function parse_penetration_dict(s::AbstractString)
    if isempty(s) || s == "missing" || s == "nothing"
        return Dict{Int, Float64}()
    end
    
    pairs = Dict{Int, Float64}()
    for m in eachmatch(r"(\d+)\s*=>\s*([\d.]+)", s)
        key = parse(Int, m.captures[1])
        val = parse(Float64, m.captures[2])
        pairs[key] = val
    end
    
    return pairs
end