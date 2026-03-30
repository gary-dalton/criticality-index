# ==============================================================================
# PHASE 2 — NETWORK DATA PREPROCESSING
# ==============================================================================
#
# Loads and preprocesses CEPII GeoDist and Gravity datasets into Arrow format.
# These provide the bilateral network edges (geographic proximity + trade flows)
# for graph-theoretic analysis of nearest-neighbor coupling.
#
# Data sources:
#   - CEPII GeoDist: dist_cepii.dta, geo_cepii.dta
#     https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=6
#   - CEPII Gravity: Gravity_csv_V202211.zip
#     https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=8
#
# Output:
#   - data/cepii_geodist.arrow      (static bilateral distances + cultural ties)
#   - data/cepii_geo_countries.arrow (country-level geographic metadata)
#   - data/cepii_gravity.arrow       (annual bilateral trade + controls)
#   - data/cepii_gravity_countries.arrow (country lookup from Gravity)
#
# ==============================================================================

using DataFrames
using ReadStatTables
using CSV
using Arrow
using ZipFile


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to CEPII GeoDist dyadic file (bilateral distances, contiguity, language, colonial ties)."""
const PATH_GEODIST_DTA = "data/dist_cepii.dta"

"""Path to CEPII GeoDist country-level file (lat/lon, landlocked, area)."""
const PATH_GEO_COUNTRIES_DTA = "data/geo_cepii.dta"

"""Path to CEPII Gravity zip archive."""
const PATH_GRAVITY_ZIP = "data/Gravity_csv_V202211.zip"

"""Arrow output path for GeoDist dyadic data."""
const PATH_GEODIST_ARROW = "data/cepii_geodist.arrow"

"""Arrow output path for GeoDist country metadata."""
const PATH_GEO_COUNTRIES_ARROW = "data/cepii_geo_countries.arrow"

"""Arrow output path for Gravity bilateral panel."""
const PATH_GRAVITY_ARROW = "data/cepii_gravity.arrow"

"""Arrow output path for Gravity country lookup."""
const PATH_GRAVITY_COUNTRIES_ARROW = "data/cepii_gravity_countries.arrow"

"""Columns to retain from the GeoDist dyadic file."""
const GEODIST_KEEP_COLS = [
    :iso_o, :iso_d,
    :contig,                    # shared border (0/1)
    :dist,                      # simple distance (km, between most populated cities)
    :distcap,                   # distance between capitals (km)
    :distw,                     # population-weighted distance (km)
    :distwces,                  # population-weighted distance (CES, alternative weighting)
    :comlang_off,               # shared official language (0/1)
    :comlang_ethno,             # shared ethnolinguistic language (0/1)
    :colony,                    # colonial relationship ever (0/1)
    :comcol,                    # common colonizer post-1945 (0/1)
    :col45,                     # colonial relationship post-1945 (0/1)
    :smctry,                    # same country (0/1)
]

"""Columns to retain from the Gravity bilateral panel."""
const GRAVITY_KEEP_COLS = [
    :year, :iso3_o, :iso3_d,
    :iso3num_o, :iso3num_d,
    :country_exists_o, :country_exists_d,
    :distw_harmonic,            # population-weighted distance (harmonic mean)
    :dist,                      # simple distance
    :contig,                    # shared border
    :comlang_off,               # shared official language
    :comlang_ethno,             # shared ethnolinguistic language
    :comcol,                    # common colonizer
    :col45,                     # colonial relationship post-1945
    :pop_o, :pop_d,             # population (origin, destination)
    :gdp_o, :gdp_d,             # GDP (origin, destination)
    :gdpcap_o, :gdpcap_d,       # GDP per capita
    :gatt_o, :gatt_d,           # GATT membership
    :wto_o, :wto_d,             # WTO membership
    :eu_o, :eu_d,               # EU membership
    :fta_wto,                   # FTA indicator (WTO-notified)
    :tradeflow_comtrade_o,      # trade flow: COMTRADE reporter (origin exports)
    :tradeflow_comtrade_d,      # trade flow: COMTRADE reporter (destination exports)
    :tradeflow_baci,            # trade flow: BACI (reconciled)
    :tradeflow_imf_o,           # trade flow: IMF DOT (origin)
    :tradeflow_imf_d,           # trade flow: IMF DOT (destination)
]


# ==============================================================================
# STEP 1: LOAD AND CONVERT GEODIST
# ==============================================================================

"""
Load CEPII GeoDist dyadic file (.dta), select key columns, and write to Arrow.

