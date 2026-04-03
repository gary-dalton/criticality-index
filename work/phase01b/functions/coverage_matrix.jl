# ==============================================================================
# PHASE 1b — COVERAGE MATRIX (Country × Year × Dataset)
# ==============================================================================
#
# Builds a country-year panel showing which datasets have data for each
# country in each year. Enables missingness-aware analysis — before joining
# any dataset, check coverage first.
#
# Output:
#   - data/ggis_coverage_matrix.arrow
#
# ==============================================================================

using DataFrames
using Arrow
using Statistics


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to output coverage matrix."""
const PATH_COVERAGE_MATRIX_ARROW = "data/ggis_coverage_matrix.arrow"


# ==============================================================================
# BUILDING
# ==============================================================================

"""
Build country × year × dataset coverage matrix.

Returns
    DataFrame with one row per country-year, boolean flags per dataset,
    plus summary statistics.

Rules
    - Country-year grid spans each country's QoG existence (qog_first_year to qog_last_year)
    - Boolean flags: has data in that specific year, not just "country exists in dataset"
    - EM-DAT: country-year has at least one event
    - DOSE: country has subnational GDP for that year
    - SHDI: country has subnational HDI for that year
    - Gravity: country appears as origin in trade data for that year
    - L&V: country was in active banking crisis that year
    - GeoDist: static (no year dimension) — flag from master reference

Usage
    matrix = build_coverage_matrix()
"""
function build_coverage_matrix()
    # Load master for the country-year grid
    master = DataFrame(Arrow.Table(PATH_COUNTRY_MASTER_ARROW))

    # Build country-year grid from QoG existence spans
    rows = NamedTuple[]
    for r in eachrow(master)
        for yr in r.qog_first_year:r.qog_last_year
            push!(rows, (
                ident_ccodealp = r.ident_ccodealp,
                year = yr
            ))
        end
    end
    grid = DataFrame(rows)
    println("  Country-year grid: $(nrow(grid)) rows ($(length(unique(grid.ident_ccodealp))) countries)")

    # --- EM-DAT: country-year has at least one event ---
    if isfile("data/emdat_country_year.arrow")
        emdat = DataFrame(Arrow.Table("data/emdat_country_year.arrow"))
        emdat_set = Set(zip(emdat.iso3, emdat.year))
        grid[!, :has_emdat_yr] = [((r.ident_ccodealp, r.year) in emdat_set) for r in eachrow(grid)]
    else
        grid[!, :has_emdat_yr] = fill(false, nrow(grid))
    end

    # --- DOSE: subnational GDP exists for that year ---
    if isfile("data/dose_subnational.arrow")
        dose = DataFrame(Arrow.Table("data/dose_subnational.arrow"))
        dose_set = Set(zip(dose.iso3, dose.year))
        grid[!, :has_dose_yr] = [((r.ident_ccodealp, r.year) in dose_set) for r in eachrow(grid)]
    else
        grid[!, :has_dose_yr] = fill(false, nrow(grid))
    end

    # --- SHDI: subnational HDI exists for that year ---
    if isfile("data/shdi_v10.arrow")
        shdi = DataFrame(Arrow.Table("data/shdi_v10.arrow"))
        shdi_sub = filter(r -> r.level == "Subnat", shdi)
        shdi_set = Set(zip(shdi_sub.isocode3, shdi_sub.year))
        grid[!, :has_shdi_yr] = [((r.ident_ccodealp, r.year) in shdi_set) for r in eachrow(grid)]
    else
        grid[!, :has_shdi_yr] = fill(false, nrow(grid))
    end

    # --- Gravity: country appears as origin in trade data for that year ---
    if isfile("data/cepii_gravity.arrow")
        gravity = DataFrame(Arrow.Table("data/cepii_gravity.arrow"))
        # Only count years with actual trade flow data (not just pair existence)
        grav_with_trade = filter(r -> !ismissing(r.tradeflow_baci) || !ismissing(r.tradeflow_imf_o), gravity)
        grav_set = Set(zip(skipmissing(grav_with_trade.iso3_o), grav_with_trade.year))
        grid[!, :has_gravity_yr] = [((r.ident_ccodealp, r.year) in grav_set) for r in eachrow(grid)]
    else
        grid[!, :has_gravity_yr] = fill(false, nrow(grid))
    end

    # --- L&V: country in active banking crisis that year ---
    if isfile("data/lv_crisis_panel.arrow")
        lv = DataFrame(Arrow.Table("data/lv_crisis_panel.arrow"))
        lv_set = Set(zip(skipmissing(lv.iso3), lv.year))
        grid[!, :has_lv_yr] = [((r.ident_ccodealp, r.year) in lv_set) for r in eachrow(grid)]
    else
        grid[!, :has_lv_yr] = fill(false, nrow(grid))
    end

    # --- GeoDist: static, copy from master ---
    geodist_countries = Set(master[master.has_geodist, :ident_ccodealp])
    grid[!, :has_geodist] = [r.ident_ccodealp in geodist_countries for r in eachrow(grid)]

    # --- QoG: always true by construction (grid is built from QoG years) ---
    grid[!, :has_qog] = fill(true, nrow(grid))

    # --- Count datasets available per country-year ---
    grid[!, :n_datasets] = grid.has_qog .+ grid.has_emdat_yr .+ grid.has_dose_yr .+
                           grid.has_shdi_yr .+ grid.has_gravity_yr .+ grid.has_lv_yr .+ grid.has_geodist

    sort!(grid, [:ident_ccodealp, :year])
    return grid
end


"""
Compute per-country coverage summary from the coverage matrix.

