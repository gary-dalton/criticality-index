# ==============================================================================
# EXPERIMENT 01 — STREAMING STORAGE & ENSEMBLE RUNNER
# ==============================================================================
#
# Per-seed summarization, Arrow write/load helpers, and the top-level
# run_btw_ensemble function. This module decouples simulation (headless
# Julia container) from analysis (Jupyter notebook) via on-disk Arrow files.
#
# Design:
#   - Simulation runs one seed at a time, peak memory = one catalog
#   - Wave-profile-dependent diagnostics (PSD/Hurst/b(x)) are computed
#     once per seed before the catalog is discarded
#   - Power-law fits are NOT computed here — those belong in analysis
#   - Raw wave profiles persisted only for L=1024 seed 1
#
# See WORKFLOW.md for the three-phase workflow description.
#
# ==============================================================================

using DataFrames
using Arrow
using Dates
using Printf
using Statistics


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Default seed counts per L for the full BTW ensemble."""
const DEFAULT_L_SEEDS = Dict(128 => 40, 256 => 30, 512 => 20, 1024 => 10)

"""Default recorded avalanches per seed."""
const DEFAULT_N_RECORD = 200_000

"""Default output directory (relative to work/)."""
const DEFAULT_OUT_DIR = "data/exp01_01"

"""High-frequency cutoff for the microscopic PSD fit (see section 5 of notebook)."""
const F_HIGH_CUTOFF = 1e-3

"""Number of log-spaced bins for the microscopic PSD storage."""
const PSD_N_BINS = 200


# ==============================================================================
# PATH HELPERS
# ==============================================================================

"""Build the path to a per-seed summary file."""
function summary_path(out_dir::AbstractString, L::Int, seed::Int)
    return joinpath(out_dir, "summaries", "summary_L$(L)_seed$(seed).arrow")
end

"""Build the path to a per-seed diagnostics file."""
function diag_path(out_dir::AbstractString, L::Int, seed::Int)
    return joinpath(out_dir, "diagnostics", "diag_L$(L)_seed$(seed).arrow")
end

"""Build the path to a per-seed micro_stats file."""
function micro_path(out_dir::AbstractString, L::Int, seed::Int)
    return joinpath(out_dir, "micro_stats", "micro_L$(L)_seed$(seed).arrow")
end

"""Build the path to a per-seed final-height file (only seed 1 per L)."""
function height_path(out_dir::AbstractString, L::Int, seed::Int)
    return joinpath(out_dir, "heights", "height_L$(L)_seed$(seed).arrow")
end

"""Build the path to a per-L manifest file."""
function manifest_path(out_dir::AbstractString, L::Int)
    return joinpath(out_dir, "manifest_L$(L).arrow")
end

"""Build the path to the raw wave profiles file (L=1024 seed 1 only)."""
function waves_path(out_dir::AbstractString, L::Int, seed::Int)
    return joinpath(out_dir, "waves", "waves_L$(L)_seed$(seed).arrow")
end


# ==============================================================================
# RESUMABILITY
# ==============================================================================

"""
Check whether a given (L, seed) has already been computed.

Arguments
    out_dir::AbstractString — data root directory
    L::Int                  — lattice size
    seed::Int               — seed number

Returns
    Bool — true if the summary file exists

Rules
    - Uses presence of summary file as the authoritative completion marker
    - If partial files exist (e.g. summary but not diag) from a crashed run,
      the seed is considered done; delete summary to force a rerun
"""
function seed_already_done(out_dir::AbstractString, L::Int, seed::Int)
    return isfile(summary_path(out_dir, L, seed))
end


# ==============================================================================
# PSD BINNING
# ==============================================================================

"""
Geometric log-binning of a raw PSD for compact Arrow storage.

Arguments
    freq::AbstractVector{<:Real} — FFT frequencies (positive)
    psd::AbstractVector{<:Real}  — PSD values at each frequency
    n_bins::Int = PSD_N_BINS     — number of log-spaced bins

Returns
    NamedTuple with:
        freq_center — geometric center of each occupied bin
        psd_mean    — mean PSD in each bin

Rules
    - Bins are log-spaced from min(freq) to max(freq)
    - Empty bins are dropped
    - Storage cost: O(n_bins) instead of O(N_waves) for the raw FFT

Usage
    binned = log_bin_psd(spec.freq, spec.psd)
