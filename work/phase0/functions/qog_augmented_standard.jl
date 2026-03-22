# ==============================================================================
# QUALITY OF GOVERNMENT (QoG) - AUGMENTED STANDARD (AS)
# 
# PREFIX SCHEMA:
# 1. ident_ : Topological Coordinates (Where/When). Protected namespace.
# 2. ggis_  : Operational Intelligence (Internal Logic/Quality Gates).
# 3. [src]_ : Analytical Sensors (Source Observations - e.g., wdi_, vdem_).
# 
# Note: ht_region remains prefix-free as the primary Anchor Cluster.
#
# File: qog_augmented_standard.jl
# ==============================================================================

using Arrow
using DataFrames
using CSV
using Statistics
using StatsBase
using ReadStatTables
using HTTP
using JSON
using Downloads
using Logging
using Markdown
using SHA
using VegaLite, VegaDatasets

# ==============================================================================
# SYSTEM CONSTANTS
# ==============================================================================

# --- Path Constants ---

"""
Path contract:
- These path strings are *relative to the process working directory* (`pwd()`).
- Functions in this file typically materialize them via `joinpath(pwd(), PATH_DATA_DIR)` etc.
- If you run code from a different working directory, these paths will resolve differently.
  (If you want stability across run locations, consider anchoring paths to `@__DIR__`.)
"""

"""Relative directory where QoG source files and pipeline artifacts are stored."""
const PATH_DATA_DIR = "data/"

"""Arrow-converted QoG Standard Time-Series (primary raw time-series input after conversion)."""
const PATH_TS_RAW = "data/qog_std_ts_jan25.arrow"
const PATH_TS_RAW_AUG = "data/qog_std_ts_jan25_aug.arrow"

"""DEPRECATED: CSV adjunct: per-row validity flag(s) used to mask/ignore structurally invalid observations."""
const PATH_VALIDITY_MASK = "data/ggis_validity_mask.csv"

"""CSV manifest extracted from the *raw Stata* file (variable names + labels + inferred prefix)."""
const PATH_MANIFEST_SRC = "data/qog_metadata_manifest.csv"

"""CSV manifest produced by your augmentation/standardization pipeline (post-processing results)."""
const PATH_MANIFEST_RESULT = "data/ggis_metadata_manifest.csv"

"""Raw QoG Standard Time-Series Stata file (.dta) used for high-fidelity metadata extraction."""
const PATH_TS_STRATA_RAW = "data/qog_std_ts_jan25.dta"

"""Lookup table mapping countries to `ht_region` (authoritative region reconstruction input)."""
const PATH_COUNTRY_REGION_LOOKUP = "data/ggis_country_region_lookup.csv"

"""Output table from prefix fidelity auditing (regional footprint / coverage diagnostics)."""
const PATH_PREFIX_GRH_FIDELITY = "data/ggis_prefix_grh_fidelity.csv"

"""Path to extracted Arrow slugs CSV (all columns from augmented DataFrame)."""
const PATH_ARROW_SLUGS = "data/ggis_arrow_slugs.csv"

"""Path to extracted PDF slugs CSV (all QoG codes form Section 4.*)."""
const PATH_PDF_SLUGS = "./data/qog_slugs.csv"

"""CSV geographic lookup table for mapping QoG country codes to UN Subregion codes."""
const PATH_GEO_LOOKUP = joinpath(PATH_DATA_DIR, "ggis_geographic_lookup.csv")


# --- Source URLs ---

"""
Public URLs for the official QoG releases consumed by this pipeline.

Contract:
- These are expected to be direct file URLs.
- `download_qog_sources` downloads each URL to `PATH_DATA_DIR` using its `basename(url)`.
- `convert_csv_to_arrow` converts the corresponding local `.csv` files to `.arrow`.
"""
const QOG_SOURCES = [
    # "https://www.qogdata.pol.gu.se/data/qog_bas_cs_jan25.csv",
    # "https://www.qogdata.pol.gu.se/data/qog_bas_ts_jan25.csv",
    # "https://www.qogdata.pol.gu.se/data/qog_std_cs_jan25.csv",
    "https://www.qogdata.pol.gu.se/data/qog_std_ts_jan25.csv",
    "https://www.qogdata.pol.gu.se/data/qog_std_cs_jan25.dta",
    "https://www.qogdata.pol.gu.se/data/codebook_std_jan25.pdf",
]


# --- Reference Data ---

"""
`ht_region` label dictionary used for reporting.

Notes:
- `ht_region` is intentionally prefix-free (anchor cluster in the Augmented Standard).
- Code list is QoG's 1–10 regional taxonomy; 0 is reserved for "GLOBAL TOTAL" in reports.
"""
const REGION_LABELS = DataFrame(
    ht_region = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    Region_Name = [
        "Eastern Europe and post Soviet Union (including Central Asia)",
        "Latin America (including Cuba, Haiti & the Dominican Republic)",
        "North Africa & the Middle East (including Israel, Turkey & Cyprus)",
        "Sub-Saharan Africa",
        "Western Europe and North America (including Australia & New Zealand)",
        "East Asia (including Japan & Mongolia)",
        "South-East Asia",
        "South Asia",
        "The Pacific (excluding Australia & New Zealand)",
        "The Caribbean"
    ]
)

# Define manual mappings for historical/non-UN entities
const GHOST_REGION_MAP = Dict(
    9156 => (name = "Tibet", code = 145),      # Eastern Asia (synthetic ccode)
    891  => (name = "Yugoslavia", code = 39),   # Southern Europe (dissolved)
)

# --- Identity Mapping ---

"""
Mapping from QoG raw identifier column names to the protected `ident_` namespace.

Contract:
- Keys are raw column names (as they appear in QoG).
- Values are the standardized names used across the pipeline.
- `load_raw_ident` applies this mapping only for keys present in the loaded file.
"""
const IDENT_MAPPING = Dict(
    "ccode"         => "ident_ccode",
    "ccode_qog"     => "ident_ccode_qog",
    "ccodealp"      => "ident_ccodealp",
    "ccodealp_year" => "ident_ccodealp_year",
    "ccodecow"      => "ident_ccodecow",
    "ccodewb"       => "ident_ccodewb",
    "cname"         => "ident_cname",
    "cname_qog"     => "ident_cname_qog",
    "cname_year"    => "ident_cname_year",
    "version"       => "ident_version",
    "year"          => "ident_year"
)


# --- Historical State Mappings ---

"""
Maps historical Alpha-3 codes to their ISO-3166-1 numeric Successor IDs.

These are indeterminate states with split/merge histories where QoG lacks a numeric ccode
but we can reasonably assign one based on the alpha code.

IMPORTANT: Uses ISO-3166-1 numeric codes (ident_ccode), NOT COW codes (ident_ccodecow).

Collision handling:
- VDR → 704 intentionally collides with VNM; resolved via COLLISION_PRIORITY_ALPHAS
- SCG uses 688 (Serbia's ISO code) since 891 (Yugoslavia) is already occupied by YUG
"""
const HISTORICAL_CCODE_MAP = Dict{String, Int}(
    "DEU" => 276,  # Germany (ISO: 276, was split as DEU/DDR)
    "ETH" => 231,  # Ethiopia (ISO: 231, stable through 1993 Eritrea split)
    "MHL" => 584,  # Marshall Islands (ISO: 584)
    "SCG" => 688,  # Serbia and Montenegro → Serbia (ISO: 688); 891 is YUG
    "YEM" => 887,  # Yemen (ISO: 887)
    "VNM" => 704,  # Vietnam (ISO: 704) — SUCCESSOR
    "VDR" => 704,  # South Vietnam → unified Vietnam (ISO: 704) — INTENTIONAL COLLISION
    "XTI" => 9156, # Tibet (no ISO code; synthetic placeholder)
)

"""
Alpha codes to prefer when resolving year collisions.
The first match in this list wins. These are the "successor" states.

Used when multiple alpha codes map to the same ccode (e.g., VNM vs VDR both → 704).
"""
const COLLISION_PRIORITY_ALPHAS = ["VNM", "DEU", "YEM", "ETH", "SCG"]


# --- Region Assignments for Rescued Entities ---
# MOVED HERE: Must be defined BEFORE standardize_regions()

"""
Region assignments for entities rescued via HISTORICAL_CCODE_MAP that may lack ht_region.
Maps ident_ccodealp → ht_region code.

Region codes (QoG ht_region):
1 = Eastern Europe & post-Soviet
2 = Latin America
3 = MENA (Middle East & North Africa)
4 = Sub-Saharan Africa
5 = Western Europe & North America
6 = East Asia
7 = Southeast Asia
8 = South Asia
9 = Pacific / Oceania
10 = Caribbean
"""
const RESCUED_ENTITY_REGIONS = Dict{String, Int}(
    "VDR" => 7,   # South Vietnam → Southeast Asia
    "XTI" => 6,   # Tibet → East Asia
    "TIB" => 6,   # Tibet (alternate alpha) → East Asia
    "DDR" => 1,   # East Germany → Eastern Europe
    "CSK" => 1,   # Czechoslovakia → Eastern Europe
    "SCG" => 1,   # Serbia and Montenegro → Eastern Europe
    "YMD" => 3,   # Yemen Democratic (South) → MENA
    "SUN" => 1,   # USSR → Eastern Europe (NOT Sudan!)
)


"""
Non-QoG territories needed for complete world map rendering.
These do NOT exist in QoG data — used only for cartographic visualization.

Format: (ccode, alpha, region, name)

Regional assignment follows ADMINISTRATIVE alignment (reporting country), not geography:
- French territories → Region 5 (France)
- US territories → Region 5 (USA)
- UK territories → Region 5 (UK)
- Danish territories → Region 5 (Denmark)

Note: SUN = Soviet Union (810), NOT Sudan. Sudan uses SDN (729).
"""
const CARTOGRAPHIC_TERRITORIES = [
    (238, "FLK", 5, "Falkland Islands"),           # UK territory
    (260, "ATF", 5, "French Southern Territories"), # France territory
    (275, "PSE", 3, "Palestine"),                   # MENA
    (304, "GRL", 5, "Greenland"),                   # Denmark territory
    (540, "NCL", 5, "New Caledonia"),               # France territory
    (630, "PRI", 5, "Puerto Rico"),                 # US territory
    (732, "ESH", 3, "Western Sahara"),              # MENA (disputed)
]


# ==============================================================================
# INTERNAL HELPERS
# ==============================================================================

"""
Internal helper: assert that a vector of column names is unique.

Throws an error with a readable list of duplicates if any are found.
"""
function _assert_unique_names(names_vec::AbstractVector{<:AbstractString}; context::AbstractString="")
    counts = countmap(String.(names_vec))
    dups = sort([k for (k, v) in counts if v > 1])
    if !isempty(dups)
        ctx = isempty(context) ? "" : " ($context)"
        error("Duplicate names detected$ctx: " * join(dups, ", "))
    end
    return true
end


# ==============================================================================
# DATA ACQUISITION
# ==============================================================================

"""
Downloads the official QoG datasets from their public URLs into the specified directory.
Usage:
    download_qog_sources(PATH_DATA_DIR, QOG_SOURCES)
Returns a NamedTuple with:
- downloaded: Vector of successfully downloaded file names.
- skipped: Vector of file names that were skipped (already exist).
- failed: Dict of file names to error messages for failed downloads.
"""
function download_qog_sources(; data_dir::AbstractString=joinpath(pwd(), PATH_DATA_DIR),
                               sources::AbstractVector{<:AbstractString}=QOG_SOURCES)

    if !isdir(data_dir)
        mkpath(data_dir)
    end

    downloaded = String[]
    skipped = String[]
    failed = Dict{String, String}()

    for url in sources
        file_name = basename(url)
        destination = joinpath(data_dir, file_name)

        # Treat empty files as corrupt/partial and re-download
        if isfile(destination) && filesize(destination) > 0
            println("Skipping: $file_name already exists in $data_dir")
            push!(skipped, file_name)
            continue
        elseif isfile(destination) && filesize(destination) == 0
            println("Re-fetching: $file_name (existing file is 0 bytes)")
        else
            println("Fetching: $file_name")
        end

        tmp = destination * ".part"
        try
            Downloads.download(url, tmp)
            mv(tmp, destination; force=true)  # atomic replace on same filesystem
            println("Success: $file_name saved to $data_dir")
            push!(downloaded, file_name)
        catch e
            # Best-effort cleanup
            if isfile(tmp)
                rm(tmp; force=true)
            end
            @error "Failed to download $file_name" exception=e
            failed[file_name] = sprint(showerror, e)
        end
    end

    return (downloaded=downloaded, skipped=skipped, failed=failed, data_dir=data_dir)
end


