# ==============================================================================
# SLUG RECLASSIFICATION
# ==============================================================================
#
# Recomputes slug penetration using clean country denominators and
# temporal windows that avoid reporting lag. Classifies slugs by
# UN region/subregion penetration vectors. Filters for re-clustering.
#
# Dependency: qog_augmented_standard.jl, country_missingness.jl
#
# ==============================================================================

using DataFrames, CSV, Statistics, SparseArrays

# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Reporting lag: skip last N years when computing penetration for active slugs."""
const SR_REPORTING_LAG = 5

"""Number of years to average for active slug penetration (anchor/modern/current)."""
const SR_ACTIVE_WINDOW = 3

"""Number of years to average for legacy slug penetration (ending at death_year)."""
const SR_LEGACY_WINDOW = 5

"""Population-weighted penetration threshold for global classification."""
const SR_GLOBAL_THRESHOLD = 0.95

"""Country penetration threshold for regional classification."""
const SR_REGIONAL_HIGH = 0.80

"""Low-coverage threshold for confirming regional concentration."""
const SR_REGIONAL_LOW = 0.20

"""Penetration below this = sparse (after clean denominator)."""
const SR_SPARSE_THRESHOLD = 0.05

"""Temporal profiles to drop (too sparse or inactive with low coverage)."""
const SR_DROP_PROFILES = Set(["experimental", "historical"])

"""Country statuses to exclude from denominators."""
const SR_EXCLUDE_STATUSES = Set(["dissolved", "political_exclusion", "self_exclusion",
                                  "microstate", "failed", "collision"])

"""UN Region codes in canonical order."""
const SR_UN_REGIONS = [2, 19, 142, 150, 9]  # Africa, Americas, Asia, Europe, Oceania (excl Antarctica)

"""UN Subregion codes in canonical order."""
const SR_UN_SUBREGIONS = [15, 202, 21, 419, 143, 30, 34, 35, 145, 151, 154, 155, 39, 53, 54, 57, 61]


# ==============================================================================
# STEP 1: BUILD CLEAN POPULATION UNIVERSE
# ==============================================================================

"""
Build a clean population universe excluding noise countries per year.

Arguments:
- df::DataFrame: Augmented QoG timeseries
- status_df::DataFrame: Country-year status classifications from country_missingness

Returns:
- NamedTuple with:
  - clean_rows: DataFrame of (ident_ccode, ident_year) pairs in the clean universe
  - year_pop: DataFrame of per-year total clean population
  - subregion_year_pop: DataFrame of per-(subregion, year) total clean population

Rules:
- Excludes country-years classified as dissolved, political_exclusion, self_exclusion,
  microstate, failed, or collision
- For collision entities (same ccode, same year), uses COLLISION_PRIORITY_ALPHAS
  to keep only successor state population
- Dissolved states' population excluded entirely — successor states cover those people
"""
function build_clean_population_universe(
    df::DataFrame,
    status_df::DataFrame;
    verbose::Bool = true
)
    # Join status onto df rows
    df_valid = filter(r -> !ismissing(r.ident_ccode) && !ismissing(r.ident_year), df)
    keyed = select(df_valid, [:ggis_rowid, :ident_ccode, :ident_year, :ident_ccodealp, :wpp_pop, :ggis_un_subregion_code])

    # Get status per (ccode, year)
    status_lookup = Dict{Tuple{Int,Int}, String}()
    for r in eachrow(status_df)
        status_lookup[(r.ident_ccode, r.ident_year)] = r.country_status
    end

    # Filter to clean rows
    clean_mask = Bool[]
    for r in eachrow(keyed)
        ccode = Int(r.ident_ccode)
        year = Int(r.ident_year)
        status = get(status_lookup, (ccode, year), "reporting")
        push!(clean_mask, !(status in SR_EXCLUDE_STATUSES))
    end

    clean_rows = keyed[clean_mask, :]

    # Deduplicate by (ccode, year) — keep first row (collision priority handled by augmented pipeline)
    clean_rows = combine(groupby(clean_rows, [:ident_ccode, :ident_year]),
        :wpp_pop => first => :wpp_pop,
        :ggis_un_subregion_code => first => :ggis_un_subregion_code,
        :ident_ccodealp => first => :ident_ccodealp
    )

    # Per-year total population
    year_pop = combine(
        groupby(dropmissing(clean_rows, :wpp_pop), :ident_year),
        :wpp_pop => sum => :total_pop,
        nrow => :n_countries
    )

    # Per-(subregion, year) population
    subregion_year_pop = combine(
        groupby(dropmissing(clean_rows, :wpp_pop), [:ggis_un_subregion_code, :ident_year]),
        :wpp_pop => sum => :total_pop,
        nrow => :n_countries
    )

    if verbose
        n_total = nrow(keyed)
        n_clean = nrow(clean_rows)
        n_excluded = n_total - sum(clean_mask)
        println("=" ^ 72)
        println("Step 1 — Clean Population Universe")
        println("=" ^ 72)
        println("    Total country-years: $n_total")
        println("    Clean country-years: $n_clean (excluded $n_excluded)")
        println("    Clean countries (latest year): $(nrow(filter(r -> r.ident_year == maximum(clean_rows.ident_year), clean_rows)))")
        println("=" ^ 72)
    end

    return (clean_rows = clean_rows, year_pop = year_pop, subregion_year_pop = subregion_year_pop)