"""
function log_bin_psd(freq::AbstractVector{<:Real}, psd::AbstractVector{<:Real};
                    n_bins::Int = PSD_N_BINS)
    positive = freq .> 0
    f = collect(freq[positive])
    p = collect(psd[positive])
    if isempty(f)
        return (freq_center = Float64[], psd_mean = Float64[])
    end
    f_min = minimum(f)
    f_max = maximum(f)
    edges = exp.(range(log(f_min), log(f_max), length = n_bins + 1))
    centers = Float64[]
    means = Float64[]
    for b in 1:n_bins
        lo, hi = edges[b], edges[b + 1]
        mask = (f .>= lo) .& (f .< hi)
        sum(mask) == 0 && continue
        push!(centers, sqrt(lo * hi))
        push!(means, mean(p[mask]))
    end
    # Ensure the very last frequency is captured
    mask_last = f .>= edges[end]
    if sum(mask_last) > 0
        push!(centers, f[end])
        push!(means, mean(p[mask_last]))
    end
    return (freq_center = centers, psd_mean = means)
end


# ==============================================================================
# PER-SEED SUMMARIZATION
# ==============================================================================

"""
Build all Arrow-ready DataFrames for one seed's simulation results.

Arguments
    catalog                 — Vector of AvalancheRecord from one seed
    L::Int                  — lattice size
    seed::Int               — seed number
    final_height::Matrix    — final lattice state
    wallclock_s::Real       — seconds spent on this seed
    n_burnin_grains::Int    — burn-in grains consumed
    converged::Bool         — whether adaptive burn-in converged

Returns
    NamedTuple of:
        summary_df      — one row per avalanche (L, seed, idx, size, duration, area, max_extent)
        diag_row        — single-row DataFrame of per-seed scalars
        micro_stats_df  — long-format (kind, x, y) for binned PSD / R-S / b(x)
        height_df       — (row, col, height) long-form of final_height

Rules
    - All DataFrames carry L and seed columns for post-hoc joins
    - Does NOT compute power-law fits (that's the analysis phase's job)
    - Uses diagnostics.jl functions: microscopic_activity_series,
      power_spectrum, spectral_exponent, hurst_rs,
      branching_ratio_activity_dependent, fat_tail_kurtosis
    - Requires the raw catalog (wave_profile vectors) to still be in memory

Usage
    pieces = summarize_seed(catalog, L, seed;
                            final_height=final, wallclock_s=t,
                            n_burnin_grains=b, converged=c)