"""
Converts all QoG CSV files referenced by `sources` to Arrow files in the same directory. Lowercases column names before writing. Skips conversion if the Arrow file already exists unless `force=true`.
Returns a NamedTuple summary.
Usage:
    convert_csv_to_arrow(; data_dir=PATH_DATA_DIR, sources=QOG_SOURCES, compress=:zstd, force=false)
Returns a NamedTuple with:
- converted: Vector of successfully converted Arrow file names.
- skipped: Vector of Arrow file names that were skipped (already exist).
- missing: Vector of CSV file names that were missing.
- failed: Dict of CSV file names to error messages for failed conversions.
- skipped_noncsv: Vector of file names in sources that were not CSVs.
"""
function convert_csv_to_arrow(; data_dir::AbstractString=joinpath(pwd(), PATH_DATA_DIR),
                                sources::AbstractVector{<:AbstractString}=QOG_SOURCES,
                                compress::Symbol=:zstd,
                                force::Bool=false)

    if !isdir(data_dir)
        mkpath(data_dir)
    end

    converted = String[]
    skipped = String[]
    missing_files = String[]
    failed = Dict{String, String}()
    skipped_noncsv = String[]

    for url in sources
        file_name = basename(url)

        if !endswith(lowercase(file_name), ".csv")
            push!(skipped_noncsv, file_name)
            continue
        end

        csv_path = joinpath(data_dir, file_name)
        arrow_path = splitext(csv_path)[1] * ".arrow"
        tmp_arrow = arrow_path * ".part"

        if !isfile(csv_path)
            @warn "Missing CSV (did you run download_qog_sources?): $csv_path"
            push!(missing_files, file_name)
            continue
        end

        # If Arrow exists and looks sane, skip unless force=true
        if isfile(arrow_path) && !force
            if filesize(arrow_path) > 0
                @info "Skipping (Arrow exists): $(basename(arrow_path))"
                push!(skipped, basename(arrow_path))
                continue
            else
                @warn "Rebuilding: $(basename(arrow_path)) (existing file is 0 bytes)"
            end
        end

        try
            @info "Converting CSV -> Arrow: $file_name"

            df = CSV.read(csv_path, DataFrame;
                normalizenames=false,
                pool=true,
                stringtype=String,
                silencewarnings=true
            )

            rename!(df, lowercase.(names(df)))
            _assert_unique_names(names(df); context="after lowercasing $file_name")

            Arrow.write(tmp_arrow, df; compress=compress)
            mv(tmp_arrow, arrow_path; force=true)

            @info "Created: $arrow_path"
            push!(converted, basename(arrow_path))
        catch e
            if isfile(tmp_arrow)
                rm(tmp_arrow; force=true)
            end
            @error "Failed converting $file_name" exception=e
            failed[file_name] = sprint(showerror, e)
        end
    end

    return (
        converted=converted,
        skipped=skipped,
        missing=missing_files,
        failed=failed,
        skipped_noncsv=skipped_noncsv,
        data_dir=data_dir,
    )
end


# ==============================================================================
# LAYER 1 & 2: REFINERY LOADERS
# ==============================================================================

"""
Extracts metadata labels and defines initial prefixes directly from the raw Stata source. 
Usage:
    generate_raw_manifest(PATH_TS_STRATA_RAW, PATH_MANIFEST_SRC)
Prefix Logic:
- Variables with '_' are assigned their lead string (e.g., 'wdi_life' -> 'wdi').
- Naked variables (ccode, year) are tagged as 'base' for later 'ident_' promotion.
"""
function generate_raw_manifest(raw_dta_path::String, output_csv::String)    
    # 1. High-Fidelity Metadata Extraction
    # We use readstatallmeta to get the full positional mapping
    _, var_names, var_metas, _ = ReadStatTables.readstatallmeta(raw_dta_path)

    meta_entries = NamedTuple[]

    # 2. Iterate through the raw structure
    for (i, v) in enumerate(var_names)
        v_str = lowercase(String(v))   # contract: manifest slugs are lowercase
        vm = var_metas[i]

        # Extract Label with a safe fallback
        lbl = haskey(vm, "label") ? vm["label"] : "No Label Found"

        prefix = if occursin("_", v_str)
            split(v_str, "_")[1]
        else
            "base"
        end

        push!(meta_entries, (Variable=v_str, Label=lbl, Prefix=prefix))
    end

    # 3. Persistence
    df_manifest = DataFrame(meta_entries)

    # Guard: no duplicate variable slugs in manifest
    _assert_unique_names(df_manifest.Variable; context="manifest Variable slugs")

    # CSV.write(output_csv, df_manifest)

    println("✓ Raw Manifest Created: $output_csv")
    println("  - Extracted $(nrow(df_manifest)) raw definitions.")
    println("  - Identified $(length(unique(df_manifest.Prefix))) unique source prefixes.")

    return df_manifest
end


"""
Identity Promotion: Ingests Arrow data, assigns unique row index, and promotes identity variables to the `ident_` namespace.
Usage:
    df_std = load_raw_ident(PATH_TS_RAW)
Returns:
- DataFrame with `ggis_rowid` (unique immutable row index) and renamed identity columns
Rules:
- `ggis_rowid` is assigned as 1:nrow(df) at load time — never changes
- Only renames keys that exist in the current file per `IDENT_MAPPING`
- Leaves `ht_region` prefix-free (handled elsewhere by design)
"""
function load_raw_ident(timeseries_path::AbstractString)
    # 1. Load main data
    df = Arrow.Table(timeseries_path) |> DataFrame

    # 2. Assign immutable row index FIRST (before any transformations)
    df.ggis_rowid = 1:nrow(df)
    
    # 3. Build rename map (Symbol => Symbol)
    cols_in_df = propertynames(df) 
    
    rename_map = Dict(
        Symbol(raw) => Symbol(promoted) 
        for (raw, promoted) in IDENT_MAPPING 
        if Symbol(raw) in cols_in_df
    )

    # 4. Apply renames (no-op if nothing matched)
    if !isempty(rename_map)
        rename!(df, rename_map)
    end
    
    # 5. Reorder columns: ggis_rowid first, then ident_*, then rest
    col_order = vcat(
        [:ggis_rowid],
        sort([c for c in propertynames(df) if startswith(string(c), "ident_")]),
        [:ht_region],
        sort([c for c in propertynames(df) if !startswith(string(c), "ident_") && c != :ggis_rowid && c != :ht_region])
    )
    # Filter to only columns that exist
    col_order = [c for c in col_order if c in propertynames(df)]
    select!(df, col_order)

    return df
end


"""
Validate the ident schema of all adjunct files prior to them being used to augment our raw time series data.
Usage:
    is_valid = validate_ident_schema("adjunct_file_path")
Returns true if the schema is valid, false otherwise.
Rule:
- Variables containing identity keywords (ccode, cname, year, version) must be in the `ident_` namespace.
- `ht_region` is exempted as the anchor cluster.
- Variables in the `ggis_` namespace trigger a warning but are allowed (internal logic).
- Any other variables containing identity keywords are violations and block the load.
"""
function validate_ident_schema(file_path::String)
    # 1. Peek at the headers
    if endswith(file_path, ".arrow")
        df_header = Arrow.Table(file_path) |> DataFrame |> d -> first(d, 0)
    else
        df_header = CSV.read(file_path, DataFrame, limit=0)
    end
    
    # 2. Define the Core Identity Pattern
    # This regex matches any string containing your specific codebook keys
    # e.g., 'ccode', 'cname', 'year', 'version'
    id_pattern = r"(^|_)(ccode|cname|year|version)(_|$)"
    
    current_vars = String.(propertynames(df_header))
    violations = String[]
    warnings = String[]

    # 3. Active Scan
    for var in current_vars
        lvar = lowercase(var)
        
        if occursin(id_pattern, lvar)
            # Tier 1: Strict Compliance
            if startswith(var, "ident_") || var == "ht_region"
                continue
            
            # Tier 2: Internal Logic (Warning but Pass)
            elseif startswith(var, "ggis_")
                push!(warnings, var)
                continue
            
            # Tier 3: Unauthorized (Block)
            else
                push!(violations, var)
            end
        end
    end
    
    # 4. Reporting
    if !isempty(warnings)
        println("⚠️  SCHEMA WARNING: $file_path")
        println("   Internal logic variables detected: $warnings")
    end

    if !isempty(violations)
        println("\n❌ SCHEMA VIOLATION: $file_path")
        println("   The following variables must be promoted to the 'ident_' namespace:")
        println("   $violations")
        return false # Block the load
    end
    
    println("✓ Namespace verified: $file_path")
    return true
end


"""
Audits a DataFrame for 'Shadow Identity' variables that violate the Augmented Standard.
    These would be captured by our validate_ident_schema function when loading adjunct files.
Usage:
    shadow_vars = audit_shadow_identities(df_std)
Returns a Vector of detected shadow identity variable names.
"""
function audit_shadow_identities(df_std::DataFrame)
    # 1. Define the Identity Pattern (Regex)
    id_pattern = r"(^|_)(ccode|cname|year|version)(_|$)"

    # 2. Extract and Scan all column names
    all_vars = String.(names(df_std))
    shadow_identities = String[]

    for var in all_vars
        lvar = lowercase(var)
        
        # Check if the variable contains identity keywords
        if occursin(id_pattern, lvar)
            # Filter OUT the authorized namespaces
            if !startswith(var, "ident_") && !startswith(var, "ggis_")
                # Special case: allow ht_region as the Anchor
                if var == "ht_region"
                    continue
                end
                push!(shadow_identities, var)
            end
        end
    end

    # 3. Report Results
    if isempty(shadow_identities)
        println("✅ CLEAN: No shadow identity variables detected in df_std.")
    else
        println("⚠️  SHADOW IDENTITIES DETECTED: $(length(shadow_identities))")
        println("The following variables violate the Augmented Standard and should be promoted or removed:")
        display(shadow_identities)
    end
    return shadow_identities
end


"""
Generates a validity mask based on the presence of `ident_ccode` in the timeseries data.
Usage:
    create_validity_mask(PATH_TS_RAW, PATH_VALIDITY_MASK)
Returns:
- DataFrame with `ggis_rowid`, `ident_ccodealp`, `ident_year`, `ggis_isvalid`
Rules:
- Preserves `ggis_rowid` for downstream joins
- `ggis_isvalid = 1` if `ident_ccode` is present, `0` otherwise
- Rows are NOT deleted — mask is for filtering, not exclusion
"""
function create_validity_mask(timeseries_path, validity_mask_path)
    df = load_raw_ident(timeseries_path)

    if !(:ident_ccode in propertynames(df))
        error("Structural Failure: 'ident_ccode' not found in source. Check IDENT_MAPPING.")
    end
    
    # 1. Generate the Validity Adjunct — INCLUDE ggis_rowid
    validity_adjunct = select(df, :ggis_rowid, :ident_ccodealp, :ident_year)
    
    # 2. Vectorized check (1 if exists, 0 if missing)
    validity_adjunct.ggis_isvalid = Int8.(.!ismissing.(df.ident_ccode))
    
    # 3. Sort: by rowid to maintain original order (or by alpha/year for human review)
    sort!(validity_adjunct, [:ident_ccodealp, order(:ident_year, rev=true)])
    
    # 4. Save as CSV for auditing and portability
    # CSV.write(validity_mask_path, validity_adjunct)

    # 5. Diagnostic Feedback
    valid_count = sum(validity_adjunct.ggis_isvalid)
    total_count = nrow(validity_adjunct)
    
    println("✓ Validity mask created")
    println("  - Primary key: ggis_rowid")
    println("  - Saturation: $valid_count / $total_count rows marked as valid.")
    println("  - Schema: ", names(validity_adjunct))
    return validity_adjunct
end


"""
Initial augmentation with region and validity. Ensures every country-year has a proper `ht_region` label and a validity flag.
Usage:
    df_aug = load_augmented_qog(PATH_TS_RAW, PATH_COUNTRY_REGION_LOOKUP, PATH_VALIDITY_MASK)
Returns:
- DataFrame with `ggis_rowid` preserved as unique row identifier
Rules:
- Native Eviction Rule: Drops any existing `ht_region` column in the raw data to
  ensure that our authoritative regional mapping takes precedence.
- Numeric Lock: Ensures that `ident_ccode` is consistently typed as `Int64` across
  both datasets to prevent join mismatches due to type discrepancies.
- Row Preservation: Asserts row count is unchanged after joins.
"""
function load_augmented_qog(ts_path, region_path, mask_path)
    # 1. Ingestion (Layer 1) — includes ggis_rowid
    df = load_raw_ident(ts_path)
    n_rows = nrow(df)
    
    regions = CSV.read(region_path, DataFrame)

    # 2. Type Alignment (The Numeric Lock)
    df.ident_ccode = passmissing(x -> Int64(round(x))).(df.ident_ccode)
    regions.ident_ccode = passmissing(x -> Int64(round(x))).(regions.ident_ccode)

    # 3. Eviction (Path-Dependency Rule)
    if :ht_region in propertynames(df)
        select!(df, Not(:ht_region))
    end

    # 4. Regional Reconstruction Join (left join preserves all df rows)
    df = leftjoin(
        df,
        select(regions, [:ident_ccode, :ht_region]),
        on=:ident_ccode,
        matchmissing=:equal
    )
    
    @assert nrow(df) == n_rows "Row count changed after region join! Expected $n_rows, got $(nrow(df))"

    # 5. Mask Application
    mask = CSV.read(mask_path, DataFrame)

    if :ht_region in propertynames(mask)
        select!(mask, Not(:ht_region))
    end
    
    # If mask has ggis_rowid, join on that (most reliable)
    # Otherwise fall back to (ccodealp, year)
    if :ggis_rowid in propertynames(mask)
        df = leftjoin(df, mask, on=:ggis_rowid, matchmissing=:equal)
    else
        df = leftjoin(df, mask, on=[:ident_ccodealp, :ident_year], matchmissing=:equal)
    end
    
    @assert nrow(df) == n_rows "Row count changed after mask join! Expected $n_rows, got $(nrow(df))"
    
    # Verify ggis_rowid survived
    @assert :ggis_rowid in propertynames(df) "ggis_rowid lost during augmentation!"
    @assert allunique(df.ggis_rowid) "ggis_rowid is no longer unique after augmentation!"

    return df
end

# ==============================================================================
# LAYER 3: TOPOLOGICAL AUDITING
# ==============================================================================

