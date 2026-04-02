# ==============================================================================
# PHASE 0b — CEPII GEODIST PREPROCESSING
# ==============================================================================
#
# Loads and preprocesses CEPII GeoDist datasets into Arrow format.
# Derives ggis_shared_lineage edge from colonizer data.
#
# Data source:
#   - CEPII GeoDist (Mayer & Zignago 2011)
#     https://cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=6
#     Files: dist_cepii.dta (50,176 dyadic pairs), geo_cepii.dta (238 countries)
#
# Output:
#   - data/cepii_geodist.arrow       (bilateral distances + cultural ties + ggis_shared_lineage)
#   - data/cepii_geo_countries.arrow  (country-level geographic metadata)
#
# ==============================================================================

using DataFrames
using StatFiles
using Arrow


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to CEPII GeoDist dyadic file."""
const PATH_GEODIST_DTA = "data/dist_cepii.dta"

"""Path to CEPII GeoDist country-level file."""
const PATH_GEO_COUNTRIES_DTA = "data/geo_cepii.dta"

"""Arrow output: bilateral dyadic data."""
const PATH_GEODIST_ARROW = "data/cepii_geodist.arrow"

"""Arrow output: country-level geographic metadata."""
const PATH_GEO_COUNTRIES_ARROW = "data/cepii_geo_countries.arrow"

"""ISO3 remapping: legacy codes to current QoG-compatible codes."""
const GEODIST_ISO3_REMAP = Dict(
    "ROM" => "ROU",  # Romania
    "ZAR" => "COD",  # DR Congo
    "TMP" => "TLS",  # Timor-Leste
)


# ==============================================================================
# LOADING
# ==============================================================================

"""
Load CEPII GeoDist country-level metadata.

Returns
    DataFrame with 238 countries — coordinates, area, languages, colonial history.

Rules
    - Reads from PATH_GEO_COUNTRIES_DTA using StatFiles (not ReadStatTables)
    - Applies ISO3 remapping
    - Does not modify source file

Usage
    geo = geodist_load_countries()
"""
function geodist_load_countries()
    geo = DataFrame(load(PATH_GEO_COUNTRIES_DTA))

    # ISO3 remap
    geo[!, :iso3] = [ismissing(v) ? missing : get(GEODIST_ISO3_REMAP, String(v), String(v))
                     for v in geo.iso3]

    return geo
end


"""
Load CEPII GeoDist bilateral dyadic data and derive ggis_shared_lineage edge.

Arguments
    geo::DataFrame — output of geodist_load_countries() (needed for colonizer data)

Returns
    DataFrame with 50,176 dyadic pairs — distances, contiguity, language,
    colonial ties, and derived ggis_shared_lineage.

Rules
    - Reads from PATH_GEODIST_DTA using StatFiles
    - Applies ISO3 remapping to both iso_o and iso_d
    - Derives ggis_shared_lineage from geo_cepii colonizer1-4 fields
    - Does not modify source file

Usage
    geo = geodist_load_countries()
    dist = geodist_load_dyadic(geo)
"""
function geodist_load_dyadic(geo::DataFrame)
    dist = DataFrame(load(PATH_GEODIST_DTA))

    # ISO3 remap
    for col in [:iso_o, :iso_d]
        dist[!, col] = [ismissing(v) ? missing : get(GEODIST_ISO3_REMAP, String(v), String(v))
                        for v in dist[!, col]]
    end

    # Derive ggis_shared_lineage from colonizer data
    colonizer_cols = [:colonizer1, :colonizer2, :colonizer3, :colonizer4]

    country_colonizers = Dict{String, Set{String}}()
    for r in eachrow(geo)
        iso = ismissing(r.iso3) ? continue : String(r.iso3)
        s = Set{String}()
        for col in colonizer_cols
            v = r[col]
            if !ismissing(v) && String(v) != ""
                push!(s, String(v))
            end
        end
        country_colonizers[iso] = s
    end

    dist[!, :ggis_shared_lineage] = zeros(Int8, nrow(dist))
    for (i, r) in enumerate(eachrow(dist))
        o = ismissing(r.iso_o) ? "" : String(r.iso_o)
        d = ismissing(r.iso_d) ? "" : String(r.iso_d)
        if haskey(country_colonizers, o) && haskey(country_colonizers, d)
            if !isempty(intersect(country_colonizers[o], country_colonizers[d]))
                dist[i, :ggis_shared_lineage] = Int8(1)
            end
        end
    end

    return dist
end


# ==============================================================================
# ARROW EXPORT
# ==============================================================================

"""
Full pipeline: load GeoDist, derive edges, write Arrow.

Returns
    NamedTuple (geo::DataFrame, dist::DataFrame)

Rules
    - Writes to PATH_GEO_COUNTRIES_ARROW and PATH_GEODIST_ARROW
    - Does not modify source files

Usage
    result = geodist_process_all()
    result.geo   # country metadata
    result.dist  # dyadic pairs with ggis_shared_lineage
"""
function geodist_process_all()
    println("Loading GeoDist countries from $(PATH_GEO_COUNTRIES_DTA)...")
    geo = geodist_load_countries()
    println("  $(nrow(geo)) countries")

    println("Loading GeoDist dyadic from $(PATH_GEODIST_DTA)...")
    dist = geodist_load_dyadic(geo)
    println("  $(nrow(dist)) pairs")
    println("  ggis_shared_lineage pairs: $(count(==(1), dist.ggis_shared_lineage))")

    # String conversion for Arrow
    for df in [geo, dist]
        for col in names(df)
            if nonmissingtype(eltype(df[!, col])) <: AbstractString
                df[!, col] = passmissing(String).(df[!, col])
            end
        end
    end

    println("Writing Arrow...")
    Arrow.write(PATH_GEO_COUNTRIES_ARROW, geo)
    println("  → $(PATH_GEO_COUNTRIES_ARROW)")
    Arrow.write(PATH_GEODIST_ARROW, dist)
    println("  → $(PATH_GEODIST_ARROW)")

    return (geo=geo, dist=dist)
end