"""
function summarize_seed(catalog, L::Int, seed::Int;
                       final_height::AbstractMatrix{<:Integer},
                       wallclock_s::Real,
                       n_burnin_grains::Int,
                       converged::Bool)
    # Avalanche summary (one row per avalanche)
    n = length(catalog)
    summary_df = DataFrame(
        L        = fill(L, n),
        seed     = fill(seed, n),
        idx      = 1:n,
        size     = Int64[a.size for a in catalog],
        duration = Int32[a.duration for a in catalog],
        area     = Int32[a.area for a in catalog],
        max_extent = Float32[a.max_extent for a in catalog],
    )

    # Microscopic activity time series (requires raw wave_profile)
    micro = microscopic_activity_series(catalog)

    # PSD + fit high-freq beta
    psd_binned = (freq_center = Float64[], psd_mean = Float64[])
    beta_high = NaN
    hurst_H = NaN
    if length(micro) >= 100
        spec = power_spectrum(Float64.(micro))
        psd_binned = log_bin_psd(spec.freq, spec.psd)
        beta_fit = spectral_exponent(spec.freq, spec.psd;
                                     freq_range = (F_HIGH_CUTOFF, maximum(spec.freq)))
        beta_high = beta_fit.beta
        h = hurst_rs(Float64.(micro))
        hurst_H = h.H
    end

    # Activity-dependent branching ratio
    bx = branching_ratio_activity_dependent(catalog; n_bins = 20)

    # Branching-ratio plateau: mean b(x) for activity levels in [2, 100]
    plateau_mean = NaN
    if !isempty(bx.activity_levels)
        mask = (bx.activity_levels .>= 2.0) .& (bx.activity_levels .<= 100.0)
        if sum(mask) >= 3
            plateau_mean = mean(bx.b_of_x[mask])
        end
    end

    # Excess kurtosis (raw sizes, window=1)
    sizes_full = Float64[a.size for a in catalog]
    kurt = fat_tail_kurtosis(sizes_full; window = 1)

    # Diagnostics single-row DataFrame
    diag_row = DataFrame(
        L = [L],
        seed = [seed],
        beta_high = [beta_high],
        hurst_H = [hurst_H],
        excess_kurtosis_raw = [kurt.excess_kurtosis],
        branching_plateau_mean = [plateau_mean],
        n_burnin_grains = [n_burnin_grains],
        converged = [converged],
        wallclock_s = [wallclock_s],
        n_avalanches = [n],
        n_nonempty = [count(a -> a.size > 0, catalog)],
    )

    # Micro stats in long format
    micro_rows = NamedTuple[]
    for (x, y) in zip(psd_binned.freq_center, psd_binned.psd_mean)
        push!(micro_rows, (kind = "psd", x = x, y = y))
    end
    for (x, y) in zip(bx.activity_levels, bx.b_of_x)
        push!(micro_rows, (kind = "bx", x = x, y = y))
    end
    # Also persist the Hurst R/S scaling points if available
    if length(micro) >= 100
        h = hurst_rs(Float64.(micro))
        for (x, y) in zip(h.scales, h.rs_vals)
            push!(micro_rows, (kind = "rs", x = Float64(x), y = y))
        end
    end
    micro_stats_df = if isempty(micro_rows)
        DataFrame(L = Int[], seed = Int[], kind = String[], x = Float64[], y = Float64[])
    else
        df = DataFrame(micro_rows)
        df[!, :L] .= L
        df[!, :seed] .= seed
        select!(df, :L, :seed, :kind, :x, :y)
        df
    end

    # Final height in long form (row, col, height)
    Lr, Lc = size(final_height)
    height_df = DataFrame(
        L = fill(L, Lr * Lc),
        seed = fill(seed, Lr * Lc),
        row = repeat(1:Lr, inner = Lc),
        col = repeat(1:Lc, outer = Lr),
        height = vec(permutedims(final_height)),
    )

    return (
        summary_df = summary_df,
        diag_row = diag_row,
        micro_stats_df = micro_stats_df,
        height_df = height_df,
    )
end


# ==============================================================================
# RAW WAVE PROFILE PERSISTENCE (L=1024 seed 1 only)
# ==============================================================================

"""
Write per-wave rows for all non-empty avalanches in a catalog.

Arguments
    catalog            — Vector of AvalancheRecord
    path::AbstractString — output Arrow file path

Rules
    - Columns: avalanche_idx, wave_idx, topplings
    - Only called for the designated L=1024 seed 1 run
    - File size ~500 MB at L=1024 — do not use for other seeds

Usage
    persist_raw_waves(catalog, waves_path(out_dir, 1024, 1))
"""
function persist_raw_waves(catalog, path::AbstractString)
    mkpath(dirname(path))
    total_waves = 0
    for a in catalog
        if a.size > 0
            total_waves += length(a.wave_profile)
        end
    end
    avalanche_idx = Vector{Int32}(undef, total_waves)
    wave_idx = Vector{Int32}(undef, total_waves)
    topplings = Vector{Int32}(undef, total_waves)
    k = 1
    for (ai, a) in enumerate(catalog)
        a.size == 0 && continue
        for (wi, t) in enumerate(a.wave_profile)
            avalanche_idx[k] = Int32(ai)
            wave_idx[k] = Int32(wi)
            topplings[k] = Int32(t)
            k += 1
        end
    end
    df = DataFrame(
        avalanche_idx = avalanche_idx,
        wave_idx = wave_idx,
        topplings = topplings,
    )
    Arrow.write(path, df)
    return path
end


# ==============================================================================
# WRITE ONE SEED
# ==============================================================================

"""
Write all Arrow files for one seed to out_dir.

Arguments
    out_dir::AbstractString — data root directory
    L::Int                  — lattice size
    seed::Int               — seed number
    pieces                  — NamedTuple returned by summarize_seed
    write_height::Bool = false     — also write height file (seed 1 per L)
    write_raw_waves::Bool = false  — also write raw wave profiles (L=1024 seed 1)
    catalog = nothing       — raw catalog, required if write_raw_waves=true

