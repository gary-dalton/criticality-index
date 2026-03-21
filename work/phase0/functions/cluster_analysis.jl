using SparseArrays
using LinearAlgebra
using Graphs
using Statistics
using CommunityDetection
using SimpleWeightedGraphs

# Dependency: qog_augmented_standard.jl (loaded via load_phase0.jl)

# ==============================================================================
# SYSTEM CONSTANTS
# ==============================================================================

# --- Path Constants ---
"""Path to metadata CSV used for clustering (slug, ggis_geo_classification, birth/death years)."""
const PATH_METADATA_CLUSTER_INPUT = "data/qog_metadata_plus2.csv"
"""Output path for clustered metadata (Step 6)."""
const PATH_METADATA_CLUSTER_OUTPUT = "data/qog_metadata_clustered.csv"

# --- Period and data rules (Step 1) ---
"""Default minimum non-missing observations required to compute a period mean (default: 1)."""
const DEFAULT_MIN_OBS_PER_PERIOD = 1
"""Default minimum observations required to compute volatility (default: 3)."""
const DEFAULT_MIN_OBS_FOR_VOL = 3

# --- Step 2 filtering rules ---
"""Minimum number of periods in which a slug must meet coverage threshold."""
const STEP2_MIN_PERIODS_REQUIRED = 1

"""Minimum per-period country coverage required for a slug."""
const STEP2_MIN_COVERAGE = 0.10


# --- Step 2A (Other-slug tagging) rules ---
"""Minimum non-missing observations within a (country, period) required to mark an Other slug as present."""
const PRESENT_MIN_OBS_OTHER = 2

# --- Anchor slugs (used for post-cluster interpretation / labeling) ---
const ANCHOR_POP = "wpp_pop"                         # Population (levels)
const ANCHOR_WEALTH_HISTORICAL = "gle_cgdpc"         # GDP per capita (historical; e.g., 1950–2011)
const ANCHOR_WEALTH_MODERN = "wdi_gdpcapcon2015"     # GDP per capita (modern; e.g., 1960–2023)
const ANCHOR_WEALTH_SWITCH_YEAR = 1960              # Prefer modern wealth series from this year onward
const ANCHOR_GOV_TYPE = "bmr_dem"                    # Binary democracy indicator (0/1)

"""Small epsilon to avoid division-by-zero in z-scoring when variance is ~0."""
const BASELINE_ZSCORE_EPS = 1e-12

"""
Default four fixed periods as closed intervals [lo, hi].
External config: revise year cutoffs here without changing logic.
"""
const DEFAULT_PERIODS = [
    (name = "P1", lo = 1990, hi = 1999),
    (name = "P2", lo = 2000, hi = 2009),
    (name = "P3", lo = 2010, hi = 2014),
    (name = "P4", lo = 2015, hi = 2023),
]

const REGIONAL_PENETRATION_UPPER_BOUND = 0.95
const REGIONAL_EXCLUSION_TOLERANCE     = 3
const TOTAL_REGIONS_COUNT              = 10

# ==============================================================================
# DATA LOADING
# ==============================================================================

"""
Loads the main QoG timeseries DataFrame and the metadata DataFrame for clustering.

Usage:
    df, meta_df = load_dataframes()
Returns:
- df: Main timeseries DataFrame (from load_qog_timeseries)
- meta_df: Metadata DataFrame from PATH_METADATA_CLUSTER_INPUT

Arguments:
- (none)

Required metadata columns (for Step 1): slug, ggis_geo_classification;
  ggis_birth_year / birth_year, ggis_death_year / death_year (optional but used when present).
"""
function load_dataframes()
    df = load_qog_timeseries()
    meta_df = CSV.read(PATH_METADATA_CLUSTER_INPUT, DataFrame)
    return df, meta_df
end

# ==============================================================================
# HELPERS: MODE, SLUG META, COUNTRY REGION
# ==============================================================================

"""
Returns true if col is numeric (eltype <: Union{Missing, Number}).

Usage:
    b = _is_numeric_col(df.some_column)
Returns:
- Bool: true if numeric, false otherwise
"""
_is_numeric_col(col) = eltype(col) <: Union{Missing, Number}

"""
Returns the most frequent value in v; on tie, returns the smallest value.
Used to define country-level region from possibly varying year-level region.

Usage:
    r = _mode_smallest(df.ggis_region)
Returns:
- Int or missing: Mode value, or missing if v is empty or all missing

Arguments:
- v: Vector of Int (or Union{Int, Missing})
"""
function _mode_smallest(v)
    v_clean = collect(skipmissing(v))
    isempty(v_clean) && return missing
    counts = Dict{Int, Int}()
    for x in v_clean
        xi = Int(x)
        counts[xi] = get(counts, xi, 0) + 1
    end
    max_count = maximum(values(counts))
    candidates = [k for (k, c) in counts if c == max_count]
    return minimum(candidates)
end

"""
Normalizes geo-class strings from metadata to one of: "global", "regional", "other".
Any unknown value is coerced to "other".
"""
function _normalize_geo_class(x)
    if ismissing(x)
        return "other"
    end
    s = lowercase(strip(string(x)))
    if s == "global" || s == "regional" || s == "other"
        return s
    end
    return "other"
end

"""
Builds a lookup from slug to (geo_class, birth_year, death_year) for applicability and lifespan.

Usage:
    lookup = _slug_meta_lookup(meta_df)
Returns:
- Dict{String, NamedTuple}: slug => (geo_class::String, birth_year::Union{Int,Missing}, death_year::Union{Int,Missing})

Arguments:
- meta_df::DataFrame: Must have columns slug, ggis_geo_classification;
  optional: ggis_birth_year/ggis_death_year or birth_year/death_year
"""
function _slug_meta_lookup(meta_df::DataFrame)
    out = Dict{String, NamedTuple}()
    for row in eachrow(meta_df)
        slug = string(row.slug)
        geo_raw = get(row, :ggis_geo_classification, missing)
        geo_str = _normalize_geo_class(geo_raw)
        by = coalesce(get(row, :ggis_birth_year, missing), get(row, :birth_year, missing))
        dy = coalesce(get(row, :ggis_death_year, missing), get(row, :death_year, missing))
        out[slug] = (geo_class = geo_str, birth_year = by, death_year = dy)
    end
    return out
end

"""
Builds a map from ident_ccode to country-level ggis_region (mode; tie → smallest).

Usage:
    region_map = _country_region_map(df)
Returns:
- Dict{Int, Int}: ident_ccode => ggis_region

Arguments:
- df::DataFrame: Must have ident_ccode and ggis_region
"""
function _country_region_map(df::DataFrame)
    out = Dict{Int, Union{Int, Missing}}()
    for sdf in groupby(df, :ident_ccode)
        ccode = Int(first(skipmissing(sdf.ident_ccode)))
        out[ccode] = _mode_smallest(sdf.ggis_region)
    end
    return out
end

# ==============================================================================
# STEP 1: COUNTRY-LEVEL FEATURE TABLE
# ==============================================================================

"""
Computes period mean for one country and one slug over applicable rows in [lo, hi],
respecting slug birth/death and min_obs_per_period.

Usage:
    m = _period_mean(df_c, slug_sym, lo, hi, birth_year, death_year, min_obs)
Returns:
- Union{Float64, Missing}: Mean or missing

Arguments:
- df_c::DataFrame: Country subset (same ident_ccode)
- slug_sym::Symbol: Variable column name
- lo::Int, hi::Int: Period bounds (inclusive)
- birth_year, death_year: Union{Int,Missing} from metadata
- min_obs_per_period::Int: Minimum non-missing count to return a mean
"""
function _period_mean(df_c::AbstractDataFrame, slug_sym::Symbol, lo::Int, hi::Int,
                      birth_year, death_year, min_obs_per_period::Int)
    col = df_c[!, slug_sym]
    _is_numeric_col(col) || return missing
    years = df_c.ident_year
    period_ok = (y -> !ismissing(y) && lo <= Int(y) <= hi).(years)
    lo_ok = ismissing(birth_year) .|| (y -> !ismissing(y) && Int(y) >= birth_year).(years)
    hi_ok = ismissing(death_year) .|| (y -> !ismissing(y) && Int(y) <= death_year).(years)
    in_scope = period_ok .& lo_ok .& hi_ok
    vals = col[in_scope]
    # Count non-missing explicitly; skipmissing(vals) is an iterator and length(...) can be unsafe.
    n_nonmiss = count(!ismissing, vals)
    if n_nonmiss >= min_obs_per_period
        return mean(skipmissing(vals))
    end
    return missing
end

"""
Computes period missrate for one country and one slug over applicable rows.
Missrate = missing_count / applicable_row_count; if applicable_row_count == 0 returns missing.

Usage:
    r = _period_missrate(df_c, slug_sym, lo, hi, birth_year, death_year, appl_mask)
Returns:
- Union{Float64, Missing}: Missrate in [0,1] or missing

Arguments:
- df_c::DataFrame: Country subset
- slug_sym::Symbol: Variable column name
- lo::Int, hi::Int: Period bounds
- birth_year, death_year: Union{Int,Missing}
- appl_mask::BitVector: Boolean mask of applicable rows (same length as df_c)
"""
function _period_missrate(df_c::AbstractDataFrame, slug_sym::Symbol, lo::Int, hi::Int,
                          birth_year, death_year, appl_mask::BitVector)
    years = df_c.ident_year
    period_ok = (y -> !ismissing(y) && lo <= Int(y) <= hi).(years)
    lo_ok = ismissing(birth_year) .|| (y -> !ismissing(y) && Int(y) >= birth_year).(years)
    hi_ok = ismissing(death_year) .|| (y -> !ismissing(y) && Int(y) <= death_year).(years)
    in_scope = period_ok .& lo_ok .& hi_ok .& appl_mask
    applicable_n = count(in_scope)
    applicable_n == 0 && return missing
    col = df_c[!, slug_sym]
    missing_n = count(i -> in_scope[i] && ismissing(col[i]), 1:nrow(df_c))
    return missing_n / applicable_n
end

"""
Computes volatility (std) over all applicable years for one country and slug,
respecting birth/death and min_obs_for_vol.

Usage:
    vol = _volatility(df_c, slug_sym, birth_year, death_year, appl_mask, min_obs_for_vol)
Returns:
- Union{Float64, Missing}

Arguments:
- df_c::DataFrame: Country subset
- slug_sym::Symbol: Variable column name
- birth_year, death_year: Union{Int,Missing}
- appl_mask::BitVector: Applicable rows
- min_obs_for_vol::Int: Minimum non-missing observations to compute std
"""
function _volatility(df_c::AbstractDataFrame, slug_sym::Symbol, birth_year, death_year,
                     appl_mask::BitVector, min_obs_for_vol::Int)
    years = df_c.ident_year
    lo_ok = ismissing(birth_year) .|| (y -> !ismissing(y) && Int(y) >= birth_year).(years)
    hi_ok = ismissing(death_year) .|| (y -> !ismissing(y) && Int(y) <= death_year).(years)
    in_scope = lo_ok .& hi_ok .& appl_mask
    col = df_c[!, slug_sym]
    _is_numeric_col(col) || return missing
    vals = col[in_scope]
    vals_clean = collect(skipmissing(vals))
    if length(vals_clean) >= min_obs_for_vol
        return std(vals_clean)
    end
    return missing