"""
Follows the 'Temporal Snapshot Rule' to evaluate sensors based on operational lifespan.
Usage:
    report, classification = audit_prefix_fidelity(df_std, manifest, "wdi", 2018)
Returns:
- final_report: DataFrame with regional fidelity stats plus GLOBAL TOTAL row
- classification: String ("Global (G)", "Regional (R)", or "Hybrid (H)")
Rules:
- Resolves temporal boundary from manifest `death_year` column
- Audits at death year OR target year, whichever is earlier
- Classifies prefix as Global if avg > 75% and std < 20
- Classifies as Regional if std > 30 or (avg < 40 and any region > 80%)
- Otherwise classifies as Hybrid
"""
function audit_prefix_fidelity(df_std::DataFrame, manifest::DataFrame, prefix::String, target_year::Int=2018)
    # A. Resolve Temporal Boundary from Manifest
    prefix_meta = manifest[coalesce.(manifest.Prefix .== prefix, false), :]
    if isempty(prefix_meta) error("Prefix '$prefix' not found in manifest.") end
    
    max_death = maximum(skipmissing(prefix_meta.death_year))
    
    # Logic: Audit at death year OR target year, whichever is earlier
    is_dead = max_death < target_year
    audit_year = is_dead ? Int(max_death) : target_year

    # B. Isolate Snapshot
    df_snapshot = df_std[coalesce.(df_std.ident_year .== audit_year, false), :]
    df_snapshot = dropmissing(df_snapshot, :ht_region)
    
    prefix_cols = [c for c in names(df_snapshot) if startswith(string(c), prefix)]
    if isempty(prefix_cols) error("No columns for '$prefix' in $audit_year.") end

    # C. Signal Density Calculation
    df_snapshot.has_signal = [any(!ismissing(r[c]) for c in prefix_cols) for r in eachrow(df_snapshot)]

    # D. Aggregate Regional Stats
    stats = combine(groupby(df_snapshot, :ht_region)) do sdf
        (Total_Countries = nrow(sdf), Signal_Countries = sum(sdf.has_signal),
         Fidelity_Pct = round((sum(sdf.has_signal) / nrow(sdf)) * 100, digits=1))
    end

    # E. Integrate Labels & Classification
    audit_table = leftjoin(stats, REGION_LABELS, on = :ht_region)
    avg_f, std_f = mean(audit_table.Fidelity_Pct), std(audit_table.Fidelity_Pct)
    
    classification = if avg_f > 75 && std_f < 20 "Global (G)"
    elseif std_f > 30 || (avg_f < 40 && any(audit_table.Fidelity_Pct .> 80)) "Regional (R)"
    else "Hybrid (H)" end

    # F. Append Global Total Line
    global_row = DataFrame(ht_region=0, Region_Name="GLOBAL TOTAL", 
        Total_Countries=sum(audit_table.Total_Countries), Signal_Countries=sum(audit_table.Signal_Countries),
        Fidelity_Pct=round((sum(audit_table.Signal_Countries)/sum(audit_table.Total_Countries))*100, digits=1))
    
    final_report = vcat(select(audit_table, [:ht_region, :Region_Name, :Total_Countries, :Signal_Countries, :Fidelity_Pct]), global_row)

    return final_report, classification
end

# ==============================================================================
# SLUG EXTRACTION UTILITIES
# ==============================================================================

"""
Path to extracted Arrow slugs CSV (all columns from augmented DataFrame).
"""
const PATH_ARROW_SLUGS = "data/ggis_arrow_slugs.csv"

"""
Infers variable type from data column, now including type-safety for non-numeric data.

Usage:
    vtype = infer_variable_type(df.wdi_gdp)
Arguments:
- `col` — AbstractVector (DataFrame column)
Returns:
- Symbol: `:binary`, `:discrete`, `:categorical`, `:continuous`, `:string`, or `:unknown`

Rules:
- `:string`      — column elements are of type `AbstractString` (prevents math errors)
- `:binary`      — all non-missing values in {0, 1}
- `:discrete`    — integer-like numeric values with <20 unique values
- `:categorical` — integer-like numeric values with 20-100 unique values
- `:continuous`  — numeric values that are not integer-like or have >100 unique values
- `:unknown`     — all values in the column are missing
"""
function infer_variable_type(col::AbstractVector)
    # Remove missing values for analysis
    non_missing = collect(skipmissing(col))
    
    if isempty(non_missing)
        return :unknown
    end
    
    # 1. Handle String/Non-Numeric Data First
    if eltype(non_missing) <: AbstractString
        return :string
    end
    
    # 2. Check for Numeric Data
    unique_vals = unique(non_missing)
    n_unique = length(unique_vals)
    
    # Check if binary (only 0 and 1)
    if n_unique <= 2 && all(v in [0, 1, 0.0, 1.0] for v in unique_vals)
        return :binary
    end
    
    # Check if integer-like (safely)
    # Check if the type itself is an Integer, or if floats represent integers
    is_integer_like = if eltype(non_missing) <: Number
        all(v -> isreal(v) && v == floor(v), non_missing)
    else
        false
    end
    
    if is_integer_like
        if n_unique < 20
            return :discrete
        elseif n_unique < 100
            return :categorical
        end
    end
    
    return :continuous
end


"""
Extracts all slugs from Arrow DataFrame with inferred types.

Usage:
    extract_arrow_slugs(df)
    extract_arrow_slugs(df; save_path="data/my_slugs.csv")

Arguments:
- `df` — Augmented DataFrame (after `load_raw_ident`, `rescue_historical_ccodes`, etc.)
- `save_path` — Output CSV path (default: PATH_ARROW_SLUGS)

Returns:
- DataFrame with columns:
  - `slug` — column name from DataFrame
  - `prefix` — extracted prefix (before first underscore)
  - `type` — inferred type (:binary, :discrete, :categorical, :continuous)

Outputs:
- Saves CSV to `save_path`

Rules:
- Includes ALL columns (ident_*, ggis_*, ht_region, analytical slugs)
- Infers type by sampling data
- Prefix extraction: "wdi_gdp" → "wdi", "ident_ccode" → "ident"
"""
function extract_arrow_slugs(df::DataFrame; save_path::String=PATH_ARROW_SLUGS)
    println("\n>>> Extracting slugs from Arrow DataFrame...")
    
    all_cols = names(df)
    n_cols = length(all_cols)
    
    slugs = String[]
    prefixes = String[]
    types = Symbol[]
    
    for col_name in all_cols
        slug = string(col_name)
        
        # Extract prefix (before first underscore)
        prefix = if contains(slug, "_")
            first(split(slug, "_"))
        else
            "base"  # No underscore = base column
        end
        
        # Infer type from data
        vtype = infer_variable_type(df[!, col_name])
        
        push!(slugs, slug)
        push!(prefixes, prefix)
        push!(types, vtype)
    end
    
    # Build result DataFrame
    result = DataFrame(
        slug = slugs,
        prefix = prefixes,
        type = types
    )
    
    # Save to CSV
    CSV.write(save_path, result)
    
    println("    Extracted $(nrow(result)) slugs")
    println("    Saved to: $save_path")
    
    # Summary by prefix
    prefix_counts = combine(groupby(result, :prefix), nrow => :count)
    sort!(prefix_counts, :count, rev=true)
    println("\n    By prefix:")
    for row in eachrow(first(prefix_counts, 10))
        println("      $(row.prefix): $(row.count)")
    end
    if nrow(prefix_counts) > 10
        println("      ... and $(nrow(prefix_counts) - 10) more")
    end
    
    # Summary by type
    type_counts = combine(groupby(result, :type), nrow => :count)
    sort!(type_counts, :count, rev=true)
    println("\n    By type:")
    for row in eachrow(type_counts)
        println("      $(row.type): $(row.count)")
    end
    
    return result
end


# ==============================================================================
# SPINE DIAGNOSTICS & HISTORICAL RESCUE
# ==============================================================================

"""
Diagnoses potential ccode collisions before applying historical rescue mappings.
Usage:
    collisions = diagnose_ccode_collisions(df_ident)
    collisions = diagnose_ccode_collisions(df_ident, custom_map)
Returns:
- DataFrame showing which proposed mappings would collide with existing data
Rules:
- Identifies cases where a proposed ISO ccode is already used by a different alpha code
- Distinguishes INTENTIONAL collisions (both alphas in HISTORICAL_CCODE_MAP) from CONFLICT
- Helps verify HISTORICAL_CCODE_MAP entries before applying rescue
"""
function diagnose_ccode_collisions(df_ident::DataFrame, 
                                   proposed_map::Dict{String, Int}=HISTORICAL_CCODE_MAP)
    # Get existing ccode → alpha mappings from the data (only rows with valid ccode)
    existing = filter(r -> !ismissing(r.ident_ccode) && !ismissing(r.ident_ccodealp), df_ident)
    existing_map = combine(groupby(existing, :ident_ccode)) do sdf
        (
            existing_alphas = join(sort(unique(sdf.ident_ccodealp)), ", "),
            existing_names = join(sort(unique(skipmissing(sdf.ident_cname)))[1:min(3, end)], ", "),
            rows = nrow(sdf)
        )
    end
    
    collisions = DataFrame(
        proposed_alpha = String[],
        proposed_ccode = Int[],
        existing_alphas = String[],
        existing_names = String[],
        existing_rows = Int[],
        status = String[]
    )
    
    # Build reverse map: ccode → all alphas that map to it
    ccode_to_alphas = Dict{Int, Vector{String}}()
    for (alpha, ccode) in proposed_map
        if !haskey(ccode_to_alphas, ccode)
            ccode_to_alphas[ccode] = String[]
        end
        push!(ccode_to_alphas[ccode], alpha)
    end
    
    for (alpha, ccode) in sort(collect(proposed_map), by=x->x[1])
        match_row = filter(r -> r.ident_ccode == ccode, existing_map)
        if nrow(match_row) > 0
            row = first(match_row)
            existing_alphas_list = split(row.existing_alphas, ", ")
            
            if alpha in existing_alphas_list
                # Same entity — no collision
                push!(collisions, (
                    proposed_alpha = alpha,
                    proposed_ccode = ccode,
                    existing_alphas = row.existing_alphas,
                    existing_names = row.existing_names,
                    existing_rows = row.rows,
                    status = "OK (same entity)"
                ))
            else
                # Check if the existing alpha is ALSO in our map (intentional collision)
                existing_in_map = any(ea in keys(proposed_map) for ea in existing_alphas_list)
                
                if existing_in_map
                    # Intentional collision — will be resolved by priority
                    push!(collisions, (
                        proposed_alpha = alpha,
                        proposed_ccode = ccode,
                        existing_alphas = row.existing_alphas,
                        existing_names = row.existing_names,
                        existing_rows = row.rows,
                        status = "⚠️ INTENTIONAL (priority resolves)"
                    ))
                else
                    # True conflict — would overwrite unrelated country
                    push!(collisions, (
                        proposed_alpha = alpha,
                        proposed_ccode = ccode,
                        existing_alphas = row.existing_alphas,
                        existing_names = row.existing_names,
                        existing_rows = row.rows,
                        status = "❌ CONFLICT"
                    ))
                end
            end
        else
            push!(collisions, (
                proposed_alpha = alpha,
                proposed_ccode = ccode,
                existing_alphas = "",
                existing_names = "",
                existing_rows = 0,
                status = "OK (new ccode)"
            ))
        end
    end
    
    sort!(collisions, [:status, :proposed_alpha])
    
    # Report
    conflicts = filter(r -> contains(r.status, "CONFLICT"), collisions)
    intentional = filter(r -> contains(r.status, "INTENTIONAL"), collisions)
    
    if nrow(intentional) > 0
        println("ℹ️  INTENTIONAL COLLISIONS ($(nrow(intentional))) — resolved by COLLISION_PRIORITY_ALPHAS:")
        for row in eachrow(intentional)
            println("   $(row.proposed_alpha) → $(row.proposed_ccode) merges with $(row.existing_alphas)")
        end
    end
    
    if nrow(conflicts) > 0
        println("\n❌ CCODE COLLISION CONFLICTS DETECTED ($(nrow(conflicts))):")
        for row in eachrow(conflicts)
            println("   $(row.proposed_alpha) → $(row.proposed_ccode) CONFLICTS with $(row.existing_alphas) ($(row.existing_names))")
        end
        println("\n   These mappings would overwrite existing country data!")
    else
        println("✓ No unintentional ccode collisions detected.")
    end
    
    return collisions
end