Rules
    - Creates subdirectories if missing
    - Always writes summary, diag, micro_stats
    - Writes height only when write_height=true
    - Writes raw waves only when write_raw_waves=true (requires catalog)

Usage
    write_seed(out_dir, L, seed, pieces;
               write_height=(seed==1), write_raw_waves=(L==1024 && seed==1),
               catalog=catalog)
"""
function write_seed(out_dir::AbstractString, L::Int, seed::Int, pieces;
                   write_height::Bool = false,
                   write_raw_waves::Bool = false,
                   catalog = nothing)
    mkpath(joinpath(out_dir, "summaries"))
    mkpath(joinpath(out_dir, "diagnostics"))
    mkpath(joinpath(out_dir, "micro_stats"))

    Arrow.write(summary_path(out_dir, L, seed), pieces.summary_df)
    Arrow.write(diag_path(out_dir, L, seed), pieces.diag_row)
    Arrow.write(micro_path(out_dir, L, seed), pieces.micro_stats_df)

    if write_height
        mkpath(joinpath(out_dir, "heights"))
        Arrow.write(height_path(out_dir, L, seed), pieces.height_df)
    end

    if write_raw_waves
        isnothing(catalog) && error(
            "write_raw_waves=true requires catalog argument")
        persist_raw_waves(catalog, waves_path(out_dir, L, seed))
    end

    return nothing
end


# ==============================================================================
# MANIFEST
# ==============================================================================

"""
Aggregate all per-seed diag rows for one L into a manifest file.

Arguments
    out_dir::AbstractString — data root
    L::Int                  — lattice size

Returns
    DataFrame written to manifest_path(out_dir, L)

Rules
    - Reads every diag_L{L}_seed{S}.arrow file present
    - Manifest provides a quick overview of the full ensemble per L
    - Called at the end of each L's loop in run_btw_ensemble

Usage
    write_manifest(out_dir, L)
"""
function write_manifest(out_dir::AbstractString, L::Int)
    diag_dir = joinpath(out_dir, "diagnostics")
    isdir(diag_dir) || return nothing
    pattern = Regex("^diag_L$(L)_seed(\\d+)\\.arrow\$")
    rows = DataFrame[]
    for f in readdir(diag_dir)
        m = match(pattern, f)
        isnothing(m) && continue
        push!(rows, DataFrame(Arrow.Table(joinpath(diag_dir, f))))
    end
    isempty(rows) && return nothing
    manifest = reduce(vcat, rows)
    sort!(manifest, :seed)
    Arrow.write(manifest_path(out_dir, L), manifest)
    return manifest
end


# ==============================================================================
# PROGRESS LOGGING
# ==============================================================================

"""
Format and write one progress line to stdout and an optional log file.

Arguments
    logio                 — open IOStream or nothing
    L::Int                — current L
    seed::Int             — current seed
    n_seeds::Int          — seeds planned for this L
    seeds_done::Int       — seeds completed across all L
    total_seeds::Int      — total seeds planned across all L
    seed_wallclock_s::Real — seconds for this seed
    cum_wallclock_s::Real  — seconds elapsed since run start
    res_converged::Bool    — whether this seed converged
    res_burnin::Int        — burn-in grains consumed

Rules
    - Writes to stdout (captured by docker logs) and to logio if provided
    - Both streams are flushed immediately so the output is live
    - ETA is a linear extrapolation from cumulative time and progress fraction

Usage
    log_progress(logio, L, s, n_seeds, seeds_done, total_seeds,
                 time() - t_seed, time() - t_start;
                 res_converged=true, res_burnin=40000)
