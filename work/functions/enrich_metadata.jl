using Dates
include("qog_augmented_standard.jl")

# ==============================================================================
# SYSTEM CONSTANTS
# ==============================================================================

# --- Path Constants ---
"""Output path for unified, joined metadata CSV."""
const PATH_METADATA_JOINED = "data/qog_metadata_joined.csv"

"""
Loads the main QoG timeseries DataFrame and the joined metadata DataFrame.

Returns:
- df: Main timeseries DataFrame (from load_qog_timeseries)
- meta_df: Metadata DataFrame (from PATH_METADATA_JOINED)
"""
function load_dataframes()
    df = load_qog_timeseries()
    meta_df = CSV.read(PATH_METADATA_JOINED, DataFrame)
    return df, meta_df
end

# ============================================================================
# PHASE 1: TEMPORAL LIFESPAN ENRICHMENT
# ============================================================================

"""
Classifies a variable's temporal profile based on its lifespan and activity.

Arguments:
- birth_year::Int: First year variable is observed
- death_year::Int: Last year variable is observed
- data_start::Int: Start year of dataset (default: DATA_START_YEAR)
- data_end::Int: End year of dataset (default: DATA_END_YEAR)
- current_year::Int: Reference year for activity (default: CURRENT_YEAR)
- active_lag::Int: Years lag for activity (default: ACTIVE_LAG_YEARS)
- thresholds::NamedTuple: Thresholds for classification (default: TEMPORAL_THRESHOLDS)

Returns:
- Symbol: One of :anchor, :experimental, :legacy, :historical, :current, :modern, :unclassified
"""
function classify_temporal_profile(
    birth_year::Int,
    death_year::Int;
    data_start::Int = DATA_START_YEAR,
    data_end::Int = DATA_END_YEAR,
    current_year::Int = CURRENT_YEAR,
    active_lag::Int = ACTIVE_LAG_YEARS,
    thresholds::NamedTuple = TEMPORAL_THRESHOLDS
)
    data_span = data_end - data_start + 1
    var_span = death_year - birth_year + 1
    usage_pct = var_span / data_span
    is_active = death_year >= (current_year - active_lag)
    recent_start = data_end - round(Int, data_span * thresholds.recent_pct)
    if usage_pct >= thresholds.anchor
        return :anchor
    elseif usage_pct < thresholds.experimental
        return :experimental
    elseif !is_active && usage_pct >= thresholds.legacy
        return :legacy
    elseif !is_active
        return :historical
    elseif is_active && birth_year >= recent_start
        return :current
    elseif is_active
        return :modern
    else
        return :unclassified
    end
end

"""
Computes temporal lifespan metrics for each slug in the data.

Arguments:
- df::DataFrame: Main timeseries DataFrame (must have :ident_year)
- slugs::Vector{String}: List of variable slugs to audit

Returns:
- DataFrame: Results with columns [slug, ggis_birth_year, ggis_death_year, ggis_is_active, ggis_temporal_gap, ggis_temporal_profile]
"""
function compute_variable_lifespan(df::DataFrame, slugs::Vector{String})
    if !(:ident_year in propertynames(df))
        error("DataFrame must contain `ident_year` column.")
    end
    results = DataFrame(
        slug = String[],
        ggis_birth_year = Int[],
        ggis_death_year = Int[],
        ggis_is_active = Bool[],
        ggis_temporal_gap = Bool[],
        ggis_temporal_profile = Symbol[]
    )
    for slug in slugs
        slug_sym = Symbol(slug)
        if !(slug_sym in propertynames(df))
            continue
        end
        mask = .!ismissing.(df[!, slug_sym]) .& .!ismissing.(df.ident_year)
        years_with_data = df.ident_year[mask]
        if isempty(years_with_data)
            continue
        end
        years_with_data = sort(unique(Int.(years_with_data)))
        birth_year = minimum(years_with_data)
        death_year = maximum(years_with_data)
        is_active = death_year >= (CURRENT_YEAR - ACTIVE_LAG_YEARS)
        expected_range = birth_year:death_year
        has_gap = (length(expected_range) - length(years_with_data)) > TEMPORAL_GAP_TOLERANCE
        profile = classify_temporal_profile(birth_year, death_year)
        push!(results, (
            slug = slug,
            ggis_birth_year = birth_year,
            ggis_death_year = death_year,
            ggis_is_active = is_active,
            ggis_temporal_gap = has_gap,
            ggis_temporal_profile = profile
        ))
    end
    println("\n>>> Results Summary")
    println("    Variables Audited: $(nrow(results))")
    profile_counts = combine(groupby(results, :ggis_temporal_profile), nrow => :count)
    sort!(profile_counts, :count, rev=true)
    for row in eachrow(profile_counts)
        println("      :$(row.ggis_temporal_profile) — $(row.count)")
    end
    return results
