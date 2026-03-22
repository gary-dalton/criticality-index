# ==============================================================================
# COUNTRY MISSINGNESS SCORING (TEMPORAL)
# ==============================================================================
#
# Scores each (country, year) by global slug coverage relative to
# subregion peers. Classifies country-years as dissolved, microstate,
# failed, degraded, reporting, or strong. Output keyed by ggis_rowid.
#
# Dependency: qog_augmented_standard.jl (loaded via load_phase0.jl)
#
# ==============================================================================

using DataFrames, CSV, Statistics

# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Known dissolved states: ccode => (name, dissolution_year)."""
const CM_DISSOLVED_STATES = Dict{Int, NamedTuple{(:name, :year), Tuple{String, Int}}}(
    278  => (name="DDR", year=1990),
    200  => (name="Czechoslovakia", year=1992),
    891  => (name="Yugoslavia", year=1992),
    810  => (name="USSR", year=1991),
    720  => (name="Yemen Democratic", year=1990),
    9156 => (name="Tibet", year=1959),
)

"""Years before dissolution where data starts degrading (catch the decline period)."""
const CM_DISSOLUTION_LAG = 5

"""Years after a country's birth_year to classify as nascent (newly independent, building data infrastructure)."""
const CM_NASCENT_YEARS = 5

"""Population below this = microstate (excluded from peer comparisons). wpp_pop is in thousands."""
const CM_MICROSTATE_POP_THRESHOLD = 100  # 100 thousand = 100,000 people

"""Recent years with expected incomplete reporting (lag artifact, not signal)."""
const CM_REPORTING_LAG_YEARS = 4

"""Coverage below this AND deviation below FAILED_DEVIATION = failed."""
const CM_FAILED_THRESHOLD = 0.40

"""Deviation below subregion peer average to flag as failed."""
const CM_FAILED_DEVIATION = -0.20

"""Coverage drop from rolling window to flag as degraded."""
const CM_DEGRADED_DROP = 0.15

"""Rolling window size for degradation detection."""
const CM_ROLLING_WINDOW = 3


# ==============================================================================
# STEP 0: COUNTRY TEMPORAL PROFILES
# ==============================================================================

"""
Build temporal profiles for each country.

Arguments:
- df::DataFrame: Augmented QoG timeseries (must have :ident_ccode, :ident_year, :wpp_pop, :ggis_un_subregion_code)

Returns:
- DataFrame with one row per country: ccode, alpha, name, country_birth_year, country_death_year,
  n_years, year_span, is_active, is_dissolved, dissolution_year, is_microstate, max_pop, un_subregion_code
"""
function build_country_profiles(df::DataFrame; verbose::Bool = true)
    df_valid = filter(r -> !ismissing(r.ident_ccode) && !ismissing(r.ident_year), df)
    g = groupby(df_valid, :ident_ccode)

    data_end = Int(maximum(skipmissing(df.ident_year)))
    current_year = data_end - CM_REPORTING_LAG_YEARS

    rows = []
    for sdf in g
        ccode = Int(first(sdf.ident_ccode))
        alpha = string(first(sdf.ident_ccodealp))
        name = string(first(sdf.ident_cname))
        years = Int.(sdf.ident_year)

        birth = minimum(years)
        death = maximum(years)
        n_years = length(years)
        span = death - birth + 1

        # Active: last data within lag window of current year
        is_active = death >= current_year

        # Dissolved
        dissolved_info = get(CM_DISSOLVED_STATES, ccode, nothing)
        is_dissolved = dissolved_info !== nothing && death <= dissolved_info.year + CM_DISSOLUTION_LAG
        dissolution_year = dissolved_info !== nothing ? dissolved_info.year : missing

        # Microstate: peak population
        pop_vals = collect(skipmissing(sdf.wpp_pop))
        max_pop = isempty(pop_vals) ? missing : maximum(pop_vals)
        is_microstate = !ismissing(max_pop) && max_pop < CM_MICROSTATE_POP_THRESHOLD

        # Collision: does this country have spine collision rows?
        has_collision = :ggis_spine_collision in propertynames(sdf) && any(coalesce.(sdf.ggis_spine_collision, false))
        # Collision years
        collision_years = if has_collision
            Int.(sdf[coalesce.(sdf.ggis_spine_collision, false), :ident_year])
        else
            Int[]
        end

        # Subregion
        un_sub = first(sdf.ggis_un_subregion_code)

        push!(rows, (
            ident_ccode = ccode,
            ident_ccodealp = alpha,
            ident_cname = name,
            country_birth_year = birth,
            country_death_year = death,
            n_years = n_years,
            year_span = span,
            is_active = is_active,
            is_dissolved = is_dissolved,
            dissolution_year = dissolution_year,
            is_microstate = is_microstate,
            max_pop = max_pop,
            has_collision = has_collision,
            collision_years = collision_years,
            un_subregion_code = un_sub,
        ))
    end

    profiles = DataFrame(rows)
    sort!(profiles, :ident_ccode)

    if verbose
        println("=" ^ 72)
        println("Step 0 — Country Temporal Profiles")
        println("=" ^ 72)
        println("    Total countries: $(nrow(profiles))")
        println("    Active: $(count(profiles.is_active))")
        println("    Dissolved: $(count(profiles.is_dissolved))")
        dissolved = filter(r -> r.is_dissolved, profiles)
        for r in eachrow(dissolved)
            println("      $(r.ident_ccodealp) $(r.ident_cname) (dissolved $(r.dissolution_year), last data $(r.country_death_year))")
        end
        println("    Microstates: $(count(profiles.is_microstate))")
        micros = filter(r -> r.is_microstate, profiles)
        for r in eachrow(micros)
            pop_str = ismissing(r.max_pop) ? "?" : "$(Int(round(r.max_pop/1000)))K"
            println("      $(r.ident_ccodealp) $(r.ident_cname) (pop $pop_str)")
        end
        println("=" ^ 72)
    end

    return profiles
