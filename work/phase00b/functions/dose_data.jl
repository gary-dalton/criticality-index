# ==============================================================================
# PHASE 0b — DOSE SUBNATIONAL GDP PREPROCESSING
# ==============================================================================
#
# Loads and preprocesses the DOSE (Database of Subnational Economic output)
# into Arrow format. Provides subnational GDP data for testing Signatures 3
# (scale invariance) and 4 (fractal structure).
#
# Data source:
#   - DOSE V2.11 (Wenz et al.)
#     https://zenodo.org/records/16313760
#     File: DOSE_V2.11.csv (46,851 rows, 83 countries, 1,661 regions, 1953-2020)
#
# Output:
#   - data/dose_subnational.arrow   (region-level panel)
#   - data/dose_national.arrow      (aggregated to country-year for QoG join)
#
# ==============================================================================

using DataFrames
using CSV
using Arrow


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to DOSE CSV file."""
const PATH_DOSE_CSV = "data/DOSE_V2.11.csv"

"""Path to output Arrow file (subnational)."""
const PATH_DOSE_SUBNATIONAL_ARROW = "data/dose_subnational.arrow"

"""Path to output Arrow file (national aggregate)."""
const PATH_DOSE_NATIONAL_ARROW = "data/dose_national.arrow"


# ==============================================================================
# LOADING
# ==============================================================================

"""
Load DOSE subnational GDP data, selecting columns relevant to the model.

Returns
    DataFrame with subnational GDP panel, one row per region-year.

Rules
    - Reads from PATH_DOSE_CSV
    - Selects key columns: identifiers, GDP per capita (constant 2015 USD),
      sectoral breakdown, population, climate
    - GID_0 (ISO3) is the join key to QoG
    - GID_1 is the GADM subnational region identifier

Usage
    df = dose_load_subnational()
"""
function dose_load_subnational()
    raw = CSV.read(PATH_DOSE_CSV, DataFrame)

    select!(raw,
        :GID_0              => :iso3,
        :GID_1              => :gid_1,
        :country            => :country,
        :region             => :region,
        :year               => :year,
        :pop                => :pop,
        :grp_pc_usd_2015    => :gdp_pc_usd2015,
        :ag_grp_pc_usd_2015 => :gdp_pc_ag_usd2015,
        :man_grp_pc_usd_2015 => :gdp_pc_man_usd2015,
        :serv_grp_pc_usd_2015 => :gdp_pc_serv_usd2015,
        :T_a                => :temp_annual,
        :P_a                => :precip_annual
    )

    # Apply project-wide temporal floor
    filter!(r -> r.year >= TEMPORAL_FLOOR, raw)

    return raw
end


"""
Aggregate DOSE to country-year level for national comparisons and QoG joins.

Arguments
    subnational::DataFrame — output of dose_load_subnational()

Returns
    DataFrame with one row per country-year. GDP per capita is population-weighted.

Rules
    - Groups by iso3 + year
    - Population-weighted mean for GDP per capita
    - Sum for total population
    - Count of regions per country-year (for coverage assessment)
    - Climate averaged (unweighted) across regions

Usage
    sub = dose_load_subnational()
    nat = dose_aggregate_national(sub)
"""
function dose_aggregate_national(subnational::DataFrame)
    # Need non-missing pop and gdp for weighted mean
    valid = dropmissing(subnational, [:pop, :gdp_pc_usd2015])

    gdf = groupby(valid, [:iso3, :country, :year])

    agg = combine(gdf,
        :pop => sum => :total_pop,
        nrow => :n_regions,
        [:gdp_pc_usd2015, :pop] => ((g, p) -> sum(g .* p) / sum(p)) => :gdp_pc_usd2015_wtd,
        [:gdp_pc_ag_usd2015, :pop] => ((g, p) -> begin
            mask = .!ismissing.(g)
            any(mask) ? sum(g[mask] .* p[mask]) / sum(p[mask]) : missing
        end) => :gdp_pc_ag_usd2015_wtd,
        [:gdp_pc_man_usd2015, :pop] => ((g, p) -> begin
            mask = .!ismissing.(g)
            any(mask) ? sum(g[mask] .* p[mask]) / sum(p[mask]) : missing
        end) => :gdp_pc_man_usd2015_wtd,
        [:gdp_pc_serv_usd2015, :pop] => ((g, p) -> begin
            mask = .!ismissing.(g)
            any(mask) ? sum(g[mask] .* p[mask]) / sum(p[mask]) : missing
        end) => :gdp_pc_serv_usd2015_wtd,
        :temp_annual => (x -> all(ismissing, x) ? missing : mean(skipmissing(x))) => :temp_annual_mean,
        :precip_annual => (x -> all(ismissing, x) ? missing : mean(skipmissing(x))) => :precip_annual_mean
    )

    sort!(agg, [:iso3, :year])
    return agg
end


# ==============================================================================
# ARROW EXPORT
# ==============================================================================

"""
Full pipeline: load DOSE, aggregate, write both Arrow files.

Returns
    NamedTuple (subnational::DataFrame, national::DataFrame)

Rules
    - Writes to PATH_DOSE_SUBNATIONAL_ARROW and PATH_DOSE_NATIONAL_ARROW
    - Does not modify source file

Usage
    result = dose_process_all()
    result.subnational  # region-level
    result.national     # country-level
"""
function dose_process_all()
    println("Loading DOSE from $(PATH_DOSE_CSV)...")
    sub = dose_load_subnational()
    println("  $(nrow(sub)) region-year rows")
    println("  Years: $(minimum(sub.year)) - $(maximum(sub.year))")
    println("  Countries: $(length(unique(sub.iso3)))")
    println("  Regions: $(length(unique(sub.gid_1)))")

    println("Aggregating to country-year...")
    nat = dose_aggregate_national(sub)
    println("  $(nrow(nat)) country-year rows")

    println("Writing Arrow files...")
    Arrow.write(PATH_DOSE_SUBNATIONAL_ARROW, sub)
    println("  → $(PATH_DOSE_SUBNATIONAL_ARROW)")
    Arrow.write(PATH_DOSE_NATIONAL_ARROW, nat)
    println("  → $(PATH_DOSE_NATIONAL_ARROW)")

    return (subnational=sub, national=nat)
end
