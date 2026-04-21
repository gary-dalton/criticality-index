# ==============================================================================
# EXPERIMENT 01.02 — MANNA SANDPILE SIMULATOR
# ==============================================================================
#
# Manna (1991) stochastic sandpile on a 2D square lattice with open boundary
# conditions. Differs from BTW: each of the z_c = 2 grains dispatched on
# toppling is sent to an *independently* chosen uniform-random neighbor, with
# replacement. Same neighbor may receive both grains, or they may split.
#
# Universality class: Conserved Directed Percolation (C-DP). Simple scaling
# (no multiscaling, unlike BTW), so auto-xmin Clauset fitting is expected to
# be stable here.
#
# Published exponents (Dickman, Muñoz, Vespignani, Zapperi 2002; Lübeck 2004):
#   τ_s ≈ 1.273   (avalanche size)
#   τ_t ≈ 1.50    (avalanche duration)
#   D   ≈ 2.75    (fractal dimension of avalanche footprint)
#   ρ_c ≈ 0.683   (fixed-energy critical density)
#
# References:
#   Manna (1991). J. Phys. A: Math. Gen. 24, L363.
#   Dickman, Muñoz, Vespignani, Zapperi (2000). Braz. J. Phys. 30, 27.
#   Dickman, Alava, Muñoz, Peltola, Vespignani, Zapperi (2002). PRE 64, 056104.
#   Lübeck (2004). Int. J. Mod. Phys. B 18, 3977.
#
# Shares AvalancheRecord, EMPTY_AVALANCHE, NEIGHBOR_OFFSETS_2D with sandpile.jl
# (both files are included from load_validation.jl into the same scope).
#
# ==============================================================================

using Random


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Critical toppling threshold for 2D Manna sandpile. Fixed by the model
definition: each toppling dispatches 2 grains to independently random neighbors."""
const Z_C_MANNA_2D = 2

"""Approximate stationary mean height for 2D Manna sandpile with open
boundaries. The fixed-energy C-DP critical density is ρ_c ≈ 0.683
(Dickman et al. 2002). The driven open-boundary variant should approach
this in the bulk; use as a warning threshold only — refine after the
first :explore burn-in trace."""
const EXPECTED_MEAN_Z_MANNA_2D = 0.68


# ==============================================================================
# SIMULATION
# ==============================================================================

"""
Run a Manna sandpile simulation on an L x L lattice.

Arguments
    L::Int                 — lattice side length
    N_transient::Int       — grains dropped before recording (steady state)
    N_record::Int          — avalanches recorded after transient
    z_c::Int = Z_C_MANNA_2D — toppling threshold
    initial_condition::Symbol = :empty — :empty (build up from z=0) or
                                          :overloaded (z in [z_c, 2z_c))
    seed::Union{Nothing,Int} = nothing — RNG seed for reproducibility

Returns
    NamedTuple with:
        catalog       — Vector{AvalancheRecord} of length N_record
        final_height  — Matrix{Int} of lattice heights at end of simulation
        n_grains      — total grains dropped (N_transient + N_record)

Rules
    - Drop one grain per step at a uniformly random site
    - If the receiving site reaches z_c, run an avalanche to completion
      before dropping the next grain
    - Parallel toppling: all sites with z >= z_c at start of a wave topple
      simultaneously. Manna is abelian-in-distribution, so parallel and
      sequential give identical avalanche-statistics distributions.
    - Per toppling: site loses z_c grains; each of the z_c grains is sent
      to an independently sampled uniform-random neighbor (the 4 offsets
      are sampled with replacement)
    - Out-of-bounds targets dissipate and increment the per-avalanche
      n_dissipated counter (when record=true)
    - Transient phase is not recorded

Usage
    result = manna_sandpile(128, N_transient=200_000, N_record=50_000, seed=1)
    sizes = avalanche_sizes(result.catalog)