Arguments:
- dta_path::String: Path to dist_cepii.dta
- arrow_path::String: Output Arrow path
- verbose::Bool: Print diagnostics

Returns:
- DataFrame with bilateral distance and cultural tie variables

Rules:
- Raw .dta is never modified; output is a new Arrow file
- Only columns in GEODIST_KEEP_COLS are retained
- Self-pairs (iso_o == iso_d) are included (useful for validation)

Usage:
    geodist = load_geodist("data/dist_cepii.dta", "data/cepii_geodist.arrow")
"""
function load_geodist(
    dta_path::String = PATH_GEODIST_DTA,
    arrow_path::String = PATH_GEODIST_ARROW;
    verbose::Bool = true
)
    verbose && println("=" ^ 72)
    verbose && println("GEODIST: Loading $(dta_path)")

    # Read Stata file
    tbl = readstat(dta_path)
    df = DataFrame(tbl)
    verbose && println("    Raw: $(nrow(df)) rows × $(ncol(df)) cols")

    # Standardize column names to lowercase symbols
    rename!(df, [Symbol(lowercase(string(c))) for c in names(df)])

    # Select columns (only those present — GeoDist versions vary)
    available = [c for c in GEODIST_KEEP_COLS if hasproperty(df, c)]
    missing_cols = setdiff(GEODIST_KEEP_COLS, available)
    if !isempty(missing_cols) && verbose
        println("    ⚠️  Missing columns: $(missing_cols)")
    end
    df = select(df, available)

    # Convert iso codes to String for clean Arrow storage
    for col in [:iso_o, :iso_d]
        if hasproperty(df, col)
            df[!, col] = String.(df[!, col])
        end
    end

    verbose && println("    Selected: $(nrow(df)) rows × $(ncol(df)) cols")
    verbose && println("    Unique origin countries: $(length(unique(df.iso_o)))")
    verbose && println("    Unique destination countries: $(length(unique(df.iso_d)))")

    # Write Arrow
    Arrow.write(arrow_path, df; compress=:zstd)
    verbose && println("    → Wrote $(arrow_path)")
    verbose && println("=" ^ 72)

    return df
end


"""
Load CEPII GeoDist country-level file (.dta) and write to Arrow.

Arguments:
- dta_path::String: Path to geo_cepii.dta
- arrow_path::String: Output Arrow path
- verbose::Bool: Print diagnostics

Returns:
- DataFrame with country-level geographic metadata (lat, lon, area, landlocked, etc.)

Rules:
- Raw .dta is never modified
- All columns retained (small file, all potentially useful)

Usage:
    geo_countries = load_geo_countries("data/geo_cepii.dta", "data/cepii_geo_countries.arrow")
"""
function load_geo_countries(
    dta_path::String = PATH_GEO_COUNTRIES_DTA,
    arrow_path::String = PATH_GEO_COUNTRIES_ARROW;
    verbose::Bool = true
)
    verbose && println("=" ^ 72)
    verbose && println("GEO COUNTRIES: Loading $(dta_path)")

    tbl = readstat(dta_path)
    df = DataFrame(tbl)
    verbose && println("    Raw: $(nrow(df)) rows × $(ncol(df)) cols")

    # Standardize column names
    rename!(df, [Symbol(lowercase(string(c))) for c in names(df)])

    # Convert string columns for clean Arrow storage
    for col in names(df)
        if eltype(df[!, col]) <: Union{Missing, <:AbstractString}
            df[!, col] = [ismissing(v) ? missing : String(v) for v in df[!, col]]
        end
    end

    verbose && println("    Countries: $(nrow(df))")
    verbose && println("    Columns: $(names(df))")

    Arrow.write(arrow_path, df; compress=:zstd)
    verbose && println("    → Wrote $(arrow_path)")
    verbose && println("=" ^ 72)

    return df
end


# ==============================================================================
# STEP 2: LOAD AND CONVERT GRAVITY
# ==============================================================================

"""
Load CEPII Gravity bilateral panel from zip archive and write to Arrow.

Arguments:
- zip_path::String: Path to Gravity zip archive
- arrow_path::String: Output Arrow path
- verbose::Bool: Print diagnostics

Returns:
- DataFrame with annual bilateral trade flows, distances, and controls