end


# ==============================================================================
# STEP 2: COMPUTE REVISED PENETRATION PER SLUG
# ==============================================================================

"""
Compute revised population-weighted penetration per slug using clean denominator
and temporal windows that avoid reporting lag.

Arguments:
- df::DataFrame: Augmented QoG timeseries
- meta_df::DataFrame: Metadata with :slug, :ggis_temporal_profile, :ggis_birth_year, :ggis_death_year
- clean_universe::NamedTuple: From build_clean_population_universe()

Returns:
- DataFrame with :slug, :temporal_profile, :penetration_window, :revised_penetration, :n_countries_covered, :drop_reason

Rules:
- anchor/modern/current: mean penetration over [data_end - lag - window + 1, data_end - lag]
- legacy: mean penetration over [death_year - legacy_window + 1, death_year]
- experimental/historical: dropped
- who_roadtrd (unclassified, single year): dropped with note
"""
function compute_revised_penetration(
    df::DataFrame,
    meta_df::DataFrame,
    clean_universe::NamedTuple;
    reporting_lag::Int = SR_REPORTING_LAG,
    active_window::Int = SR_ACTIVE_WINDOW,
    legacy_window::Int = SR_LEGACY_WINDOW,
    verbose::Bool = true
)
    data_end = Int(maximum(clean_universe.clean_rows.ident_year))
    active_end = data_end - reporting_lag
    active_start = active_end - active_window + 1

    # Build year_pop lookup
    year_pop_lookup = Dict{Int, Float64}()
    for r in eachrow(clean_universe.year_pop)
        year_pop_lookup[r.ident_year] = r.total_pop
    end

    # Build (ccode, year) → pop lookup from clean rows
    ccode_year_pop = Dict{Tuple{Int,Int}, Float64}()
    for r in eachrow(dropmissing(clean_universe.clean_rows, :wpp_pop))
        ccode_year_pop[(Int(r.ident_ccode), Int(r.ident_year))] = r.wpp_pop
    end

    # Clean country set per year
    clean_ccode_years = Set{Tuple{Int,Int}}()
    for r in eachrow(clean_universe.clean_rows)
        push!(clean_ccode_years, (Int(r.ident_ccode), Int(r.ident_year)))
    end

    df_valid = filter(r -> !ismissing(r.ident_ccode) && !ismissing(r.ident_year), df)
    df_cols = Set(string.(propertynames(df)))

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 2 — Revised Slug Penetration")
        println("=" ^ 72)
        println("    Data end: $data_end")
        println("    Active window: $(active_start)-$(active_end)")
        println("    Legacy window: last $legacy_window years before death")
    end

    rows = []
    for r in eachrow(meta_df)
        slug = string(r.slug)
        profile = ismissing(r.ggis_temporal_profile) ? "missing" : string(r.ggis_temporal_profile)
        birth = ismissing(r.ggis_birth_year) ? missing : Int(r.ggis_birth_year)
        death = ismissing(r.ggis_death_year) ? missing : Int(r.ggis_death_year)

        # Drop check
        if profile in SR_DROP_PROFILES
            push!(rows, (slug=slug, temporal_profile=profile, penetration_window="",
                         revised_penetration=missing, n_countries_covered=0, drop_reason=profile))
            continue
        end
        if slug == "who_roadtrd"
            push!(rows, (slug=slug, temporal_profile="missing", penetration_window="",
                         revised_penetration=missing, n_countries_covered=0,
                         drop_reason="single_year_2021"))
            continue
        end
        if !(slug in df_cols)
            push!(rows, (slug=slug, temporal_profile=profile, penetration_window="",
                         revised_penetration=missing, n_countries_covered=0,
                         drop_reason="not_in_data"))
            continue
        end

        # Determine window
        if profile in ["anchor", "modern", "current"]
            win_start = active_start
            win_end = active_end
        elseif profile == "legacy"
            if ismissing(death)
                push!(rows, (slug=slug, temporal_profile=profile, penetration_window="",
                             revised_penetration=missing, n_countries_covered=0,
                             drop_reason="missing_death_year"))
                continue
            end
            win_end = death
            win_start = death - legacy_window + 1
        else
            # unknown profile — compute at active window as fallback
            win_start = active_start
            win_end = active_end
        end

        # Compute mean penetration over window years
        yearly_pens = Float64[]
        total_countries = 0
        for year in win_start:win_end
            total_pop = get(year_pop_lookup, year, 0.0)
            total_pop == 0.0 && continue

            # Sum population of clean countries where this slug is non-missing
            covered_pop = 0.0
            n_covered = 0
            year_df = filter(r -> Int(r.ident_year) == year, df_valid)
            for row in eachrow(year_df)
                ccode = Int(row.ident_ccode)
                (ccode, year) in clean_ccode_years || continue
                ismissing(row[Symbol(slug)]) && continue
                pop = get(ccode_year_pop, (ccode, year), 0.0)
                covered_pop += pop
                n_covered += 1
            end
            push!(yearly_pens, covered_pop / total_pop)
            total_countries = max(total_countries, n_covered)
        end

        pen = isempty(yearly_pens) ? 0.0 : mean(yearly_pens)
        window_str = "$(win_start)-$(win_end)"

        push!(rows, (slug=slug, temporal_profile=profile, penetration_window=window_str,
                     revised_penetration=round(pen, digits=4), n_countries_covered=total_countries,
                     drop_reason=missing))
    end

    result = DataFrame(rows)

    if verbose
        kept = filter(r -> ismissing(r.drop_reason), result)
        dropped = filter(r -> !ismissing(r.drop_reason), result)
        println("    Kept: $(nrow(kept)) slugs")
        println("    Dropped: $(nrow(dropped)) slugs")
        drop_reasons = combine(groupby(dropped, :drop_reason), nrow => :count)
        for r in eachrow(sort(drop_reasons, :count, rev=true))
            println("      $(rpad(string(r.drop_reason), 20)) $(r.count)")
        end

        # How many cross global threshold?
        n_global = count(r -> !ismissing(r.revised_penetration) && r.revised_penetration >= SR_GLOBAL_THRESHOLD, eachrow(result))
        println("    Revised globals (≥$(SR_GLOBAL_THRESHOLD)): $n_global")
        println("=" ^ 72)
    end

    return result
