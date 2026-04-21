# ==============================================================================
# EXPERIMENT 01 — SANDPILE SIMULATORS
# ==============================================================================
#
# Bak-Tang-Wiesenfeld (BTW) sandpile on a 2D square lattice with open
# boundary conditions. Implements parallel toppling for clean wave structure
# (per Dhar 1990 Abelian property, the final state is independent of toppling
# order, so parallel and sequential give identical avalanche statistics).
#
# Output:
#   - AvalancheRecord per recorded avalanche (size, duration, area, extent,
#     wave profile)
#
# References:
#   Bak, Tang, Wiesenfeld (1987). Phys. Rev. Lett. 59, 381.
#   Dhar (1999). Physica A 263, 4-25.
#
# ==============================================================================

using Random


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Critical toppling threshold for 2D square lattice BTW sandpile.
Fixed by lattice geometry: each site has 4 nearest neighbors."""
const Z_C_BTW_2D = 4

"""Neighbor offsets for 2D square lattice (4-connectivity)."""
const NEIGHBOR_OFFSETS_2D = ((-1, 0), (1, 0), (0, -1), (0, 1))


# ==============================================================================
# AVALANCHE RECORD
# ==============================================================================

"""Single avalanche statistics from one grain drop.

Fields
    size           — total topplings during the avalanche
    duration       — number of parallel toppling waves
    area           — distinct sites that toppled at least once
    max_extent     — maximum Euclidean distance from origin to any toppled site
    n_dissipated   — grains that left the lattice during this avalanche
    wave_profile   — topplings per wave (length == duration)

Rules
    - `n_dissipated` counts grains that exit the system from any cause.
      Today only perimeter out-of-bounds distributions increment it.
      Future surface-dissipation mechanisms (bulk leak ε, per-site leak
      field, discrete drain sites, height-cap overflow) increment the
      same counter so downstream analysis is mechanism-agnostic.
"""
struct AvalancheRecord
    size::Int
    duration::Int
    area::Int
    max_extent::Float64
    n_dissipated::Int
    wave_profile::Vector{Int}
end

"""Empty avalanche (grain dropped on a stable site that did not topple)."""
const EMPTY_AVALANCHE = AvalancheRecord(0, 0, 0, 0.0, 0, Int[])


# ==============================================================================
# SIMULATION
# ==============================================================================

"""
Run a BTW sandpile simulation on an L x L lattice.

Arguments
    L::Int                 — lattice side length
    N_transient::Int       — grains dropped before recording (steady state)
    N_record::Int          — avalanches recorded after transient
    z_c::Int = Z_C_BTW_2D  — critical toppling threshold
    initial_condition::Symbol = :empty — :empty (build up from z=0) or
                                          :overloaded (z >> z_c, original BTW 1987)
    seed::Union{Nothing,Int} = nothing — RNG seed for reproducibility

Returns
    NamedTuple with:
        catalog       — Vector{AvalancheRecord} of length N_record
        final_height  — Matrix{Int} of lattice heights at end of simulation
        n_grains      — total grains dropped (N_transient + N_record)

Rules
    - :empty initial condition (default): lattice starts at z=0, fills via
      grain-by-grain dropping. Tests self-organization from below.
    - :overloaded initial condition: each site initialized to a uniform
      random integer in [z_c, 2*z_c). Initial massive cascade brings the
      system into the recurrent class quickly. This is the original BTW
      1987 setup. Either way, transient phase is discarded.
    - Drop one grain per step at uniformly random site
    - If receiving site reaches z_c, run avalanche to completion before next drop
    - Parallel toppling: all sites unstable at start of wave topple simultaneously
    - Sites at lattice boundary lose grains that would exit the grid (dissipation)
    - Transient phase is not recorded; recording phase captures all avalanches
      including empty ones (grains dropped on stable sites)

Usage
    result = btw_sandpile(128, N_transient=100_000, N_record=10_000, seed=42)
    # Or with original BTW 1987 initial condition:
    result = btw_sandpile(128, N_transient=10_000, N_record=10_000,
                          initial_condition=:overloaded, seed=42)
    catalog = result.catalog
    sizes = [a.size for a in catalog if a.size > 0]