Rules:
- Raw zip is never modified; output is a new Arrow file
- Only columns in GRAVITY_KEEP_COLS are retained (raw file has 80+ columns)
- Country-pair-years where neither trade flow variable has data are dropped
- The 1.25 GB CSV is read streaming from the zip — no intermediate extraction

Usage:
    gravity = load_gravity("data/Gravity_csv_V202211.zip", "data/cepii_gravity.arrow")
"""
function load_gravity(
    zip_path::String = PATH_GRAVITY_ZIP,
    arrow_path::String = PATH_GRAVITY_ARROW;
    verbose::Bool = true
)
    verbose && println("=" ^ 72)
    verbose && println("GRAVITY: Loading from $(zip_path)")
    verbose && println("    Reading CSV from zip (this may take a few minutes)...")

    # Read Gravity CSV from zip
    gravity_df = nothing
    countries_df = nothing

    r = ZipFile.Reader(zip_path)
    for f in r.files
        if occursin("Gravity_V", f.name) && endswith(f.name, ".csv")
            verbose && println("    Extracting: $(f.name)")
            gravity_df = CSV.read(f, DataFrame; missingstring=["", "NA"])
        elseif occursin("Countries_V", f.name) && endswith(f.name, ".csv")
            verbose && println("    Extracting: $(f.name)")
            countries_df = CSV.read(f, DataFrame; missingstring=["", "NA"])
        end
    end
    close(r)

    if isnothing(gravity_df)
        error("Could not find Gravity CSV in zip archive")
    end

    verbose && println("    Raw: $(nrow(gravity_df)) rows × $(ncol(gravity_df)) cols")

    # Standardize column names to lowercase symbols
    rename!(gravity_df, [Symbol(lowercase(string(c))) for c in names(gravity_df)])

    # Select columns
    available = [c for c in GRAVITY_KEEP_COLS if hasproperty(gravity_df, c)]
    missing_cols = setdiff(GRAVITY_KEEP_COLS, available)
    if !isempty(missing_cols) && verbose
        println("    ⚠️  Missing columns: $(missing_cols)")
    end
    gravity_df = select(gravity_df, available)

    # Convert ISO codes to String
    for col in [:iso3_o, :iso3_d]
        if hasproperty(gravity_df, col)
            gravity_df[!, col] = [ismissing(v) ? missing : String(v) for v in gravity_df[!, col]]
        end
    end

    verbose && println("    Selected: $(nrow(gravity_df)) rows × $(ncol(gravity_df)) cols")
    verbose && println("    Year range: $(minimum(gravity_df.year))–$(maximum(gravity_df.year))")
    verbose && println("    Unique origins: $(length(unique(skipmissing(gravity_df.iso3_o))))")
    verbose && println("    Unique destinations: $(length(unique(skipmissing(gravity_df.iso3_d))))")

    # Count non-missing trade flows
    has_trade = .!ismissing.(gravity_df.tradeflow_baci) .|
                .!ismissing.(gravity_df.tradeflow_comtrade_o) .|
                .!ismissing.(gravity_df.tradeflow_comtrade_d) .|
                .!ismissing.(gravity_df.tradeflow_imf_o) .|
                .!ismissing.(gravity_df.tradeflow_imf_d)
    verbose && println("    Rows with any trade data: $(sum(has_trade)) / $(nrow(gravity_df))")

    # Write Arrow
    Arrow.write(arrow_path, gravity_df; compress=:zstd)
    verbose && println("    → Wrote $(arrow_path)")

    # Also save countries lookup
    if !isnothing(countries_df)
        rename!(countries_df, [Symbol(lowercase(string(c))) for c in names(countries_df)])
        for col in names(countries_df)
            if eltype(countries_df[!, col]) <: Union{Missing, <:AbstractString}
                countries_df[!, col] = [ismissing(v) ? missing : String(v) for v in countries_df[!, col]]
            end
        end
        Arrow.write(PATH_GRAVITY_COUNTRIES_ARROW, countries_df; compress=:zstd)
        verbose && println("    → Wrote $(PATH_GRAVITY_COUNTRIES_ARROW) ($(nrow(countries_df)) countries)")
    end

    verbose && println("=" ^ 72)
    return gravity_df
end


# ==============================================================================
# STEP 3: VALIDATE COUNTRY CODE ALIGNMENT WITH QOG
# ==============================================================================

"""
Check alignment between CEPII ISO3 codes and QoG ccodealp identifiers.