"""
Investigates rows with missing `ident_ccode` or `ident_year` that contain other data.
Usage:
    issues = diagnose_spine_issues(df_ident)
    diagnose_spine_issues(df_ident; output_path="./data/spine_issues.csv")
Returns:
- DataFrame of problematic rows with diagnostic columns added
Rules:
- Requires `ggis_rowid` for row identification
- Categorizes issues as BLANK_ROW, MISSING_BOTH, MISSING_CCODE_ONLY, or MISSING_YEAR_ONLY
- Includes `ident_ccodecow` when available for COW code reference
- NO rows are deleted — this is diagnostic only
"""
function diagnose_spine_issues(df_ident::DataFrame; output_path::Union{String, Nothing}=nothing)
    if !(:ggis_rowid in propertynames(df_ident))
        error("Missing `ggis_rowid`. Use `load_raw_ident()` to load data first.")
    end
    
    # --- 1. Identify missing spine rows ---
    missing_ccode = ismissing.(df_ident.ident_ccode)
    missing_year = ismissing.(df_ident.ident_year)
    missing_spine = missing_ccode .| missing_year
    
    if sum(missing_spine) == 0
        println("✓ No spine issues found.")
        return DataFrame()
    end
    
    bad_rows = df_ident[missing_spine, :]
    
    # --- 2. Categorize each row ---
    non_ident_cols = [c for c in propertynames(df_ident) 
                     if !startswith(string(c), "ident_") && 
                        !startswith(string(c), "ggis_") && 
                        c != :ht_region]
    
    # Check if ident_ccodecow exists
    has_ccodecow_col = :ident_ccodecow in propertynames(df_ident)
    
    # Build diagnostic DataFrame
    diag = DataFrame(
        ggis_rowid = bad_rows.ggis_rowid,
        missing_ccode = missing_ccode[missing_spine],
        missing_year = missing_year[missing_spine],
        has_ccodealp = .!ismissing.(bad_rows.ident_ccodealp),
        has_cname = .!ismissing.(bad_rows.ident_cname),
        has_region = .!ismissing.(bad_rows.ht_region),
        ident_ccodealp = bad_rows.ident_ccodealp,
        ident_cname = bad_rows.ident_cname,
        ident_year = bad_rows.ident_year,
        ident_ccode = bad_rows.ident_ccode,
        ht_region = bad_rows.ht_region
    )
    
    # Add ident_ccodecow if available
    if has_ccodecow_col
        diag.ident_ccodecow = bad_rows.ident_ccodecow
        diag.has_ccodecow = .!ismissing.(bad_rows.ident_ccodecow)
    end
    
    # Count non-missing values in non-ident columns for each row
    non_ident_data_count = Int[]
    for row in eachrow(bad_rows)
        count = sum(!ismissing(row[c]) for c in non_ident_cols if c in propertynames(row))
        push!(non_ident_data_count, count)
    end
    diag.non_ident_data_count = non_ident_data_count
    
    # Classify the issue type
    diag.issue_type = map(eachrow(diag)) do r
        if r.non_ident_data_count == 0
            "BLANK_ROW"
        elseif r.missing_ccode && r.missing_year
            "MISSING_BOTH"
        elseif r.missing_ccode
            "MISSING_CCODE_ONLY"
        else
            "MISSING_YEAR_ONLY"
        end
    end
    
    # Sort by issue type, then by available identifiers
    sort!(diag, [:issue_type, :ident_ccodealp, :ident_cname])
    
    # --- 3. Print summary ---
    println(">>> SPINE DIAGNOSTIC REPORT")
    println("    Total rows with spine issues: $(nrow(diag))")
    
    issue_counts = combine(groupby(diag, :issue_type), nrow => :count)
    sort!(issue_counts, :count, rev=true)
    println("\n    By issue type:")
    for row in eachrow(issue_counts)
        println("      $(row.issue_type): $(row.count)")
    end
    
    # Group by available identifiers for non-blank rows
    data_rows = filter(r -> r.issue_type != "BLANK_ROW", diag)
    if nrow(data_rows) > 0
        println("\n    Problematic entities (non-blank rows):")
        
        if has_ccodecow_col
            by_entity = combine(groupby(data_rows, [:ident_ccodealp, :ident_cname])) do sdf
                cow_codes = unique(skipmissing(sdf.ident_ccodecow))
                (
                    rows = nrow(sdf),
                    issue_types = join(unique(sdf.issue_type), ", "),
                    ccodecow = isempty(cow_codes) ? missing : first(cow_codes),
                    avg_data_cols = round(mean(sdf.non_ident_data_count), digits=1)
                )
            end
        else
            by_entity = combine(groupby(data_rows, [:ident_ccodealp, :ident_cname])) do sdf
                (
                    rows = nrow(sdf),
                    issue_types = join(unique(sdf.issue_type), ", "),
                    avg_data_cols = round(mean(sdf.non_ident_data_count), digits=1)
                )
            end
        end
        sort!(by_entity, :rows, rev=true)
        
        for row in eachrow(first(by_entity, 15))
            alp = coalesce(row.ident_ccodealp, "???")
            name = coalesce(row.ident_cname, "???")
            cow_str = has_ccodecow_col && !ismissing(row.ccodecow) ? " [COW: $(row.ccodecow)]" : ""
            println("      - $alp ($name)$cow_str: $(row.rows) rows, $(row.issue_types)")
        end
        
        if nrow(by_entity) > 15
            println("      ... and $(nrow(by_entity) - 15) more entities")
        end
    end
    
    # --- 4. Save if requested ---
    if output_path !== nothing
        CSV.write(output_path, diag)
        println("\n>>> Saved diagnostic report to: $output_path")
    end
    
    return diag
end


"""
Rescues rows with missing `ident_ccode` by looking up `ident_ccodealp` in `HISTORICAL_CCODE_MAP`.
Adds collision metadata but NEVER deletes or merges rows.
Usage:
    df_rescued = rescue_historical_ccodes(df_ident)
    df_rescued = rescue_historical_ccodes(df_ident; verbose=true)
Returns:
- A **new** DataFrame with:
  - Rescued ccodes filled in
  - `ggis_ccode_rescued::Bool` — true if ccode was filled from HISTORICAL_CCODE_MAP
  - `ggis_spine_collision::Bool` — true if row shares (ccode, year) with another row
Rules:
- NO ROWS ARE DELETED OR MERGED — row count is preserved
- `ggis_rowid` remains the unique identifier
- `(ident_ccode, ident_year)` may have duplicates (use with `ident_ccodealp` or `ggis_rowid`)
"""
function rescue_historical_ccodes(df_ident::DataFrame; verbose::Bool=false)
    if !(:ggis_rowid in propertynames(df_ident))
        error("Missing `ggis_rowid`. Use `load_raw_ident()` to load data first.")
    end
    
    df = copy(df_ident)
    n_rows = nrow(df)
    
    # --- 1. Rescue missing ccodes ---
    n_missing_before = count(ismissing, df.ident_ccode)
    
    # Track which rows were rescued
    df.ggis_ccode_rescued = fill(false, n_rows)
    
    for i in 1:n_rows
        if ismissing(df.ident_ccode[i])
            alp = coalesce(df.ident_ccodealp[i], "")
            if haskey(HISTORICAL_CCODE_MAP, alp)
                df.ident_ccode[i] = HISTORICAL_CCODE_MAP[alp]
                df.ggis_ccode_rescued[i] = true
            end
        end
    end
    
    n_rescued = sum(df.ggis_ccode_rescued)
    n_missing_after = count(ismissing, df.ident_ccode)
    
    println(">>> Historical Ccode Rescue:")
    println("    Missing before: $n_missing_before")
    println("    Rescued: $n_rescued")
    println("    Missing after: $n_missing_after")
    println("    Row count: $n_rows (unchanged)")
    
    if verbose && n_rescued > 0
        rescued_summary = combine(
            groupby(filter(r -> r.ggis_ccode_rescued, df), :ident_ccodealp),
            nrow => :count,
            :ident_ccode => first => :ccode
        )
        sort!(rescued_summary, :count, rev=true)
        println("    By alpha code:")
        for row in eachrow(rescued_summary)
            println("      $(row.ident_ccodealp) → $(row.ccode): $(row.count) rows")
        end
    end
    
    # --- 2. Collision detection (informational — no rows removed) ---
    df.ggis_spine_collision = fill(false, n_rows)
    
    # Only check rows with valid ccode and year
    valid_mask = .!ismissing.(df.ident_ccode) .& .!ismissing.(df.ident_year)
    
    if any(valid_mask)
        # Find all (ccode, year) pairs that appear more than once
        spine_counts = combine(
            groupby(df[valid_mask, [:ggis_rowid, :ident_ccode, :ident_year]], [:ident_ccode, :ident_year]),
            nrow => :n,
            :ggis_rowid => collect => :rowids
        )
        collision_pairs = filter(r -> r.n > 1, spine_counts)
        
        if nrow(collision_pairs) > 0
            # Mark all rows involved in collisions
            collision_rowids = Set(vcat(collision_pairs.rowids...))
            df.ggis_spine_collision = [r in collision_rowids for r in df.ggis_rowid]
            
            n_collision_rows = sum(df.ggis_spine_collision)
            n_collision_pairs = nrow(collision_pairs)
            
            println("\n    ℹ️  Spine collisions detected (NOT resolved — rows preserved):")
            println("       Unique (ccode, year) pairs with >1 row: $n_collision_pairs")
            println("       Total rows involved: $n_collision_rows")
            
            if verbose
                # Summarize by entity combination
                collision_detail = innerjoin(
                    df[df.ggis_spine_collision, [:ggis_rowid, :ident_ccode, :ident_year, :ident_ccodealp, :ident_cname]],
                    collision_pairs[:, [:ident_ccode, :ident_year]],
                    on=[:ident_ccode, :ident_year]
                )
                
                by_pair = combine(groupby(collision_detail, [:ident_ccode, :ident_year])) do sdf
                    alphas = sort(unique(coalesce.(sdf.ident_ccodealp, "???")))
                    names = sort(unique(coalesce.(sdf.ident_cname, "???")))
                    (
                        entities = join(alphas, " + "),
                        names = join(names, " + "),
                        rows = nrow(sdf)
                    )
                end
                
                # Group by entity combination for summary
                by_combo = combine(groupby(by_pair, :entities)) do sdf
                    (
                        year_count = nrow(sdf),
                        year_min = minimum(sdf.ident_year),
                        year_max = maximum(sdf.ident_year),
                        example_names = first(sdf.names)
                    )
                end
                sort!(by_combo, :year_count, rev=true)
                
                println("       By entity combination:")
                for row in eachrow(by_combo)
                    println("         $(row.entities): $(row.year_count) years ($(row.year_min)-$(row.year_max))")
                    println("           Names: $(row.example_names)")
                end
            end
        else
            println("    ✓ No spine collisions — (ident_ccode, ident_year) is unique")
        end
    end
    
    # Verify row count unchanged
    @assert nrow(df) == n_rows "Row count changed unexpectedly!"
    
    return df
end


"""
Previews year-level collisions that would occur after applying `HISTORICAL_CCODE_MAP`.
Usage:
    preview = preview_rescue_collisions(df_ident)
    preview = preview_rescue_collisions(df_ident; show_years=true)
Returns:
- DataFrame with collision details by entity combination
Rules:
- Simulates rescue without modifying input
- Groups by (ccode, year) to find rows that would share the same spine
- NO rows will be deleted — this is informational only
"""
function preview_rescue_collisions(df_ident::DataFrame, 
                                   proposed_map::Dict{String, Int}=HISTORICAL_CCODE_MAP;
                                   show_years::Bool=false)
    # Simulate rescue: compute what ccode would be after mapping
    simulated_ccode = map(eachrow(df_ident)) do r
        if ismissing(r.ident_ccode)
            alp = coalesce(r.ident_ccodealp, "")
            return get(proposed_map, alp, missing)
        else
            return r.ident_ccode
        end
    end
    
    # Build temporary DataFrame for grouping
    df_sim = DataFrame(
        ccode = simulated_ccode,
        year = df_ident.ident_year,
        alpha = df_ident.ident_ccodealp,
        name = df_ident.ident_cname
    )
    
    # Filter to rows with valid ccode and year
    df_valid = filter(r -> !ismissing(r.ccode) && !ismissing(r.year), df_sim)
    
    # Find collision pairs
    by_spine = combine(groupby(df_valid, [:ccode, :year])) do sdf
        alphas = sort(unique(coalesce.(sdf.alpha, "???")))
        (
            entities = join(alphas, " + "),
            count = nrow(sdf)
        )
    end
    
    collisions = filter(r -> r.count > 1, by_spine)
    
    if nrow(collisions) == 0
        println("✓ No (ccode, year) collisions would occur after rescue.")
        return DataFrame(
            entities = String[],
            year_count = Int[],
            year_min = Int[],
            year_max = Int[],
            years = String[]
        )
    end
    
    # Summary by entity combination — build manually to avoid mixed scalar/vector issue
    by_combo = DataFrame(
        entities = String[],
        year_count = Int[],
        year_min = Int[],
        year_max = Int[],
        years = String[]
    )
    
    for g in groupby(collisions, :entities)
        ent = first(g.entities)
        yrs = sort(collect(g.year))
        push!(by_combo, (
            entities = ent,
            year_count = length(yrs),
            year_min = minimum(yrs),
            year_max = maximum(yrs),
            years = show_years ? join(yrs, ", ") : ""
        ))
    end
    
    sort!(by_combo, :year_count, rev=true)
    
    total_collision_pairs = nrow(collisions)
    
    println(">>> RESCUE COLLISION PREVIEW (informational — NO rows will be deleted):")
    println("    Total (ccode, year) pairs with >1 row: $total_collision_pairs")
    println("\n    By entity combination:")
    
    for row in eachrow(by_combo)
        println("      $(row.entities): $(row.year_count) years ($(row.year_min)-$(row.year_max))")
        if show_years && !isempty(row.years)
            println("        Years: $(row.years)")
        end
    end
    
    println("\n    NOTE: Use `ggis_rowid` as unique key, or (ident_ccode, ident_year, ident_ccodealp)")
    
    return by_combo
end

# ==============================================================================
# DIAGNOSTICS & DOCUMENTATION
# ==============================================================================

function list_unmapped_summary(df)
    orphans = df[coalesce.(ismissing.(df.ht_region), false), :]
    if isempty(orphans) return nothing end
    return combine(groupby(orphans, [:ident_cname, :ident_ccode])) do sdf
        (Rows = nrow(sdf), Period = "$(minimum(sdf.ident_year)) - $(maximum(sdf.ident_year))")
    end
end


"""
DEPRECATED (moved): `compare_slug_alignment` is comparison logic and now lives in
`qog_metadata_enrichment.jl`.
Usage:
    include("phase0/functions/qog_metadata_enrichment.jl")
    result = compare_slug_alignment(df_aug, manifest; strict=false)

This wrapper remains only to avoid breaking older notebooks.
"""
function compare_slug_alignment(df_aug::DataFrame, manifest::DataFrame; strict::Bool=true)
    @warn "compare_slug_alignment has moved to qog_metadata_enrichment.jl. Include that file and call it from there."
    error("compare_slug_alignment is deprecated in qog_augmented_standard.jl. Use the version in qog_metadata_enrichment.jl.")
end


"""
Generates a Markdown table documenting all functions in the specified Julia source file.
Usage:
    document_functions_precise("path/to/source_file.jl")
Rules:
- Extracts function name, call signature, and description from docstrings.
- Prioritizes 'Usage:' lines for call signatures when available.
- Captures the first meaningful line of the docstring as the description.
"""
function document_functions_precise(filepath::String)
    if !isfile(filepath)
        @error "File not found: $filepath"
        return
    end

    content = read(filepath, String)
    
    # Regex Breakdown:
    # \"\"\"((?:(?!\"\"\").)*?)\"\"\"  -> Matches the SHORTEST block between triple quotes
    # \s+function\s+                   -> Followed by the function keyword
    # ([a-zA-Z0-9_!]+)                -> Captures name
    # \((.*?)\)                       -> Captures arguments
    pattern = r"(?s)\"\"\"((?:(?!\"\"\").)*?)\"\"\"\s+function\s+([a-zA-Z0-9_!]+)\((.*?)\)"
    
    md_text = "| Function | How to Call | Description |\n| :--- | :--- | :--- |\n"
    
    for m in eachmatch(pattern, content)
        raw_doc = strip(m.captures[1])
        f_name = m.captures[2]
        
        # 1. Extract Call Signature (Prioritize 'Usage:' line, otherwise use name(args))
        usage_match = match(r"Usage:\s*\n?\s*(.*)", raw_doc)
        how_to_call = usage_match !== nothing ? "`$(strip(usage_match.captures[1]))`" : "`$f_name(...)`"
        
        # 2. Extract Description (The first line that isn't a signature or 'Usage')
        doc_lines = split(raw_doc, "\n")
        # Find the first line that has actual text and isn't just the function name repeated
        desc_line = ""
        for line in doc_lines
            l = strip(line)
            if isempty(l) || contains(l, "Usage:") || contains(l, "Returns:") || (length(l) < 30 && contains(l, f_name))
                continue
            end
            desc_line = l
            break
        end

        md_text *= "| **`$f_name`** | $how_to_call | $desc_line |\n"
    end
    
    display(Markdown.parse("### 🛠️ Function API Reference\n" * md_text))