end


# ==============================================================================
# STEP 3: UN REGION & SUBREGION PENETRATION VECTORS
# ==============================================================================

"""
Compute UN region (6) and subregion (18) penetration vectors per slug.

Arguments:
- df::DataFrame: Augmented QoG timeseries
- meta_df::DataFrame: Metadata
- penetration_df::DataFrame: From compute_revised_penetration (for window info)
- clean_universe::NamedTuple: Clean population universe

Returns:
- DataFrame with :slug, :un_region_penetration (Vector{Float64} len 5),
  :un_subregion_penetration (Vector{Float64} len 17), :un_geo_classification
"""
function compute_un_penetration_vectors(
    df::DataFrame,
    meta_df::DataFrame,
    penetration_df::DataFrame,
    clean_universe::NamedTuple;
    regional_high::Float64 = SR_REGIONAL_HIGH,
    regional_low::Float64 = SR_REGIONAL_LOW,
    verbose::Bool = true
)
    # Only compute for kept slugs
    kept = filter(r -> ismissing(r.drop_reason) && !ismissing(r.revised_penetration), penetration_df)

    # Build subregion → country sets from clean universe (latest available year per country)
    latest_clean = combine(groupby(clean_universe.clean_rows, :ident_ccode),
        :ident_year => maximum => :latest_year,
        :ggis_un_subregion_code => first => :ggis_un_subregion_code
    )

    # Region lookup from subregion
    subregion_to_region = Dict{Int, Int}()
    for r in eachrow(latest_clean)
        sub = r.ggis_un_subregion_code
        # Map subregion to region (UN M49)
        reg = if sub in [15, 202]; 2              # Africa
        elseif sub in [21, 419]; 19               # Americas
        elseif sub in [143, 30, 34, 35, 145]; 142 # Asia
        elseif sub in [151, 154, 155, 39]; 150    # Europe
        elseif sub in [53, 54, 57, 61]; 9         # Oceania
        else 0
        end
        subregion_to_region[sub] = reg
    end

    # Countries per subregion
    sub_countries = Dict{Int, Set{Int}}()
    for r in eachrow(latest_clean)
        sub = r.ggis_un_subregion_code
        if !haskey(sub_countries, sub)
            sub_countries[sub] = Set{Int}()
        end
        push!(sub_countries[sub], Int(r.ident_ccode))
    end

    # Countries per region
    reg_countries = Dict{Int, Set{Int}}()
    for (sub, countries) in sub_countries
        reg = get(subregion_to_region, sub, 0)
        reg == 0 && continue
        if !haskey(reg_countries, reg)
            reg_countries[reg] = Set{Int}()
        end
        union!(reg_countries[reg], countries)
    end

    df_valid = filter(r -> !ismissing(r.ident_ccode), df)
    df_cols = Set(string.(propertynames(df)))
    clean_ccodes = Set(Int.(latest_clean.ident_ccode))

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 3 — UN Region & Subregion Penetration Vectors")
        println("=" ^ 72)
        println("    Slugs to process: $(nrow(kept))")
        println("    UN Regions: $(length(SR_UN_REGIONS))")
        println("    UN Subregions: $(length(SR_UN_SUBREGIONS))")
    end

    rows = []
    for r in eachrow(kept)
        slug = r.slug
        !(slug in df_cols) && continue

        # Parse window
        parts = split(r.penetration_window, "-")
        win_start = parse(Int, parts[1])
        win_end = parse(Int, parts[2])

        # Countries where slug has data in the window (any year)
        window_df = filter(row -> !ismissing(row.ident_ccode) &&
                           win_start <= coalesce(row.ident_year, 0) <= win_end, df_valid)
        covered = Set{Int}()
        for row in eachrow(window_df)
            ccode = Int(row.ident_ccode)
            ccode in clean_ccodes || continue
            ismissing(row[Symbol(slug)]) && continue
            push!(covered, ccode)
        end

        # Region vector
        reg_pen = Float64[]
        for reg in SR_UN_REGIONS
            total = length(get(reg_countries, reg, Set{Int}()))
            present = length(intersect(covered, get(reg_countries, reg, Set{Int}())))
            push!(reg_pen, total > 0 ? present / total : 0.0)
        end

        # Subregion vector
        sub_pen = Float64[]
        for sub in SR_UN_SUBREGIONS
            total = length(get(sub_countries, sub, Set{Int}()))
            present = length(intersect(covered, get(sub_countries, sub, Set{Int}())))
            push!(sub_pen, total > 0 ? present / total : 0.0)
        end

        # Classify
        is_global = r.revised_penetration >= SR_GLOBAL_THRESHOLD
        n_high_regions = count(>=(regional_high), reg_pen)
        n_low_regions = count(<=(regional_low), reg_pen)
        n_high_subs = count(>=(regional_high), sub_pen)

        geo_class = if is_global
            "global"
        elseif n_high_regions == 1 && n_low_regions >= 3
            "regional"
        elseif n_high_subs >= 1 && n_high_subs <= 2 && count(<=(regional_low), sub_pen) >= 12
            "subregional"
        elseif r.revised_penetration < SR_SPARSE_THRESHOLD
            "sparse"
        else
            "partial"
        end

        push!(rows, (
            slug = slug,
            un_region_penetration = round.(reg_pen, digits=4),
            un_subregion_penetration = round.(sub_pen, digits=4),
            un_geo_classification = geo_class,
        ))
    end

    vectors = DataFrame(rows)

    if verbose
        geo_counts = combine(groupby(vectors, :un_geo_classification), nrow => :count)
        sort!(geo_counts, :count, rev=true)
        for r in eachrow(geo_counts)
            println("    $(rpad(r.un_geo_classification, 15)) $(r.count) slugs")
        end
        println("=" ^ 72)
    end

    return vectors