"""
function btw_sandpile(L::Int;
                     N_transient::Int,
                     N_record::Int,
                     z_c::Int = Z_C_BTW_2D,
                     initial_condition::Symbol = :empty,
                     seed::Union{Nothing, Int} = nothing)
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)

    # Pre-allocated buffers reused across avalanches and any initial relaxation
    current_wave = Tuple{Int, Int}[]
    next_wave = Tuple{Int, Int}[]
    sizehint!(current_wave, L * L)
    sizehint!(next_wave, L * L)

    # --- Initial condition ---
    if initial_condition == :empty
        z = zeros(Int, L, L)
    elseif initial_condition == :overloaded
        # Original BTW 1987: random heights above critical threshold.
        # Uniform integers in [z_c, 2*z_c) ensures every site is unstable.
        z = rand(rng, z_c:(2 * z_c - 1), L, L)
        # Relax the initial overloaded state to a stable configuration
        # before starting the transient grain-drop counting.
        for i in 1:L, j in 1:L
            push!(current_wave, (i, j))
        end
        relax_avalanche!(z, L, z_c, current_wave, next_wave)
    else
        error("initial_condition must be :empty or :overloaded, got :$initial_condition")
    end

    # --- Transient phase: reach steady state ---
    for _ in 1:N_transient
        i = rand(rng, 1:L)
        j = rand(rng, 1:L)
        z[i, j] += 1
        if z[i, j] >= z_c
            run_avalanche!(z, i, j, L, z_c, current_wave, next_wave;
                          record = false)
        end
    end

    # --- Recording phase ---
    catalog = Vector{AvalancheRecord}(undef, N_record)
    for k in 1:N_record
        i = rand(rng, 1:L)
        j = rand(rng, 1:L)
        z[i, j] += 1
        if z[i, j] >= z_c
            catalog[k] = run_avalanche!(z, i, j, L, z_c, current_wave, next_wave;
                                       record = true)
        else
            catalog[k] = EMPTY_AVALANCHE
        end
    end

    return (catalog = catalog,
            final_height = copy(z),
            n_grains = N_transient + N_record)
end


"""
Run a BTW sandpile with adaptive burn-in — detect steady state automatically
from the observed mean height and dissipation rate, then begin recording.

Arguments
    L::Int                               — lattice side length
    N_record::Int                        — avalanches to record after steady state
    z_c::Int = Z_C_BTW_2D                — critical toppling threshold
    initial_condition::Symbol = :empty   — :empty or :overloaded
    check_every::Int = 1000              — check convergence every N grains
    z_range_threshold::Float64 = 0.02    — max range of mean_z over check window
    dissipation_band::Tuple = (0.9, 1.1) — acceptable range for dissipation_rate
    consecutive_passes::Int = 5          — windows that must pass both tests
    max_burnin_grains::Union{Nothing,Int} = nothing — safety cap (default 20*L²)
    seed::Union{Nothing,Int} = nothing   — RNG seed

Returns
    NamedTuple with:
        catalog          — Vector{AvalancheRecord} of length N_record
        final_height     — lattice heights at end of simulation
        n_burnin_grains  — grains consumed during adaptive burn-in
        converged        — true if steady state was detected; false if
                           max_burnin_grains hit first
        burnin_trace     — Vector of NamedTuples (same as btw_burnin_trace)
                           for diagnosis

Rules
    - Burn-in runs without recording until convergence conditions hold:
        * range(mean_z) over last K windows < z_range_threshold
        * mean(dissipation_rate_recent) over last K windows in dissipation_band
      where K = consecutive_passes
    - Once detected, records exactly N_record avalanches
    - Safety cap: if max_burnin_grains is reached without convergence,
      returns converged=false and proceeds to recording anyway
    - Default max_burnin_grains = 20*L² is very generous (transition happens
      at ~2.15*L² empirically)