end


# ==============================================================================
# STEP 1: PER-COUNTRY, PER-YEAR GLOBAL SLUG COVERAGE
# ==============================================================================

"""
Score each (country, year) by global slug coverage relative to subregion peers.

Arguments:
- df::DataFrame: Augmented QoG timeseries
- meta_df::DataFrame: Metadata with :slug and :ggis_geo_classification
- profiles_df::DataFrame: Country profiles from build_country_profiles()

Returns:
- DataFrame: ident_ccode, ident_year, n_global_present, n_global_total,
  global_coverage_pct, subregion_peer_avg, peer_deviation, lag_affected
"""
function score_country_missingness(
    df::DataFrame,
    meta_df::DataFrame,
    profiles_df::DataFrame;
    verbose::Bool = true
)
    # Identify global slugs that exist as columns
    global_slugs = filter(r -> coalesce(r.ggis_geo_classification == "global", false), meta_df).slug
    df_cols = Set(string.(propertynames(df)))
    valid_global = String[s for s in global_slugs if s in df_cols]
    n_global = length(valid_global)

    data_end = Int(maximum(skipmissing(df.ident_year)))

    # Build ccode → subregion lookup
    ccode_to_sub = Dict{Int, Int}()
    for r in eachrow(profiles_df)
        ccode_to_sub[r.ident_ccode] = r.un_subregion_code
    end

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 1 — Per-Country, Per-Year Global Slug Coverage")
        println("=" ^ 72)
        println("    Global slugs in data: $n_global")
        println("    Computing coverage for each (country, year)...")
    end

    # For each (country, year): count non-missing global slugs
    df_valid = filter(r -> !ismissing(r.ident_ccode) && !ismissing(r.ident_year), df)
    g = groupby(df_valid, [:ident_ccode, :ident_year])

    out_ccode = Int[]
    out_year = Int[]
    out_present = Int[]

    for sdf in g
        ccode = Int(first(sdf.ident_ccode))
        year = Int(first(sdf.ident_year))
        n_present = 0
        for s in valid_global
            if !ismissing(sdf[1, Symbol(s)])
                n_present += 1
            end
        end
        push!(out_ccode, ccode)
        push!(out_year, year)
        push!(out_present, n_present)
    end

    scores = DataFrame(
        ident_ccode = out_ccode,
        ident_year = out_year,
        n_global_present = out_present,
    )
    scores.n_global_total .= n_global
    scores.global_coverage_pct = scores.n_global_present ./ n_global

    # Add subregion
    scores.un_subregion_code = [get(ccode_to_sub, c, 0) for c in scores.ident_ccode]

    # Compute subregion peer averages per year
    peer_avgs = combine(
        groupby(scores, [:un_subregion_code, :ident_year]),
        :global_coverage_pct => mean => :subregion_peer_avg
    )
    scores = leftjoin(scores, peer_avgs, on=[:un_subregion_code, :ident_year])

    # Peer deviation
    scores.peer_deviation = scores.global_coverage_pct .- scores.subregion_peer_avg

    # Lag flag
    scores.lag_affected = scores.ident_year .> (data_end - CM_REPORTING_LAG_YEARS)

    if verbose
        println("    Scored $(nrow(scores)) (country, year) pairs")
        println("    Lag-affected years: $(count(scores.lag_affected))")
        println("=" ^ 72)
    end

    return scores
