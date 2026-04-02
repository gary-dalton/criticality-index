# ==============================================================================
# PHASE 0b — CEPII GRAVITY PREPROCESSING
# ==============================================================================
#
# Loads and preprocesses CEPII Gravity bilateral trade panel into Arrow format.
# Provides annual trade flow edges for the economic network layer (ρ).
#
# Data source:
#   - CEPII Gravity V202211 (Conte, Cotterlaz & Mayer 2022)
#     https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=8
#     File: Gravity_csv_V202211.zip (~1.2 GB CSV, 87 columns, 1948-2020)
#
# Output:
#   - data/cepii_gravity.arrow           (annual bilateral panel, selected columns)
#   - data/cepii_gravity_countries.arrow  (country lookup with existence dates)
#
# ==============================================================================

using DataFrames
using CSV
using Arrow
using ZipFile


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to CEPII Gravity zip archive."""
const PATH_GRAVITY_ZIP = "data/Gravity_csv_V202211.zip"

"""Arrow output: bilateral trade panel."""
const PATH_GRAVITY_ARROW = "data/cepii_gravity.arrow"

"""Arrow output: country lookup."""
const PATH_GRAVITY_COUNTRIES_ARROW = "data/cepii_gravity_countries.arrow"

"""ISO3 remapping (same as GeoDist)."""
const GRAVITY_ISO3_REMAP = Dict(
    "ROM" => "ROU",  # Romania
    "ZAR" => "COD",  # DR Congo
    "TMP" => "TLS",  # Timor-Leste
)

"""Columns to retain from the 87-column Gravity CSV.

Trade flow decisions:
- tradeflow_baci: PRIMARY (reconciled COMTRADE, from ~2000)
- tradeflow_imf_d: FALLBACK (best historical coverage, pre-2000)
- tradeflow_comtrade_o/d: DROPPED (redundant with BACI post-2000, worse than IMF pre-2000)
- manuf_tradeflow_baci: DROPPED (identical coverage to BACI, narrow subset)

Supplementary edges:
- comrelig: KEPT (cultural coupling, 36% missing post-1990)
- diplo_disagreement: KEPT (diplomatic distance, 48% missing post-1990)
- scaled_sci_2021: DROPPED (single-year Facebook snapshot, 50% missing)
"""
const GRAVITY_KEEP_COLS = [
    # Identifiers
    :year, :iso3_o, :iso3_d, :country_id_o, :country_id_d,
    :country_exists_o, :country_exists_d,
    # Distance
    :distw_harmonic, :contig,
    # Trade flows — primary + fallback only
    :tradeflow_baci, :tradeflow_imf_o, :tradeflow_imf_d,
    # Economic size
    :gdp_o, :gdp_d, :pop_o, :pop_d,
    # Institutional/trade agreements
    :gatt_o, :gatt_d, :wto_o, :wto_d,
    :eu_o, :eu_d, :fta_wto,
    # Cultural/colonial (supplements GeoDist)
    :comrelig, :col_dep_ever, :sibling_ever, :empire,
    :diplo_disagreement
]


# ==============================================================================
# LOADING
# ==============================================================================

"""
Load CEPII Gravity bilateral panel from zip, apply remapping and temporal floor.

Returns
    DataFrame with annual bilateral trade flows and controls.

Rules
    - Reads selected columns only (GRAVITY_KEEP_COLS) from the 1.2 GB CSV
    - Applies GRAVITY_ISO3_REMAP to iso3_o and iso3_d
    - Applies TEMPORAL_FLOOR (from constants.jl)
    - Does not modify source file

Usage
    grav = gravity_load()
"""
function gravity_load()
    zf = ZipFile.Reader(PATH_GRAVITY_ZIP)
    gravity_entry = first(filter(f -> endswith(f.name, "Gravity_V202211.csv"), zf.files))
    raw = CSV.read(gravity_entry, DataFrame; select=GRAVITY_KEEP_COLS)
    close(zf)

    # ISO3 remap
    for col in [:iso3_o, :iso3_d]
        raw[!, col] = [ismissing(v) ? missing : get(GRAVITY_ISO3_REMAP, String(v), String(v))
                       for v in raw[!, col]]
    end

    # Temporal floor
    filter!(r -> r.year >= TEMPORAL_FLOOR, raw)

    return raw
end


"""
Load Gravity countries lookup from zip, apply remapping.

Returns
    DataFrame with 252 countries — existence dates, country groups, hegemonic spheres.

Rules
    - last_year = missing means country still exists
    - Applies GRAVITY_ISO3_REMAP

Usage
    countries = gravity_load_countries()
"""
function gravity_load_countries()
    zf = ZipFile.Reader(PATH_GRAVITY_ZIP)
    countries_entry = first(filter(f -> endswith(f.name, "Countries_V202211.csv"), zf.files))
    df = CSV.read(countries_entry, DataFrame)
    close(zf)

    # ISO3 remap
    df[!, :iso3] = [ismissing(v) ? missing : get(GRAVITY_ISO3_REMAP, String(v), String(v))
                    for v in df.iso3]

    return df
end


# ==============================================================================
# ARROW EXPORT
# ==============================================================================

"""
Full pipeline: load Gravity + countries, write Arrow.

Returns
    NamedTuple (gravity::DataFrame, countries::DataFrame)

Rules
    - Writes to PATH_GRAVITY_ARROW and PATH_GRAVITY_COUNTRIES_ARROW
    - Does not modify source files

Usage
    result = gravity_process_all()
    result.gravity    # bilateral panel
    result.countries  # country lookup
"""
function gravity_process_all()
    println("Loading Gravity from $(PATH_GRAVITY_ZIP) (this may take a few minutes)...")
    grav = gravity_load()
    println("  $(nrow(grav)) rows × $(ncol(grav)) cols")
    println("  Years: $(minimum(grav.year)) – $(maximum(grav.year))")

    println("Loading countries lookup...")
    countries = gravity_load_countries()
    println("  $(nrow(countries)) countries")

    # String conversion for Arrow
    for df in [grav, countries]
        for col in names(df)
            if nonmissingtype(eltype(df[!, col])) <: AbstractString
                df[!, col] = passmissing(String).(df[!, col])
            end
        end
    end

    println("Writing Arrow...")
    Arrow.write(PATH_GRAVITY_ARROW, grav)
    println("  → $(PATH_GRAVITY_ARROW)  ($(round(filesize(PATH_GRAVITY_ARROW) / 1024^2, digits=1)) MB)")
    Arrow.write(PATH_GRAVITY_COUNTRIES_ARROW, countries)
    println("  → $(PATH_GRAVITY_COUNTRIES_ARROW)  ($(round(filesize(PATH_GRAVITY_COUNTRIES_ARROW) / 1024, digits=1)) KB)")

    return (gravity=grav, countries=countries)
end