Usage
    result = btw_sandpile_adaptive(128; N_record=200_000, seed=42)
    if !result.converged
        @warn "Burn-in did not converge; results may be non-stationary"
    end
    println("Burn-in took \$(result.n_burnin_grains) grains")
"""
function btw_sandpile_adaptive(L::Int;
                              N_record::Int,
                              z_c::Int = Z_C_BTW_2D,
                              initial_condition::Symbol = :empty,
                              check_every::Int = 1000,
                              z_range_threshold::Float64 = 0.02,
                              dissipation_band::Tuple = (0.9, 1.1),
                              consecutive_passes::Int = 5,
                              max_burnin_grains::Union{Nothing, Int} = nothing,
                              seed::Union{Nothing, Int} = nothing)
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    max_burnin = isnothing(max_burnin_grains) ? 20 * L * L : max_burnin_grains

    current_wave = Tuple{Int, Int}[]
    next_wave = Tuple{Int, Int}[]
    sizehint!(current_wave, L * L)
    sizehint!(next_wave, L * L)

    # Initial condition
    if initial_condition == :empty
        z = zeros(Int, L, L)
    elseif initial_condition == :overloaded
        z = rand(rng, z_c:(2 * z_c - 1), L, L)
        for i in 1:L, j in 1:L
            push!(current_wave, (i, j))
        end
        relax_avalanche!(z, L, z_c, current_wave, next_wave)
    else
        error("initial_condition must be :empty or :overloaded, got :$initial_condition")
    end

    initial_mass = sum(z)

    # Adaptive burn-in with trace
    trace = NamedTuple[]
    sizes_since_log = Int[]
    sizehint!(sizes_since_log, check_every)
    last_dissipation = 0
    k = 0  # grain counter

    recent_mean_z = Float64[]
    recent_dissipation = Float64[]
    converged = false

    while k < max_burnin
        k += 1
        i = rand(rng, 1:L)
        j = rand(rng, 1:L)
        z[i, j] += 1
        if z[i, j] >= z_c
            rec = run_avalanche!(z, i, j, L, z_c, current_wave, next_wave;
                                record = true)
            push!(sizes_since_log, rec.size)
        else
            push!(sizes_since_log, 0)
        end

        if k % check_every == 0
            current_mass = sum(z)
            cumulative_dissipation = (initial_mass + k) - current_mass
            recent_diss = (cumulative_dissipation - last_dissipation) / check_every
            mean_z_val = current_mass / (L * L)
            push!(trace, (
                step = k,
                mean_z = mean_z_val,
                cumulative_dissipation = cumulative_dissipation,
                dissipation_rate_recent = recent_diss,
                mean_avalanche_size_recent = mean(sizes_since_log),
            ))
            last_dissipation = cumulative_dissipation
            empty!(sizes_since_log)

            # Convergence test
            push!(recent_mean_z, mean_z_val)
            push!(recent_dissipation, recent_diss)
            if length(recent_mean_z) > consecutive_passes
                popfirst!(recent_mean_z)
                popfirst!(recent_dissipation)
            end

            if length(recent_mean_z) == consecutive_passes
                z_range = maximum(recent_mean_z) - minimum(recent_mean_z)
                diss_mean = mean(recent_dissipation)
                if z_range < z_range_threshold &&
                   dissipation_band[1] <= diss_mean <= dissipation_band[2]
                    converged = true
                    break
                end
            end
        end
    end

    n_burnin_grains = k

    # Recording phase
    catalog = Vector{AvalancheRecord}(undef, N_record)
    for j in 1:N_record
        ii = rand(rng, 1:L)
        jj = rand(rng, 1:L)
        z[ii, jj] += 1
        if z[ii, jj] >= z_c
            catalog[j] = run_avalanche!(z, ii, jj, L, z_c,
                                       current_wave, next_wave; record = true)
        else
            catalog[j] = EMPTY_AVALANCHE
        end
    end

    return (catalog = catalog,
            final_height = copy(z),
            n_burnin_grains = n_burnin_grains,
            converged = converged,
            burnin_trace = trace)
end


"""
Run a single avalanche to completion using parallel toppling waves.