end


# ==============================================================================
# STEP 2: COUNTRY-YEAR STATUS CLASSIFICATION
# ==============================================================================

"""
Classify each (country, year) as dissolved, nascent, collision, microstate, failed, degraded, reporting, or strong.

Arguments:
- profiles_df::DataFrame: Country profiles (with has_collision, collision_years)
- scores_df::DataFrame: Missingness scores from Step 1

Returns:
- DataFrame with ident_ccode, ident_year, country_status

Status priority order:
1. dissolved — known dissolved state, year >= dissolution_year - DISSOLUTION_LAG
2. nascent — country within first NASCENT_YEARS of its data (newly independent)
3. collision — year is a spine collision year (multiple entities sharing ccode)
4. microstate — population below threshold
5. failed — low coverage AND far below peers
6. degraded — coverage dropping in rolling window
7. reporting — normal
8. strong — above peer average
"""
function classify_country_status(
    profiles_df::DataFrame,
    scores_df::DataFrame;
    failed_threshold::Float64 = CM_FAILED_THRESHOLD,
    failed_deviation::Float64 = CM_FAILED_DEVIATION,
    degraded_drop::Float64 = CM_DEGRADED_DROP,
    rolling_window::Int = CM_ROLLING_WINDOW,
    nascent_years::Int = CM_NASCENT_YEARS,
    verbose::Bool = true
)
    # Build lookups
    profile_lookup = Dict{Int, NamedTuple}()
    for r in eachrow(profiles_df)
        profile_lookup[r.ident_ccode] = (
            is_dissolved = r.is_dissolved,
            dissolution_year = r.dissolution_year,
            is_microstate = r.is_microstate,
            birth = r.country_birth_year,
            has_collision = r.has_collision,
            collision_years = Set(r.collision_years),
        )
    end

    # Sort scores for rolling window computation
    sorted_scores = sort(scores_df, [:ident_ccode, :ident_year])
    country_groups = groupby(sorted_scores, :ident_ccode)

    statuses = String[]

    for sdf in country_groups
        ccode = Int(first(sdf.ident_ccode))
        prof = get(profile_lookup, ccode, nothing)
        covs = sdf.global_coverage_pct
        years = Int.(sdf.ident_year)
        n = length(years)

        for i in 1:n
            year = years[i]
            cov = covs[i]
            dev = sdf.peer_deviation[i]

            # 1. Dissolved: known dissolved state, from dissolution_year - lag onward
            #    Catches the pre-dissolution decline period too
            if prof !== nothing && prof.is_dissolved && !ismissing(prof.dissolution_year) &&
               year >= prof.dissolution_year - CM_DISSOLUTION_LAG
                push!(statuses, "dissolved")

            # 2. Nascent: first N years of a country's data (newly independent)
            elseif prof !== nothing && year < prof.birth + nascent_years
                push!(statuses, "nascent")

            # 3. Collision: year has multiple entities sharing this ccode
            elseif prof !== nothing && prof.has_collision && year in prof.collision_years
                push!(statuses, "collision")

            # 4. Microstate: population below threshold
            elseif prof !== nothing && prof.is_microstate
                push!(statuses, "microstate")

            # 5. Failed: low coverage AND far below peers
            elseif cov < failed_threshold && dev < failed_deviation
                push!(statuses, "failed")

            else
                # 6. Degraded: coverage dropping in rolling window AND peer deviation worsening
                #    Only flag as degraded if the drop is country-specific, not a global reporting lag.
                #    Check: own coverage dropping AND peer_deviation getting worse (more negative).
                is_degraded = false
                if i > rolling_window
                    current_start = max(1, i - rolling_window + 1)
                    current_avg = mean(covs[current_start:i])
                    prior_start = max(1, current_start - rolling_window)
                    prior_end = current_start - 1
                    if prior_end >= prior_start
                        prior_avg = mean(covs[prior_start:prior_end])
                        own_drop = prior_avg - current_avg

                        # Also check peer deviation trend
                        devs = sdf.peer_deviation
                        current_dev_avg = mean(devs[current_start:i])
                        prior_dev_avg = mean(devs[prior_start:prior_end])
                        dev_worsening = prior_dev_avg - current_dev_avg

                        # Degraded only if: own coverage dropped AND deviation worsened
                        # This filters out global reporting lag (where everyone drops equally)
                        if own_drop >= degraded_drop && dev_worsening >= degraded_drop / 2
                            is_degraded = true
                        end
                    end
                end

                if is_degraded
                    push!(statuses, "degraded")
                # 7/8. Strong vs reporting
                elseif dev >= 0
                    push!(statuses, "strong")
                else
                    push!(statuses, "reporting")
                end
            end
        end
    end

    result = copy(sorted_scores[:, [:ident_ccode, :ident_year, :global_coverage_pct, :peer_deviation, :lag_affected]])
    result.country_status = statuses

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 2 — Country-Year Status Classification")
        println("=" ^ 72)
        status_counts = combine(groupby(result, :country_status), nrow => :count)
        sort!(status_counts, :count, rev=true)
        for r in eachrow(status_counts)
            println("    $(rpad(r.country_status, 15)) $(r.count) country-years")
        end
        println("=" ^ 72)
    end

    return result