Arguments:
- geodist_df::DataFrame: From load_geodist (needs :iso_o column)
- gravity_df::DataFrame: From load_gravity (needs :iso3_o column)
- qog_path::String: Path to QoG time-series Arrow file

Returns:
- NamedTuple with :matched, :cepii_only, :qog_only, :summary

Rules:
- Uses ccodealp from QoG as the reference identifier
- Reports mismatches but does not attempt automatic reconciliation
- Country code mismatches must be resolved manually before network construction

Usage:
    alignment = validate_country_alignment(geodist, gravity)
"""
function validate_country_alignment(
    geodist_df::DataFrame,
    gravity_df::DataFrame;
    qog_path::String = "data/qog_std_ts_jan25.arrow",
    verbose::Bool = true
)
    verbose && println("=" ^ 72)
    verbose && println("COUNTRY CODE ALIGNMENT")

    # QoG country codes
    qog = Arrow.Table(qog_path) |> DataFrame
    qog_codes = Set(unique(skipmissing(qog.ccodealp)))
    verbose && println("    QoG unique ccodealp: $(length(qog_codes))")

    # GeoDist country codes
    geodist_codes = Set(unique(vcat(geodist_df.iso_o, geodist_df.iso_d)))
    verbose && println("    GeoDist unique ISO3: $(length(geodist_codes))")

    # Gravity country codes
    gravity_codes = Set(unique(skipmissing(vcat(gravity_df.iso3_o, gravity_df.iso3_d))))
    verbose && println("    Gravity unique ISO3: $(length(gravity_codes))")

    # All CEPII codes
    cepii_codes = union(geodist_codes, gravity_codes)

    # Alignment
    matched = intersect(cepii_codes, qog_codes)
    cepii_only = setdiff(cepii_codes, qog_codes)
    qog_only = setdiff(qog_codes, cepii_codes)

    verbose && println("    ─────────────────────────────")
    verbose && println("    Matched:    $(length(matched))")
    verbose && println("    CEPII only: $(length(cepii_only))")
    verbose && println("    QoG only:   $(length(qog_only))")

    if !isempty(cepii_only) && verbose
        println("    CEPII-only codes: $(sort(collect(cepii_only)))")
    end
    if !isempty(qog_only) && verbose
        println("    QoG-only codes:   $(sort(collect(qog_only)))")
    end

    verbose && println("=" ^ 72)

    return (
        matched = matched,
        cepii_only = cepii_only,
        qog_only = qog_only,
        summary = DataFrame(
            source = ["QoG", "GeoDist", "Gravity", "All CEPII", "Matched", "CEPII only", "QoG only"],
            count = [length(qog_codes), length(geodist_codes), length(gravity_codes),
                     length(cepii_codes), length(matched), length(cepii_only), length(qog_only)]
        )
    )
end


# ==============================================================================
# CONVENIENCE: LOAD ALL NETWORK DATA
# ==============================================================================

"""
Load all network data from Arrow files (after initial conversion).

Arguments:
- None (uses default Arrow paths)

Returns:
- NamedTuple with :geodist, :geo_countries, :gravity, :gravity_countries

Rules:
- Requires Arrow files to exist (run load_geodist, load_geo_countries, load_gravity first)
- Returns DataFrames ready for graph construction

Usage:
    net = load_network_data()
    net.geodist   # bilateral distances
    net.gravity   # annual bilateral trade
"""
function load_network_data(; verbose::Bool = true)
    verbose && println("Loading network data from Arrow...")

    geodist = Arrow.Table(PATH_GEODIST_ARROW) |> DataFrame
    verbose && println("    geodist: $(nrow(geodist)) rows")

    geo_countries = Arrow.Table(PATH_GEO_COUNTRIES_ARROW) |> DataFrame
    verbose && println("    geo_countries: $(nrow(geo_countries)) rows")

    gravity = Arrow.Table(PATH_GRAVITY_ARROW) |> DataFrame
    verbose && println("    gravity: $(nrow(gravity)) rows")

    gravity_countries = Arrow.Table(PATH_GRAVITY_COUNTRIES_ARROW) |> DataFrame
    verbose && println("    gravity_countries: $(nrow(gravity_countries)) rows")

    return (
        geodist = geodist,
        geo_countries = geo_countries,
        gravity = gravity,
        gravity_countries = gravity_countries,
    )
end
