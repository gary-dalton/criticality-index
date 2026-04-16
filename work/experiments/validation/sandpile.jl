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
    wave_profile   — topplings per wave (length == duration)
"""
struct AvalancheRecord
    size::Int
    duration::Int
    area::Int
    max_extent::Float64
    wave_profile::Vector{Int}
end

"""Empty avalanche (grain dropped on a stable site that did not topple)."""
const EMPTY_AVALANCHE = AvalancheRecord(0, 0, 0, 0.0, Int[])


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
    seed::Union{Nothing,Int} = nothing — RNG seed for reproducibility

Returns
    NamedTuple with:
        catalog       — Vector{AvalancheRecord} of length N_record
        final_height  — Matrix{Int} of lattice heights at end of simulation
        n_grains      — total grains dropped (N_transient + N_record)

Rules
    - Initialize lattice to all zeros
    - Drop one grain per step at uniformly random site
    - If receiving site reaches z_c, run avalanche to completion before next drop
    - Parallel toppling: all sites unstable at start of wave topple simultaneously
    - Sites at lattice boundary lose grains that would exit the grid (dissipation)
    - Transient phase is not recorded; recording phase captures all avalanches
      including empty ones (grains dropped on stable sites)

Usage
    result = btw_sandpile(128, N_transient=100_000, N_record=10_000, seed=42)
    catalog = result.catalog
    sizes = [a.size for a in catalog if a.size > 0]
"""
function btw_sandpile(L::Int;
                     N_transient::Int,
                     N_record::Int,
                     z_c::Int = Z_C_BTW_2D,
                     seed::Union{Nothing, Int} = nothing)
    rng = isnothing(seed) ? Random.default_rng() : MersenneTwister(seed)
    z = zeros(Int, L, L)

    # Pre-allocated buffers reused across avalanches
    current_wave = Tuple{Int, Int}[]
    next_wave = Tuple{Int, Int}[]
    sizehint!(current_wave, L * L)
    sizehint!(next_wave, L * L)

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
        wave_profile
    )
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