end


# ==============================================================================
# STEP 3: ROW-LEVEL FLAGS (KEYED BY ggis_rowid)
# ==============================================================================

"""
Join status classifications back to individual rows via ggis_rowid.

Arguments:
- df::DataFrame: Augmented QoG timeseries (must have :ggis_rowid, :ident_ccode, :ident_year)
- status_df::DataFrame: Classifications from Step 2

Returns:
- DataFrame with :ggis_rowid + flag columns

Usage:
    flags = build_missingness_flags(df, status_df)
    CSV.write("data/country_missingness_flags.csv", flags)
"""
function build_missingness_flags(df::DataFrame, status_df::DataFrame; verbose::Bool = true)
    # Select only the columns we need from df
    df_keys = select(filter(r -> !ismissing(r.ident_ccode), df), [:ggis_rowid, :ident_ccode, :ident_year])

    # Join on (ccode, year)
    flags = leftjoin(df_keys, status_df, on=[:ident_ccode, :ident_year])

    # Rename for ggis_ namespace
    rename!(flags, :country_status => :ggis_country_status)
    rename!(flags, :global_coverage_pct => :ggis_global_slug_coverage)
    rename!(flags, :peer_deviation => :ggis_peer_deviation)
    rename!(flags, :lag_affected => :ggis_lag_affected)

    # Keep only ggis_rowid + flag columns
    select!(flags, [:ggis_rowid, :ggis_country_status, :ggis_global_slug_coverage, :ggis_peer_deviation, :ggis_lag_affected])

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 3 — Row-Level Missingness Flags")
        println("=" ^ 72)
        println("    Rows flagged: $(nrow(flags))")
        println("    Missing status: $(count(ismissing, flags.ggis_country_status))")
        status_counts = combine(groupby(dropmissing(flags, :ggis_country_status), :ggis_country_status), nrow => :count)
        sort!(status_counts, :count, rev=true)
        for r in eachrow(status_counts)
            println("    $(rpad(r.ggis_country_status, 15)) $(r.count) rows")
        end
        println("=" ^ 72)
    end

    return flags
end


# ==============================================================================
# STEP 4: REVISED SLUG PENETRATION
# ==============================================================================

"""
Recalculate slug penetration using only reporting + strong countries as denominator.

Arguments:
- df::DataFrame: Augmented QoG timeseries
- meta_df::DataFrame: Metadata with :slug
- status_df::DataFrame: Country-year classifications

Returns:
- DataFrame with :slug, :original_penetration, :revised_penetration, :penetration_change
"""
function recalculate_slug_penetration(
    df::DataFrame,
    meta_df::DataFrame,
    status_df::DataFrame;
    verbose::Bool = true
)
    # Get the most recent non-lag year's status per country
    non_lag = filter(r -> !r.lag_affected, status_df)
    if nrow(non_lag) == 0
        non_lag = status_df
    end
    latest_year = maximum(non_lag.ident_year)
    latest_status = filter(r -> r.ident_year == latest_year, non_lag)

    # Denominator: reporting + strong countries
    good_countries = Set(filter(r -> r.country_status in ["reporting", "strong"], latest_status).ident_ccode)
    all_countries = Set(skipmissing(unique(df.ident_ccode)))
    n_all = length(all_countries)
    n_good = length(good_countries)

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 4 — Revised Slug Penetration")
        println("=" ^ 72)
        println("    Reference year: $latest_year")
        println("    All countries: $n_all")
        println("    Reporting + strong: $n_good")
        println("    Excluded: $(n_all - n_good)")
    end

    # For each slug: count countries with data (ever, any year)
    df_valid = filter(r -> !ismissing(r.ident_ccode), df)
    g = groupby(df_valid, :ident_ccode)

    slugs = String.(meta_df.slug)
    df_cols = Set(string.(propertynames(df)))
    valid_slugs = [s for s in slugs if s in df_cols]

    # Build slug → set of countries with data
    slug_countries = Dict{String, Set{Int}}()
    for s in valid_slugs
        slug_countries[s] = Set{Int}()
    end
    for sdf in g
        ccode = Int(first(sdf.ident_ccode))
        for s in valid_slugs
            if any(!ismissing, sdf[!, Symbol(s)])
                push!(slug_countries[s], ccode)
            end
        end
    end

    # Compute penetrations
    rows = []
    for s in valid_slugs
        countries_with_data = slug_countries[s]
        original = length(countries_with_data) / n_all
        good_with_data = length(intersect(countries_with_data, good_countries))
        revised = n_good > 0 ? good_with_data / n_good : 0.0
        push!(rows, (
            slug = s,
            original_penetration = round(original, digits=4),
            revised_penetration = round(revised, digits=4),
            penetration_change = round(revised - original, digits=4),
        ))
    end

    result = DataFrame(rows)
    sort!(result, :penetration_change, rev=true)

    if verbose
        # Show slugs that changed most
        big_gains = filter(r -> r.penetration_change >= 0.05, result)
        println("    Slugs gaining ≥5 ppt: $(nrow(big_gains))")
        for r in eachrow(first(big_gains, 10))
            println("      $(rpad(r.slug, 25)) $(round(r.original_penetration*100, digits=1))% → $(round(r.revised_penetration*100, digits=1))%")
        end
        println("=" ^ 72)
    end

    return result