end


# ==============================================================================
# STEP 4: FILTER FOR RE-CLUSTERING
# ==============================================================================

"""
Prepare the clustering pool: remove global, regional, subregional, and sparse slugs.

Arguments:
- penetration_df::DataFrame: From compute_revised_penetration
- vectors_df::DataFrame: From compute_un_penetration_vectors

Returns:
- NamedTuple with :clustering_pool (Vector{String}), :removed (DataFrame), :summary (DataFrame)
"""
function prepare_clustering_pool(
    penetration_df::DataFrame,
    vectors_df::DataFrame;
    verbose::Bool = true
)
    # Start with kept slugs
    kept = filter(r -> ismissing(r.drop_reason), penetration_df)
    kept_slugs = Set(kept.slug)

    # Join with geo classification
    geo_lookup = Dict(r.slug => r.un_geo_classification for r in eachrow(vectors_df))

    pool = String[]
    removed_slugs = String[]
    removed_reasons = String[]

    for slug in kept.slug
        geo = get(geo_lookup, slug, "unknown")
        if geo in ["global", "regional", "subregional", "sparse"]
            push!(removed_slugs, slug)
            push!(removed_reasons, geo)
        elseif geo == "partial"
            push!(pool, slug)
        else
            push!(pool, slug)  # unknown → include
        end
    end

    removed = DataFrame(slug = removed_slugs, removal_reason = removed_reasons)
    removal_summary = combine(groupby(removed, :removal_reason), nrow => :count)
    sort!(removal_summary, :count, rev=true)

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 4 — Clustering Pool")
        println("=" ^ 72)
        println("    Kept slugs (from Step 2): $(nrow(kept))")
        println("    Removed:")
        for r in eachrow(removal_summary)
            println("      $(rpad(r.removal_reason, 15)) $(r.count)")
        end
        println("    Clustering pool: $(length(pool)) slugs")
        println("=" ^ 72)
    end

    return (clustering_pool = pool, removed = removed, summary = removal_summary)