end

"""
Checks for discrepancies between start_year/birth_year and end_year/death_year in meta_df.
Prints any errors where the absolute difference exceeds the tolerance (default: 1).

Usage:
    check_year_discrepancies(meta_df)
Returns:
    - Nothing (prints errors to console)

Arguments:
- meta_df::DataFrame: Metadata DataFrame containing year columns
- tolerance::Int: Allowed difference (default: 1)

Prints:
- List of errors with slug and year values
"""
function check_year_discrepancies(meta_df::DataFrame; tolerance::Int=1)
    errors = DataFrame(
        slug = String[],
        start_year = Int[],
        birth_year = Int[],
        end_year = Int[],
        death_year = Int[],
        type = String[],
        diff = Int[]
    )
    for row in eachrow(meta_df)
        slug = hasproperty(row, :slug) ? row.slug : ""
        sy = hasproperty(row, :start_year) ? row.start_year : missing
        by = hasproperty(row, :birth_year) ? row.birth_year : missing
        ey = hasproperty(row, :end_year) ? row.end_year : missing
        dy = hasproperty(row, :death_year) ? row.death_year : missing
        if !ismissing(sy) && !ismissing(by)
            diff = abs(sy - by)
            if diff > tolerance
                push!(errors, (slug, sy, by, ey, dy, "start/birth", diff))
            end
        end
        if !ismissing(ey) && !ismissing(dy)
            diff = abs(ey - dy)
            if diff > tolerance
                push!(errors, (slug, sy, by, ey, dy, "end/death", diff))
            end
        end
    end
    if nrow(errors) == 0
        println("No year discrepancies found exceeding tolerance $(tolerance).")
    else
        println("Year discrepancies found (tolerance=$(tolerance)):")
        for row in eachrow(errors)
            println("Slug: $(row.slug) | $(row.type) | start: $(row.start_year), birth: $(row.birth_year), end: $(row.end_year), death: $(row.death_year) | diff: $(row.diff)")
        end
    end
    return nothing
end

# ============================================================================
# CONSTANTS: DATA BOUNDS AND THRESHOLDS
# ============================================================================

# Load dataframes
df, meta_df = load_dataframes()

"""
Earliest and latest year in the dataset, derived from :ident_year.
"""
const DATA_START_YEAR = Int(minimum(skipmissing(df.ident_year)))
const DATA_END_YEAR   = Int(maximum(skipmissing(df.ident_year)))

"""
User override: current year is system date minus lag years.
"""
const ACTIVE_LAG_YEARS = 3
const CURRENT_YEAR     = Dates.year(Dates.today()) - ACTIVE_LAG_YEARS

"""
Temporal gap tolerance for non-contiguous reporting.
"""
const TEMPORAL_GAP_TOLERANCE = 2

"""
Thresholds for temporal profile classification.
"""
const TEMPORAL_THRESHOLDS = (
    anchor       = 0.97,
    experimental = 0.15,
    legacy       = 0.50,
    recent_pct   = 0.25
)

"""
Geographic coverage thresholds for global/regional classification.
"""
const GLOBAL_PENETRATION_UPPER_BOUND   = 0.95
const REGIONAL_PENETRATION_UPPER_BOUND = 0.95
const REGIONAL_PENETRATION_LOWER_BOUND = 0.05
const REGIONAL_EXCLUSION_TOLERANCE     = 3   # "all but at most 3 regions"
const TOTAL_REGIONS_COUNT              = 10  # Total QoG regions

# ============================================================================
# MAIN EXECUTION: ENRICH METADATA WITH TEMPORAL LIFESPAN
# ============================================================================