end

"""
Builds the country-level feature table (Step 1): one row per ident_ccode with
period means, delta_total, recent_change, volatility, and period missrates per slug.
Applicability: global → all rows; regional → only rows where ggis_region == country_region; other → all.

Usage:
    country_features_df, audit = build_country_features_df(df, meta_df)
    country_features_df, audit = build_country_features_df(df, meta_df; periods=DEFAULT_PERIODS, min_obs_per_period=1, min_obs_for_vol=3)
Returns:
- country_features_df::DataFrame: Columns ident_ccode, ggis_region; then per slug: slug__P1_mean, ..., slug__P4_mean, slug__delta_total, slug__recent_change, slug__volatility, slug__P1_missrate, ..., slug__P4_missrate
- country_features_audit::DataFrame: Per-slug counts and coverage for QA (optional)

Arguments:
- df::DataFrame: Panel with ident_ccode, ident_year, ggis_region, plus slug columns
- meta_df::DataFrame: Metadata with slug, ggis_geo_classification, and optionally ggis_birth_year, ggis_death_year
- periods: Vector of NamedTuples (name, lo, hi); default DEFAULT_PERIODS
- min_obs_per_period::Int: Minimum observations for period mean (default: 1)
- min_obs_for_vol::Int: Minimum observations for volatility (default: 3)
- include_audit::Bool: If true, also return audit table (default: true)
"""
function build_country_features_df(
    df::DataFrame,
    meta_df::DataFrame;
    periods::Vector{<:NamedTuple} = DEFAULT_PERIODS,
    min_obs_per_period::Int = DEFAULT_MIN_OBS_PER_PERIOD,
    min_obs_for_vol::Int = DEFAULT_MIN_OBS_FOR_VOL,
    include_audit::Bool = true
)
    # Slugs: intersect metadata slugs with df column names
    meta_slugs = string.(meta_df.slug)
    df_names = Set(string.(names(df)))
    slugs_in_df = [s for s in meta_slugs if s in df_names]
    slug_meta = _slug_meta_lookup(meta_df)
    country_region = _country_region_map(df)
    country_groups = collect(groupby(df, :ident_ccode))
    sort!(country_groups; by = g -> Int(first(skipmissing(g.ident_ccode))))
    ccodes = [Int(first(skipmissing(g.ident_ccode))) for g in country_groups]
    n_periods = length(periods)


    # Prebuild period year masks for whole df (we'll subset by country anyway; here we only use lo/hi)
    # Per-country, per-slug we also apply birth/death and applicability

    # Build row per country; column names use double-underscore: slug__P1_mean, etc.
    period_names = [p.name for p in periods]
    feature_cols = String[]
    for slug in slugs_in_df
        base = slug * "__"
        for pname in period_names
            push!(feature_cols, base * pname * "_mean")
        end
        push!(feature_cols, base * "delta_total", base * "recent_change", base * "volatility")
        for pname in period_names
            push!(feature_cols, base * pname * "_missrate")
        end
    end

    # Preallocate columns: keys + feature columns
    n_countries = length(ccodes)
    key_ccode = Int[]
    key_region = Union{Int, Missing}[]
    feature_columns = Dict{String, Vector{Union{Missing, Float64}}}()
    for col in feature_cols
        feature_columns[col] = fill(missing, n_countries)
    end

    # Audit: per slug, applicable rows by period, overall coverage, countries with ≥1 obs per period
    audit_rows = Vector{NamedTuple}(undef, 0)

    for (idx, df_c) in enumerate(country_groups)
        ccode = Int(first(skipmissing(df_c.ident_ccode)))
        c_region = get(country_region, ccode, missing)
        push!(key_ccode, ccode)
        push!(key_region, c_region)

        for slug in slugs_in_df
            slug_sym = Symbol(slug)
            info = get(slug_meta, slug, (geo_class = "other", birth_year = missing, death_year = missing))
            geo_class = info.geo_class
            by = info.birth_year
            dy = info.death_year

            # Applicability mask for this country + slug
            if geo_class == "regional"
                appl_mask = coalesce.(df_c.ggis_region .== c_region, false)
            else
                appl_mask = trues(nrow(df_c))
            end

            # Period means and missrates
            means = Union{Float64, Missing}[]
            missrates = Union{Float64, Missing}[]
            for p in periods
                m = _period_mean(df_c, slug_sym, p.lo, p.hi, by, dy, min_obs_per_period)
                push!(means, m)
                r = _period_missrate(df_c, slug_sym, p.lo, p.hi, by, dy, appl_mask)
                push!(missrates, r)
            end

            # delta_total = last_period_mean - first_period_mean; recent_change = last - second-to-last
            p1_m = means[1]
            p_last_m = means[end]
            p_prev_m = n_periods >= 2 ? means[end - 1] : missing
            delta_total = (ismissing(p1_m) || ismissing(p_last_m)) ? missing : (p_last_m - p1_m)
            recent_change = (ismissing(p_prev_m) || ismissing(p_last_m)) ? missing : (p_last_m - p_prev_m)
            vol = _volatility(df_c, slug_sym, by, dy, appl_mask, min_obs_for_vol)

            base = slug * "__"
            for (i, pname) in enumerate(period_names)
                feature_columns[base * pname * "_mean"][idx] = means[i]
                feature_columns[base * pname * "_missrate"][idx] = missrates[i]
            end
            feature_columns[base * "delta_total"][idx] = delta_total
            feature_columns[base * "recent_change"][idx] = recent_change
            feature_columns[base * "volatility"][idx] = vol
        end
    end

    country_features_df = DataFrame(ident_ccode = key_ccode, ggis_region = key_region)
    for col in feature_cols
        country_features_df[!, col] = feature_columns[col]
    end

    # Audit table: per slug, applicable rows by period, countries with ≥1 obs
    if include_audit
        for slug in slugs_in_df
            slug_sym = Symbol(slug)
            info = get(slug_meta, slug, (geo_class = "other", birth_year = missing, death_year = missing))
            by, dy = info.birth_year, info.death_year
            n_appl_p1 = 0
            n_appl_p4 = 0
            n_countries_p1 = 0
            n_countries_p4 = 0
            for ccode in ccodes
                df_c = df[df.ident_ccode .== ccode, :]
                c_region = get(country_region, ccode, missing)
                appl = info.geo_class == "regional" ? coalesce.(df_c.ggis_region .== c_region, false) : trues(nrow(df_c))
                n1 = _period_applicable_count(df_c, slug_sym, periods[1].lo, periods[1].hi, by, dy, appl)
                n_last = _period_applicable_count(df_c, slug_sym, periods[end].lo, periods[end].hi, by, dy, appl)
                n_appl_p1 += n1
                n_appl_p4 += n_last
                n_countries_p1 += (n1 > 0 ? 1 : 0)
                n_countries_p4 += (n_last > 0 ? 1 : 0)
            end
            push!(audit_rows, (slug = slug, applicable_P1 = n_appl_p1, applicable_P_last = n_appl_p4, countries_with_obs_P1 = n_countries_p1, countries_with_obs_P_last = n_countries_p4))
        end
        country_features_audit = length(audit_rows) > 0 ? DataFrame(audit_rows) : DataFrame()
    else
        country_features_audit = DataFrame()
    end

    return country_features_df, country_features_audit
end

"""Count of applicable rows in period for one country (for audit)."""
function _period_applicable_count(df_c::AbstractDataFrame, slug_sym::Symbol, lo::Int, hi::Int,
                                  birth_year, death_year, appl_mask::BitVector)
    years = df_c.ident_year
    period_ok = (y -> !ismissing(y) && lo <= Int(y) <= hi).(years)
    lo_ok = ismissing(birth_year) .|| (y -> !ismissing(y) && Int(y) >= birth_year).(years)
    hi_ok = ismissing(death_year) .|| (y -> !ismissing(y) && Int(y) <= death_year).(years)
    in_scope = period_ok .& lo_ok .& hi_ok .& appl_mask
    return count(in_scope)
end

# ==============================================================================
# QA / SANITY CHECKS
# ==============================================================================

"""
Runs sanity checks on country_features_df after Step 1.
Checks: row count equals number of unique ident_ccode in df; optional spot checks.

Usage:
    check_country_features_qa(df, country_features_df)
Returns:
- Nothing (prints results to console)

Arguments:
- df::DataFrame: Original panel (must have ident_ccode)
- country_features_df::DataFrame: Output of build_country_features_df()

Prints:
- Row count check (pass/fail)
- Optional: suggestion to inspect a global slug's missrates
"""
function check_country_features_qa(df::DataFrame, country_features_df::DataFrame)
    n_unique_ccode = length(unique(skipmissing(df.ident_ccode)))
    n_rows = nrow(country_features_df)
    ok = (n_rows == n_unique_ccode)
    println("\n>>> Step 1 QA: country_features_df")
    println("    Unique ident_ccode in df: $n_unique_ccode")
    println("    Rows in country_features_df: $n_rows")
    println("    Row count match: $(ok ? "PASS" : "FAIL")")
    if !ok
        @warn "Row count mismatch: country_features_df should have one row per unique ident_ccode."
    end
    println("    For a known global slug with good coverage, missrates should be mostly low in later periods.")
    println("    For regional-only slugs, missrates should not penalize countries outside region (applicable_n==0 → missing).")
    return nothing
end

# ==============================================================================
# RUN CLUSTER SAMPLES — Intent and usage (like run_enrich_metadata_samples)
# ==============================================================================

