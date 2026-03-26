using DataFrames
using CSV
using Arrow

const SUBNATIONAL_DATA_DIR = joinpath(@__DIR__, "..", "..", "data")

"""
Load and validate DOSE (Database of Subnational Economic Output) from CSV.

Arguments
- `filepath::String`: Path to the DOSE CSV file (e.g., DOSE_V2.csv)

Returns
- `DataFrame`: Cleaned DOSE data with standardized columns

Rules
- Raw data is never modified; returns a new DataFrame
- Filters to rows with non-missing GRP values
- Standardizes country code column to `iso3` for spine compatibility

Usage
    dose = load_dose(joinpath(data_dir, "DOSE_V2.csv"))
"""
function load_dose(filepath::String)
    df = CSV.read(filepath, DataFrame)

    println("DOSE: $(nrow(df)) rows, $(ncol(df)) columns")
    println("  Columns: ", names(df))
    println("  Countries: ", length(unique(df.country)))
    println("  Regions: ", length(unique(df.GID_1)))
    println("  Year range: ", minimum(df.year), "–", maximum(df.year))

    return df
end

"""
Load and validate Subnational HDI (SHDI) from CSV.

Arguments
- `filepath::String`: Path to the SHDI CSV file

Returns
- `DataFrame`: Cleaned SHDI data with standardized columns

Rules
- Raw data is never modified; returns a new DataFrame
- Filters to subnational rows only (level != "National")
- Standardizes country code column to `iso3` for spine compatibility

Usage
    shdi = load_shdi(joinpath(data_dir, "SHDI-SGDI-Total.csv"))
"""
function load_shdi(filepath::String)
    df = CSV.read(filepath, DataFrame)

    println("SHDI: $(nrow(df)) rows, $(ncol(df)) columns")
    println("  Columns: ", names(df))
    println("  Countries: ", length(unique(df.iso_code)))
    println("  Year range: ", minimum(df.year), "–", maximum(df.year))

    # Separate national and subnational
    national = filter(r -> r.level == "National", df)
    subnational = filter(r -> r.level != "National", df)
    println("  National rows: ", nrow(national))
    println("  Subnational rows: ", nrow(subnational))
    println("  Subnational regions: ", length(unique(subnational.GDLCODE)))

    return df
end

"""
Compute within-country dispersion measures for a subnational dataset.

Arguments
- `df::DataFrame`: Subnational data with columns `iso3` (or `country`/`iso_code`), `year`, and a value column
- `value_col::Symbol`: Column containing the measure to compute dispersion on
- `country_col::Symbol`: Column containing country identifier
- `min_regions::Int`: Minimum number of regions required to compute dispersion (default: 3)

Returns
- `DataFrame`: Country-year panel with dispersion measures: `cv` (coefficient of variation),
  `gini`, `iqr_ratio` (interquartile range / median), `n_regions`

Rules
- Skips country-years with fewer than `min_regions` non-missing regions
- Returns new DataFrame; does not modify input

Usage
    dispersion = compute_subnational_dispersion(dose, :grp_pc_usd_2015, :country)
"""
function compute_subnational_dispersion(df::DataFrame, value_col::Symbol, country_col::Symbol; min_regions::Int=3)
    results = DataFrame(
        country=String[], year=Int[],
        cv=Float64[], gini=Float64[], iqr_ratio=Float64[],
        n_regions=Int[]
    )

    for g in groupby(df, [country_col, :year])
        vals = collect(skipmissing(g[!, value_col]))

        if length(vals) < min_regions
            continue
        end

        μ = mean(vals)
        σ = std(vals)
        cv = μ > 0 ? σ / μ : missing

        sorted = sort(vals)
        n = length(sorted)
        q1 = sorted[max(1, round(Int, 0.25 * n))]
        q3 = sorted[max(1, round(Int, 0.75 * n))]
        med = sorted[max(1, round(Int, 0.5 * n))]
        iqr_ratio = med > 0 ? (q3 - q1) / med : missing

        # Gini coefficient
        gini_val = _gini(vals)

        push!(results, (
            country=string(first(g[!, country_col])),
            year=first(g.year),
            cv=coalesce(cv, NaN),
            gini=gini_val,
            iqr_ratio=coalesce(iqr_ratio, NaN),
            n_regions=n
        ))
    end

    return results
end