end


# ==============================================================================
# ORCHESTRATION
# ==============================================================================

"""
Run the full country missingness pipeline.

Arguments:
- df::DataFrame: Augmented QoG timeseries
- meta_df::DataFrame: Metadata with ggis_geo_classification

Returns:
- NamedTuple with all pipeline outputs

Usage:
    df = load_augmented_or_build()
    meta_df = CSV.read("data/qog_metadata_plus2.csv", DataFrame)
    result = run_country_missingness(df, meta_df)
"""
function run_country_missingness(
    df::DataFrame,
    meta_df::DataFrame;
    verbose::Bool = true
)
    # Step 0
    profiles = build_country_profiles(df; verbose=verbose)

    # Step 1
    scores = score_country_missingness(df, meta_df, profiles; verbose=verbose)

    # Step 2
    status = classify_country_status(profiles, scores; verbose=verbose)

    # Step 3
    flags = build_missingness_flags(df, status; verbose=verbose)

    # Step 4
    penetration = recalculate_slug_penetration(df, meta_df, status; verbose=verbose)

    return (
        profiles = profiles,
        scores = scores,
        status = status,
        flags = flags,
        penetration = penetration,
    )
end


# ==============================================================================
# SAMPLES
# ==============================================================================

function run_country_missingness_samples()
    println("\n" * "=" ^ 72)
    println("  country_missingness.jl — Function intent and usage")
    println("=" ^ 72)
    println("""

    ┌─ build_country_profiles(df)
    │  Per-country birth/death year, dissolved/microstate flags.
    │  RETURNS: DataFrame (one row per country)
    └──────────────────────────────────────────────────────────────

    ┌─ score_country_missingness(df, meta_df, profiles_df)
    │  Per (country, year): global slug coverage + subregion peer deviation.
    │  RETURNS: DataFrame (one row per country-year)
    └──────────────────────────────────────────────────────────────

    ┌─ classify_country_status(profiles_df, scores_df)
    │  Labels each (country, year): dissolved, microstate, failed,
    │  degraded, reporting, strong.
    │  RETURNS: DataFrame with country_status column
    └──────────────────────────────────────────────────────────────

    ┌─ run_country_missingness(df, meta_df)
    │  Full pipeline: profiles → scores → classify → flags → penetration.
    │  RETURNS: NamedTuple with all outputs
    │
    │  USAGE:
    │    df = load_augmented_or_build()
    │    meta_df = CSV.read("data/qog_metadata_plus2.csv", DataFrame)
    │    result = run_country_missingness(df, meta_df)
    │    result.flags        # ggis_rowid-keyed status flags
    │    result.penetration  # revised slug penetration
    └──────────────────────────────────────────────────────────────
    """)
    println("=" ^ 72)
end

println("""
╔══════════════════════════════════════════════════════════════════════════╗
║ COUNTRY MISSINGNESS SCORING - PHASE 1 LOADED                          ║
╚══════════════════════════════════════════════════════════════════════════╝

Quick Start:
    df = load_augmented_or_build()
    meta_df = CSV.read("data/qog_metadata_plus2.csv", DataFrame)
    result = run_country_missingness(df, meta_df)

═══════════════════════════════════════════════════════════════════════════
""")