"""
function log_progress(logio, L::Int, seed::Int, n_seeds::Int,
                     seeds_done::Int, total_seeds::Int,
                     seed_wallclock_s::Real, cum_wallclock_s::Real;
                     res_converged::Bool, res_burnin::Int)
    pct = 100.0 * seeds_done / total_seeds
    eta_s = seeds_done > 0 ?
        cum_wallclock_s * (total_seeds - seeds_done) / seeds_done : NaN
    mem_gb = Sys.maxrss() / 1e9
    ts = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
    line = @sprintf("[%s] L=%d seed=%d/%d | %.1fs | cum %s | %.1f%% done | ETA %s | mem %.2f GB | converged=%s burnin=%d",
                    ts, L, seed, n_seeds,
                    seed_wallclock_s,
                    format_duration(cum_wallclock_s),
                    pct,
                    isnan(eta_s) ? "—" : format_duration(eta_s),
                    mem_gb,
                    res_converged, res_burnin)
    println(line)
    flush(stdout)
    if !isnothing(logio)
        println(logio, line)
        flush(logio)
    end
    return nothing
end

"""Format seconds as H:MM:SS or M:SS, dropping leading zeros."""
function format_duration(s::Real)
    total = round(Int, s)
    h = div(total, 3600)
    m = div(total - h * 3600, 60)
    sec = total - h * 3600 - m * 60
    if h > 0
        return @sprintf("%dh %02dm %02ds", h, m, sec)
    else
        return @sprintf("%dm %02ds", m, sec)
    end
end


# ==============================================================================
# ENSEMBLE RUNNER
# ==============================================================================

"""
Run a full BTW ensemble, streaming per-seed Arrow outputs.

Arguments
    L_seeds::Dict{Int, Int} = DEFAULT_L_SEEDS — seed count per L
    n_record::Int = DEFAULT_N_RECORD          — avalanches per seed
    out_dir::AbstractString = DEFAULT_OUT_DIR — output directory
    initial_condition::Symbol = :empty        — passed to btw_sandpile_adaptive
    log_path::Union{Nothing, AbstractString} = nothing — log file path
                                                         (default: out_dir/run.log)

Returns
    nothing — all results are written to disk

Rules
    - Resumable: skips (L, seed) pairs whose summary file already exists
    - Bounded memory: one seed's catalog at a time, GC'd before next seed
    - Raw wave profiles preserved only for L=1024 seed 1
    - Final height preserved only for seed 1 of each L
    - Per-seed progress logged to stdout AND log_path
    - Per-L manifest written after each L's loop completes

Usage
    run_btw_ensemble()                                    # full defaults
    run_btw_ensemble(L_seeds=Dict(64=>3), n_record=10_000,
                     out_dir="data/exp01_01_test")       # custom smoke test
"""
function run_btw_ensemble(;
        L_seeds::Dict{Int, Int} = DEFAULT_L_SEEDS,
        n_record::Int = DEFAULT_N_RECORD,
        out_dir::AbstractString = DEFAULT_OUT_DIR,
        initial_condition::Symbol = :empty,
        log_path::Union{Nothing, AbstractString} = nothing)

    mkpath(out_dir)
    Ls = sort(collect(keys(L_seeds)))
    total_seeds = sum(values(L_seeds))
    seeds_done = 0
    t_start = time()

    actual_log_path = isnothing(log_path) ? joinpath(out_dir, "run.log") : log_path
    logio = open(actual_log_path, "a")

    banner = @sprintf("=== run_btw_ensemble start: L_seeds=%s n_record=%d out_dir=%s ic=%s ===",
                     L_seeds, n_record, out_dir, initial_condition)
    println(banner)
    println(logio, banner)
    flush(stdout); flush(logio)

    try
        for L in Ls
            n_seeds = L_seeds[L]
            for s in 1:n_seeds
                if seed_already_done(out_dir, L, s)
                    seeds_done += 1
                    continue
                end
                t_seed = time()
                res = btw_sandpile_adaptive(L;
                                            N_record = n_record,
                                            seed = s,
                                            initial_condition = initial_condition)

                # Capture scalars BEFORE freeing res (used in progress log)
                converged = res.converged
                burnin = res.n_burnin_grains

                pieces = summarize_seed(res.catalog, L, s;
                                        final_height = res.final_height,
                                        wallclock_s = time() - t_seed,
                                        n_burnin_grains = burnin,
                                        converged = converged)
                write_seed(out_dir, L, s, pieces;
                           write_height = (s == 1),
                           write_raw_waves = (L == 1024 && s == 1),
                           catalog = res.catalog)

                # Release memory before next seed
                res = nothing
                pieces = nothing
                GC.gc()

                seeds_done += 1
                log_progress(logio, L, s, n_seeds, seeds_done, total_seeds,
                             time() - t_seed, time() - t_start;
                             res_converged = converged, res_burnin = burnin)
            end
            write_manifest(out_dir, L)
        end
    finally
        close(logio)
    end

    println("=== run_btw_ensemble finished in $(format_duration(time() - t_start)) ===")
    return nothing
end


# ==============================================================================
# LOADERS (analysis phase)
# ==============================================================================

"""
Load all per-seed files for a given L into analysis-ready DataFrames.