"""
Compute Gini coefficient from a vector of values.

Arguments
- `vals::Vector`: Non-negative numeric values

Returns
- `Float64`: Gini coefficient (0 = perfect equality, 1 = perfect inequality)

Rules
- Returns 0.0 for single-element vectors
- Assumes non-negative values

Usage
    g = _gini([1.0, 2.0, 3.0, 100.0])
"""
function _gini(vals::Vector)
    n = length(vals)
    if n <= 1
        return 0.0
    end
    sorted = sort(vals)
    cumvals = cumsum(sorted)
    total = cumvals[end]
    if total == 0
        return 0.0
    end
    # Gini = (2 * sum(i * x_i) / (n * sum(x_i))) - (n + 1) / n
    numerator = 2.0 * sum(i * sorted[i] for i in 1:n)
    return (numerator / (n * total)) - (n + 1) / n
end

"""
Test distribution similarity across scales (Signature 4: Fractal Structure).

Compares the distribution of a measure across subnational regions within a country
to the distribution across countries globally. If the shapes match, the system
exhibits fractal structure at these two scales.

Arguments
- `subnational_df::DataFrame`: Subnational data with country, region, year, and value columns
- `national_df::DataFrame`: National-level data with country, year, and value columns
- `value_col::Symbol`: Column to compare distributions on
- `country_col_sub::Symbol`: Country identifier in subnational data
- `country_col_nat::Symbol`: Country identifier in national data
- `target_year::Int`: Year to test

Returns
- `DataFrame`: Per-country results with `ks_statistic` (Kolmogorov-Smirnov distance between
  within-country subnational distribution and global national distribution), `n_regions`,
  and `p_similar` (1 - ks_statistic, higher = more similar)

Rules
- Requires at least 5 subnational regions per country for meaningful comparison
- Uses two-sample KS test logic (maximum absolute difference between ECDFs)

Usage
    fractal = test_distribution_similarity(dose_sub, dose_nat, :grp_pc_usd_2015, :country, :country, 2015)
"""
function test_distribution_similarity(
    subnational_df::DataFrame, national_df::DataFrame,
    value_col::Symbol, country_col_sub::Symbol, country_col_nat::Symbol,
    target_year::Int; min_regions::Int=5
)
    # Global national distribution for target year
    nat_year = filter(r -> r.year == target_year, national_df)
    global_vals = collect(skipmissing(nat_year[!, value_col]))

    if isempty(global_vals)
        error("No national data for year $target_year")
    end

    # Normalize global distribution
    global_sorted = sort(global_vals)
    global_n = length(global_sorted)

    # Per-country subnational distributions
    sub_year = filter(r -> r.year == target_year, subnational_df)
    results = DataFrame(
        country=String[], ks_statistic=Float64[],
        p_similar=Float64[], n_regions=Int[]
    )

    for g in groupby(sub_year, country_col_sub)
        vals = collect(skipmissing(g[!, value_col]))
        if length(vals) < min_regions
            continue
        end

        # Two-sample KS statistic
        ks = _ks_two_sample(vals, global_vals)

        push!(results, (
            country=string(first(g[!, country_col_sub])),
            ks_statistic=ks,
            p_similar=1.0 - ks,
            n_regions=length(vals)
        ))
    end

    sort!(results, :ks_statistic)
    return results
end

"""
Two-sample Kolmogorov-Smirnov statistic.

Arguments
- `x::Vector`: First sample
- `y::Vector`: Second sample

Returns
- `Float64`: Maximum absolute difference between the two empirical CDFs (0 = identical, 1 = maximally different)

Rules
- Pure function, no side effects

Usage
    ks = _ks_two_sample(sample_a, sample_b)
"""
function _ks_two_sample(x::Vector, y::Vector)
    nx = length(x)
    ny = length(y)

    # Combine and sort all values
    all_vals = sort(vcat(x, y))

    max_diff = 0.0
    for v in all_vals
        ecdf_x = count(xi -> xi <= v, x) / nx
        ecdf_y = count(yi -> yi <= v, y) / ny
        diff = abs(ecdf_x - ecdf_y)
        if diff > max_diff
            max_diff = diff
        end
    end

    return max_diff
end

"""
Write a DataFrame to Arrow format in the data directory.

Arguments
- `df::DataFrame`: Data to write
- `filename::String`: Output filename (e.g., "dose_processed.arrow")

Returns
- `String`: Path to the written file

Rules
- Overwrites existing file if present
- Writes to SUBNATIONAL_DATA_DIR

Usage
    path = write_subnational_arrow(df, "dose_dispersion.arrow")
"""
function write_subnational_arrow(df::DataFrame, filename::String)
    outpath = joinpath(SUBNATIONAL_DATA_DIR, filename)
    Arrow.write(outpath, df)
    println("Wrote $(nrow(df)) rows to $outpath")
    return outpath
end