"""
Prints function intent and usage for cluster_analysis.jl (Step 1: country-level feature table).
Call this to see how to load data, build country features, and run QA.

Usage:
    run_cluster_analysis_samples()
Returns:
- Nothing (prints to console)
"""
function run_cluster_analysis_samples()
    println("\n" * "="^76)
    println("  cluster_analysis.jl — Function intent and usage (Step 1: country-level features)")
    println("="^76)

    println("\n┌─ load_dataframes()")
    println("│  INTENT: Load the main QoG timeseries and the clustering metadata in one call.")
    println("│  USE WHEN: You need both df and meta_df for building country features.")
    println("│")
    println("│  RETURNS: (df, meta_df)")
    println("│    - df: main timeseries from load_qog_timeseries()")
    println("│    - meta_df: from PATH_METADATA_CLUSTER_INPUT (qog_metadata_plus2.csv)")
    println("│")
    println("│  USAGE:")
    println("│    df, meta = load_dataframes()")
    println("└" * "─"^74)

    println("\n┌─ build_country_features_df(df, meta_df; periods, min_obs_per_period, min_obs_for_vol, include_audit)")
    println("│  INTENT: Build country-level feature table (one row per ident_ccode) with period means,")
    println("│          delta_total, recent_change, volatility, and period missrates per slug.")
    println("│  USE WHEN: Step 1 of clustering prep — you need country-level summary for clustering.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    df::DataFrame — panel with ident_ccode, ident_year, ggis_region, plus slug columns")
    println("│    meta_df::DataFrame — slug, ggis_geo_classification, ggis_birth_year, ggis_death_year")
    println("│    Optional kwargs: periods=DEFAULT_PERIODS, min_obs_per_period=1, min_obs_for_vol=3, include_audit=true")
    println("│")
    println("│  RETURNS: (country_features_df, country_features_audit)")
    println("│    - country_features_df: ident_ccode, ggis_region, then per slug: slug__P1_mean, ..., slug__delta_total,")
    println("│      slug__recent_change, slug__volatility, slug__P1_missrate, ...")
    println("│    - country_features_audit: per-slug applicable counts and country coverage (for QA)")
    println("│")
    println("│  USAGE:")
    println("│    df, meta = load_dataframes()")
    println("│    features_df, audit = build_country_features_df(df, meta)")
    println("│    check_country_features_qa(df, features_df)")
    println("└" * "─"^74)

    println("\n┌─ check_country_features_qa(df, country_features_df)")
    println("│  INTENT: Run sanity checks on Step 1 output (row count, suggestions).")
    println("│  USE WHEN: After building country_features_df to verify row count and expectations.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    df::DataFrame — original panel")
    println("│    country_features_df::DataFrame — output of build_country_features_df()")
    println("│")
    println("│  RETURNS: Nothing (prints to console)")
    println("│")
    println("│  USAGE:")
    println("│    check_country_features_qa(df, features_df)")
    println("└" * "─"^74)

    println("\n┌─ build_country_period_missingness_baseline_df(country_features_df, meta_df; periods, verbose)")
    println("│  INTENT: Step 2A — Build country×period baseline missingness using ONLY:")
    println("│          - Global slugs, and")
    println("│          - Regional slugs applicable to the country’s region.")
    println("│")
    println("│  RETURNS: DataFrame with columns:")
    println("│    ident_ccode, period, miss_global, miss_regional")
    println("│")
    println("│  USAGE:")
    println("│    miss_df = build_country_period_missingness_baseline_df(country_features_df, meta)")
    println("└" * "─"^74)
    println("\n┌─ build_other_slug_presence_df(df, meta_df; periods, min_present_obs, verbose)")
    println("│  INTENT: Step 2A — Compute Other-slug presence directly from panel df.")
    println("│          present(S,c,p)=1 if nonmissing obs in (c,p) >= PRESENT_MIN_OBS_OTHER (default 2).")
    println("│")
    println("│  RETURNS: Sparse DataFrame (only present rows):")
    println("│    slug, ident_ccode, period, nonmissing_obs")
    println("│")
    println("│  USAGE:")
    println("│    presence_df = build_other_slug_presence_df(df, meta)")
    println("└" * "─"^74)
    println("\n┌─ build_country_period_anchor_df(df; periods, verbose)")
    println("│  INTENT: Step 2A — Compute anchor summaries for post-cluster interpretation:")
    println("│          log-pop, stitched log-wealth, and regime share/change by period.")
    println("│  NOTE: Anchors are NOT used for clustering; used to label/interpret slug modules.")
    println("│")
    println("│  RETURNS: DataFrame with columns (per ident_ccode, period):")
    println("│    log_pop_level, log_pop_change, log_gdp_level, log_gdp_change, dem_share, dem_change")
    println("│")
    println("│  USAGE:")
    println("│    anchors_df = build_country_period_anchor_df(df)")
    println("└" * "─"^74)

    println("\n┌─ filter_slugs_step2(country_features_df, meta_df; periods, coverage_threshold, require_periods, df_panel, id_patterns, exclude_slugs)")
    println("│  INTENT: Step 2 — Filter unusable slugs before feature-selection and clustering.")
    println("│          Drops non-numeric, low-coverage, insufficient-period, near-constant, and identifier-like slugs.")
    println("│  USE WHEN: After Step 1, before Step 3 (predictive ranking) and Step 4 (clustering).")
    println("│")
    println("│  ARGUMENTS:")
    println("│    country_features_df::DataFrame — output of build_country_features_df()")
    println("│    meta_df::DataFrame — metadata including `slug` (and geo/lifespan fields used earlier)")
    println("│    Optional kwargs:")
    println("│      periods=DEFAULT_PERIODS")
    println("│      coverage_threshold=STEP2_MIN_COVERAGE")
    println("│      require_periods=STEP2_MIN_PERIODS_REQUIRED")
    println("│      df_panel=df  (recommended; improves numeric detection)")
    println("│      id_patterns=[...]  (regex list)")
    println("│      exclude_slugs=[...]")
    println("│")
    println("│  RETURNS: (kept_slugs, rejected_slugs, slug_filter_report)")
    println("│")
    println("│  USAGE:")
    println("│    kept, rejected, report = filter_slugs_step2(country_features_df, meta; df_panel=df)")
    println("│    first(report, 20)")
    println("│    length(kept), length(rejected)")
    println("└" * "─"^74)


    println("\n" * "="^76)

println("\n┌─ build_country_period_missingness_baseline_df(country_features_df, meta_df; periods=DEFAULT_PERIODS)")
println("│  INTENT: Build per-(country,period) missingness baselines using ONLY slugs tagged Global and Regional.")
println("│          Regional missrates are averaged over applicable regional slugs (non-applicable → missing → ignored).")
println("│  USE WHEN: You are tagging / clustering Other slugs and need each country-period's measurement environment.")
println("│  RETURNS: country_period_missingness_df (long form: ident_ccode, period, miss_global, miss_regional, n_global_used, n_regional_used)")
println("└" * "─"^74)

println("\n┌─ build_country_period_anchor_df(df; periods=DEFAULT_PERIODS)")
println("│  INTENT: Compute post-cluster interpretation features per (country,period) from anchor slugs:")
println("│          log population, stitched log wealth, and democracy share/change.")
println("│  NOTE: Anchors are NOT used to form clusters; they are used to label/interpret country sets after clustering.")
println("│  RETURNS: country_period_anchor_df (long form: ident_ccode, period, log_pop_level/change, log_gdp_level/change, dem_share/change)")
println("└" * "─"^74)

println("\n┌─ build_other_slug_presence_df(df, meta_df; periods=DEFAULT_PERIODS, min_present_obs=PRESENT_MIN_OBS_OTHER)")
println("│  INTENT: Compute presence of Other slugs by (country,period) directly from the raw panel df.")
println("│          present=true iff nonmissing_obs >= min_present_obs.")
println("│  RETURNS: other_presence_df (sparse: only present rows; columns: slug, ident_ccode, period, nonmissing_obs)")
println("└" * "─"^74)
    println("  TYPICAL WORKFLOW (Steps 1–3A):")
    println("  Step 1 ---")
    println("  1. df, meta = load_dataframes()")
    println("  2. country_features_df, audit = build_country_features_df(df, meta)")
    println("  3. check_country_features_qa(df, country_features_df)")
    println("  4. first(country_features_df, 5)")
    println("  Step 2A ---")
    println("  5. miss_df = build_country_period_missingness_baseline_df(country_features_df, meta)")
    println("  Step 2B ---")
    println("  6. presence_df = build_other_slug_presence_df(df, meta)  # Other slugs only; k=2 by const")
    println("  Step 2C ---")
    println("  7. anchors_df = build_country_period_anchor_df(df)        # post-cluster diagnostics")
    println("  Step 3A ---")
    println("  8. X, slug_index, cell_index = build_slug_cell_matrix(presence_df)")
    println("  9. edges_dir = cosine_topk_edges(X, slug_index; k=20, min_sim=0.05)")
    println(" 10. edges_und = symmetrize_edges(edges_dir; mode=:max)")
    println("  Step 3B ---")
    println(" 11. g, slugs_g, comps = graph_components_diagnostics(edges_und);")
    println(" 12. comp_slugs = component_slug_sets(comps, slugs_g); length.(comp_slugs))")
    println(" 13. small = argmin(length.(comp_slugs)); println(comp_slugs[small])")
    println(" 14. g_w, slugs_g, slug_to_idx = build_weighted_slug_graph(edges_und);")
    println(" Step 4 ---")
    println(" 15. cluster_presence_df, cluster_sizes_df = cluster_presence(presence_df, slug_cluster_df)")
    println(" 16. cluster_presence_enriched_df = attach_environment_and_anchors(cluster_presence_df, miss_df, anchor_df)")
    println(" 17. cluster_summary_df = summarize_clusters(cluster_presence_enriched_df)")
    println(" 18. top_countries_df = top_countries_by_cluster(cluster_presence_enriched_df)")
    println(" 19. period_cov_df  = period_coverage_by_cluster(cluster_presence_enriched_df)")
    println("  Step 5 ---")
    println(" 20. audit = join_audit(cluster_presence_enriched_df, miss_df, anchor_df)")
    println("="^76 * "\n")
    return nothing
end

# ==============================================================================
# STEP 2: FILTER UNUSABLE SLUGS
# ==============================================================================

"""
Returns true if a slug looks like an identifier / key rather than an analytical variable.

Default patterns are conservative; adjust via `id_patterns` in `filter_slugs_step2`.
"""
function _looks_like_identifier(slug::AbstractString, id_patterns::Vector{Regex})
    s = lowercase(String(slug))
    for rx in id_patterns
        occursin(rx, s) && return true
    end
    return false
end

"""
Infer whether a slug is numeric.

Priority order:
1) If `df_panel` is provided and contains the slug, use the panel column eltype.
2) Otherwise, infer from `country_features_df` period-mean columns: if any period mean
   has at least one non-missing value, treat as numeric.

Returns:
- Bool
"""
function _infer_slug_numeric(
    slug::AbstractString,
    country_features_df::AbstractDataFrame,
    period_names::Vector{String};
    df_panel::Union{Nothing, AbstractDataFrame} = nothing
)::Bool
    sym = Symbol(slug)

    # 1) Panel: conclude TRUE when clearly numeric
    if df_panel !== nothing && (sym in propertynames(df_panel))
        col = df_panel[!, sym]
        if eltype(col) <: Union{Missing, Number}
            return true
        end
    end

    # 2) Fallback: any period mean column has observed numeric values
    for pname in period_names
        colname = Symbol(string(slug, "__", pname, "_mean"))
        if colname in names(country_features_df)
            v = country_features_df[!, colname]
            if (eltype(v) <: Union{Missing, Number}) && any(!ismissing, v)
                return true
            end
        end
    end

    return false
end


