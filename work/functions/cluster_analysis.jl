include("qog_augmented_standard.jl")

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
    run_cluster_samples()
Returns:
- Nothing (prints to console)
"""
function run_cluster_samples()
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
    println("  TYPICAL WORKFLOW (Step 1):")
    println("  1. df, meta = load_dataframes()")
    println("  2. country_features_df, audit = build_country_features_df(df, meta)")
    println("  3. check_country_features_qa(df, country_features_df)")
    println("  4. first(country_features_df, 5)")
    println("  5. kept, rejected, report = filter_slugs_step2(country_features_df, meta; df_panel=df)")
    println("  6. (Step 3+: rank features, cluster, inspect, update metadata)")
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