"""
function manna_sandpile(L::Int;
                        N_transient::Int,
                        N_record::Int,
                        z_c::Int = Z_C_MANNA_2D,
                        initial_condition::Symbol = :empty,
                        seed::Union{Nothing, Int} = nothing)
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)

    current_wave = Tuple{Int, Int}[]
    next_wave = Tuple{Int, Int}[]
    sizehint!(current_wave, L * L)
    sizehint!(next_wave, L * L)

    if initial_condition == :empty
        z = zeros(Int, L, L)
    elseif initial_condition == :overloaded
        z = rand(rng, z_c:(2 * z_c - 1), L, L)
        for i in 1:L, j in 1:L
            push!(current_wave, (i, j))
        end
        relax_manna!(z, L, z_c, current_wave, next_wave, rng)
    else
        error("initial_condition must be :empty or :overloaded, got :$initial_condition")
    end

    for _ in 1:N_transient
        i = rand(rng, 1:L)
        j = rand(rng, 1:L)
        z[i, j] += 1
        if z[i, j] >= z_c
            run_manna_avalanche!(z, i, j, L, z_c, current_wave, next_wave, rng;
                                 record = false)
        end
    end

    catalog = Vector{AvalancheRecord}(undef, N_record)
    for k in 1:N_record
        i = rand(rng, 1:L)
        j = rand(rng, 1:L)
        z[i, j] += 1
        if z[i, j] >= z_c
            catalog[k] = run_manna_avalanche!(z, i, j, L, z_c,
                                              current_wave, next_wave, rng;
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
Run a Manna sandpile with adaptive burn-in — detect steady state from the
observed mean height and dissipation rate, then begin recording.

Arguments
    L::Int                               — lattice side length
    N_record::Int                        — avalanches to record after steady state
    z_c::Int = Z_C_MANNA_2D              — toppling threshold
    initial_condition::Symbol = :empty   — :empty or :overloaded
    check_every::Int = 1000              — check convergence every N grains
    z_range_threshold::Float64 = 0.02    — max range of mean_z over check window
    dissipation_band::Tuple = (0.9, 1.1) — acceptable range for dissipation_rate
    consecutive_passes::Int = 5          — windows that must pass both tests
    max_burnin_grains::Union{Nothing,Int} = nothing — safety cap (default 20*L²)
    seed::Union{Nothing,Int} = nothing   — RNG seed

Returns
    NamedTuple with fields: catalog, final_height, n_burnin_grains, converged,
    burnin_trace (Vector of NamedTuples with diagnostic columns).

Rules
    - Convergence conditions (must hold for `consecutive_passes` windows):
        * range(mean_z) over last K windows < z_range_threshold
        * mean(dissipation_rate_recent) in dissipation_band
    - For 2D Manna, mean_z → ≈ 0.68 and dissipation_rate → 1.0 at steady state
    - z_range_threshold = 0.02 is absolute (same default as BTW); this is
      ~3% of Manna's expected mean_z vs ~1% for BTW — flag for tightening
      if the burn-in trace shows premature convergence

Usage
    result = manna_sandpile_adaptive(128; N_record=50_000, seed=1)
"""
function manna_sandpile_adaptive(L::Int;
                                  N_record::Int,
                                  z_c::Int = Z_C_MANNA_2D,
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

    if initial_condition == :empty
        z = zeros(Int, L, L)
    elseif initial_condition == :overloaded
        z = rand(rng, z_c:(2 * z_c - 1), L, L)
        for i in 1:L, j in 1:L
            push!(current_wave, (i, j))
        end
        relax_manna!(z, L, z_c, current_wave, next_wave, rng)
    else
        error("initial_condition must be :empty or :overloaded, got :$initial_condition")
    end

    initial_mass = sum(z)

    trace = NamedTuple[]
    sizes_since_log = Int[]
    sizehint!(sizes_since_log, check_every)
    last_dissipation = 0
    k = 0

    recent_mean_z = Float64[]
    recent_dissipation = Float64[]
    converged = false

    while k < max_burnin
        k += 1
        i = rand(rng, 1:L)
        j = rand(rng, 1:L)
        z[i, j] += 1
        if z[i, j] >= z_c
            rec = run_manna_avalanche!(z, i, j, L, z_c,
                                       current_wave, next_wave, rng;
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

    catalog = Vector{AvalancheRecord}(undef, N_record)
    for j in 1:N_record
        ii = rand(rng, 1:L)
        jj = rand(rng, 1:L)
        z[ii, jj] += 1
        if z[ii, jj] >= z_c
            catalog[j] = run_manna_avalanche!(z, ii, jj, L, z_c,
                                              current_wave, next_wave, rng;
                                              record = true)
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
Run a single Manna avalanche using parallel toppling waves.

Arguments
    z::Matrix{Int}                       — lattice heights (modified in place)
    i_start::Int, j_start::Int           — trigger site
    L::Int                               — lattice side length
    z_c::Int                             — toppling threshold
    current_wave::Vector{Tuple{Int,Int}} — pre-allocated scratch
    next_wave::Vector{Tuple{Int,Int}}    — pre-allocated scratch
    rng                                  — RNG (required; toppling is stochastic)
    record::Bool = true                  — whether to compute statistics

Returns
    AvalancheRecord (or EMPTY_AVALANCHE if record=false)

Rules
    - Wave t: all sites currently unstable (z >= z_c) topple simultaneously
    - Each toppling: site loses z_c grains; each of the z_c grains is sent
      to an independent uniform-random neighbor (with replacement)
    - Out-of-bounds targets dissipate; increment n_dissipated counter if record
    - Wave t+1: check toppled site AND all 4 geometric neighbors for instability
      (a neighbor may have received grains via any of the z_c random draws,
      so we cannot narrow by draw direction)
    - Continues until no unstable sites remain
"""
function run_manna_avalanche!(z::Matrix{Int}, i_start::Int, j_start::Int,
                              L::Int, z_c::Int,
                              current_wave::Vector{Tuple{Int, Int}},
                              next_wave::Vector{Tuple{Int, Int}},
                              rng;
                              record::Bool = true)
    empty!(current_wave)
    empty!(next_wave)
    push!(current_wave, (i_start, j_start))

    total_topplings = 0
    duration = 0
    max_extent_sq = 0.0
    n_dissipated_local = 0
    wave_profile = record ? Int[] : Int[]
    area_set = record ? Set{Tuple{Int, Int}}() : Set{Tuple{Int, Int}}()

    while !isempty(current_wave)
        duration += 1
        n_in_wave = length(current_wave)

        if record
            push!(wave_profile, n_in_wave)
            total_topplings += n_in_wave
        end

        for (i, j) in current_wave
            z[i, j] -= z_c

            if record
                push!(area_set, (i, j))
                d_sq = Float64((i - i_start)^2 + (j - j_start)^2)
                if d_sq > max_extent_sq
                    max_extent_sq = d_sq
                end
            end

            # Independently sample a neighbor for each of the z_c grains
            for _ in 1:z_c
                (di, dj) = NEIGHBOR_OFFSETS_2D[rand(rng, 1:length(NEIGHBOR_OFFSETS_2D))]
                ni = i + di
                nj = j + dj
                if 1 <= ni <= L && 1 <= nj <= L
                    z[ni, nj] += 1
                elseif record
                    n_dissipated_local += 1
                end
            end
        end

        # Build next wave: toppled site may still be unstable, and any of its
        # 4 geometric neighbors may have received grains this wave.
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
Relax a Manna lattice from an arbitrary unstable configuration to stability.

Arguments
    z, L, z_c, current_wave, next_wave, rng — see run_manna_avalanche!

Returns
    nothing — modifies z in place

Rules
    - Used when initializing with :overloaded; caller seeds current_wave with
      all initially unstable sites before calling
    - Same stochastic toppling as run_manna_avalanche! but without
      per-avalanche bookkeeping
"""
function relax_manna!(z::Matrix{Int}, L::Int, z_c::Int,
                      current_wave::Vector{Tuple{Int, Int}},
                      next_wave::Vector{Tuple{Int, Int}},
                      rng)
    while !isempty(current_wave)
        for (i, j) in current_wave
            z[i, j] -= z_c
            for _ in 1:z_c
                (di, dj) = NEIGHBOR_OFFSETS_2D[rand(rng, 1:length(NEIGHBOR_OFFSETS_2D))]
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
Run a Manna sandpile while logging convergence diagnostics.

Arguments
    L::Int                            — lattice side length
    N_grains::Int                     — total grains to drop
    log_every::Int = 1000             — record diagnostics every N grain drops
    z_c::Int = Z_C_MANNA_2D           — toppling threshold
    initial_condition::Symbol = :empty — :empty or :overloaded
    seed::Union{Nothing,Int} = nothing — RNG seed

Returns
    Vector of NamedTuples (one per log point) with fields:
        step, mean_z, cumulative_dissipation,
        dissipation_rate_recent, mean_avalanche_size_recent

Rules
    - For 2D Manna, empty start:
        * mean_z → ≈ 0.68 (C-DP critical density)
        * dissipation_rate_recent → 1.0 (conservation in steady state)
        * mean_avalanche_size_recent → stationary value
    - Use once per L to choose N_transient, then run manna_sandpile
      (or just use manna_sandpile_adaptive which detects steady state)

Usage
    trace = manna_burnin_trace(128; N_grains=200_000, log_every=2000, seed=1)
"""
function manna_burnin_trace(L::Int;
                            N_grains::Int,
                            log_every::Int = 1000,
                            z_c::Int = Z_C_MANNA_2D,
                            initial_condition::Symbol = :empty,
                            seed::Union{Nothing, Int} = nothing)
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)

    current_wave = Tuple{Int, Int}[]
    next_wave = Tuple{Int, Int}[]
    sizehint!(current_wave, L * L)
    sizehint!(next_wave, L * L)

    if initial_condition == :empty
        z = zeros(Int, L, L)
    elseif initial_condition == :overloaded
        z = rand(rng, z_c:(2 * z_c - 1), L, L)
        for i in 1:L, j in 1:L
            push!(current_wave, (i, j))
        end
        relax_manna!(z, L, z_c, current_wave, next_wave, rng)
    else
        error("initial_condition must be :empty or :overloaded, got :$initial_condition")
    end

    initial_mass = sum(z)

    trace = NamedTuple[]
    sizes_since_log = Int[]
    sizehint!(sizes_since_log, log_every)
    last_dissipation = 0

    for k in 1:N_grains
        i = rand(rng, 1:L)
        j = rand(rng, 1:L)
        z[i, j] += 1
        if z[i, j] >= z_c
            rec = run_manna_avalanche!(z, i, j, L, z_c,
                                       current_wave, next_wave, rng;
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