end


"""
Generates a Markdown table documenting all constants in the specified Julia source file.
Usage:
    summarize_constants_from_file("path/to/source_file.jl")
Rules:
- Extracts constant name and description from docstrings.
- Only matches `const` declarations outside of docstrings.
"""
function summarize_constants_from_file(filepath::String)
    if !isfile(filepath)
        @error "File not found: $filepath"
        return
    end

    lines = readlines(filepath)
    md_text = "| Constant | Description |\n| :--- | :--- |\n"
    
    current_doc = String[]
    in_docstring = false
    
    for line in lines
        t_line = strip(line)
        
        # Handle Docstring Toggle
        if startswith(t_line, "\"\"\"")
            if count("\"\"\"", t_line) == 2 && !in_docstring
                # Case: Single-line docstring """text"""
                doc_content = replace(t_line, "\"\"\"" => "")
                current_doc = [strip(doc_content)]
            elseif !in_docstring
                # Case: Start of multi-line
                in_docstring = true
                current_doc = String[]  # Reset for new docstring
                doc_content = replace(t_line, "\"\"\"" => "")
                !isempty(strip(doc_content)) && push!(current_doc, strip(doc_content))
            else
                # Case: End of multi-line
                in_docstring = false
                doc_content = replace(t_line, "\"\"\"" => "")
                !isempty(strip(doc_content)) && push!(current_doc, strip(doc_content))
            end
            continue
        end

        # Accumulate lines if we are inside a docstring
        if in_docstring
            push!(current_doc, t_line)
            continue
        end

        # Only match const declarations OUTSIDE docstrings
        # Must start with "const " (not just contain it)
        if startswith(lstrip(line), "const ")
            m = match(r"^const\s+([A-Z][A-Z0-9_]*)\s*=", lstrip(line))
            if m !== nothing
                const_name = m.captures[1]
                
                # Join multi-line docs with spaces
                full_desc = isempty(current_doc) ? "_No description_" : join(current_doc, " ")
                
                # Clean up: Replace any internal quotes or problematic markdown chars
                full_desc = replace(full_desc, "|" => "\\|")
                full_desc = replace(full_desc, "_" => "\\_")  # Escape underscores
                
                md_text *= "| **`$(const_name)`** | $(strip(full_desc)) |\n"
                current_doc = String[]  # Reset after capturing
            end
        elseif !isempty(current_doc) && !startswith(lstrip(line), "const ")
            # If we have accumulated docs but hit a non-const line, reset
            # (the docstring was for a function, not a constant)
            if !isempty(strip(line)) && !startswith(strip(line), "#")
                current_doc = String[]
            end
        end
    end
    
    display(Markdown.parse("### 📂 Constants Defined in `$(basename(filepath))`\n" * md_text))
end


# ==============================================================================
# EXAMPLES (ALWAYS AT END)
# ==============================================================================

"""
Demonstration of the standard augmentation pipeline.
Usage:
    run_augmented_standard_samples()
Note: This function is for testing/demonstration only.
"""
function run_augmented_standard_samples()
    # Example: Download QoG sources
    download_summary = download_qog_sources()
    println(download_summary)

    # Example: Convert CSV to Arrow
    convert_summary = convert_csv_to_arrow()
    println(convert_summary)

    # Example: Generate Raw Manifest
    raw_manifest = generate_raw_manifest(
        joinpath(PATH_DATA_DIR, "qog_std_ts_raw.dta"),
        joinpath(PATH_MANIFEST_SRC, "qog_raw_manifest.csv")
    )
    println(raw_manifest)

    # Example: Load Raw Ident
    df_ident = load_raw_ident(joinpath(PATH_DATA_DIR, "qog_std_ts_raw.arrow"))
    println("Loaded df_ident with $(nrow(df_ident)) rows and $(ncol(df_ident)) columns.")

    # Example: Validate Ident Schema
    is_valid = validate_ident_schema(joinpath(PATH_DATA_DIR, "qog_adjunct_example.arrow"))
    println("Schema valid: $is_valid")

    # Example: Audit Shadow Identities
    shadow_vars = audit_shadow_identities(df_ident)
    println("Shadow identity variables: $shadow_vars")

    # Example: Create Validity Mask
    validity_mask = create_validity_mask(
        joinpath(PATH_DATA_DIR, "qog_std_ts_raw.arrow"),
        joinpath(PATH_DATA_DIR, "qog_validity_mask.csv")
    )
    println(validity_mask)

    # Example: Load Augmented QoG
    df_aug = load_augmented_qog(
        joinpath(PATH_DATA_DIR, "qog_std_ts_raw.arrow"),
        joinpath(PATH_DATA_DIR, "country_region_lookup.csv"),
        joinpath(PATH_DATA_DIR, "qog_validity_mask.csv")
    )
    println("Loaded df_aug with $(nrow(df_aug)) rows and $(ncol(df_aug)) columns.")

    # Load and standardize (non-mutating)
    df_ident = load_raw_ident(PATH_TS_RAW)

    # Step 2: Check for collisions BEFORE rescue
    collisions = diagnose_ccode_collisions(df_ident)

    # Preview what collisions will happen
    preview = preview_rescue_collisions(df_ident)

    # Step 3: If no conflicts, proceed with rescue
    df_rescued = rescue_historical_ccodes(df_ident; verbose=true)

    # Step 1: Diagnose the spine issues
    issues = diagnose_spine_issues(df_ident; output_path="./data/spine_issues.csv")

    # Step 3: Now standardize_regions should pass
    df_regions = standardize_regions(df_rescued; verbose=true)

    # Step 4: Get orphans as DataFrame for manual review (AFTER df_regions is created)
    orphans = list_region_orphans(df_regions)
end

# ==============================================================================
# REGION STANDARDIZATION
# ==============================================================================

"""
Standardizes regional identifiers and adds `ggis_region` to the DataFrame.
Usage:
    df_regions = standardize_regions(df_ident)
    df_regions = standardize_regions(df_ident; verbose=true)
Returns:
- A **new** DataFrame with `ggis_region` column added (does not mutate input)
Rules:
- Requires `ggis_rowid` as unique row identifier (from `load_raw_ident`)
- Requires `ident_ccodealp` for fallback imputation from RESCUED_ENTITY_REGIONS
- Copies `ht_region` to `ggis_region` (operational namespace)
- Imputation order:
  1. Use `ht_region` if present
  2. Impute from same `ident_ccode` group (share region across entity-years)
  3. Fallback to `RESCUED_ENTITY_REGIONS` for rescued historical entities
- Row count is preserved — no deletions
"""
function standardize_regions(df_ident::DataFrame; verbose::Bool=false)
    # --- 0. Validate required columns ---
    required_cols = [:ggis_rowid, :ident_ccode, :ident_ccodealp, :ident_year, :ht_region]
    missing_cols = [c for c in required_cols if !(c in propertynames(df_ident))]
    if !isempty(missing_cols)
        error("Missing required columns: $(missing_cols). Use `load_raw_ident()` first.")
    end
    n_rows = nrow(df_ident)
    
    # --- 1. Verify ggis_rowid is unique ---
    if !allunique(df_ident.ggis_rowid)
        error("ggis_rowid is not unique! This should never happen.")
    end
    println("✓ ggis_rowid verified unique: $n_rows rows")

    # --- 2. Report spine status ---
    n_valid_spine = count(r -> !ismissing(r.ident_ccode) && !ismissing(r.ident_year), eachrow(df_ident))
    n_missing_spine = n_rows - n_valid_spine
    
    if n_missing_spine > 0
        println("    ℹ️  Rows with incomplete spine (missing ccode or year): $n_missing_spine")
    end
    
    # Check for spine collisions (informational)
    if :ggis_spine_collision in propertynames(df_ident)
        n_collisions = sum(df_ident.ggis_spine_collision)
        if n_collisions > 0
            println("    ℹ️  Rows in spine collisions: $n_collisions (preserved — use ggis_rowid)")
        end
    end

    # --- 3. Create NEW DataFrame with ggis_region ---
    df_result = copy(df_ident)
    df_result.ggis_region = allowmissing(copy(df_result.ht_region))
    
    n_initial_missing = count(ismissing, df_result.ggis_region)
    println("  - Initial missing regions: $n_initial_missing / $n_rows")

    # --- 4. Stage 1: Grouped Imputation (by ccode) ---
    has_ccode = .!ismissing.(df_result.ident_ccode)
    
    if any(has_ccode)
        # Build lookup: ccode -> region (take first non-missing)
        ccode_region_map = Dict{Int, Int}()
        for g in groupby(df_result[has_ccode, :], :ident_ccode)
            ccode = first(g.ident_ccode)
            valid_regions = collect(skipmissing(g.ggis_region))
            if !isempty(valid_regions)
                ccode_region_map[ccode] = first(valid_regions)
            end
        end
        
        # Apply imputation
        n_imputed_ccode = 0
        for i in 1:n_rows
            if ismissing(df_result.ggis_region[i]) && !ismissing(df_result.ident_ccode[i])
                ccode = df_result.ident_ccode[i]
                if haskey(ccode_region_map, ccode)
                    df_result.ggis_region[i] = ccode_region_map[ccode]
                    n_imputed_ccode += 1
                end
            end
        end
        println("  - Imputed from same ccode: $n_imputed_ccode")
    end

    # --- 5. Stage 2: Fallback to RESCUED_ENTITY_REGIONS ---
    n_imputed_rescued = 0
    for i in 1:n_rows
        if ismissing(df_result.ggis_region[i])
            alp = coalesce(df_result.ident_ccodealp[i], "")
            if haskey(RESCUED_ENTITY_REGIONS, alp)
                df_result.ggis_region[i] = RESCUED_ENTITY_REGIONS[alp]
                n_imputed_rescued += 1
            end
        end
    end
    if n_imputed_rescued > 0
        println("  - Imputed from RESCUED_ENTITY_REGIONS: $n_imputed_rescued")
    end

    n_final_missing = count(ismissing, df_result.ggis_region)
    println("  - Final missing regions: $n_final_missing / $n_rows")

    # --- 6. Report orphans ---
    if n_final_missing > 0 && verbose
        orphans = filter(r -> ismissing(r.ggis_region), df_result)
        orphan_summary = combine(groupby(orphans, [:ident_ccode, :ident_ccodealp, :ident_cname])) do sdf
            years = collect(skipmissing(sdf.ident_year))
            (
                rows = nrow(sdf),
                year_min = isempty(years) ? missing : minimum(years),
                year_max = isempty(years) ? missing : maximum(years)
            )
        end
        sort!(orphan_summary, :rows, rev=true)
        
        println("\n    ⚠️  ORPHAN ENTITIES (no region assignment):")
        for row in eachrow(first(orphan_summary, 10))
            alp = coalesce(row.ident_ccodealp, "???")
            name = coalesce(row.ident_cname, "???")
            yr_str = ismissing(row.year_min) ? "no years" : "$(row.year_min)-$(row.year_max)"
            println("      - $alp ($name): $(row.rows) rows ($yr_str)")
        end
        if nrow(orphan_summary) > 10
            println("      ... and $(nrow(orphan_summary) - 10) more")
        end
    end

    # Verify row count unchanged
    @assert nrow(df_result) == n_rows "Row count changed unexpectedly!"
    
    println("\n✅ Regions standardized to 'ggis_region'")
    println("   Primary key: ggis_rowid (always unique)")
    
    return df_result
end

"""
Returns a summary DataFrame of entities that have no `ggis_region` assignment.
Usage:
    orphans = list_region_orphans(df_regions)
Returns:
- DataFrame with columns: `ident_ccode`, `ident_ccodealp`, `ident_cname`, `rows`, `year_min`, `year_max`
- Empty DataFrame if no orphans exist
Rules:
- Requires `ggis_region` column (run `standardize_regions` first)
- Sorts output by row count descending
"""
function list_region_orphans(df_ident::DataFrame)
    if !(:ggis_region in propertynames(df_ident))
        error("Column 'ggis_region' not found. Run standardize_regions first.")
    end
    
    orphans = filter(r -> ismissing(r.ggis_region), df_ident)
    
    if nrow(orphans) == 0
        println("✓ No region orphans found.")
        return DataFrame(
            ident_ccode = Union{Int,Missing}[],
            ident_ccodealp = Union{String,Missing}[],
            ident_cname = Union{String,Missing}[],
            rows = Int[],
            year_min = Union{Int,Missing}[],
            year_max = Union{Int,Missing}[]
        )
    end
    
    orphan_summary = combine(groupby(orphans, [:ident_ccode, :ident_ccodealp, :ident_cname])) do sdf
        years = collect(skipmissing(sdf.ident_year))
        (
            rows = nrow(sdf),
            year_min = isempty(years) ? missing : minimum(years),
            year_max = isempty(years) ? missing : maximum(years)
        )
    end
    
    sort!(orphan_summary, :rows, rev=true)
    
    println(">>> Region Orphans: $(nrow(orphan_summary)) entities, $(sum(orphan_summary.rows)) total rows")
    
    return orphan_summary
end


