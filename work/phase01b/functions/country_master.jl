# ==============================================================================
# PHASE 1b — MASTER COUNTRY REFERENCE
# ==============================================================================
#
# Builds a single authoritative country reference that all datasets join to.
# Combines QoG spine, geographic lookup, Phase 1 status, and coverage flags
# for all Phase 0b external datasets.
#
# Output:
#   - data/ggis_country_master.arrow
#
# ==============================================================================

using DataFrames
using CSV
using Arrow
using Statistics
using StatsBase  # for countmap


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to output master country reference."""
const PATH_COUNTRY_MASTER_ARROW = "data/ggis_country_master.arrow"


# ==============================================================================
# BUILDING
# ==============================================================================

"""
Build the master country reference from all available data sources.

Returns
    DataFrame with one row per QoG country (202 rows), containing
    geographic classification, Phase 1 status, existence dates per source,
    and boolean coverage flags for each external dataset.

Rules
    - QoG ident_ccodealp is the authoritative key
    - All joins are left joins from QoG spine (no countries added from external sources)
    - Phase 1 status extracted from row-level missingness flags via modal aggregation
    - Coverage flags indicate whether a country appears in each external dataset

Usage
    master = build_country_master()
"""
function build_country_master()
    # --- Step 1: QoG spine ---
    qog = DataFrame(Arrow.Table("data/qog_std_ts_jan25_aug.arrow"))
    master = combine(groupby(dropmissing(qog, :ident_ccodealp), :ident_ccodealp),
        :ident_cname => first => :ident_cname,
        :ident_ccode => first => :ident_ccode,
        :ident_year => minimum => :qog_first_year,
        :ident_year => maximum => :qog_last_year,
        :ident_year => length => :qog_n_years
    )

    # --- Step 2: Geographic lookup ---
    if isfile("data/ggis_geographic_lookup.csv")
        geo = CSV.read("data/ggis_geographic_lookup.csv", DataFrame)
        geo_cols = select(geo,
            :ident_ccodealp,
            :un_region_name => :un_region,
            :un_subregion_name => :un_subregion,
            :continent
        )
        master = leftjoin(master, geo_cols, on=:ident_ccodealp)
    end

    # --- Step 3: Phase 1 status ---
    if isfile("data/country_missingness_flags.csv")
        miss_flags = CSV.read("data/country_missingness_flags.csv", DataFrame)
        qog_with_status = hcat(
            select(qog, :ident_ccodealp, :ident_year),
            select(miss_flags, :ggis_country_status, :ggis_global_slug_coverage)
        )
        country_status = combine(
            groupby(dropmissing(qog_with_status, :ident_ccodealp), :ident_ccodealp),
            :ggis_country_status => (x -> argmax(countmap(x))) => :phase1_modal_status,
            :ggis_country_status => last => :phase1_latest_status,
            :ggis_global_slug_coverage => mean => :mean_slug_coverage,
            :ggis_country_status => (x -> length(unique(x))) => :n_distinct_statuses
        )
        master = leftjoin(master, country_status, on=:ident_ccodealp)
    end

    # --- Step 4: Coverage flags ---
    flag_sources = [
        ("data/emdat_country_year.arrow",   :iso3,      :has_emdat),
        ("data/dose_subnational.arrow",     :iso3,      :has_dose),
        ("data/shdi_v10.arrow",             :isocode3,  :has_shdi),
        ("data/cepii_geodist.arrow",        :iso_o,     :has_geodist),
        ("data/cepii_gravity.arrow",        :iso3_o,    :has_gravity),
        ("data/lv_crisis_panel.arrow",      :iso3,      :has_lv),
    ]

    for (path, col, flag) in flag_sources
        if isfile(path)
            df = DataFrame(Arrow.Table(path))
            codes = Set(unique(skipmissing(df[!, col])))
            master[!, flag] = [c in codes for c in master.ident_ccodealp]
        else
            master[!, flag] = fill(false, nrow(master))
        end
    end

    # --- Step 5: Existence dates per external dataset ---
    year_sources = [
        ("data/emdat_country_year.arrow",   :iso3,     :year, "emdat"),
        ("data/dose_subnational.arrow",     :iso3,     :year, "dose"),
        ("data/shdi_v10.arrow",             :isocode3, :year, "shdi"),
        ("data/cepii_gravity.arrow",        :iso3_o,   :year, "gravity"),
    ]

    for (path, iso_col, year_col, prefix) in year_sources
        if isfile(path)
            df = DataFrame(Arrow.Table(path))
            valid = dropmissing(df, [iso_col, year_col])
            yr = combine(groupby(valid, iso_col),
                year_col => minimum => Symbol("$(prefix)_first_year"),
                year_col => maximum => Symbol("$(prefix)_last_year")
            )
            rename!(yr, iso_col => :ident_ccodealp)
            master = leftjoin(master, yr, on=:ident_ccodealp)
        end
    end

    sort!(master, :ident_ccodealp)
    return master
end


"""
Write master country reference to Arrow.

Arguments
    master::DataFrame — output of build_country_master()

Usage
    master = build_country_master()
    write_country_master(master)
"""
function write_country_master(master::DataFrame)
    # String conversion for Arrow
    for col in names(master)
        if nonmissingtype(eltype(master[!, col])) <: AbstractString
            master[!, col] = passmissing(String).(master[!, col])
        end
    end

    Arrow.write(PATH_COUNTRY_MASTER_ARROW, master)
    println("  → $(PATH_COUNTRY_MASTER_ARROW)  ($(round(filesize(PATH_COUNTRY_MASTER_ARROW) / 1024, digits=1)) KB)")
end