"""
Enriches the metadata DataFrame with temporal lifespan metrics for each variable.

Returns:
- DataFrame: meta_df with new columns [ggis_birth_year, ggis_death_year, ggis_is_active, ggis_temporal_gap, ggis_temporal_profile]
"""
function enrich_metadata_with_lifespan()
    target_slugs = String.(meta_df.slug)
    lifespan_audit_df = compute_variable_lifespan(df, target_slugs)
    enriched = leftjoin(meta_df, lifespan_audit_df, on=:slug)
    return enriched
end

# ============================================================================
# PHASE 2: GEOGRAPHIC COVERAGE AUDITING
# ============================================================================

"""
Pre-computes global population denominators for each year in the dataset.

Arguments:
- df::DataFrame: Main timeseries DataFrame (must have :ident_year and :wpp_pop)

Returns:
- DataFrame: Columns [ident_year, total_global_pop]
"""
function compute_global_population_universe(df::DataFrame)
    if !(:ident_year in propertynames(df))
        error("DataFrame must contain `ident_year` column.")
    end
    if !(:wpp_pop in propertynames(df))
        error("DataFrame must contain `wpp_pop` column.")
    end
    
    global_pop_universe = combine(
        groupby(df, :ident_year), 
        :wpp_pop => (x -> sum(skipmissing(x))) => :total_global_pop
    )
    
    return global_pop_universe
end

"""
Pre-computes regional country count denominators for each region-year combination.

Arguments:
- df::DataFrame: Main timeseries DataFrame (must have :ident_year and :ggis_region)

Returns:
- DataFrame: Columns [ident_year, ggis_region, total_countries_in_region]
"""
function compute_regional_country_universe(df::DataFrame)
    if !(:ident_year in propertynames(df))
        error("DataFrame must contain `ident_year` column.")
    end
    if !(:ggis_region in propertynames(df))
        error("DataFrame must contain `ggis_region` column.")
    end
    
    regional_universe = combine(
        groupby(df, [:ident_year, :ggis_region]), 
        nrow => :total_countries_in_region
    )
    
    return regional_universe
end

"""
Computes global population penetration for a single slug at its death year.

Arguments:
- df::DataFrame: Main timeseries DataFrame
- slug_sym::Symbol: Variable slug as symbol
- target_year::Int: Death year to compute penetration at
- global_pop_universe::DataFrame: Pre-computed global population denominators

Returns:
- Float64: Global penetration (0.0 to 1.0), or 0.0 if no data
"""
function compute_global_penetration(
    df::DataFrame, 
    slug_sym::Symbol, 
    target_year::Int,
    global_pop_universe::DataFrame
)
    # Filter to target year
    year_mask = df.ident_year .== target_year
    
    # Get global denominator for this year
    global_denom_idx = findfirst(==(target_year), global_pop_universe.ident_year)
    if isnothing(global_denom_idx)
        return 0.0
    end
    global_pop_denom = global_pop_universe.total_global_pop[global_denom_idx]
    
    if global_pop_denom <= 0
        return 0.0
    end
    
    # Get numerator: sum wpp_pop where slug is present
    slug_mask = .!ismissing.(df[!, slug_sym])
    valid_rows = df[year_mask .& slug_mask, :]
    
    numerator_pop = sum(skipmissing(valid_rows.wpp_pop))
    
    return numerator_pop / global_pop_denom
end

"""
Computes regional country penetration for a single slug at its death year.

Arguments:
- df::DataFrame: Main timeseries DataFrame
- slug_sym::Symbol: Variable slug as symbol
- target_year::Int: Death year to compute penetration at
- regional_universe::DataFrame: Pre-computed regional country count denominators

Returns:
- Vector{Float64}: Regional penetrations (length TOTAL_REGIONS_COUNT), values 0.0 to 1.0
"""
function compute_regional_penetrations(
    df::DataFrame,
    slug_sym::Symbol,
    target_year::Int,
    regional_universe::DataFrame
)
    # Filter to target year where slug is present
    year_mask = df.ident_year .== target_year
    slug_mask = .!ismissing.(df[!, slug_sym])
    valid_rows = df[year_mask .& slug_mask, :]
    
    # Count countries with data per region
    slug_region_counts = combine(groupby(valid_rows, :ggis_region), nrow => :count)
    
    # Get regional denominators for this year
    year_region_denoms = filter(r -> r.ident_year == target_year, regional_universe)
    
    # Calculate penetration for each region (1 to TOTAL_REGIONS_COUNT)
    regional_pens = Float64[]
    
    for r_code in 1:TOTAL_REGIONS_COUNT
        # Denominator: total countries in region for this year
        denom_row = filter(r -> r.ggis_region == r_code, year_region_denoms)
        r_denom = isempty(denom_row) ? 0 : denom_row.total_countries_in_region[1]
        
        # Numerator: countries with data in this region
        num_row = filter(r -> r.ggis_region == r_code, slug_region_counts)
        r_num = isempty(num_row) ? 0 : num_row.count[1]
        
        p = (r_denom > 0) ? (r_num / r_denom) : 0.0
        push!(regional_pens, p)
    end
    
    return regional_pens