"""
Step 2: Filter unusable slugs before feature-selection and clustering.

This function is additive (does not modify `country_features_df`).

Rules (in order):
- Drop identifier-like slugs (pattern-based)
- Drop non-numeric slugs (per user's Step 2 decision)
- Drop if overall coverage (non-missing period means) < `coverage_threshold`
- Drop if not usable in all periods (each period coverage >= threshold; require 4 periods)
- Drop if near-constant (std==0 or unique<=1 in last period mean)

Coverage definition:
- For each slug, consider its period mean columns `slug__P*_mean`.
- Overall coverage = (# non-missing cells across countries×periods) / (n_countries * n_periods)
- Period coverage = (# non-missing countries in that period) / n_countries

Returns:
- kept_slugs::Vector{String}
- rejected_slugs::Vector{String}
- slug_filter_report::DataFrame

Usage:
    kept, rejected, report = filter_slugs_step2(country_features_df, meta_df)
    kept, rejected, report = filter_slugs_step2(country_features_df, meta_df; df_panel=df)
"""
function filter_slugs_step2(
    country_features_df::AbstractDataFrame,
    meta_df::AbstractDataFrame;
    periods::Vector{<:NamedTuple} = DEFAULT_PERIODS,
    coverage_threshold::Float64 = STEP2_MIN_COVERAGE,
    require_periods::Int = STEP2_MIN_PERIODS_REQUIRED,
    df_panel::Union{Nothing, AbstractDataFrame} = nothing,
    id_patterns::Vector{Regex} = [
        r"^ident_", r"_id$", r"rowid", r"ccode", r"year", r"^iso", r"code$"
    ],
    exclude_slugs::Vector{String} = String[],
    verbose::Bool = true
)
    # Period names
    period_names = String[p.name for p in periods]
    n_periods = length(period_names)
    if require_periods != n_periods
        @warn "require_periods != length(periods); using require_periods=$require_periods and periods=$n_periods"
    end

    # Candidate slugs: from metadata, present in country_features_df as at least one mean column
    meta_slugs = String.(meta_df.slug)
    cf_names = Set(Symbol.(names(country_features_df)))
    slugs = String[]
    for slug in meta_slugs
        slug in exclude_slugs && continue
        # require at least one period-mean column exists
        any_present = any(pn -> Symbol(string(slug, "__", pn, "_mean")) in cf_names, period_names)
        any_present && push!(slugs, slug)
    end

    n_countries = nrow(country_features_df)

    report_rows = NamedTuple[]
    kept_slugs = String[]
    rejected_slugs = String[]

    for slug in slugs
        # Basic columns for reporting
        decision = "keep"
        reason = ""

        # F5: identifier-like
        if _looks_like_identifier(slug, id_patterns)
            decision = "drop"
            reason = "identifier_like"
        end

        # F2: non-numeric (user choice: drop)
        numeric = _infer_slug_numeric(slug, country_features_df, period_names; df_panel=df_panel)
        if decision == "keep" && !numeric
            decision = "drop"
            reason = "non_numeric"
        end

        # Coverage metrics (based on means only)
        period_cov = fill(0.0, n_periods)
        usable_periods = 0
        overall_cov = 0.0

        if n_countries == 0
            overall_cov = 0.0
        else
            total_nonmiss = 0
            total_cells = n_countries * n_periods
            for (i, pn) in enumerate(period_names)
                colname = Symbol(string(slug, "__", pn, "_mean"))
                if colname in names(country_features_df)
                    v = country_features_df[!, colname]
                    nonmiss = count(!ismissing, v)
                    period_cov[i] = nonmiss / n_countries
                    total_nonmiss += nonmiss
                else
                    period_cov[i] = 0.0
                end
            end
            overall_cov = total_nonmiss / total_cells
            usable_periods = count(c -> c >= coverage_threshold, period_cov)
        end

        # Coverage and period usability
        if decision == "keep" && overall_cov < coverage_threshold
            decision = "drop"
            reason = "low_coverage"
        end
        if decision == "keep" && usable_periods < require_periods
            decision = "drop"
            reason = "insufficient_periods"
        end

        # Near-constant (use last period mean)
        near_constant = false
        if decision == "keep"
            last_col = Symbol(string(slug, "__", period_names[end], "_mean"))
            if last_col in names(country_features_df)
                v = country_features_df[!, last_col]
                vv = collect(skipmissing(v))
                if length(vv) <= 1
                    near_constant = true
                else
                    if std(vv) == 0.0 || length(unique(vv)) <= 1
                        near_constant = true
                    end
                end
            else
                near_constant = true
            end

            if near_constant
                decision = "drop"
                reason = "near_constant"
            end
        end

        if decision == "keep"
            push!(kept_slugs, slug)
        else
            push!(rejected_slugs, slug)
        end

        push!(report_rows, (
            slug = slug,
            numeric = numeric,
            coverage = overall_cov,
            usable_periods = usable_periods,
            decision = decision,
            reason = reason,
            period_coverages = period_cov
        ))
    end

    slug_filter_report = DataFrame(report_rows)

    # Sort report for readability: drops first, then by increasing coverage
    sort!(slug_filter_report, [:decision, :coverage])

    if verbose
        total = length(slugs)
        kept_n = length(kept_slugs)
        rejected_n = length(rejected_slugs)

        println("\n" * "="^72)
        println("Step 2 — Slug Filtering Diagnostics")
        println("="^72)

        println("Total candidate slugs: $total")
        println("Kept slugs:            $kept_n")
        println("Rejected slugs:        $rejected_n")
        println("Keep rate:             $(round(100 * kept_n / max(total,1); digits=1)) %")

        println("\nRejection reasons:")
        by_reason = combine(groupby(slug_filter_report, :reason), nrow => :count)
        sort!(by_reason, :count, rev=true)
        show(by_reason, allrows=true, allcols=true)
        println()

        println("\nCoverage statistics (kept slugs):")
        kept_cov = slug_filter_report.coverage[slug_filter_report.decision .== "keep"]
        if !isempty(kept_cov)
            println("  min coverage: ", round(minimum(kept_cov); digits=3))
            println("  median:       ", round(median(kept_cov); digits=3))
            println("  mean:         ", round(mean(kept_cov); digits=3))
            println("  max:          ", round(maximum(kept_cov); digits=3))
        end

        println("\nExample kept slugs:")
        println(join(first(kept_slugs, min(10, length(kept_slugs))), ", "))

        println("\nExample rejected slugs:")
        println(join(first(rejected_slugs, min(10, length(rejected_slugs))), ", "))

        println("="^72 * "\n")
    end


    return kept_slugs, rejected_slugs, slug_filter_report
end


# ==============================================================================
# STEP 2A: BASELINES + OTHER-SLUG PRESENCE (for tagging "Other" slugs)
# ==============================================================================
#
# IMPORTANT: This is a different pipeline than `filter_slugs_step2`.
# Here we DO NOT prune "Other" slugs by coverage. Instead, we:
#   (a) compute country-period missingness baselines using Global + applicable Regional slugs,
#   (b) compute optional anchor summaries for post-cluster interpretation,
#   (c) compute Other-slug presence by (country,period) directly from the raw panel.
#
# These outputs support:
#   - Rep A (membership topology): slug → {countries×periods where present}
#   - Rep B (signature topology): slug → differences in missingness environment (and later anchors)

"""Normalize geo-classification labels from metadata."""
function _norm_geo_class(x)::String
    if ismissing(x)
        return "other"
    end
    s = lowercase(strip(string(x)))
    return s == "" ? "other" : s
end

"""Return slugs from meta_df by geo classification (global/regional/other)."""
function slugs_by_geo(meta_df::AbstractDataFrame, geo::AbstractString)::Vector{String}
    geo_n = lowercase(strip(String(geo)))
    has_slug = :slug in propertynames(meta_df)
    has_geo  = :ggis_geo_classification in propertynames(meta_df)
    (!has_slug || !has_geo) && error("meta_df must have columns :slug and :ggis_geo_classification")

    out = String[]
    for r in eachrow(meta_df)
        if _norm_geo_class(r.ggis_geo_classification) == geo_n
            push!(out, string(r.slug))
        end
    end
    return out
end