"""
Injects a geographic sub-region coordinate into the QoG time-series using the UN M49 standard.

This function acts as a Phase 0 saturation gate. It maps every observation to a UN sub-region 
code under the `ggis_` namespace. It relies on the global `GHOST_REGION_MAP` to resolve 
historical or non-standard entities (e.g., Tibet 9156) that are absent from modern UN lookups.

Usage:
    df_ungeo = apply_georegion_layer(df, geo_df)

# Arguments
- `df::DataFrame`: The rescued QoG time-series containing `ident_ccode`.
- `geo_df::DataFrame`: The geographic lookup table containing `ident_ccode` and `un_subregion_code`.

# Returns
- `df_enriched::DataFrame`: A copy of the input DataFrame with the added `:ggis_un_subregion_code` column.

# Invariants
- **Immutability:** The input `df` is not modified in-place.
- **Saturation:** Every row MUST resolve to a sub-region code; otherwise, a `Phase 0 Failure` error is thrown.
- **Namespace:** The raw `un_subregion_code` is dropped to prevent collision with engineered `ggis_` variables.
"""
function apply_georegion_layer(df::DataFrame, geo_df::DataFrame)
    df_enriched = copy(df)
    
    # 1. Standard Join
    map_ref = select(geo_df, [:ident_ccode, :un_subregion_code])
    df_enriched = leftjoin(df_enriched, map_ref, on = :ident_ccode)
    
    # 2. Mapping Function with corrected key
    function resolve_code(ccode, un_code)
        if !ismissing(ccode) && haskey(GHOST_REGION_MAP, ccode)
            return Int64(GHOST_REGION_MAP[ccode].code)
        end
        return un_code
    end
    
    df_enriched[!, :ggis_un_subregion_code] = map(
        (c, u) -> resolve_code(c, u), 
        df_enriched.ident_ccode, 
        df_enriched.un_subregion_code
    )
    
    # 3. Final Verification
    missing_indices = findall(ismissing, df_enriched.ggis_un_subregion_code)
    if !isempty(missing_indices)
        bad_entities = unique(df_enriched[missing_indices, [:ident_ccode, :ident_cname]])
        @error "Phase 0 Failure: Spine not saturated." Unmapped=bad_entities
        error("Process Halted.")
    end
    
    select!(df_enriched, Not(:un_subregion_code))
    println("✅ Phase 0: 100% Saturation. All rows mapped to UN Sub-regions.")
    return df_enriched
end


"""
Comprehensive loader for QoG time-series data with full processing pipeline. Executes the complete data preparation workflow: load raw Arrow with rowid assignment, preview rescue collisions (optional), apply historical ccode rescue, standardize regions, report coverage diagnostics, and list orphan entities.
Usage:
    df = load_qog_timeseries()
    df = load_qog_timeseries("path/to/custom.arrow"; preview_collisions=false, verbose=false)
Returns:
- DataFrame with fully processed time-series data ready for analysis
Pipeline Steps:
1. Load raw data with `load_raw_ident` (assigns `ggis_rowid`)
2. Preview rescue collisions via `preview_rescue_collisions` (optional)
3. Apply historical ccode rescue via `rescue_historical_ccodes`
4. Standardize regions via `standardize_regions` (grouped imputation + fallback mapping)
5. Report coverage diagnostics and list orphans via `list_region_orphans`
Output Guarantees:
- Unique `ggis_rowid` for all rows (immutable identifier)
- `ident_*` namespace variables properly promoted
- Historical ccodes rescued where possible
- `ggis_region` populated via multiple imputation strategies
- Collision tracking via `ggis_spine_collision` flag
- Rescue tracking via `ggis_ccode_rescued` flag
Key Columns:
- ggis_rowid: Unique row identifier (immutable)
- ident_ccode, ident_ccodealp, ident_cname, ident_year: Entity identifiers
- ggis_region: Standardized region (1-6, or missing for orphans)
- ggis_ccode_rescued: Flag indicating rescued ccodes
- ggis_spine_collision: Flag indicating duplicate (ccode, year) pairs
- ht_region: Original region from source data
Notes:
- Default path is PATH_TS_RAW (data/qog_std_ts_jan25.arrow)
- Set `preview_collisions=false` to skip collision preview
- Set `verbose=false` to suppress detailed rescue/region diagnostics
- All diagnostic output prints to stdout
- Orphan summary is printed but the orphan DataFrame is not returned (use `list_region_orphans` separately if needed)
- The function does NOT modify the original Arrow file
"""
function load_qog_timeseries(timeseries_path::AbstractString=PATH_TS_RAW; 
                             preview_collisions::Bool=true,
                             show_collision_years::Bool=true,
                             verbose::Bool=true,
                             geo_lookup_path::AbstractString=PATH_GEO_LOOKUP,
                             force_rebuild::Bool=false)
    
    println("="^80)
    println("QoG Time-Series Loader Pipeline")
    println("="^80)
    println("Input: $timeseries_path")
    println()
    
    # -------------------------------------------------------------------------
    # Step 1: Load with rowid assignment
    # -------------------------------------------------------------------------
    println(">>> Step 1/5: Loading raw data with identity promotion...")
    df_ident = load_raw_ident(timeseries_path)
    println("    Loaded: $(nrow(df_ident)) rows × $(ncol(df_ident)) columns")
    if isfile(PATH_TS_RAW_AUG) && !force_rebuild
        println("="^80)
        println("QoG Time-Series Loader Pipeline")
        println("="^80)
        println("Detected pre-augmented Arrow file: $(PATH_TS_RAW_AUG)")
        println("Loading augmented data directly...")
        df_final = Arrow.Table(PATH_TS_RAW_AUG) |> DataFrame
        println("Loaded: $(nrow(df_final)) rows × $(ncol(df_final)) columns")
        println("="^80)
        return df_final
    end
    # ...existing code...
    println("="^80)
    println("QoG Time-Series Loader Pipeline")
    println("="^80)
    println("Input: $timeseries_path")
    println()
    # Step 1: Load with rowid assignment
    println(">>> Step 1/5: Loading raw data with identity promotion...")
    df_ident = load_raw_ident(timeseries_path)
    println("    Loaded: $(nrow(df_ident)) rows × $(ncol(df_ident)) columns")
    println("    ✓ ggis_rowid assigned")
    println()
    # Step 2: Preview rescue collisions
    if preview_collisions
        println(">>> Step 2/5: Previewing rescue collisions...")
        collision_preview = preview_rescue_collisions(df_ident; show_years=show_collision_years)
        if nrow(collision_preview) > 0
            println("    ⚠️  Found $(nrow(collision_preview)) collision group(s)")
            if show_collision_years && :years in propertynames(collision_preview)
                println("    (See year details above)")
            end
        end
        println()
    else
        println(">>> Step 2/5: Skipping collision preview")
        println()
    end
    # Step 3: Apply rescue
    println(">>> Step 3/5: Rescuing historical ccodes...")
    df_rescued = rescue_historical_ccodes(df_ident; verbose=verbose)
    println()
    # Step 4: Standardize regions
    println(">>> Step 4/5: Standardizing regions...")
    df_regions = standardize_regions(df_rescued; verbose=verbose)
    println()
    # Step 5: Coverage diagnostics and orphan report
    println(">>> Step 5/5: Coverage diagnostics...")
    n_total = nrow(df_regions)
    n_missing = count(ismissing, df_regions.ggis_region)
    n_assigned = n_total - n_missing
    coverage_pct = round(100 * n_assigned / n_total, digits=2)
    println("    Total rows: $n_total")
    println("    Regions assigned: $n_assigned ($coverage_pct%)")
    println("    Missing regions: $n_missing")
    println()
    if n_missing > 0
        println(">>> Orphan entities (no region assignment):")
        orphans = list_region_orphans(df_regions)
        println()
    else
        println(">>> ✓ No orphan entities — full region coverage achieved!")
        println()
    end
    # Step 6: Apply geographic sub-region layer
    println(">>> Step 6: Applying UN geographic sub-region layer...")
    geo_df = CSV.read(geo_lookup_path, DataFrame)
    df_final = apply_georegion_layer(df_regions, geo_df)
    println()
    # Final summary
    println("="^80)
    println("Pipeline Complete!")
    println("="^80)
    println("Output DataFrame: $(nrow(df_final)) rows × $(ncol(df_final)) columns")
    println()
    println("Key columns:")
    println("  - ggis_rowid:          Unique row identifier")
    println("  - ident_ccode:         Country code (with historical rescue)")
    println("  - ident_year:          Year")
    println("  - ggis_region:         Standardized region (1-6)")
    println("  - ggis_ccode_rescued:  Historical rescue flag")
    println("  - ggis_spine_collision: Duplicate spine flag")
    println("  - ggis_un_subregion_code: UN sub-region code")
    println()
    println("Ready for analysis! 🚀")
    println("="^80)
    println()
    println("To save for fast future loads: save_augmented(df_final)")
    println("="^80)
    return df_final
end


"""Path for the checksum sidecar file."""
const PATH_TS_RAW_AUG_CHECKSUM = PATH_TS_RAW_AUG * ".sha256"

"""
Compute a SHA-256 checksum of a file.
"""
function _file_sha256(path::String)
    open(path, "r") do io
        bytes2hex(SHA.sha256(io))
    end
end

"""
Save the augmented DataFrame to Arrow for fast future loads.

Arguments:
- df::DataFrame: The augmented DataFrame from load_qog_timeseries()
- path::String: Output path (default: PATH_TS_RAW_AUG)

Returns:
- Nothing

Rules:
- Runs integrity checks before saving (row count, ggis_rowid uniqueness, required columns)
- Writes a .sha256 sidecar file for verification on load
- Overwrites existing file if present
"""
function save_augmented(df::DataFrame; path::String = PATH_TS_RAW_AUG)
    # Integrity checks before saving
    required_cols = [:ggis_rowid, :ident_ccode, :ident_year, :ident_ccodealp, :ggis_region, :ggis_un_subregion_code]
    for col in required_cols
        if !(col in propertynames(df))
            error("Cannot save: missing required column :$col")
        end
    end
    if !allunique(df.ggis_rowid)
        error("Cannot save: ggis_rowid is not unique")
    end
    if count(ismissing, df.ggis_region) > 0
        error("Cannot save: ggis_region has missing values")
    end

    Arrow.write(path, df)

    # Write checksum sidecar
    checksum = _file_sha256(path)
    checksum_path = path * ".sha256"
    open(checksum_path, "w") do io
        println(io, checksum)
    end

    println("✅ Saved augmented DataFrame: $(nrow(df)) rows × $(ncol(df)) cols → $path")
    println("   Checksum: $checksum → $checksum_path")
end


"""
Load the pre-built augmented DataFrame from Arrow, with integrity verification.

Arguments:
- path::String: Path to augmented Arrow file (default: PATH_TS_RAW_AUG)

Returns:
- DataFrame: The augmented QoG timeseries

Rules:
- Verifies row count, ggis_rowid uniqueness, required columns, and no missing regions
- Errors if any check fails (forces re-run of full pipeline)

Usage:
    df = load_augmented()                    # load cached file
    df = load_augmented_or_build()           # load cached, or build if missing
"""
function load_augmented(; path::String = PATH_TS_RAW_AUG, verbose::Bool = true)
    if !isfile(path)
        error("Augmented file not found: $path\nRun the full pipeline: df = load_qog_timeseries(); save_augmented(df)")
    end

    # --- Checksum verification ---
    checksum_path = path * ".sha256"
    if isfile(checksum_path)
        expected = strip(read(checksum_path, String))
        actual = _file_sha256(path)
        if actual != expected
            error("Checksum mismatch for $path\n  Expected: $expected\n  Actual:   $actual\nFile may be corrupted. Re-run pipeline and save_augmented()")
        end
        if verbose
            println("✓ Checksum verified: $path")
        end
    else
        if verbose
            println("⚠️  No checksum file found — skipping verification")
        end
    end

    df = Arrow.Table(path) |> DataFrame

    # --- Structural integrity checks ---
    required_cols = [:ggis_rowid, :ident_ccode, :ident_year, :ident_ccodealp, :ggis_region, :ggis_un_subregion_code]
    missing_cols = [col for col in required_cols if !(col in propertynames(df))]
    if !isempty(missing_cols)
        error("Integrity failure: missing columns $(missing_cols) in $path\nRe-run pipeline and save_augmented()")
    end

    if !allunique(df.ggis_rowid)
        error("Integrity failure: ggis_rowid not unique in $path\nRe-run pipeline and save_augmented()")
    end

    n_missing_regions = count(ismissing, df.ggis_region)
    if n_missing_regions > 0
        error("Integrity failure: $n_missing_regions missing regions in $path\nRe-run pipeline and save_augmented()")
    end

    if verbose
        println("✓ Loaded: $(nrow(df)) rows × $(ncol(df)) cols from $path")
        println("  ggis_rowid unique: ✓ | Required columns: ✓ | Missing regions: 0 ✓")
    end

    return df
end


"""
Load the augmented DataFrame from cache if available, otherwise build from scratch.

Returns:
- DataFrame: The augmented QoG timeseries

Usage:
    df = load_augmented_or_build()
"""
function load_augmented_or_build(; verbose::Bool = true)
    if isfile(PATH_TS_RAW_AUG)
        try
            return load_augmented(; verbose=verbose)
        catch e
            if verbose
                println("⚠️  Cached file failed integrity: $(e.msg)")
                println("    Rebuilding from scratch...")
            end
        end
    end

    if verbose
        println(">>> Running full pipeline...")
    end
    df = load_qog_timeseries(; verbose=verbose)
    save_augmented(df)
    return df
end


# ==============================================================================
# CARTOGRAPHIC UTILITIES
# ==============================================================================