end

"""
Classifies a variable's geographic profile based on global and regional penetration.

Arguments:
- global_pen::Float64: Global population penetration (0.0 to 1.0)
- regional_pens::Vector{Float64}: Regional penetrations (length TOTAL_REGIONS_COUNT)

Returns:
- Symbol: One of :global, :regional, :other

Classification Rules:
- :global — global_pen >= GLOBAL_PENETRATION_UPPER_BOUND
- :regional — >= 1 region with high coverage (>= REGIONAL_PENETRATION_UPPER_BOUND)
              AND >= (TOTAL_REGIONS_COUNT - REGIONAL_EXCLUSION_TOLERANCE) regions 
              with low coverage (<= REGIONAL_PENETRATION_LOWER_BOUND)
- :other — all remaining variables
"""
function classify_geographic_profile(
    global_pen::Float64,
    regional_pens::Vector{Float64}
)
    # Global rule
    if global_pen >= GLOBAL_PENETRATION_UPPER_BOUND
        return :global
    end
    
    # Count regions meeting high/low thresholds
    high_coverage_regions = count(p -> p >= REGIONAL_PENETRATION_UPPER_BOUND, regional_pens)
    low_coverage_regions = count(p -> p <= REGIONAL_PENETRATION_LOWER_BOUND, regional_pens)
    
    # Regional rule: high coverage in >= 1 region AND low coverage in >= 7 regions
    min_low_coverage_regions = TOTAL_REGIONS_COUNT - REGIONAL_EXCLUSION_TOLERANCE
    
    if (high_coverage_regions >= 1) && (low_coverage_regions >= min_low_coverage_regions)
        return :regional
    end
    
    return :other
end

"""
Computes geographic coverage metrics for all variables based on their empirical death year.

Arguments:
- df::DataFrame: Main timeseries DataFrame (must have :ident_year, :wpp_pop, :ggis_region)
- lifespan_df::DataFrame: Lifespan audit results (must have :slug and :ggis_death_year)

Returns:
- DataFrame: Results with columns [slug, ggis_global_penetration, ggis_geo_classification, ggis_region_penetration]

Notes:
- ggis_region_penetration is a Vector{Float64} of length TOTAL_REGIONS_COUNT
- Prints classification summary to console
"""
function compute_geographic_coverage(df::DataFrame, lifespan_df::DataFrame)
    # Validation
    required_cols = [:ident_year, :wpp_pop, :ggis_region]
    missing_cols = setdiff(required_cols, propertynames(df))
    if !isempty(missing_cols)
        error("DataFrame missing required columns for geographic coverage: $missing_cols")
    end
    
    if !(:slug in propertynames(lifespan_df)) || !(:ggis_death_year in propertynames(lifespan_df))
        error("lifespan_df must contain :slug and :ggis_death_year columns")
    end
    
    println("\n>>> Computing Geographic Coverage (Step 8)")
    println("    Global Threshold:   ≥ $(GLOBAL_PENETRATION_UPPER_BOUND)")
    println("    Regional Threshold: ≥ $(REGIONAL_PENETRATION_UPPER_BOUND) (Core) AND ≤ $(REGIONAL_PENETRATION_LOWER_BOUND) (Exclusion in $(TOTAL_REGIONS_COUNT - REGIONAL_EXCLUSION_TOLERANCE)+ regions)")
    
    # Pre-compute denominators once
    println("    Pre-computing geographic universes...")
    global_pop_universe = compute_global_population_universe(df)
    regional_universe = compute_regional_country_universe(df)
    
    # Prepare results DataFrame
    results = DataFrame(
        slug = String[],
        ggis_global_penetration = Float64[],
        ggis_geo_classification = Symbol[],
        ggis_region_penetration = Vector{Float64}[]
    )
    
    # Process each slug
    total_slugs = nrow(lifespan_df)
    
    for (i, row) in enumerate(eachrow(lifespan_df))
        slug_sym = Symbol(row.slug)
        target_year = row.ggis_death_year
        
        # Check if slug exists in df
        if !(slug_sym in propertynames(df))
            continue
        end
        
        # Compute global penetration
        global_pen = compute_global_penetration(df, slug_sym, target_year, global_pop_universe)
        
        # Compute regional penetrations
        regional_pens = compute_regional_penetrations(df, slug_sym, target_year, regional_universe)
        
        # Classify geographic profile
        classification = classify_geographic_profile(global_pen, regional_pens)
        
        # Store results
        push!(results, (
            slug = row.slug,
            ggis_global_penetration = global_pen,
            ggis_geo_classification = classification,
            ggis_region_penetration = regional_pens
        ))
    end
    
    # Print summary
    println("\n>>> Geographic Classification Summary")
    summary = combine(groupby(results, :ggis_geo_classification), nrow => :count)
    sort!(summary, :count, rev=true)
    for row in eachrow(summary)
        println("    :$(row.ggis_geo_classification) — $(row.count)")
    end
    
    return results