Arguments
    data_dir::AbstractString — data root
    L::Int                   — lattice size

Returns
    NamedTuple with:
        summaries   — DataFrame with all avalanches across all seeds for this L
        diagnostics — per-seed diag rows stacked
        micro       — per-seed micro_stats stacked
        heights     — loaded height DataFrame if heights/height_L{L}_seed1.arrow exists
                      (nothing otherwise)
        raw_waves   — loaded raw wave profiles if L=1024 and file exists (nothing otherwise)

Rules
    - Summaries carry seed column; group by seed for ensemble statistics
    - Raises if no per-seed summary files exist for L

Usage
    loaded = load_ensemble("data/exp01_01", 128)
    by_seed = groupby(loaded.summaries, :seed)
"""
function load_ensemble(data_dir::AbstractString, L::Int)
    sum_dir = joinpath(data_dir, "summaries")
    diag_dir = joinpath(data_dir, "diagnostics")
    micro_dir = joinpath(data_dir, "micro_stats")

    sum_pattern = Regex("^summary_L$(L)_seed(\\d+)\\.arrow\$")
    sum_files = sort(filter(f -> occursin(sum_pattern, f), readdir(sum_dir)))
    isempty(sum_files) && error("No summary files for L=$L under $sum_dir")
    summaries = reduce(vcat, [DataFrame(Arrow.Table(joinpath(sum_dir, f))) for f in sum_files])

    diag_pattern = Regex("^diag_L$(L)_seed(\\d+)\\.arrow\$")
    diag_files = sort(filter(f -> occursin(diag_pattern, f), readdir(diag_dir)))
    diagnostics = reduce(vcat, [DataFrame(Arrow.Table(joinpath(diag_dir, f))) for f in diag_files])

    micro_pattern = Regex("^micro_L$(L)_seed(\\d+)\\.arrow\$")
    micro_files = sort(filter(f -> occursin(micro_pattern, f), readdir(micro_dir)))
    micro = reduce(vcat, [DataFrame(Arrow.Table(joinpath(micro_dir, f))) for f in micro_files])

    heights_file = height_path(data_dir, L, 1)
    heights = isfile(heights_file) ? DataFrame(Arrow.Table(heights_file)) : nothing

    raw_waves = nothing
    if L == 1024
        w_file = waves_path(data_dir, L, 1)
        if isfile(w_file)
            raw_waves = DataFrame(Arrow.Table(w_file))
        end
    end

    return (summaries = summaries,
            diagnostics = diagnostics,
            micro = micro,
            heights = heights,
            raw_waves = raw_waves)
end

"""Load the per-L manifest for provenance/overview."""
function load_manifest(data_dir::AbstractString, L::Int)
    p = manifest_path(data_dir, L)
    isfile(p) || error("No manifest for L=$L at $p")
    return DataFrame(Arrow.Table(p))
end

"""
Convert a loaded ensemble into a structure resembling the in-notebook results
dict, so existing analysis cells can be retrofitted with minimal change.

Arguments
    sums::DataFrame, diags::DataFrame, micros::DataFrame — load_ensemble output
    L::Int

Returns
    NamedTuple with .summaries, .diagnostics, .micro fields (same as inputs)
    plus convenience groupings:
        .per_seed_summaries — grouped by seed
        .seeds              — vector of seed numbers
"""
function reconstruct_ensemble(sums::DataFrame, diags::DataFrame, micros::DataFrame, L::Int)
    seeds = sort(unique(diags.seed))
    return (summaries = sums,
            diagnostics = diags,
            micro = micros,
            seeds = seeds,
            n_seeds = length(seeds),
            L = L)
end


# ==============================================================================
# HEIGHT FIELD RECONSTRUCTION (from long-form Arrow file)
# ==============================================================================

"""
Reconstruct a final_height matrix from a long-form heights DataFrame.

Arguments
    height_df::DataFrame — columns (L, seed, row, col, height)

Returns
    Matrix{Int} of the height field
"""
function reconstruct_height_field(height_df::DataFrame)
    L = Int(maximum(height_df.row))
    M = zeros(Int, L, L)
    for r in eachrow(height_df)
        M[r.row, r.col] = r.height
    end
    return M
end