"""
Build per-(country,period) missingness baselines using ONLY:
  - slugs tagged Global
  - slugs tagged Regional (averaged over applicable slugs; non-applicable missrate columns are missing and ignored)

Inputs:
- country_features_df: output of build_country_features_df (wide; one row per ident_ccode)
- meta_df: metadata with slug + ggis_geo_classification

Output:
- DataFrame (long):
    ident_ccode, period,
    miss_global, miss_regional,
    n_global_used, n_regional_used

Notes:
- Uses Step 1's `slug__<period>_missrate` columns; no raw df scan needed.
- Regional applicability is already handled in Step 1 via `applicable_n==0 → missing`, so averaging ignoring missings
  effectively averages only in-region slugs for that country.
"""
function build_country_period_missingness_baseline_df(
    country_features_df::AbstractDataFrame,
    meta_df::AbstractDataFrame;
    periods::Vector{<:NamedTuple} = DEFAULT_PERIODS,
    verbose::Bool = true
)::DataFrame
    # --- Step 2A: compute (country, period) missingness baselines ---
    # Global baseline: average missrate across slugs tagged "global" (existing behavior).
    # Regional baseline: average missrate across slugs tagged "regional" that are applicable
    # to the country's region AND alive during the period (birth/death overlap), with a
    # concentration constraint (strong in ≤ REGIONAL_EXCLUSION_TOLERANCE regions).

    period_names = [p.name for p in periods]
    global_slugs   = slugs_by_geo(meta_df, "global")
    regional_slugs = slugs_by_geo(meta_df, "regional")

    # Required for regional baselines
    (:ggis_region in propertynames(country_features_df)) || error("country_features_df must include :ggis_region for regional baselines")

    # Keep only slugs that actually have missrate columns in country_features_df
    df_cols = Set(Symbol.(names(country_features_df)))

    # --------------------------------------------------------------------------
    # Helpers (local)
    # --------------------------------------------------------------------------
    _as_string(x) = ismissing(x) ? "" : string(x)

    function _parse_region_penetration(x)::Union{Missing, Vector{Float64}}
        ismissing(x) && return missing
        s = strip(_as_string(x))
        isempty(s) && return missing
        s = replace(s, "[" => "", "]" => "")
        parts = split(s, ",")
        vals = Float64[]
        for p in parts
            t = strip(p)
            isempty(t) && continue
            push!(vals, parse(Float64, t))
        end
        length(vals) == TOTAL_REGIONS_COUNT || return missing
        return vals
    end

    function _alive_in_period(birth_year, death_year, lo::Int, hi::Int)::Bool
        # Overlap rule: [birth, death] overlaps [lo, hi]
        by = ismissing(birth_year) ? -typemax(Int) : Int(round(birth_year))
        dy = ismissing(death_year) ?  typemax(Int) : Int(round(death_year))
        return (by <= hi) && (dy >= lo)
    end

    # Build a lookup: slug => (penetration_vec, birth_year, death_year, strong_region_count)
    regional_meta = Dict{String, NamedTuple{(:pen,:by,:dy,:nstrong), Tuple{Union{Missing,Vector{Float64}}, Any, Any, Int}}}()
    if (:slug in propertynames(meta_df)) && (:ggis_region_penetration in propertynames(meta_df))
        for row in eachrow(meta_df)
            geo = hasproperty(row, :ggis_geo_classification) ? lowercase(_as_string(getproperty(row, :ggis_geo_classification))) : ""
            geo == "regional" || continue
            slug = _as_string(getproperty(row, :slug))
            pen  = _parse_region_penetration(getproperty(row, :ggis_region_penetration))
            by   = hasproperty(row, :ggis_birth_year) ? getproperty(row, :ggis_birth_year) : missing
            dy   = hasproperty(row, :ggis_death_year) ? getproperty(row, :ggis_death_year) : missing
            if ismissing(pen)
                regional_meta[slug] = (pen=missing, by=by, dy=dy, nstrong=0)
            else
                nstrong = count(>=(REGIONAL_PENETRATION_UPPER_BOUND), pen)
                regional_meta[slug] = (pen=pen, by=by, dy=dy, nstrong=nstrong)
            end
        end
    else
        error("meta_df must include :slug and :ggis_region_penetration to build regional pools")
    end

    # --------------------------------------------------------------------------
    # Precompute missrate columns by period for global slugs (existing behavior)
    # --------------------------------------------------------------------------
    global_cols_by_period = Dict{String, Vector{Symbol}}()
    for pname in period_names
        gcols = Symbol[]
        for s in global_slugs
            c = Symbol(string(s, "__", pname, "_missrate"))
            c in df_cols && push!(gcols, c)
        end
        global_cols_by_period[pname] = gcols
    end

    # --------------------------------------------------------------------------
    # Precompute regional pools as missrate columns by (period, region)
    # --------------------------------------------------------------------------
    regions_present = unique(Int.(country_features_df[!, :ggis_region]))
    regional_cols_by_period_region = Dict{String, Dict{Int, Vector{Symbol}}}()
    for (pi, pname) in enumerate(period_names)
        # find this period bounds
        p = periods[pi]
        lo = Int(p.lo); hi = Int(p.hi)

        per_region = Dict{Int, Vector{Symbol}}()
        for r in regions_present
            cols = Symbol[]
            for s in regional_slugs
                meta = get(regional_meta, _as_string(s), nothing)
                meta === nothing && continue
                ismissing(meta.pen) && continue
                meta.nstrong <= REGIONAL_EXCLUSION_TOLERANCE || continue
                meta.pen[r] >= REGIONAL_PENETRATION_UPPER_BOUND || continue
                _alive_in_period(meta.by, meta.dy, lo, hi) || continue

                c = Symbol(string(s, "__", pname, "_missrate"))
                c in df_cols && push!(cols, c)
            end
            per_region[r] = cols
        end
        regional_cols_by_period_region[pname] = per_region
    end

    # --------------------------------------------------------------------------
    # Build long output
    # --------------------------------------------------------------------------
    out_ccode  = Int[]
    out_period = String[]
    out_miss_g = Vector{Union{Missing, Float64}}()
    out_miss_r = Vector{Union{Missing, Float64}}()
    out_ng     = Int[]
    out_nr     = Int[]

    ccodes  = country_features_df[!, :ident_ccode]
    cregion = Int.(country_features_df[!, :ggis_region])
    n_c = length(ccodes)

    for pname in period_names
        gcols = global_cols_by_period[pname]
        rmap  = regional_cols_by_period_region[pname]

        for i in 1:n_c
            push!(out_ccode, Int(ccodes[i]))
            push!(out_period, pname)

            # Global baseline missingness (avg across global missrate cols, ignoring missing)
            if isempty(gcols)
                push!(out_miss_g, missing); push!(out_ng, 0)
            else
                s = 0.0; k = 0
                for c in gcols
                    v = country_features_df[i, c]
                    if !ismissing(v)
                        s += Float64(v); k += 1
                    end
                end
                push!(out_miss_g, k == 0 ? missing : (s / k))
                push!(out_ng, k)
            end

            # Regional baseline missingness: region-specific pool for this country
            r = cregion[i]
            rcols = get(rmap, r, Symbol[])

            if isempty(rcols)
                push!(out_miss_r, missing); push!(out_nr, 0)
            else
                s = 0.0; k = 0
                for c in rcols
                    v = country_features_df[i, c]
                    if !ismissing(v)
                        s += Float64(v); k += 1
                    end
                end
                push!(out_miss_r, k == 0 ? missing : (s / k))
                # NOTE: n_regional_used is the size of the (period, region) slug pool (varies by region & period)
                push!(out_nr, length(rcols))
            end
        end
    end

    out = DataFrame(
        ident_ccode = out_ccode,
        period = out_period,
        miss_global = out_miss_g,
        miss_regional = out_miss_r,
        n_global_used = out_ng,
        n_regional_used = out_nr
    )

    if verbose
        println("\n" * "="^72)
        println("Step 2A — Missingness baseline diagnostics")
        println("="^72)
        println("Periods: ", join(period_names, ", "))
        println("Global slugs in metadata:   ", length(global_slugs))
        println("Regional slugs in metadata: ", length(regional_slugs))
        println("Global missrate columns found (by period):")
        for pname in period_names
            println("  ", pname, ": ", length(global_cols_by_period[pname]))
        end
        println("Regional pool sizes (by period, region):")
        for pname in period_names
            rmap = regional_cols_by_period_region[pname]
            for r in sort(collect(keys(rmap)))
                println("  ", pname, "  r=", r, "  n=", length(rmap[r]))
            end
        end
        println("="^72 * "\n")
    end

    return out
end

"""
Compute per-(country,period) anchor summaries (log scale) for post-cluster interpretation.

Anchors:
- ANCHOR_POP: log population
- Wealth: stitched between ANCHOR_WEALTH_HISTORICAL and ANCHOR_WEALTH_MODERN
          Prefer modern series from ANCHOR_WEALTH_SWITCH_YEAR onward.
- ANCHOR_GOV_TYPE: democracy indicator (0/1)

Aggregations per (country,period):
- level: mean(log(value)) over non-missing and value>0
- change: last - first of log(value) within the period (requires ≥2 non-missing obs)

Returns (long):
  ident_ccode, period,
  log_pop_level, log_pop_change,
  log_gdp_level, log_gdp_change,
  dem_share, dem_change
"""
function build_country_period_anchor_df(
    df::AbstractDataFrame;
    periods::Vector{<:NamedTuple} = DEFAULT_PERIODS,
    verbose::Bool = true
)::DataFrame
    period_names = [p.name for p in periods]

    # Sanity: anchors must exist
    for s in (ANCHOR_POP, ANCHOR_WEALTH_HISTORICAL, ANCHOR_WEALTH_MODERN, ANCHOR_GOV_TYPE)
        Symbol(s) in propertynames(df) || @warn "Anchor slug not found in df: $s"
    end

    out = DataFrame(
        ident_ccode = Int[],
        period = String[],
        log_pop_level = Union{Missing, Float64}[],
        log_pop_change = Union{Missing, Float64}[],
        log_gdp_level = Union{Missing, Float64}[],
        log_gdp_change = Union{Missing, Float64}[],
        dem_share = Union{Missing, Float64}[],
        dem_change = Union{Missing, Float64}[]
    )

    # Group by country for efficient per-country slicing
    g = groupby(df, :ident_ccode)

    for sdf in g
        ccode = Int(first(sdf.ident_ccode))
        years = sdf.ident_year

        pop_col = Symbol(ANCHOR_POP)
        hist_col = Symbol(ANCHOR_WEALTH_HISTORICAL)
        mod_col = Symbol(ANCHOR_WEALTH_MODERN)
        dem_col = Symbol(ANCHOR_GOV_TYPE)

        pop = pop_col in propertynames(sdf) ? sdf[!, pop_col] : fill(missing, nrow(sdf))
        wh  = hist_col in propertynames(sdf) ? sdf[!, hist_col] : fill(missing, nrow(sdf))
        wm  = mod_col in propertynames(sdf) ? sdf[!, mod_col] : fill(missing, nrow(sdf))
        dem = dem_col in propertynames(sdf) ? sdf[!, dem_col] : fill(missing, nrow(sdf))

        # For wealth: year-wise stitch (prefer modern from switch year onward when present)
        wealth = Vector{Union{Missing, Float64}}(undef, nrow(sdf))
        for i in 1:nrow(sdf)
            y = years[i]
            if ismissing(y)
                wealth[i] = missing
                continue
            end
            yi = Int(y)
            if yi >= ANCHOR_WEALTH_SWITCH_YEAR
                v = wm[i]
                if !ismissing(v)
                    wealth[i] = Float64(v)
                else
                    wealth[i] = ismissing(wh[i]) ? missing : Float64(wh[i])
                end
            else
                wealth[i] = ismissing(wh[i]) ? missing : Float64(wh[i])
            end
        end

        for p in periods
            # mask for this period
            mask = (y -> !ismissing(y) && p.lo <= Int(y) <= p.hi).(years)
            if !any(mask)
                push!(out, (ident_ccode=ccode, period=p.name,
                            log_pop_level=missing, log_pop_change=missing,
                            log_gdp_level=missing, log_gdp_change=missing,
                            dem_share=missing, dem_change=missing))
                continue
            end

            # --- Population ---
            pop_vals = pop[mask]
            pop_clean = [Float64(v) for v in pop_vals if !ismissing(v) && Float64(v) > 0]
            log_pop_level = isempty(pop_clean) ? missing : mean(log.(pop_clean))

            # change = last - first (log scale)
            log_pop_change = missing
            if length(pop_clean) >= 2
                # take first/last by time ordering within period, using non-missing & >0
                idxs = findall(mask)
                # sort idxs by year (already sorted in panel typically, but don't assume)
                idxs = sort(idxs, by=i -> Int(years[i]))
                series = Float64[]
                for i in idxs
                    v = pop[i]
                    if !ismissing(v) && Float64(v) > 0
                        push!(series, log(Float64(v)))
                    end
                end
                if length(series) >= 2
                    log_pop_change = series[end] - series[1]
                end
            end

            # --- Wealth (stitched) ---
            w_vals = wealth[mask]
            w_clean = [Float64(v) for v in w_vals if !ismissing(v) && Float64(v) > 0]
            log_gdp_level = isempty(w_clean) ? missing : mean(log.(w_clean))

            log_gdp_change = missing
            if length(w_clean) >= 2
                idxs = findall(mask)
                idxs = sort(idxs, by=i -> Int(years[i]))
                series = Float64[]
                for i in idxs
                    v = wealth[i]
                    if !ismissing(v) && Float64(v) > 0
                        push!(series, log(Float64(v)))
                    end
                end
                if length(series) >= 2
                    log_gdp_change = series[end] - series[1]
                end
            end

            # --- Democracy ---
            dem_vals = dem[mask]
            dem_clean = [Float64(v) for v in dem_vals if !ismissing(v)]
            dem_share = isempty(dem_clean) ? missing : mean(dem_clean)

            dem_change = missing
            if length(dem_clean) >= 2
                idxs = findall(mask)
                idxs = sort(idxs, by=i -> Int(years[i]))
                series = Float64[]
                for i in idxs
                    v = dem[i]
                    if !ismissing(v)
                        push!(series, Float64(v))
                    end
                end
                if length(series) >= 2
                    dem_change = series[end] - series[1]
                end
            end

            push!(out, (ident_ccode=ccode, period=p.name,
                        log_pop_level=log_pop_level, log_pop_change=log_pop_change,
                        log_gdp_level=log_gdp_level, log_gdp_change=log_gdp_change,
                        dem_share=dem_share, dem_change=dem_change))
        end
    end

    if verbose
        println("\n" * "="^72)
        println("Step 2A — Anchor diagnostics (post-cluster interpretation)")
        println("="^72)
        println("Anchors:")
        println("  POP:    ", ANCHOR_POP)
        println("  WEALTH: ", ANCHOR_WEALTH_HISTORICAL, " (pre-", ANCHOR_WEALTH_SWITCH_YEAR, "), ", ANCHOR_WEALTH_MODERN, " (>= ", ANCHOR_WEALTH_SWITCH_YEAR, ")")
        println("  GOV:    ", ANCHOR_GOV_TYPE)
        println("Rows produced: ", nrow(out))
        println("Countries: ", length(unique(out.ident_ccode)))
        println("="^72 * "\n")
    end

    return out