end

"""
Enriches the metadata DataFrame with geographic coverage metrics for each variable.

Arguments:
- enriched_df::DataFrame: Metadata DataFrame already enriched with temporal lifespan

Returns:
- DataFrame: enriched_df with new columns [ggis_global_penetration, ggis_geo_classification, ggis_region_penetration]
"""
function enrich_metadata_with_geographic_coverage(enriched_df::DataFrame)
    # Extract lifespan data needed for geographic computation
    lifespan_cols = [:slug, :ggis_death_year]
    missing_cols = setdiff(lifespan_cols, propertynames(enriched_df))
    
    if !isempty(missing_cols)
        error("enriched_df must contain temporal lifespan columns: $missing_cols. Run enrich_metadata_with_lifespan() first.")
    end
    
    lifespan_data = enriched_df[:, lifespan_cols]
    
    # Compute geographic coverage
    geo_audit_df = compute_geographic_coverage(df, lifespan_data)
    
    # Join back to enriched metadata
    enriched_with_geo = leftjoin(enriched_df, geo_audit_df, on=:slug)
    
    return enriched_with_geo
end

# ==============================================================================
# SUPPORT: INTENT AND USAGE FOR EACH FUNCTION
# ==============================================================================

"""
    run_enrich_metadata_samples()

Prints to REPL or Jupyter the intent and how to use each function in this module.
Run this for quick reference and support when working with enrich_metadata.jl.
"""
function run_enrich_metadata_samples()
    println("\n" * "="^76)
    println("  enrich_metadata.jl — Function intent and usage")
    println("="^76)

    # --- load_dataframes ---
    println("\n┌─ load_dataframes()")
    println("│  INTENT: Load the main QoG timeseries and the joined metadata in one call.")
    println("│  USE WHEN: You need both df and meta_df for auditing or enrichment.")
    println("│")
    println("│  RETURNS: (df, meta_df)")
    println("│    - df: main timeseries from load_qog_timeseries()")
    println("│    - meta_df: from PATH_METADATA_JOINED")
    println("│")
    println("│  USAGE:")
    println("│    df, meta = load_dataframes()")
    println("└" * "─"^74)

    # --- classify_temporal_profile ---
    println("\n┌─ classify_temporal_profile(birth_year, death_year; kwargs...)")
    println("│  INTENT: Classify a variable's temporal profile from its lifespan.")
    println("│  USE WHEN: You have first/last year and want :anchor, :experimental,")
    println("│           :legacy, :historical, :current, :modern, or :unclassified.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    birth_year::Int, death_year::Int (positional)")
    println("│    Optional kwargs: data_start, data_end, current_year, active_lag, thresholds")
    println("│")
    println("│  RETURNS: Symbol (e.g. :anchor, :current)")
    println("│")
    println("│  USAGE:")
    println("│    profile = classify_temporal_profile(1946, 2022)")
    println("│    profile = classify_temporal_profile(2010, 2022; current_year=2022)")
    println("└" * "─"^74)

    # --- compute_variable_lifespan ---
    println("\n┌─ compute_variable_lifespan(df, slugs)")
    println("│  INTENT: Compute temporal lifespan metrics for each slug in the data.")
    println("│  USE WHEN: Auditing variables for birth/death year, gaps, and profile.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    df::DataFrame — must have :ident_year")
    println("│    slugs::Vector{String} — variable slugs to audit")
    println("│")
    println("│  RETURNS: DataFrame with columns:")
    println("│    slug, ggis_birth_year, ggis_death_year, ggis_is_active,")
    println("│    ggis_temporal_gap, ggis_temporal_profile")
    println("│  (Also prints a summary of profile counts.)")
    println("│")
    println("│  USAGE:")
    println("│    df, meta = load_dataframes()")
    println("│    slugs = meta.slug[1:50]  # or meta.slug")
    println("│    lifespan_df = compute_variable_lifespan(df, slugs)")
    println("└" * "─"^74)

    # --- enrich_metadata_with_lifespan ---
    println("\n┌─ enrich_metadata_with_lifespan()")
    println("│  INTENT: Enrich the metadata DataFrame with temporal lifespan for every variable.")
    println("│  USE WHEN: You want one metadata table with birth/death, active, gap, profile.")
    println("│")
    println("│  RETURNS: DataFrame — meta_df with added columns:")
    println("│    ggis_birth_year, ggis_death_year, ggis_is_active,")
    println("│    ggis_temporal_gap, ggis_temporal_profile")
    println("│")
    println("│  USAGE:")
    println("│    enriched = enrich_metadata_with_lifespan()")
    println("│    first(enriched, 10)")
    println("│    CSV.write(\"data/qog_metadata_enriched.csv\", enriched)")
    println("└" * "─"^74)

    # --- compute_global_population_universe ---
    println("\n┌─ compute_global_population_universe(df)")
    println("│  INTENT: Pre-compute global population denominators for each year.")
    println("│  USE WHEN: You need year-level population totals for penetration calculations.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    df::DataFrame — must have :ident_year and :wpp_pop")
    println("│")
    println("│  RETURNS: DataFrame with columns [ident_year, total_global_pop]")
    println("│")
    println("│  USAGE:")
    println("│    df, _ = load_dataframes()")
    println("│    global_universe = compute_global_population_universe(df)")
    println("└" * "─"^74)

    # --- compute_regional_country_universe ---
    println("\n┌─ compute_regional_country_universe(df)")
    println("│  INTENT: Pre-compute country counts per region-year for denominators.")
    println("│  USE WHEN: You need region-year level country totals for penetration.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    df::DataFrame — must have :ident_year and :ggis_region")
    println("│")
    println("│  RETURNS: DataFrame with columns [ident_year, ggis_region, total_countries_in_region]")
    println("│")
    println("│  USAGE:")
    println("│    df, _ = load_dataframes()")
    println("│    regional_universe = compute_regional_country_universe(df)")
    println("└" * "─"^74)

    # --- compute_global_penetration ---
    println("\n┌─ compute_global_penetration(df, slug_sym, target_year, global_pop_universe)")
    println("│  INTENT: Compute global population penetration for one slug at a specific year.")
    println("│  USE WHEN: You need population-weighted global coverage for a single variable.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    df::DataFrame")
    println("│    slug_sym::Symbol — variable slug as symbol")
    println("│    target_year::Int — year to compute penetration")
    println("│    global_pop_universe::DataFrame — from compute_global_population_universe()")
    println("│")
    println("│  RETURNS: Float64 (0.0 to 1.0)")
    println("│")
    println("│  USAGE:")
    println("│    global_universe = compute_global_population_universe(df)")
    println("│    pen = compute_global_penetration(df, :wdi_gdp, 2022, global_universe)")
    println("└" * "─"^74)

    # --- compute_regional_penetrations ---
    println("\n┌─ compute_regional_penetrations(df, slug_sym, target_year, regional_universe)")
    println("│  INTENT: Compute country penetration for each region for one slug at a year.")
    println("│  USE WHEN: You need regional coverage percentages for a variable.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    df::DataFrame")
    println("│    slug_sym::Symbol — variable slug as symbol")
    println("│    target_year::Int — year to compute penetration")
    println("│    regional_universe::DataFrame — from compute_regional_country_universe()")
    println("│")
    println("│  RETURNS: Vector{Float64} (length 10, values 0.0 to 1.0)")
    println("│")
    println("│  USAGE:")
    println("│    regional_universe = compute_regional_country_universe(df)")
    println("│    pens = compute_regional_penetrations(df, :wdi_gdp, 2022, regional_universe)")
    println("└" * "─"^74)

    # --- classify_geographic_profile ---
    println("\n┌─ classify_geographic_profile(global_pen, regional_pens)")
    println("│  INTENT: Classify a variable as :global, :regional, or :other based on coverage.")
    println("│  USE WHEN: You have penetration metrics and need classification.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    global_pen::Float64 — global population penetration")
    println("│    regional_pens::Vector{Float64} — regional penetrations (length 10)")
    println("│")
    println("│  RETURNS: Symbol (:global, :regional, or :other)")
    println("│")
    println("│  USAGE:")
    println("│    classification = classify_geographic_profile(0.98, [0.95, 0.02, ...])")
    println("└" * "─"^74)

    # --- compute_geographic_coverage ---
    println("\n┌─ compute_geographic_coverage(df, lifespan_df)")
    println("│  INTENT: Compute geographic coverage for all variables at their death year.")
    println("│  USE WHEN: Auditing variables for global/regional reach and classification.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    df::DataFrame — must have :ident_year, :wpp_pop, :ggis_region")
    println("│    lifespan_df::DataFrame — must have :slug, :ggis_death_year")
    println("│")
    println("│  RETURNS: DataFrame with columns:")
    println("│    slug, ggis_global_penetration, ggis_geo_classification,")
    println("│    ggis_region_penetration (Vector{Float64})")
    println("│  (Also prints a classification summary.)")
    println("│")
    println("│  USAGE:")
    println("│    df, meta = load_dataframes()")
    println("│    lifespan_df = compute_variable_lifespan(df, meta.slug)")
    println("│    geo_df = compute_geographic_coverage(df, lifespan_df)")
    println("└" * "─"^74)

    # --- enrich_metadata_with_geographic_coverage ---
    println("\n┌─ enrich_metadata_with_geographic_coverage(enriched_df)")
    println("│  INTENT: Add geographic coverage columns to already temporally-enriched metadata.")
    println("│  USE WHEN: You have temporal enrichment and want to add geographic metrics.")
    println("│")
    println("│  ARGUMENTS:")
    println("│    enriched_df::DataFrame — from enrich_metadata_with_lifespan()")
    println("│")
    println("│  RETURNS: DataFrame with added columns:")
    println("│    ggis_global_penetration, ggis_geo_classification, ggis_region_penetration")
    println("│")
    println("│  USAGE:")
    println("│    enriched = enrich_metadata_with_lifespan()")
    println("│    enriched_with_geo = enrich_metadata_with_geographic_coverage(enriched)")
    println("│    CSV.write(\"data/qog_metadata_enriched.csv\", enriched_with_geo)")
    println("└" * "─"^74)

    println("\n" * "="^76)
    println("  TYPICAL WORKFLOW:")
    println("  1. enriched = enrich_metadata_with_lifespan()")
    println("  2. enriched_full = enrich_metadata_with_geographic_coverage(enriched)")
    println("  3. CSV.write(\"data/qog_metadata_enriched.csv\", enriched_full)")
    println("="^76 * "\n")
    return nothing
end

# Example usage (uncomment to run):
# run_enrich_metadata_samples()   # print intent & usage
#
# # Temporal enrichment
# enriched_metadata = enrich_metadata_with_lifespan()
# first(enriched_metadata, 10)
#
# # Add geographic coverage
# enriched_full = enrich_metadata_with_geographic_coverage(enriched_metadata)
# first(enriched_full, 10)
#
# # Save results
# CSV.write("data/qog_metadata_enriched.csv", enriched_full)