"""
Generates a cartographic region lookup DataFrame for world map rendering.
Usage:
    carto_lookup = generate_cartographic_lookup(df_augmented)
Returns:
- DataFrame with (ident_ccode, ident_ccodealp, ident_cname, ht_region) for all mappable entities
Rules:
- Extracts unique (ccode, alpha, region) from augmented QoG data
- Appends CARTOGRAPHIC_TERRITORIES for non-QoG entities
- Suitable for joining with TopoJSON world-110m by ccode
"""
function generate_cartographic_lookup(df::DataFrame)
    # Extract unique entities from QoG data
    qog_entities = combine(groupby(df, [:ident_ccode, :ident_ccodealp])) do sdf
        regions = collect(skipmissing(sdf.ggis_region))
        names = collect(skipmissing(sdf.ident_cname))
        (
            ht_region = isempty(regions) ? missing : first(regions),
            ident_cname = isempty(names) ? missing : first(names)
        )
    end
    
    # Filter to rows with valid ccode and region
    qog_entities = filter(r -> !ismissing(r.ident_ccode) && !ismissing(r.ht_region), qog_entities)
    
    # Add cartographic territories
    carto_df = DataFrame(
        ident_ccode = [t[1] for t in CARTOGRAPHIC_TERRITORIES],
        ident_ccodealp = [t[2] for t in CARTOGRAPHIC_TERRITORIES],
        ht_region = [t[3] for t in CARTOGRAPHIC_TERRITORIES],
        ident_cname = [t[4] for t in CARTOGRAPHIC_TERRITORIES]
    )
    
    # Combine (QoG entities take precedence if overlap)
    result = vcat(qog_entities, carto_df)
    
    # Deduplicate by ccode (keep first, which is QoG)
    result = combine(groupby(result, :ident_ccode), first)
    
    sort!(result, :ident_ccode)
    
    println(">>> Generated cartographic lookup: $(nrow(result)) entities")
    println("    From QoG: $(nrow(qog_entities))")
    println("    Supplemental territories: $(length(CARTOGRAPHIC_TERRITORIES))")
    
    return select(result, [:ident_cname, :ident_ccode, :ident_ccodealp, :ht_region])
end


# ==============================================================================
# DIAGNOSTICS & DOCUMENTATION
# ==============================================================================

function list_unmapped_summary(df)
    orphans = df[coalesce.(ismissing.(df.ht_region), false), :]
    if isempty(orphans) return nothing end
    return combine(groupby(orphans, [:ident_cname, :ident_ccode])) do sdf
        (Rows = nrow(sdf), Period = "$(minimum(sdf.ident_year)) - $(maximum(sdf.ident_year))")
    end
end


"""
Checks case-sensitive equivalence between dataset column slugs and manifest slugs.
Usage:
    result = compare_slug_alignment(df_aug, manifest)
    result = compare_slug_alignment(df_aug, manifest; strict=false)
Returns:
- NamedTuple with `ok::Bool`, `only_in_df::Vector{String}`, `only_in_manifest::Vector{String}`
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

    # Optional: ensure each side is internally unique (helps catch upstream issues early)
    _assert_unique_names(df_slugs; context="df_aug column slugs")
    _assert_unique_names(manifest_slugs; context="manifest.Variable slugs")

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
Generates a Markdown table documenting all functions in the specified Julia source file.
Usage:
    document_functions_precise("path/to/source_file.jl")
Rules:
- Extracts function name, call signature, and description from docstrings.
- Prioritizes 'Usage:' lines for call signatures when available.
- Captures the first meaningful line of the docstring as the description.
"""
function document_functions_precise(filepath::String)
    if !isfile(filepath)
        @error "File not found: $filepath"
        return
    end

    content = read(filepath, String)
    
    # Regex Breakdown:
    # \"\"\"((?:(?!\"\"\").)*?)\"\"\"  -> Matches the SHORTEST block between triple quotes
    # \s+function\s+                   -> Followed by the function keyword
    # ([a-zA-Z0-9_!]+)                -> Captures name
    # \((.*?)\)                       -> Captures arguments
    pattern = r"(?s)\"\"\"((?:(?!\"\"\").)*?)\"\"\"\s+function\s+([a-zA-Z0-9_!]+)\((.*?)\)"
    
    md_text = "| Function | How to Call | Description |\n| :--- | :--- | :--- |\n"
    
    for m in eachmatch(pattern, content)
        raw_doc = strip(m.captures[1])
        f_name = m.captures[2]
        
        # 1. Extract Call Signature (Prioritize 'Usage:' line, otherwise use name(args))
        usage_match = match(r"Usage:\s*\n?\s*(.*)", raw_doc)
        how_to_call = usage_match !== nothing ? "`$(strip(usage_match.captures[1]))`" : "`$f_name(...)`"
        
        # 2. Extract Description (The first line that isn't a signature or 'Usage')
        doc_lines = split(raw_doc, "\n")
        # Find the first line that has actual text and isn't just the function name repeated
        desc_line = ""
        for line in doc_lines
            l = strip(line)
            if isempty(l) || contains(l, "Usage:") || contains(l, "Returns:") || (length(l) < 30 && contains(l, f_name))
                continue
            end
            desc_line = l
            break
        end

        md_text *= "| **`$f_name`** | $how_to_call | $desc_line |\n"
    end
    
    display(Markdown.parse("### 🛠️ Function API Reference\n" * md_text))
end


"""
Generates a Markdown table documenting all constants in the specified Julia source file.
Usage:
    summarize_constants_from_file("path/to/source_file.jl")
Rules:
- Extracts constant name and description from docstrings.
- Only matches `const` declarations outside of docstrings.
"""
function summarize_constants_from_file(filepath::String)
    if !isfile(filepath)
        @error "File not found: $filepath"
        return
    end

    lines = readlines(filepath)
    md_text = "| Constant | Description |\n| :--- | :--- |\n"
    
    current_doc = String[]
    in_docstring = false
    
    for line in lines
        t_line = strip(line)
        
        # Handle Docstring Toggle
        if startswith(t_line, "\"\"\"")
            if count("\"\"\"", t_line) == 2 && !in_docstring
                # Case: Single-line docstring """text"""
                doc_content = replace(t_line, "\"\"\"" => "")
                current_doc = [strip(doc_content)]
            elseif !in_docstring
                # Case: Start of multi-line
                in_docstring = true
                current_doc = String[]  # Reset for new docstring
                doc_content = replace(t_line, "\"\"\"" => "")
                !isempty(strip(doc_content)) && push!(current_doc, strip(doc_content))
            else
                # Case: End of multi-line
                in_docstring = false
                doc_content = replace(t_line, "\"\"\"" => "")
                !isempty(strip(doc_content)) && push!(current_doc, strip(doc_content))
            end
            continue
        end

        # Accumulate lines if we are inside a docstring
        if in_docstring
            push!(current_doc, t_line)
            continue
        end

        # Only match const declarations OUTSIDE docstrings
        # Must start with "const " (not just contain it)
        if startswith(lstrip(line), "const ")
            m = match(r"^const\s+([A-Z][A-Z0-9_]*)\s*=", lstrip(line))
            if m !== nothing
                const_name = m.captures[1]
                
                # Join multi-line docs with spaces
                full_desc = isempty(current_doc) ? "_No description_" : join(current_doc, " ")
                
                # Clean up: Replace any internal quotes or problematic markdown chars
                full_desc = replace(full_desc, "|" => "\\|")
                full_desc = replace(full_desc, "_" => "\\_")  # Escape underscores
                
                md_text *= "| **`$(const_name)`** | $(strip(full_desc)) |\n"
                current_doc = String[]  # Reset after capturing
            end
        elseif !isempty(current_doc) && !startswith(lstrip(line), "const ")
            # If we have accumulated docs but hit a non-const line, reset
            # (the docstring was for a function, not a constant)
            if !isempty(strip(line)) && !startswith(strip(line), "#")
                current_doc = String[]
            end
        end
    end
    
    display(Markdown.parse("### 📂 Constants Defined in `$(basename(filepath))`\n" * md_text))
end


# ==============================================================================
# EXAMPLES (ALWAYS AT END)
# ==============================================================================

"""
Demonstration of the standard augmentation pipeline.
Usage:
    run_augmented_standard_samples()
Note: This function is for testing/demonstration only.
"""
function run_augmented_standard_samples()
    println("=" ^ 60)
    println("QoG Augmented Standard - Pipeline Demo")
    println("=" ^ 60)
    
    # Standard pipeline
    println("\n>>> Step 1: Load raw data with ggis_rowid")
    df_ident = load_raw_ident(PATH_TS_RAW)
    println("    Loaded $(nrow(df_ident)) rows, $(ncol(df_ident)) columns")
    
    println("\n>>> Step 2: Diagnose spine issues")
    issues = diagnose_spine_issues(df_ident)
    
    println("\n>>> Step 3: Check for ccode collisions before rescue")
    collisions = diagnose_ccode_collisions(df_ident)
    
    println("\n>>> Step 4: Preview rescue collisions")
    preview = preview_rescue_collisions(df_ident)
    
    println("\n>>> Step 5: Rescue historical ccodes")
    df_rescued = rescue_historical_ccodes(df_ident; verbose=true)
    
    println("\n>>> Step 6: Standardize regions")
    df_regions = standardize_regions(df_rescued; verbose=true)
    
    println("\n>>> Step 7: List region orphans")
    orphans = list_region_orphans(df_regions)
    
    println("\n>>> Step 8: Generate cartographic lookup")
    carto = generate_cartographic_lookup(df_regions)
    
    # Verify row preservation
    @assert nrow(df_regions) == nrow(df_ident) "Row count mismatch!"
    
    println("\n" * "=" ^ 60)
    println("✅ Pipeline complete: $(nrow(df_regions)) rows preserved")
    println("=" ^ 60)
    
    return df_regions
end

# ========================================================================
# AUGMENTED STANDARD PIPELINE EXAMPLES & DOCUMENTATION
# ========================================================================

"""
Comprehensive documentation and code examples for the QoG Augmented Standard pipeline.

This function prints methodology and code examples for reference.
It does NOT execute any code — use it as a quick reference guide.

Usage:
    run_augmented_standard_samples()                  # Print all documentation
    run_augmented_standard_samples(section=:all)      # Same as above
    run_augmented_standard_samples(section=:prereq)   # Prerequisites only
    run_augmented_standard_samples(section=:acquire)  # Data acquisition
    run_augmented_standard_samples(section=:manifest) # Manifest extraction
    run_augmented_standard_samples(section=:spine)    # Spine diagnostics
    run_augmented_standard_samples(section=:rescue)   # Historical rescue
    run_augmented_standard_samples(section=:region)   # Region standardization
    run_augmented_standard_samples(section=:carto)    # Cartographic lookup
    run_augmented_standard_samples(section=:slugs)    # Arrow slug extraction
    run_augmented_standard_samples(section=:validate) # Validation utilities
    run_augmented_standard_samples(section=:summary)  # Minimal pipeline
"""
function run_augmented_standard_samples(; section::Symbol = :all, execute::Bool = false)
    sections = Dict(
        :prereq => aug_print_section_prereq,
        :acquire => aug_print_section_acquire,
        :manifest => aug_print_section_manifest,
        :spine => aug_print_section_spine,
        :rescue => aug_print_section_rescue,
        :region => aug_print_section_region,
        :carto => aug_print_section_carto,
        :slugs => aug_print_section_slugs,
        :validate => aug_print_section_validate,
        :summary => aug_print_section_summary
    )

    if execute
        println("⚠️  execute=true is not implemented.")
        println("    This function is for documentation only.")
        println("    Copy code blocks to your REPL or notebook to run them.")
        return nothing
    end

    if section == :all
        println("=" ^ 70)
        println("QoG AUGMENTED STANDARD - Complete Pipeline Guide")
        println("=" ^ 70)
        println("\n📖 This is DOCUMENTATION ONLY — no code is executed.")
        println("   Copy code blocks to your REPL or notebook to run them.\n")
        
        # Print in logical order
        for key in [:prereq, :acquire, :manifest, :spine, :rescue, :region, :carto, :slugs, :validate, :summary]
            sections[key]()
        end
        
        println("=" ^ 70)
        println("Documentation complete.")
        println("=" ^ 70)
    elseif haskey(sections, section)
        println("=" ^ 70)
        println("QoG AUGMENTED STANDARD - Section: $section")
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

function aug_print_section_prereq()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ PREREQUISITES                                                           │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Before running the augmentation pipeline, ensure you have:
    
    1. Julia packages installed
    2. QoG source files downloaded (or use `download_qog_sources()`)
    3. Working directory set to project root
    
    ```julia
    # Load dependencies
    using Arrow, DataFrames, CSV, Statistics, StatsBase
    using ReadStatTables, HTTP, JSON, Downloads
    
    # Load the augmentation functions
    include("phase0/functions/qog_augmented_standard.jl")
    
    # Verify working directory
    println("Working directory: ", pwd())
    println("Data directory exists: ", isdir(PATH_DATA_DIR))
    ```
    
    Key Path Constants:
    
    | Constant | Description |
    |----------|-------------|
    | `PATH_DATA_DIR` | Directory for all data files |
    | `PATH_TS_RAW` | Arrow-converted QoG time-series |
    | `PATH_TS_STRATA_RAW` | Raw Stata .dta file |
    | `PATH_MANIFEST_SRC` | Extracted variable manifest |
    | `PATH_ARROW_SLUGS` | Extracted column slugs |
    
    Namespace Prefixes:
    
    | Prefix | Purpose |
    |--------|---------|
    | `ident_` | Topological coordinates (where/when) — protected namespace |
    | `ggis_` | Operational intelligence (internal logic/quality gates) |
    | `[src]_` | Analytical sensors (e.g., `wdi_`, `vdem_`, `bmr_`) |
    | (none) | `ht_region` is prefix-free as the anchor cluster |
    """)
end


function aug_print_section_acquire()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ DATA ACQUISITION                                                        │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Download official QoG datasets and convert to Arrow format.
    
    ```julia
    # Step 1: Download QoG source files
    download_summary = download_qog_sources()
    
    # Check results
    println("Downloaded: ", download_summary.downloaded)
    println("Skipped: ", download_summary.skipped)
    println("Failed: ", download_summary.failed)
    ```
    
    ```julia
    # Step 2: Convert CSV to Arrow format
    convert_summary = convert_csv_to_arrow()
    
    # Check results
    println("Converted: ", convert_summary.converted)
    println("Skipped: ", convert_summary.skipped)
    ```
    
    Source URLs (defined in `QOG_SOURCES`):
    
    | File | Description |
    |------|-------------|
    | `qog_std_ts_jan25.csv` | Standard Time-Series (main data) |
    | `qog_std_cs_jan25.dta` | Standard Cross-Section (Stata, for metadata) |
    | `codebook_std_jan25.pdf` | Official codebook |
    
    Notes:
    - Downloads are idempotent (skips existing files)
    - Arrow conversion lowercases all column names
    - Use `force=true` in `convert_csv_to_arrow` to rebuild existing files
    """)