end

"""
Compute sparse presence table for slugs tagged Other.

Definition:
- present(S,c,p) = true iff nonmissing_obs(S,c,p) >= min_present_obs

This scans raw df (panel) directly; it does NOT rely on Step 1 audit.

Returns:
- other_presence_df (sparse; only present rows):
    slug::String, ident_ccode::Int, period::String, nonmissing_obs::Int
"""
function build_other_slug_presence_df(
    df::AbstractDataFrame,
    meta_df::AbstractDataFrame;
    periods::Vector{<:NamedTuple} = DEFAULT_PERIODS,
    min_present_obs::Int = PRESENT_MIN_OBS_OTHER,
    verbose::Bool = true
)::DataFrame
    period_names = [p.name for p in periods]
    other_slugs = slugs_by_geo(meta_df, "other")

    # Only slugs that exist in df
    df_syms = Set(propertynames(df))
    other_slugs = [s for s in other_slugs if Symbol(s) in df_syms]

    # Group by country once
    g = groupby(df, :ident_ccode)

    out_slug = String[]
    out_ccode = Int[]
    out_period = String[]
    out_nonmiss = Int[]

    # Precompute per-country indices by period (within each SubDataFrame)
    for sdf in g
        ccode = Int(first(sdf.ident_ccode))
        years = sdf.ident_year

        period_idxs = Dict{String, Vector{Int}}()
        for p in periods
            idxs = findall(y -> !ismissing(y) && p.lo <= Int(y) <= p.hi, years)
            period_idxs[p.name] = idxs
        end

        for slug in other_slugs
            col = sdf[!, Symbol(slug)]
            for pname in period_names
                idxs = period_idxs[pname]
                isempty(idxs) && continue
                n_nonmiss = 0
                for i in idxs
                    if !ismissing(col[i])
                        n_nonmiss += 1
                        # small early-exit when we already meet threshold
                        if n_nonmiss >= min_present_obs
                            break
                        end
                    end
                end
                if n_nonmiss >= min_present_obs
                    push!(out_slug, slug)
                    push!(out_ccode, ccode)
                    push!(out_period, pname)
                    push!(out_nonmiss, n_nonmiss)
                end
            end
        end
    end

    out = DataFrame(
        slug = out_slug,
        ident_ccode = out_ccode,
        period = out_period,
        nonmissing_obs = out_nonmiss
    )

    if verbose
        println("\n" * "="^72)
        println("Step 2A — Other-slug presence diagnostics")
        println("="^72)
        println("Other slugs in metadata: ", length(slugs_by_geo(meta_df, "other")))
        println("Other slugs found in df: ", length(other_slugs))
        println("min_present_obs:         ", min_present_obs)
        println("Sparse presence rows:    ", nrow(out))
        if nrow(out) > 0
            println("Example present rows:")
            println(first(out, min(10, nrow(out))))
        end
        println("="^72 * "\n")
    end

    return out
end


# ==============================================================================
# STEP 3A: MEMBERSHIP TOPOLOGY CLUSTERING (Other slugs)
# ==============================================================================

"""
Build a sparse binary matrix X with rows = Other slugs, cols = (country,period) cells.

Inputs:
- presence_df: output of build_other_slug_presence_df (sparse, only present rows)
    columns: slug::String, ident_ccode::Int, period::String, nonmissing_obs::Int

Outputs:
- X::SparseMatrixCSC{Float64,Int}   (binary 0/1)
- slug_index::Vector{String}        (row -> slug)
- cell_index::Vector{Tuple{Int,String}}  (col -> (ident_ccode, period))
"""
function build_slug_cell_matrix(presence_df::AbstractDataFrame; verbose::Bool=true)
    @assert all(Symbol.(["slug","ident_ccode","period"]) .∈ Ref(propertynames(presence_df))) "presence_df missing required columns"

    # Stable row index: slugs sorted
    slugs = sort!(unique(String.(presence_df.slug)))
    slug_to_i = Dict{String,Int}(s => i for (i,s) in enumerate(slugs))

    # Stable col index: cells sorted by (ccode, period)
    cells = unique([(Int(r.ident_ccode), String(r.period)) for r in eachrow(presence_df)])
    sort!(cells, by = x -> (x[1], x[2]))
    cell_to_j = Dict{Tuple{Int,String},Int}(c => j for (j,c) in enumerate(cells))

    # Build sparse triplets
    I = Int[]
    J = Int[]
    V = Float64[]
    sizehint!(I, nrow(presence_df))
    sizehint!(J, nrow(presence_df))
    sizehint!(V, nrow(presence_df))

    for r in eachrow(presence_df)
        i = slug_to_i[String(r.slug)]
        j = cell_to_j[(Int(r.ident_ccode), String(r.period))]
        push!(I, i); push!(J, j); push!(V, 1.0)
    end

    # NOTE: requires `using SparseArrays`
    X = sparse(I, J, V, length(slugs), length(cells))

    if verbose
        n_slugs = size(X,1)
        n_cells = size(X,2)
        nnzX    = nnz(X)
        dens    = nnzX / (n_slugs * n_cells)

        # Row and column nnz distributions (cheap enough at this size)
        row_counts = vec(sum(X .!= 0.0, dims=2))
        col_counts = vec(sum(X .!= 0.0, dims=1))

        println("\n" * "="^72)
        println("Step 3A — Membership topology matrix build")
        println("="^72)
        println("Input presence rows: ", nrow(presence_df))
        println("Unique Other slugs:  ", n_slugs)
        println("Unique cells:        ", n_cells, "  (country,period)")
        println("nnz(X):              ", nnzX)
        println("Density:             ", round(dens * 100, digits=4), "%")

        # Prevalence summaries
        println("\nSlug prevalence (#cells present):")
        println("  min/median/max: ", minimum(row_counts), " / ",
                               Int(round(median(row_counts))), " / ",
                               maximum(row_counts))

        println("Cell load (#slugs present):")
        println("  min/median/max: ", minimum(col_counts), " / ",
                               Int(round(median(col_counts))), " / ",
                               maximum(col_counts))

        # Examples
        println("\nExample slugs: ", join(slugs[1:min(end,10)], ", "))
        println("Example cells: ", join(string.(cells[1:min(end,10)]), ", "))
        println("="^72 * "\n")
    end

    return X, slugs, cells
end


"""
Compute cosine-similarity top-k neighbor edges between slugs using sparse dot products.

Method:
- Normalize rows by L2 norm
- Similarity = dot(normalized_row_i, normalized_row_j)
- For each i, keep the top-k j with similarity >= min_sim

Outputs:
- edges_df: DataFrame with columns:
    slug_i, slug_j, sim

Notes:
- This is O(nnz) per row using sparse row access; still heavy at 1k+ slugs,
  but feasible if you keep k small (10-30).
"""
function cosine_topk_edges(
    X::SparseMatrixCSC{Float64,Int},
    slug_index::Vector{String};
    k::Int = 20,
    min_sim::Float64 = 0.0,
    verbose::Bool = true
)::DataFrame
    n = size(X, 1)
    @assert n == length(slug_index)

    # L2 norms for each row (slug)
    norms = Vector{Float64}(undef, n)
    for i in 1:n
        # sparse row extraction via view on transpose
        # (CSC is column-oriented; rows are cheap on Xt = X')
        # We'll compute norms via sum of squares of row nonzeros.
        norms[i] = 0.0
    end

    Xt = transpose(X) # still sparse
    # Compute row norms by iterating nonzeros in X (CSC columns)
    # Accumulate squares into norms[row]
    for col in 1:size(X,2)
        for ptr in X.colptr[col]:(X.colptr[col+1]-1)
            row = X.rowval[ptr]
            v   = X.nzval[ptr]
            norms[row] += v*v
        end
    end
    for i in 1:n
        norms[i] = sqrt(norms[i])
    end

    # Precompute normalized X as a lazy operation: similarity uses dot / (ni*nj)
    # We'll compute candidates via column overlaps: for each slug i, build a map of dot products.
    out_i = String[]
    out_j = String[]
    out_s = Float64[]

    # Build row-wise nonzero lists using Xt (columns are rows of X)
    # row_nz_cols[i] gives the list of columns where X[i, col] != 0
    row_nz_cols = Vector{Vector{Int}}(undef, n)
    for i in 1:n
        row_nz_cols[i] = Int[]
    end
    for j in 1:size(X,2)
        for ptr in X.colptr[j]:(X.colptr[j+1]-1)
            i = X.rowval[ptr]
            push!(row_nz_cols[i], j)
        end
    end

    if verbose
        println("\n" * "="^72)
        println("Step 3A — Membership topology (cosine top-k edges)")
        println("="^72)
        println("Slugs (rows): ", n)
        println("Cells (cols): ", size(X,2))
        println("Requested k:   ", k)
        println("min_sim:       ", min_sim)
        println("="^72)
    end

    # For each slug i, accumulate dot products to other slugs via shared columns.
    # We do: for each column where i is present, iterate all slugs present in that column.
    # To support this, build col -> slugs list once (from CSC structure).
    col_slugs = Vector{Vector{Int}}(undef, size(X,2))
    for col in 1:size(X,2)
        sl = Int[]
        for ptr in X.colptr[col]:(X.colptr[col+1]-1)
            push!(sl, X.rowval[ptr])
        end
        col_slugs[col] = sl
    end

    for i in 1:n
        ni = norms[i]
        if ni == 0.0
            continue
        end

        acc = Dict{Int,Float64}()

        for col in row_nz_cols[i]
            for j in col_slugs[col]
                j == i && continue
                acc[j] = get(acc, j, 0.0) + 1.0  # since binary, dot += 1 per shared cell
            end
        end

        # Convert dot -> cosine and select top-k
        sims = Tuple{Int,Float64}[]
        for (j, dotv) in acc
            nj = norms[j]
            nj == 0.0 && continue
            s = dotv / (ni * nj)
            s >= min_sim && push!(sims, (j, s))
        end

        if !isempty(sims)
            sort!(sims, by = x -> -x[2])
            take = sims[1:min(k, length(sims))]
            for (j, s) in take
                push!(out_i, slug_index[i])
                push!(out_j, slug_index[j])
                push!(out_s, s)
            end
        end
    end

    edges_df = DataFrame(slug_i = out_i, slug_j = out_j, sim = out_s)

    if verbose
        println("Edges produced (directed top-k): ", nrow(edges_df))
        if nrow(edges_df) > 0
            println("Example edges:")
            println(first(edges_df, min(10, nrow(edges_df))))
        end
        println("="^72 * "\n")
    end

    return edges_df
