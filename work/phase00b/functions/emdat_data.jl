# ==============================================================================
# PHASE 0b — EM-DAT DISASTER DATA PREPROCESSING
# ==============================================================================
#
# Loads and preprocesses the EM-DAT international disaster database into Arrow
# format. These provide exogenous shock events for the Excitation (E) component
# and backtesting of governance system response to perturbations.
#
# Data source:
#   - EM-DAT: The International Disaster Database
#     https://www.emdat.be/
#     File: public_emdat_incl_hist_2026-03-26.xlsx (27,536 events, 1900-2026)
#
# Output:
#   - data/emdat_events.arrow     (event-level disaster records)
#   - data/emdat_country_year.arrow (aggregated country-year summaries)
#
# ==============================================================================

using DataFrames
using XLSX
using Arrow


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to EM-DAT Excel file (includes historical pre-2000 events)."""
const PATH_EMDAT_XLSX = "data/public_emdat_incl_hist_2026-03-26.xlsx"

"""Path to output Arrow file (event-level)."""
const PATH_EMDAT_EVENTS_ARROW = "data/emdat_events.arrow"

"""Path to output Arrow file (country-year aggregated)."""
const PATH_EMDAT_COUNTRY_YEAR_ARROW = "data/emdat_country_year.arrow"


# ==============================================================================
# LOADING
# ==============================================================================

"""
Load EM-DAT disaster data from Excel, selecting columns relevant to the model.

Returns
    DataFrame with disaster events, one row per event.

Rules
    - Reads from PATH_EMDAT_XLSX, sheet "EM-DAT Data"
    - Selects and renames columns to snake_case
    - Converts numeric columns from Any to proper types
    - Historic flag preserved for reporting-bias awareness

Usage
    df = emdat_load_events()
"""
function emdat_load_events()
    raw = DataFrame(XLSX.readtable(PATH_EMDAT_XLSX, "EM-DAT Data"))

    # Select and rename relevant columns
    # Dropped columns below 40% completeness: No. Injured (33%), No. Affected (42%),
    # No. Homeless (10%), Total Damage Adjusted (21%), Magnitude (19%), Magnitude Scale
    # Total Affected is kept as the aggregate (= Injured + Affected + Homeless)
    select!(raw,
        "DisNo."              => :dis_no,
        "Historic"            => :historic,
        "Disaster Group"      => :disaster_group,
        "Disaster Type"       => :disaster_type,
        "Disaster Subtype"    => :disaster_subtype,
        "ISO"                 => :iso3,
        "Country"             => :country,
        "Subregion"           => :subregion,
        "Region"              => :region,
        "Start Year"          => :start_year,
        "Start Month"         => :start_month,
        "End Year"            => :end_year,
        "Total Deaths"        => :total_deaths,
        "Total Affected"      => :total_affected,
        "Latitude"            => :latitude,
        "Longitude"           => :longitude
    )

    # Type conversions — XLSX reads mixed columns as Any
    for col in [:start_year, :start_month, :end_year,
                :total_deaths, :total_affected,
                :latitude, :longitude]
        raw[!, col] = passmissing(x -> x isa Number ? Float64(x) : tryparse(Float64, string(x))
                                 ).(raw[!, col])
    end

    # Mark historic flag as boolean
    raw[!, :is_historic] = coalesce.(raw.historic .== "Yes", false)
    select!(raw, Not(:historic))

    # Apply project-wide temporal floor
    filter!(r -> coalesce(r.start_year >= TEMPORAL_FLOOR, false), raw)

    return raw
end


"""
Aggregate EM-DAT events to country-year level for model integration.

Arguments
    events::DataFrame — output of emdat_load_events()

Returns
    DataFrame with one row per country-year, containing event counts and
    aggregate impact measures.

Rules
    - Groups by iso3 + start_year
    - Counts events by disaster_group (Natural, Technological)
    - Sums deaths and affected
    - NaN/missing impacts treated as missing (not zero)

Usage
    events = emdat_load_events()
    cy = emdat_aggregate_country_year(events)
"""
function emdat_aggregate_country_year(events::DataFrame)
    # Filter to events with a valid year
    valid = dropmissing(events, :start_year)
    valid[!, :year] = Int.(valid.start_year)

    gdf = groupby(valid, [:iso3, :country, :year])

    agg = combine(gdf,
        nrow => :n_events,
        :disaster_group => (x -> count(==("Natural"), x)) => :n_natural,
        :disaster_group => (x -> count(==("Technological"), x)) => :n_technological,
        :total_deaths => (x -> all(ismissing, x) ? missing : sum(skipmissing(x))) => :sum_deaths,
        :total_affected => (x -> all(ismissing, x) ? missing : sum(skipmissing(x))) => :sum_affected
    )

    sort!(agg, [:iso3, :year])
    return agg
end


# ==============================================================================
# ARROW EXPORT
# ==============================================================================

"""
Full pipeline: load EM-DAT, aggregate, write both Arrow files.

Returns
    NamedTuple (events::DataFrame, country_year::DataFrame)

Rules
    - Writes to PATH_EMDAT_EVENTS_ARROW and PATH_EMDAT_COUNTRY_YEAR_ARROW
    - Does not modify source file

Usage
    result = emdat_process_all()
    result.events       # event-level
    result.country_year # aggregated
"""
function emdat_process_all()
    println("Loading EM-DAT from $(PATH_EMDAT_XLSX)...")
    events = emdat_load_events()
    println("  $(nrow(events)) events loaded")
    println("  Years: $(minimum(skipmissing(events.start_year))) - $(maximum(skipmissing(events.start_year)))")
    println("  Countries: $(length(unique(events.iso3)))")

    println("Aggregating to country-year...")
    cy = emdat_aggregate_country_year(events)
    println("  $(nrow(cy)) country-year rows")

    println("Writing Arrow files...")
    Arrow.write(PATH_EMDAT_EVENTS_ARROW, events)
    println("  → $(PATH_EMDAT_EVENTS_ARROW)")
    Arrow.write(PATH_EMDAT_COUNTRY_YEAR_ARROW, cy)
    println("  → $(PATH_EMDAT_COUNTRY_YEAR_ARROW)")

    return (events=events, country_year=cy)
end