end


function aug_print_section_manifest()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ MANIFEST EXTRACTION                                                     │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Extract variable names, labels, and prefixes from the raw Stata file.
    This creates the authoritative manifest of QoG variables.
    
    ```julia
    # Generate manifest from Stata file
    manifest = generate_raw_manifest(PATH_TS_STRATA_RAW, PATH_MANIFEST_SRC)
    
    # Inspect the manifest
    first(manifest, 10)
    ```
    
    Manifest columns:
    
    | Column | Description |
    |--------|-------------|
    | `Variable` | Lowercase variable name (slug) |
    | `Label` | Human-readable description from Stata |
    | `Prefix` | Source prefix (e.g., `wdi`, `vdem`, `base`) |
    
    Prefix assignment rules:
    - Variables with `_` get their lead string (e.g., `wdi_gdp` → `wdi`)
    - Naked variables (`ccode`, `year`) are tagged as `base`
    - `base` variables are later promoted to `ident_` namespace
    
    ```julia
    # Count variables by prefix
    combine(groupby(manifest, :Prefix), nrow => :count) |> 
        df -> sort(df, :count, rev=true)
    ```
    """)
end


function aug_print_section_spine()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ SPINE DIAGNOSTICS                                                       │
    └─────────────────────────────────────────────────────────────────────────┘
    
    The "spine" is the (ident_ccode, ident_year) pair that uniquely identifies
    each observation. Before augmentation, diagnose any spine issues.
    
    ```julia
    # Load data with identity promotion
    df_ident = load_raw_ident(PATH_TS_RAW)
    
    # Check what we got
    println("Rows: ", nrow(df_ident))
    println("Columns: ", ncol(df_ident))
    println("Has ggis_rowid: ", :ggis_rowid in propertynames(df_ident))
    ```
    
    ```julia
    # Diagnose spine issues (missing ccode or year)
    issues = diagnose_spine_issues(df_ident)
    
    # Optional: save to file for manual review
    issues = diagnose_spine_issues(df_ident; output_path="data/spine_issues.csv")
    ```
    
    Issue types:
    
    | Type | Meaning |
    |------|---------|
    | `BLANK_ROW` | Row has no data at all |
    | `MISSING_BOTH` | Missing both ccode and year |
    | `MISSING_CCODE_ONLY` | Has year but no ccode |
    | `MISSING_YEAR_ONLY` | Has ccode but no year |
    
    ```julia
    # Audit for shadow identity variables (violations of namespace rules)
    shadow_vars = audit_shadow_identities(df_ident)
    
    # Should return empty if namespace is clean
    ```
    
    Key columns after `load_raw_ident`:
    
    | Column | Description |
    |--------|-------------|
    | `ggis_rowid` | Unique immutable row index (1:nrow) |
    | `ident_ccode` | ISO-3166-1 numeric country code |
    | `ident_ccodealp` | ISO-3166-1 alpha-3 country code |
    | `ident_year` | Observation year |
    | `ident_cname` | Country name |
    | `ht_region` | QoG regional classification (1-10) |
    """)
end


function aug_print_section_rescue()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ HISTORICAL CCODE RESCUE                                                 │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Some historical entities have alpha codes but missing numeric ccodes.
    The rescue process fills these in using `HISTORICAL_CCODE_MAP`.
    
    ```julia
    # Step 1: Check for collisions BEFORE rescue
    collisions = diagnose_ccode_collisions(df_ident)
    
    # Collision statuses:
    # - "OK (same entity)" — no problem
    # - "OK (new ccode)" — adding new ccode, no conflict
    # - "⚠️ INTENTIONAL" — known collision, resolved by priority
    # - "❌ CONFLICT" — would overwrite different country!
    ```
    
    ```julia
    # Step 2: Preview what collisions will occur
    preview = preview_rescue_collisions(df_ident)
    
    # Show year details
    preview = preview_rescue_collisions(df_ident; show_years=true)
    ```
    
    ```julia
    # Step 3: Apply rescue (if no conflicts)
    df_rescued = rescue_historical_ccodes(df_ident; verbose=true)
    
    # New columns added:
    # - ggis_ccode_rescued::Bool — true if ccode was filled
    # - ggis_spine_collision::Bool — true if row shares (ccode, year)
    ```
    
    Historical mappings (from `HISTORICAL_CCODE_MAP`):
    
    | Alpha | → ccode | Entity |
    |-------|---------|--------|
    | DEU | 276 | Germany (unified) |
    | VNM | 704 | Vietnam (unified) |
    | VDR | 704 | South Vietnam → Vietnam |
    | YEM | 887 | Yemen (unified) |
    | SCG | 688 | Serbia and Montenegro → Serbia |
    | ETH | 231 | Ethiopia |
    | MHL | 584 | Marshall Islands |
    | XTI | 9156 | Tibet (synthetic code) |
    
    Collision priority (from `COLLISION_PRIORITY_ALPHAS`):
    - When VNM and VDR both map to 704, VNM wins (successor state)
    
    **IMPORTANT**: No rows are ever deleted. Use `ggis_rowid` as unique key.
    """)
end


function aug_print_section_region()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ REGION STANDARDIZATION                                                  │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Assign authoritative regions to all rows. Creates `ggis_region` column
    (operational copy of `ht_region` with imputation).
    
    ```julia
    # Standardize regions (requires rescued data)
    df_regions = standardize_regions(df_rescued; verbose=true)
    
    # Check coverage
    n_missing = count(ismissing, df_regions.ggis_region)
    println("Missing regions: \$n_missing / \$(nrow(df_regions))")
    ```
    
    Imputation order:
    
    1. **Use ht_region** if present (from QoG source)
    2. **Impute from same ccode** — share region across entity-years
    3. **Fallback to RESCUED_ENTITY_REGIONS** — for historical entities
    
    ```julia
    # List entities without region assignment
    orphans = list_region_orphans(df_regions)
    ```
    
    QoG Region Codes (`ht_region`):
    
    | Code | Region |
    |------|--------|
    | 1 | Eastern Europe & post-Soviet Union |
    | 2 | Latin America |
    | 3 | North Africa & Middle East (MENA) |
    | 4 | Sub-Saharan Africa |
    | 5 | Western Europe & North America |
    | 6 | East Asia |
    | 7 | Southeast Asia |
    | 8 | South Asia |
    | 9 | The Pacific |
    | 10 | The Caribbean |
    
    Rescued entity regions (from `RESCUED_ENTITY_REGIONS`):
    
    | Alpha | → Region | Entity |
    |-------|----------|--------|
    | VDR | 7 | South Vietnam → Southeast Asia |
    | XTI | 6 | Tibet → East Asia |
    | DDR | 1 | East Germany → Eastern Europe |
    | SCG | 1 | Serbia & Montenegro → Eastern Europe |
    | SUN | 1 | USSR → Eastern Europe |
    """)
end


function aug_print_section_carto()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ CARTOGRAPHIC LOOKUP                                                     │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Generate a lookup table for world map rendering. Includes both QoG entities
    and supplemental territories needed for complete map coverage.
    
    ```julia
    # Generate cartographic lookup
    carto = generate_cartographic_lookup(df_regions)
    
    # Inspect
    first(carto, 10)
    ```
    
    Output columns:
    
    | Column | Description |
    |--------|-------------|
    | `ident_cname` | Country/territory name |
    | `ident_ccode` | ISO-3166-1 numeric code |
    | `ident_ccodealp` | ISO-3166-1 alpha-3 code |
    | `ht_region` | Regional classification |
    
    Supplemental territories (from `CARTOGRAPHIC_TERRITORIES`):
    
    | ccode | Alpha | Region | Territory |
    |-------|-------|--------|-----------|
    | 238 | FLK | 5 | Falkland Islands (UK) |
    | 260 | ATF | 5 | French Southern Territories |
    | 275 | PSE | 3 | Palestine |
    | 304 | GRL | 5 | Greenland (Denmark) |
    | 540 | NCL | 5 | New Caledonia (France) |
    | 630 | PRI | 5 | Puerto Rico (US) |
    | 732 | ESH | 3 | Western Sahara |
    
    Note: Territories are assigned to their administering country's region
    (e.g., French territories → Region 5 with France).
    """)
end


function aug_print_section_slugs()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ ARROW SLUG EXTRACTION                                                   │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Extract all column slugs from the augmented DataFrame with inferred types.
    This creates a CSV manifest of all columns in the Arrow data.
    
    ```julia
    # Extract slugs from augmented data
    slugs_df = extract_arrow_slugs(df_regions)
    
    # Output saved to PATH_ARROW_SLUGS
    ```
    
    Output columns:
    
    | Column | Description |
    |--------|-------------|
    | `slug` | Column name from DataFrame |
    | `prefix` | Extracted prefix (e.g., `wdi`, `ident`, `ggis`) |
    | `type` | Inferred type from data |
    
    Type inference rules:
    
    | Type | Criteria |
    |------|----------|
    | `:binary` | All non-missing values in {0, 1} |
    | `:discrete` | Integer-like with <20 unique values |
    | `:categorical` | Integer-like with 20-100 unique values |
    | `:continuous` | Everything else |
    | `:unknown` | All values missing |
    
    ```julia
    # Summary by prefix
    combine(groupby(slugs_df, :prefix), nrow => :count) |>
        df -> sort(df, :count, rev=true) |>
        df -> first(df, 15)
    ```
    
    ```julia
    # Summary by type
    combine(groupby(slugs_df, :type), nrow => :count) |>
        df -> sort(df, :count, rev=true)
    ```
    
    Note: This extracts ALL columns including:
    - `ident_*` (identity namespace)
    - `ggis_*` (operational namespace)
    - `ht_region` (anchor cluster)
    - All analytical slugs (`wdi_*`, `vdem_*`, etc.)
    """)
end


function aug_print_section_validate()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ VALIDATION UTILITIES                                                    │
    └─────────────────────────────────────────────────────────────────────────┘
    
    Validate data integrity and namespace compliance.
    
    ```julia
    # Validate ident schema of an adjunct file
    is_valid = validate_ident_schema(PATH_ARROW_SLUGS);
    is_valid = validate_ident_schema(PATH_MANIFEST_SRC);
    is_valid = validate_ident_schema(PATH_PDF_SLUGS);

    # Returns true if compliant, false if violations found
    ```
    
    Schema rules:
    - Variables with identity keywords (`ccode`, `cname`, `year`, `version`) 
      must be in `ident_` namespace
    - `ht_region` is exempted (anchor cluster)
    - `ggis_*` variables trigger warning but are allowed
    
    ```julia
    # DEPRECATED:Compare slug alignment between DataFrame and manifest
    result = compare_slug_alignment(df_aug, manifest)
    
    # Returns NamedTuple:
    # - ok::Bool — true if aligned
    # - only_in_df::Vector{String} — columns not in manifest
    # - only_in_manifest::Vector{String} — manifest vars not in data
    ```
    
    ```julia
    # DEPRECATED: Strict mode (throws error on mismatch)
    compare_slug_alignment(df_aug, manifest; strict=true)
    
    # DEPRECATED: Non-strict mode (returns results for inspection)
    result = compare_slug_alignment(df_aug, manifest; strict=false)
    ```
    
    Row preservation checks:
    
    ```julia
    # Always verify row count after operations
    @assert nrow(df_after) == nrow(df_before) "Row count changed!"
    
    # Verify ggis_rowid is still unique
    @assert allunique(df.ggis_rowid) "ggis_rowid no longer unique!"
    ```
    """)
end


function aug_print_section_summary()
    println("""
    ┌─────────────────────────────────────────────────────────────────────────┐
    │ SUMMARY: MINIMAL COMPLETE PIPELINE                                      │
    └─────────────────────────────────────────────────────────────────────────┘
    
    ```julia
    # === MINIMAL AUGMENTATION PIPELINE ===
    
    using Arrow, DataFrames, CSV, Statistics, StatsBase, ReadStatTables
    
    # 1. Load functions
    include("phase0/functions/qog_augmented_standard.jl")
    
    # 2. Download and convert (if needed)
    download_qog_sources()
    convert_csv_to_arrow()
    
    # 3. Extract manifest from Stata
    manifest = generate_raw_manifest(PATH_TS_STRATA_RAW, PATH_MANIFEST_SRC)
    
    # 4. Load and promote identity columns
    df_ident = load_raw_ident(PATH_TS_RAW)
    
    # 5. Diagnose spine issues
    issues = diagnose_spine_issues(df_ident)
    
    # 6. Rescue historical ccodes
    df_rescued = rescue_historical_ccodes(df_ident; verbose=true)
    
    # 7. Standardize regions
    df_regions = standardize_regions(df_rescued; verbose=true)
    
    # 8. Extract all slugs from Arrow
    slugs_df = extract_arrow_slugs(df_regions)
    
    # 9. Verify row preservation
    @assert nrow(df_regions) == nrow(df_ident) "Row count mismatch!"
    @assert allunique(df_regions.ggis_rowid) "ggis_rowid not unique!"
    
    println("✅ Augmentation complete: \$(nrow(df_regions)) rows")
    ```
    
    Output files:
    
    | File | Description |
    |------|-------------|
    | `PATH_MANIFEST_SRC` | Variable manifest from Stata |
    | `PATH_ARROW_SLUGS` | All column slugs with types |
    
    Key columns in augmented DataFrame:
    
    | Column | Description |
    |--------|-------------|
    | `ggis_rowid` | Unique immutable row index |
    | `ggis_ccode_rescued` | True if ccode was filled from map |
    | `ggis_spine_collision` | True if (ccode, year) is not unique |
    | `ggis_region` | Operational region (with imputation) |
    """)
end