end

"""
Symmetrize directed top-k edges into an undirected edge list, then print diagnostics.

Inputs:
- edges_df: DataFrame(slug_i, slug_j, sim) from cosine_topk_edges

Outputs:
- und_edges: DataFrame(slug_a, slug_b, weight)
"""
function symmetrize_edges(edges_df::AbstractDataFrame; mode::Symbol = :max, verbose::Bool=true)
    @assert all(Symbol.(["slug_i","slug_j","sim"]) .∈ Ref(propertynames(edges_df)))

    acc = Dict{Tuple{String,String}, Vector{Float64}}()
    for r in eachrow(edges_df)
        a = String(r.slug_i); b = String(r.slug_j)
        (a == b) && continue
        p = a < b ? (a,b) : (b,a)
        if !haskey(acc, p)
            acc[p] = Float64[]
        end
        push!(acc[p], Float64(r.sim))
    end

    out_a = String[]; out_b = String[]; out_w = Float64[]; out_n = Int[]
    for (p, vals) in acc
        w = mode == :mean ? mean(vals) : maximum(vals)
        push!(out_a, p[1]); push!(out_b, p[2]); push!(out_w, w); push!(out_n, length(vals))
    end

    und = DataFrame(slug_a = out_a, slug_b = out_b, weight = out_w, n_dir = out_n)

    if verbose
        println("\n" * "="^72)
        println("Step 3A — Symmetrize top-k edges (undirected graph)")
        println("="^72)
        println("Directed edges in:   ", nrow(edges_df))
        println("Undirected edges out:", nrow(und))
        println("Mode:                ", String(mode))
        println("Reciprocal edges (%):", round(100 * mean(und.n_dir .== 2), digits=2))
        println("Weight min/med/max:  ",
            round(minimum(und.weight), digits=4), " / ",
            round(median(und.weight), digits=4), " / ",
            round(maximum(und.weight), digits=4)
        )
        println("Example undirected edges:")
        println(first(und, min(10, nrow(und))))
        println("="^72 * "\n")
    end

    return und
end

"""
Build graph from undirected slug edges and print connectivity diagnostics.

Inputs:
    edges_und: DataFrame with columns
        slug_a, slug_b, weight

Outputs:
    g      : Graphs.jl SimpleGraph
    slugs  : index -> slug mapping
    comps  : connected components (vectors of node indices)
"""
function graph_components_diagnostics(edges_und; verbose=true)

    @assert all(Symbol.(["slug_a","slug_b"]) .∈ Ref(propertynames(edges_und)))

    # ---- build node index ----
    slugs = sort(unique(vcat(edges_und.slug_a, edges_und.slug_b)))
    slug_to_idx = Dict(s => i for (i, s) in enumerate(slugs))

    g = SimpleGraph(length(slugs))

    for r in eachrow(edges_und)
        u = slug_to_idx[r.slug_a]
        v = slug_to_idx[r.slug_b]
        u != v && add_edge!(g, u, v)
    end

    comps = connected_components(g)
    sizes = sort(map(length, comps))

    if verbose
        println("\n" * "="^72)
        println("Step 3A — Graph connectivity diagnostics")
        println("="^72)
        println("Nodes: ", nv(g))
        println("Edges: ", ne(g))
        println("Connected components: ", length(comps))
        println("Component size min/med/max: ",
                minimum(sizes), " / ",
                Int(round(median(sizes))), " / ",
                maximum(sizes))
        println("Largest component share (%): ",
                round(100 * maximum(sizes) / nv(g), digits=2))
        println("="^72 * "\n")
    end

    return g, slugs, comps
end

"""
Convert graph connected components from index space into slug lists.

Inputs
------
comps:
    Output of `Graphs.connected_components(g)`, i.e. a vector of
    vectors of vertex indices, where each inner vector represents one
    connected component.

slugs_g:
    Vector mapping vertex index → slug identifier. Typically this is
    the slug ordering used when constructing the graph.

Behavior
--------
Each component is converted from integer vertex indices into the
corresponding slug identifiers.

No reordering of components or members is performed; the structure
returned by `connected_components` is preserved.

Returns
-------
Vector{Vector{String}}

A vector where each element is the list of slugs belonging to one
connected component.

Notes
-----
• Component order is not guaranteed to be sorted by size.
• Slug ordering inside each component follows the index order returned
  by `connected_components`.
• Use `length.(result)` to inspect component sizes.

Example
-------
    g, slugs_g, comps = graph_components_diagnostics(edges_und)

    comp_slugs = component_slug_sets(comps, slugs_g)

    # sizes of components
    length.(comp_slugs)

"""
function component_slug_sets(comps, slugs_g)
    return [slugs_g[c] for c in comps]
end


"""
Build a SimpleWeightedGraph from an undirected slug edge list.

Inputs
------
edges_und:
    DataFrame with columns:
      slug_a::String, slug_b::String, weight::Float64

Behavior
--------
Creates a stable vertex ordering from the unique slug set, then constructs a
weighted undirected graph with those vertices. Edge weights are stored in the
graph.

Returns
-------
g_w::SimpleWeightedGraph
slugs_g::Vector{String}
    Vertex index -> slug mapping (1-based).
slug_to_idx::Dict{String,Int}
    Slug -> vertex index mapping.
"""
function build_weighted_slug_graph(edges_und::AbstractDataFrame)
    @assert all(Symbol.(["slug_a","slug_b","weight"]) .∈ Ref(propertynames(edges_und)))

    slugs_g = sort(unique(vcat(String.(edges_und.slug_a), String.(edges_und.slug_b))))
    slug_to_idx = Dict(s => i for (i, s) in enumerate(slugs_g))

    src = Vector{Int}(undef, nrow(edges_und))
    dst = Vector{Int}(undef, nrow(edges_und))
    wts = Vector{Float64}(undef, nrow(edges_und))

    for (k, r) in enumerate(eachrow(edges_und))
        src[k] = slug_to_idx[String(r.slug_a)]
        dst[k] = slug_to_idx[String(r.slug_b)]
        wts[k] = Float64(r.weight)
    end

    # Build weighted graph in one go (fast path).
    g_w = SimpleWeightedGraph(src, dst, wts)

    return g_w, slugs_g, slug_to_idx
end



"""
Constructs a cluster × (country, period) presence table from slug presence data.

Pipeline role:
- Step 4A (Interpretation): convert slug-level presence rows into a cluster-level
  footprint across (ident_ccode, period), with intensity measures.

Process:
1) Join `presence_df` with `slug_cluster_df` on :slug.
2) Aggregate by (:cluster_id, :ident_ccode, :period):
   - present_slugs = count of present slug-rows in that cell
   - present_obs   = sum(nonmissing_obs) in that cell
3) Add cluster sizes and compute present_slug_share.

Usage:
    cluster_presence_df, audit = cluster_presence(presence_df, slug_cluster_df)

Returns:
- cluster_presence_df::DataFrame with columns:
    :cluster_id, :ident_ccode, :period,
    :present_slugs, :present_obs,
    :cluster_slug_count, :present_slug_share
- audit::NamedTuple diagnostics

Arguments:
- presence_df::DataFrame: must contain :slug, :ident_ccode, :period, :nonmissing_obs
  (only “present” rows should exist, per your sparse rule)
- slug_cluster_df::DataFrame: must contain :slug, :cluster_id

Audit fields:
- n_presence_rows
- n_cluster_rows
- n_join_rows
- n_missing_cluster_id
- n_cells (unique (cluster,country,period))
- min_cluster_size, max_cluster_size

Notes:
- If any slugs lack cluster IDs, this function errors (by design).
"""
function cluster_presence(presence_df::DataFrame, slug_cluster_df::DataFrame)
    # cluster sizes
    cluster_sizes_df = combine(groupby(slug_cluster_df, :cluster_id),
                              nrow => :cluster_slug_count)

    # join slug -> cluster
    cp = leftjoin(presence_df, slug_cluster_df, on=:slug)

    n_missing_cluster = sum(ismissing.(cp.cluster_id))
    if n_missing_cluster > 0
        bad = unique(cp[ismissing.(cp.cluster_id), :slug])
        error("cluster_presence: $(n_missing_cluster) rows missing cluster_id after join. Example slugs: $(first(bad, min(length(bad), 10)))")
    end

    # aggregate per cluster-cell
    cluster_presence_df =
        combine(groupby(cp, [:cluster_id, :ident_ccode, :period]),
                nrow => :present_slugs,
                :nonmissing_obs => sum => :present_obs)

    # add cluster size and normalized intensity
    cluster_presence_df = leftjoin(cluster_presence_df, cluster_sizes_df, on=:cluster_id)
    cluster_presence_df[!, :present_slug_share] =
        cluster_presence_df.present_slugs ./ cluster_presence_df.cluster_slug_count

    # audit
    sizes = cluster_sizes_df.cluster_slug_count
    audit = (n_presence_rows = nrow(presence_df),
             n_cluster_rows = nrow(slug_cluster_df),
             n_join_rows = nrow(cp),
             n_missing_cluster_id = n_missing_cluster,
             n_cells = nrow(cluster_presence_df),
             min_cluster_size = isempty(sizes) ? missing : minimum(sizes),
             max_cluster_size = isempty(sizes) ? missing : maximum(sizes))

    return cluster_presence_df, audit
end