Arguments
    matrix::DataFrame — output of build_coverage_matrix()

Returns
    DataFrame with one row per country, showing coverage percentages
    per dataset across different temporal windows.

Usage
    matrix = build_coverage_matrix()
    summary = coverage_summary(matrix)
"""
function coverage_summary(matrix::DataFrame)
    # Temporal windows
    windows = [
        ("all",      TEMPORAL_FLOOR, 2030),
        ("deep",     1970, 2030),
        ("standard", 1990, 2030),
        ("recent",   2005, 2030),
    ]

    results = DataFrame[]

    for (wname, wstart, wend) in windows
        w = filter(r -> r.year >= wstart && r.year <= wend, matrix)
        nrow(w) == 0 && continue

        summary = combine(groupby(w, :ident_ccodealp),
            nrow => Symbol("$(wname)_n_years"),
            :has_emdat_yr => mean => Symbol("$(wname)_pct_emdat"),
            :has_dose_yr => mean => Symbol("$(wname)_pct_dose"),
            :has_shdi_yr => mean => Symbol("$(wname)_pct_shdi"),
            :has_gravity_yr => mean => Symbol("$(wname)_pct_gravity"),
            :has_lv_yr => mean => Symbol("$(wname)_pct_lv"),
            :n_datasets => mean => Symbol("$(wname)_avg_datasets"),
        )

        if isempty(results)
            push!(results, summary)
        else
            results[1] = leftjoin(results[1], summary, on=:ident_ccodealp)
        end
    end

    return results[1]
end


"""
Compute population-weighted dataset penetration.

Arguments
    master::DataFrame — from ggis_country_master.arrow (needs coverage flags)

Returns
    DataFrame with one row per dataset showing country count and
    population-weighted coverage.

Rules
    - Uses QoG's wdi_pop for population weighting (most recent available year)
    - Falls back to unweighted count if population data unavailable

Usage
    penetration = dataset_penetration(master)
"""
function dataset_penetration(master::DataFrame)
    # Load QoG for population
    qog = DataFrame(Arrow.Table("data/qog_std_ts_jan25_aug.arrow"))

    # Get most recent population per country
    pop_col = :wdi_pop
    if hasproperty(qog, pop_col)
        qog_pop = combine(
            groupby(dropmissing(qog, [pop_col, :ident_ccodealp]), :ident_ccodealp),
            pop_col => last => :population
        )
        master_pop = leftjoin(master, qog_pop, on=:ident_ccodealp)
    else
        master_pop = copy(master)
        master_pop[!, :population] .= missing
    end

    total_pop = sum(skipmissing(master_pop.population))

    results = DataFrame(
        dataset = String[],
        n_countries = Int[],
        pct_countries = Float64[],
        pop_covered = Float64[],
        pct_pop = Float64[]
    )

    for (col, name) in [
        (:has_emdat, "EM-DAT"),
        (:has_dose, "DOSE"),
        (:has_shdi, "SHDI"),
        (:has_geodist, "GeoDist"),
        (:has_gravity, "Gravity"),
        (:has_lv, "L&V"),
    ]
        covered = filter(r -> r[col], master_pop)
        n = nrow(covered)
        pop = sum(skipmissing(covered.population))
        push!(results, (
            dataset = name,
            n_countries = n,
            pct_countries = round(100 * n / nrow(master), digits=1),
            pop_covered = pop,
            pct_pop = round(100 * pop / total_pop, digits=1)
        ))
    end

    return results
end


# ==============================================================================
# ARROW EXPORT
# ==============================================================================

"""
Full pipeline: build coverage matrix, write Arrow.

Returns
    DataFrame (the coverage matrix)

Usage
    matrix = build_and_write_coverage_matrix()
"""
function build_and_write_coverage_matrix()
    println("Building coverage matrix...")
    matrix = build_coverage_matrix()
    println("  $(nrow(matrix)) country-year rows × $(ncol(matrix)) cols")

    # String conversion for Arrow
    for col in names(matrix)
        if nonmissingtype(eltype(matrix[!, col])) <: AbstractString
            matrix[!, col] = passmissing(String).(matrix[!, col])
        end
    end

    println("Writing Arrow...")
    Arrow.write(PATH_COVERAGE_MATRIX_ARROW, matrix)
    println("  → $(PATH_COVERAGE_MATRIX_ARROW)  ($(round(filesize(PATH_COVERAGE_MATRIX_ARROW) / 1024^2, digits=1)) MB)")

    return matrix
end