Arguments
    z::Matrix{Int}                       — lattice heights (modified in place)
    i_start::Int, j_start::Int           — site where grain triggered the avalanche
    L::Int                               — lattice side length
    z_c::Int                             — toppling threshold
    current_wave::Vector{Tuple{Int,Int}} — pre-allocated buffer
    next_wave::Vector{Tuple{Int,Int}}    — pre-allocated buffer
    record::Bool = true                  — whether to compute and return statistics

Returns
    AvalancheRecord (or EMPTY_AVALANCHE if record=false)

Rules
    - Wave t: all sites currently unstable (z >= z_c) topple simultaneously
    - Each toppling: site loses z_c grains, each of 4 neighbors gains 1 grain
    - Out-of-bounds neighbors: grain is lost (boundary dissipation)
    - Wave t+1: any site (toppled or neighbor) now at z >= z_c
    - Continues until no unstable sites remain
    - In parallel toppling, a site topples at most once per wave even if it
      remains unstable; it will topple again in the next wave if still unstable
"""
function run_avalanche!(z::Matrix{Int}, i_start::Int, j_start::Int,
                       L::Int, z_c::Int,
                       current_wave::Vector{Tuple{Int, Int}},
                       next_wave::Vector{Tuple{Int, Int}};
                       record::Bool = true)
    empty!(current_wave)
    empty!(next_wave)
    push!(current_wave, (i_start, j_start))

    # Recording state (only updated if record=true)
    total_topplings = 0
    duration = 0
    max_extent_sq = 0.0
    n_dissipated_local = 0
    wave_profile = record ? Int[] : Int[]
    # Track unique sites for area count via a Set
    area_set = record ? Set{Tuple{Int, Int}}() : Set{Tuple{Int, Int}}()

    while !isempty(current_wave)
        duration += 1
        n_in_wave = length(current_wave)

        if record
            push!(wave_profile, n_in_wave)
            total_topplings += n_in_wave
        end

        # All sites in current_wave topple
        for (i, j) in current_wave
            z[i, j] -= z_c

            if record
                push!(area_set, (i, j))
                d_sq = Float64((i - i_start)^2 + (j - j_start)^2)
                if d_sq > max_extent_sq
                    max_extent_sq = d_sq
                end
            end

            # Distribute grains to neighbors (boundary dissipation if out of grid)
            for (di, dj) in NEIGHBOR_OFFSETS_2D
                ni = i + di
                nj = j + dj
                if 1 <= ni <= L && 1 <= nj <= L
                    z[ni, nj] += 1
                elseif record
                    n_dissipated_local += 1
                end
            end
        end

        # Build next wave: any currently unstable site
        # Check toppled sites and their neighbors (the only sites whose z changed)
        empty!(next_wave)
        seen = Set{Tuple{Int, Int}}()  # dedupe within wave

        for (i, j) in current_wave
            # Toppled site itself may still be unstable
            if z[i, j] >= z_c && !((i, j) in seen)
                push!(next_wave, (i, j))
                push!(seen, (i, j))
            end
            # Neighbors received grains; check each
            for (di, dj) in NEIGHBOR_OFFSETS_2D
                ni = i + di
                nj = j + dj
                if 1 <= ni <= L && 1 <= nj <= L &&
                   z[ni, nj] >= z_c && !((ni, nj) in seen)
                    push!(next_wave, (ni, nj))
                    push!(seen, (ni, nj))
                end
            end
        end

        # Swap buffers
        current_wave, next_wave = next_wave, current_wave
    end

    if !record
        return EMPTY_AVALANCHE
    end

    return AvalancheRecord(
        total_topplings,
        duration,
        length(area_set),
        sqrt(max_extent_sq),
        n_dissipated_local,
        wave_profile
    )
end


"""
Relax the lattice from an arbitrary unstable configuration to a stable one.

Arguments
    z::Matrix{Int}                       — lattice heights (modified in place)
    L::Int                               — lattice side length
    z_c::Int                             — toppling threshold
    current_wave::Vector{Tuple{Int,Int}} — pre-populated with all initially
                                           unstable sites; modified in place
    next_wave::Vector{Tuple{Int,Int}}    — pre-allocated scratch buffer