"""
Attaches missingness environment and anchor summaries to cluster presence cells.

Pipeline role:
- Step 4B (Interpretation): enrich cluster footprint cells with:
  - country-period environment (miss_global, miss_regional)
  - anchor dynamics (log_pop_level/change, log_gdp_level/change, dem_share/change)

Process:
1) leftjoin(cluster_presence_df, miss_df) on (:ident_ccode, :period)
2) leftjoin(result, anchors_df) on (:ident_ccode, :period)

Usage:
    enriched_df, audit = attach_environment_and_anchors(cluster_presence_df, miss_df, anchors_df)

Returns:
- enriched_df::DataFrame: cluster_presence_df plus miss_df and anchors_df columns
- audit::NamedTuple diagnostics

Arguments:
- cluster_presence_df::DataFrame: must contain :ident_ccode, :period
- miss_df::DataFrame: must contain :ident_ccode, :period, :miss_global, :miss_regional
- anchors_df::DataFrame: must contain :ident_ccode, :period plus anchor columns:
  :log_pop_level, :log_pop_change, :log_gdp_level, :log_gdp_change, :dem_share, :dem_change

Audit fields:
- n_in, n_after_miss, n_after_anchors
- miss_dup_keys, anchors_dup_keys
- missing_counts (for key joined columns)

Notes:
- If row counts increase after joins, investigate duplicate keys in miss_df / anchors_df.
"""
function attach_environment_and_anchors(cluster_presence_df::DataFrame,
                                        miss_df::DataFrame,
                                        anchors_df::DataFrame)

    miss_dup = _count_duplicate_keys(miss_df, [:ident_ccode, :period])
    anch_dup = _count_duplicate_keys(anchors_df, [:ident_ccode, :period])

    x = leftjoin(cluster_presence_df, miss_df, on=[:ident_ccode, :period])
    y = leftjoin(x, anchors_df, on=[:ident_ccode, :period])

    # Schema presence check (robust to names() returning strings)
    cols_y = Set(Symbol.(names(y)))
    expected = Symbol[
        :miss_global, :miss_regional,
        :log_pop_level, :log_pop_change,
        :log_gdp_level, :log_gdp_change,
        :dem_share, :dem_change
    ]
    expected_present = Dict(s => (s in cols_y) for s in expected)

    # Focused missingness diagnostics (signal columns)
    cols_check = Symbol[:miss_global, :miss_regional, :log_pop_level, :log_gdp_level, :dem_share]
    mc = _missing_counts(y, cols_check)

    n = nrow(y)
    mr = (;
        (c => (mc[c] == -1 ? missing : mc[c] / n) for c in cols_check)...
    )

    key_types = (;
        ident_ccode = eltype(cluster_presence_df.ident_ccode),
        period = eltype(cluster_presence_df.period),
        miss_ident_ccode = eltype(miss_df.ident_ccode),
        miss_period = eltype(miss_df.period),
        anchors_ident_ccode = eltype(anchors_df.ident_ccode),
        anchors_period = eltype(anchors_df.period)
    )

    audit = (n_in = nrow(cluster_presence_df),
             n_after_miss = nrow(x),
             n_after_anchors = nrow(y),
             miss_dup_keys = miss_dup,
             anchors_dup_keys = anch_dup,
             expected_present = expected_present,
             missing_counts = mc,
             missing_rates = mr,
             key_types = key_types)

    return y, audit
end

"""
Computes per-cluster summary statistics for interpretation.

Pipeline role:
- Step 4C (Interpretation): collapse cluster presence cells into per-cluster
  applicability + environment + anchor signature.

Required inputs:
- A cluster presence table enriched with environment and anchors (recommended),
  though the function will compute what it can based on available columns.

Usage:
    cluster_summary_df, audit = summarize_clusters(cluster_presence_enriched_df)

Returns:
- cluster_summary_df::DataFrame with columns (when available):
    :cluster_id
    :footprint_cells
    :n_countries
    :n_periods
    :mean_present_slugs
    :mean_present_slug_share
    :mean_miss_global, :mean_miss_regional, :median_miss_global, :median_miss_regional
    :mean_log_pop_level, :mean_log_pop_change
    :mean_log_gdp_level, :mean_log_gdp_change
    :mean_dem_share, :mean_dem_change
- audit::NamedTuple diagnostics

Arguments:
- x::DataFrame: must contain :cluster_id, :ident_ccode, :period,
  :present_slugs, :present_slug_share
  Optional: miss/anchor columns as above

Audit fields:
- n_clusters
- cluster_size_min, cluster_size_max (by footprint_cells)
"""
function summarize_clusters(x::DataFrame)
    g = groupby(x, :cluster_id)

    cluster_summary_df = combine(g,
        nrow => :footprint_cells,
        :ident_ccode => (v -> length(unique(v))) => :n_countries,
        :period => (v -> length(unique(v))) => :n_periods,
        :present_slugs => _safe_mean => :mean_present_slugs,
        :present_slug_share => _safe_mean => :mean_present_slug_share,

        # environment (if present)
        :miss_global => _safe_mean => :mean_miss_global,
        :miss_regional => _safe_mean => :mean_miss_regional,
        :miss_global => _safe_median => :median_miss_global,
        :miss_regional => _safe_median => :median_miss_regional,

        # anchors (if present)
        :log_pop_level => _safe_mean => :mean_log_pop_level,
        :log_pop_change => _safe_mean => :mean_log_pop_change,
        :log_gdp_level => _safe_mean => :mean_log_gdp_level,
        :log_gdp_change => _safe_mean => :mean_log_gdp_change,
        :dem_share => _safe_mean => :mean_dem_share,
        :dem_change => _safe_mean => :mean_dem_change
    )

    fp = cluster_summary_df.footprint_cells
    audit = (n_clusters = nrow(cluster_summary_df),
             cluster_size_min = isempty(fp) ? missing : minimum(fp),
             cluster_size_max = isempty(fp) ? missing : maximum(fp))

    return cluster_summary_df, audit
end

"""
Ranks countries within each cluster by footprint and mean intensity.

Pipeline role:
- Step 4D (Interpretation): for each cluster, show where it “lives” geographically.

Computes per (cluster, ident_ccode):
- country_cells: number of (country,period) cells where cluster is present
- mean_slug_share: mean present_slug_share across those cells (intensity proxy)

Usage:
    top_countries_df, audit = top_countries_by_cluster(enriched_df; topn=15)

Returns:
- top_countries_df::DataFrame with columns:
    :cluster_id, :ident_ccode, :country_cells, :mean_slug_share
  containing top `topn` rows per cluster (or fewer if small).
- audit::NamedTuple diagnostics

Arguments:
- x::DataFrame: must contain :cluster_id, :ident_ccode, :present_slug_share
- topn::Int=15: number of top countries to keep per cluster

Audit fields:
- n_rows_in
- n_rows_out
- topn
"""
function top_countries_by_cluster(x::DataFrame; topn::Int=15)
    t = combine(groupby(x, [:cluster_id, :ident_ccode]),
                nrow => :country_cells,
                :present_slug_share => (v -> mean(skipmissing(v))) => :mean_slug_share)

    sort!(t, [:cluster_id, :country_cells, :mean_slug_share], rev=true)

    top_countries_df = combine(groupby(t, :cluster_id)) do sdf
        first(sdf, min(topn, nrow(sdf)))
    end

    audit = (n_rows_in = nrow(x),
             n_rows_out = nrow(top_countries_df),
             topn = topn)

    return top_countries_df, audit
end

"""
Computes period coverage and mean intensity per cluster.

Pipeline role:
- Step 4D (Interpretation): show temporal signature of each cluster across fixed periods.

Computes per (cluster, period):
- cells: number of (country,period) cells where cluster is present
- mean_slug_share: mean present_slug_share within that period

Usage:
    period_cov_df, audit = period_coverage_by_cluster(enriched_df)

Returns:
- period_cov_df::DataFrame with columns:
    :cluster_id, :period, :cells, :mean_slug_share
- audit::NamedTuple diagnostics

Arguments:
- x::DataFrame: must contain :cluster_id, :period, :present_slug_share

Audit fields:
- n_rows_in
- n_rows_out
- n_clusters
- n_periods
"""
function period_coverage_by_cluster(x::DataFrame)
    t = combine(groupby(x, [:cluster_id, :period]),
                nrow => :cells,
                :present_slug_share => (v -> mean(skipmissing(v))) => :mean_slug_share)

    sort!(t, [:cluster_id, :period])

    audit = (n_rows_in = nrow(x),
             n_rows_out = nrow(t),
             n_clusters = length(unique(t.cluster_id)),
             n_periods = length(unique(t.period)))

    return t, audit
end


"""
Audits join coverage for environment and anchors against cluster presence.

Performs left joins of `cluster_presence_df` with:
1) `miss_df` on (:ident_ccode, :period)
2) `anchors_df` on (:ident_ccode, :period)

and returns counts of missing join results. Also detects duplicate key rows
in the right-side tables, which can cause row-explosion in joins.

Usage:
    audit = join_audit(cluster_presence_df, miss_df, anchors_df)

Returns:
- NamedTuple with:
    miss_missing::Int        # rows lacking miss_df match (via miss_global missing)
    miss_total::Int          # total rows after joining miss_df (should equal nrow(cluster_presence_df) unless miss_df has dup keys)
    anchors_missing::Int     # rows lacking anchors_df match (via log_pop_level missing)
    anchors_total::Int       # total rows after joining anchors_df
    miss_dup_keys::Int       # duplicate key rows in miss_df for (ident_ccode, period)
    anchors_dup_keys::Int    # duplicate key rows in anchors_df for (ident_ccode, period)

Arguments:
- cluster_presence_df::DataFrame: must contain :ident_ccode, :period
- miss_df::DataFrame: must contain :ident_ccode, :period, :miss_global
- anchors_df::DataFrame: must contain :ident_ccode, :period, :log_pop_level

Notes:
- This audit assumes :miss_global and :log_pop_level are the primary “match signals”.
  If those can be missing even when matched, replace with a stricter match test.
"""
function join_audit(cluster_presence_df::DataFrame,
                    miss_df::DataFrame,
                    anchors_df::DataFrame)

    miss_dup = _count_duplicate_keys(miss_df, [:ident_ccode, :period])
    anch_dup = _count_duplicate_keys(anchors_df, [:ident_ccode, :period])

    x = leftjoin(cluster_presence_df, miss_df, on=[:ident_ccode, :period])
    y = leftjoin(cluster_presence_df, anchors_df, on=[:ident_ccode, :period])

    miss_missing = (:miss_global ∈ names(x)) ? sum(ismissing.(x.miss_global)) : -1
    anch_missing = (:log_pop_level ∈ names(y)) ? sum(ismissing.(y.log_pop_level)) : -1

    return (miss_missing = miss_missing,
            miss_total = nrow(x),
            anchors_missing = anch_missing,
            anchors_total = nrow(y),
            miss_dup_keys = miss_dup,
            anchors_dup_keys = anch_dup)
end

"""
Counts duplicate key rows in df for a given set of join keys.

Usage:
    ndup = _count_duplicate_keys(df, [:ident_ccode, :period])
Returns:
- Int: Number of rows that are duplicates beyond the first occurrence per key

Arguments:
- df::DataFrame
- keys::Vector{Symbol}
"""
function _count_duplicate_keys(df::DataFrame, keys::Vector{Symbol})
    isempty(df) && return 0
    g = groupby(df, keys)
    return sum(max(0, nrow(sdf) - 1) for sdf in g)
end

"""
Returns a compact missingness count for selected columns.

Usage:
    m = _missing_counts(df, [:miss_global, :log_pop_level])
Returns:
- NamedTuple: (col => n_missing, ...)

Arguments:
- df::DataFrame
- cols::Vector{Symbol}
"""
function _missing_counts(df::DataFrame, cols::Vector{Symbol})
    dfcols = Set(Symbol.(names(df)))  # normalize
    out = Dict{Symbol, Int}()

    for c in cols
        if c in dfcols
            out[c] = sum(ismissing.(df[!, c]))
        else
            out[c] = -1
        end
    end

    return (; out...)
end


"""
Safe mean over a vector that may be all-missing.
Returns `missing` if there are no non-missing values.
"""
_safe_mean(v) = begin
    w = collect(skipmissing(v))
    isempty(w) ? missing : mean(w)
end

"""
Safe median over a vector that may be all-missing.
Returns `missing` if there are no non-missing values.
"""
_safe_median(v) = begin
    w = collect(skipmissing(v))
    isempty(w) ? missing : median(w)
end