end


# ==============================================================================
# ORCHESTRATION
# ==============================================================================

"""
Run the full slug reclassification pipeline.

Arguments:
- df::DataFrame: Augmented QoG timeseries
- meta_df::DataFrame: Metadata
- status_df::DataFrame: Country-year status from run_country_missingness()

Returns:
- NamedTuple with all pipeline outputs

Usage:
    miss_result = run_country_missingness(df, meta_df)
    reclass_result = run_slug_reclassification(df, meta_df, miss_result.status)
"""
function run_slug_reclassification(
    df::DataFrame,
    meta_df::DataFrame,
    status_df::DataFrame;
    verbose::Bool = true
)
    # Step 1: Clean population universe
    clean_universe = build_clean_population_universe(df, status_df; verbose=verbose)

    # Step 2: Revised penetration
    penetration = compute_revised_penetration(df, meta_df, clean_universe; verbose=verbose)

    # Step 3: UN vectors + geo classification
    vectors = compute_un_penetration_vectors(df, meta_df, penetration, clean_universe; verbose=verbose)

    # Step 4: Filter for clustering
    pool = prepare_clustering_pool(penetration, vectors; verbose=verbose)

    return (
        clean_universe = clean_universe,
        penetration = penetration,
        vectors = vectors,
        clustering_pool = pool,
    )
end


# ==============================================================================
# SAMPLES
# ==============================================================================

function run_slug_reclassification_samples()
    println("\n" * "=" ^ 72)
    println("  slug_reclassification.jl — Function intent and usage")
    println("=" ^ 72)
    println("""

    ┌─ build_clean_population_universe(df, status_df)
    │  Excludes dissolved/micro/failed/exclusion country-years from denominator.
    │  RETURNS: (clean_rows, year_pop, subregion_year_pop)
    └──────────────────────────────────────────────────────────────

    ┌─ compute_revised_penetration(df, meta_df, clean_universe)
    │  Pop-weighted penetration per slug using temporal windows.
    │  Active slugs: mean of [now-7, now-5]. Legacy: last 5 at death.
    │  Drops experimental + historical.
    │  RETURNS: DataFrame with revised_penetration per slug
    └──────────────────────────────────────────────────────────────

    ┌─ compute_un_penetration_vectors(df, meta_df, pen_df, clean)
    │  UN region (5) and subregion (17) penetration vectors per slug.
    │  Classifies: global / regional / subregional / sparse / partial.
    │  RETURNS: DataFrame with vectors + un_geo_classification
    └──────────────────────────────────────────────────────────────

    ┌─ run_slug_reclassification(df, meta_df, status_df)
    │  Full pipeline: clean universe → penetration → vectors → filter.
    │  RETURNS: NamedTuple with all outputs
    │
    │  USAGE:
    │    miss = run_country_missingness(df, meta_df)
    │    reclass = run_slug_reclassification(df, meta_df, miss.status)
    │    reclass.clustering_pool.clustering_pool  # filtered slug list
    └──────────────────────────────────────────────────────────────
    """)
    println("=" ^ 72)
end

println("""
╔══════════════════════════════════════════════════════════════════════════╗
║ SLUG RECLASSIFICATION - PHASE 1 LOADED                                ║
╚══════════════════════════════════════════════════════════════════════════╝

Quick Start:
    miss = run_country_missingness(df, meta_df)
    reclass = run_slug_reclassification(df, meta_df, miss.status)

═══════════════════════════════════════════════════════════════════════════
""")