Returns
    nothing — modifies z to a fully stable configuration (all sites < z_c)

Rules
    - Used when initializing with the :overloaded condition (BTW 1987)
    - Same parallel toppling logic as run_avalanche! but without per-avalanche
      bookkeeping and without a single origin point
    - Caller must seed current_wave with all unstable sites before calling
"""
function relax_avalanche!(z::Matrix{Int}, L::Int, z_c::Int,
                         current_wave::Vector{Tuple{Int, Int}},
                         next_wave::Vector{Tuple{Int, Int}})
    while !isempty(current_wave)
        for (i, j) in current_wave
            z[i, j] -= z_c
            for (di, dj) in NEIGHBOR_OFFSETS_2D
                ni = i + di
                nj = j + dj
                if 1 <= ni <= L && 1 <= nj <= L
                    z[ni, nj] += 1
                end
            end
        end

        empty!(next_wave)
        seen = Set{Tuple{Int, Int}}()
        for (i, j) in current_wave
            if z[i, j] >= z_c && !((i, j) in seen)
                push!(next_wave, (i, j))
                push!(seen, (i, j))
            end
            for (di, dj) in NEIGHBOR_OFFSETS_2D
                ni = i + di
                nj = j + dj
                if 1 <= ni <= L && 1 <= nj <= L &&
                   z[ni, nj] >= z_c && !((ni, nj) in seen)
                    push!(next_wave, (ni, nj))
                    push!(seen, (ni, nj))
                end
            end
        end

        current_wave, next_wave = next_wave, current_wave
    end
    return nothing
end


# ==============================================================================
# BURN-IN / CONVERGENCE DIAGNOSTICS
# ==============================================================================

"""
Run a BTW sandpile while logging convergence diagnostics, to determine
empirically when the system has reached steady state.

Arguments
    L::Int                            — lattice side length
    N_grains::Int                     — total grains to drop
    log_every::Int = 1000             — record diagnostics every N grain drops
    z_c::Int = Z_C_BTW_2D             — critical toppling threshold
    initial_condition::Symbol = :empty — :empty or :overloaded
    seed::Union{Nothing,Int} = nothing — RNG seed

Returns
    Vector of NamedTuples (one per log point) with fields:
        step                       — grain drops completed
        mean_z                     — current mean lattice height
        cumulative_dissipation     — total grains lost at boundary so far
        dissipation_rate_recent    — grains lost per drop in last log_every steps
        mean_avalanche_size_recent — mean avalanche size in last log_every drops
                                     (including empty avalanches)

Rules
    - Convergence indicators (for 2D BTW, empty start):
        * mean_z → 17/8 = 2.125 (Dhar 1999, exact stationary value)
        * dissipation_rate_recent → 1.0 (one grain out per grain in)
        * mean_avalanche_size_recent → stationary value
    - All three should plateau when the system reaches the recurrent class
    - For :overloaded start: initial relaxation happens before grain dropping
      (and is not counted in N_grains); convergence should be much faster
    - Use this once per lattice size to choose an appropriate N_transient,
      then use that value in btw_sandpile production runs

Usage
    trace = btw_burnin_trace(128; N_grains=200_000, log_every=2000, seed=1)
    # Plot trace.mean_z vs trace.step to see convergence
"""
function btw_burnin_trace(L::Int;
                         N_grains::Int,
                         log_every::Int = 1000,
                         z_c::Int = Z_C_BTW_2D,
                         initial_condition::Symbol = :empty,
                         seed::Union{Nothing, Int} = nothing)
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)

    current_wave = Tuple{Int, Int}[]
    next_wave = Tuple{Int, Int}[]
    sizehint!(current_wave, L * L)
    sizehint!(next_wave, L * L)

    # Initial condition (same as btw_sandpile)
    if initial_condition == :empty
        z = zeros(Int, L, L)
    elseif initial_condition == :overloaded
        z = rand(rng, z_c:(2 * z_c - 1), L, L)
        for i in 1:L, j in 1:L
            push!(current_wave, (i, j))
        end
        relax_avalanche!(z, L, z_c, current_wave, next_wave)
    else
        error("initial_condition must be :empty or :overloaded, got :$initial_condition")
    end

    initial_mass = sum(z)

    trace = NamedTuple[]
    sizes_since_log = Int[]
    sizehint!(sizes_since_log, log_every)
    last_dissipation = 0  # cumulative grains lost at end of previous log point

    for k in 1:N_grains
        i = rand(rng, 1:L)
        j = rand(rng, 1:L)
        z[i, j] += 1
        if z[i, j] >= z_c
            rec = run_avalanche!(z, i, j, L, z_c, current_wave, next_wave;
                                record = true)
            push!(sizes_since_log, rec.size)
        else
            push!(sizes_since_log, 0)
        end

        if k % log_every == 0
            current_mass = sum(z)
            cumulative_dissipation = (initial_mass + k) - current_mass
            recent_dissipation = cumulative_dissipation - last_dissipation
            push!(trace, (
                step = k,
                mean_z = current_mass / (L * L),
                cumulative_dissipation = cumulative_dissipation,
                dissipation_rate_recent = recent_dissipation / log_every,
                mean_avalanche_size_recent = mean(sizes_since_log),
            ))
            last_dissipation = cumulative_dissipation
            empty!(sizes_since_log)
        end
    end

    return trace
end


# ==============================================================================
# CATALOG UTILITIES
# ==============================================================================

"""Extract avalanche sizes from a catalog, optionally excluding empty avalanches.

Arguments
    catalog::Vector{AvalancheRecord}
    exclude_empty::Bool = true — drop avalanches with size == 0

Returns
    Vector{Int} of avalanche sizes

Rules
    - Empty avalanches occur when a grain is dropped on a stable site
    - For most diagnostics, empty avalanches are not events and should be excluded

Usage
    sizes = avalanche_sizes(result.catalog)
"""
function avalanche_sizes(catalog::Vector{AvalancheRecord}; exclude_empty::Bool = true)
    if exclude_empty
        return [a.size for a in catalog if a.size > 0]
    else
        return [a.size for a in catalog]
    end
end

"""Extract avalanche durations from a catalog. See avalanche_sizes for details."""
function avalanche_durations(catalog::Vector{AvalancheRecord}; exclude_empty::Bool = true)
    if exclude_empty
        return [a.duration for a in catalog if a.size > 0]
    else
        return [a.duration for a in catalog]
    end
end

"""Extract avalanche areas (distinct toppled sites) from a catalog."""
function avalanche_areas(catalog::Vector{AvalancheRecord}; exclude_empty::Bool = true)
    if exclude_empty
        return [a.area for a in catalog if a.size > 0]
    else
        return [a.area for a in catalog]
    end
end

"""Extract maximum spatial extents from a catalog."""
function avalanche_extents(catalog::Vector{AvalancheRecord}; exclude_empty::Bool = true)
    if exclude_empty
        return [a.max_extent for a in catalog if a.size > 0]
    else
        return [a.max_extent for a in catalog]
    end
end

"""Extract grains that left the lattice during each avalanche.

Arguments
    catalog::Vector{AvalancheRecord}
    exclude_empty::Bool = true — drop avalanches with size == 0

Returns
    Vector{Int} of dissipation counts

Rules
    - In steady state, mean value should approach 1 (one grain in per grain drop,
      one grain out for conservation). Per-event values range from 0 (interior
      avalanche) to many (large boundary-reaching avalanche).
    - Currently reflects perimeter-only dissipation; extensions to bulk leak,
      drain sites, or graph surfaces will increment the same field with no
      signature change.

Usage
    diss = avalanche_dissipations(result.catalog)
"""
function avalanche_dissipations(catalog::Vector{AvalancheRecord}; exclude_empty::Bool = true)
    if exclude_empty
        return [a.n_dissipated for a in catalog if a.size > 0]
    else
        return [a.n_dissipated for a in catalog]
    end
end
