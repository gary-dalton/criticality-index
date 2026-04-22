# ==============================================================================
# EXPERIMENT 01.01 — HEADLESS ANALYSIS
# ==============================================================================
#
# Pre-computes all per-L and per-seed power-law fits, ensemble statistics,
# and extrapolations from the per-seed Arrow files written by
# run_btw_ensemble. Outputs pooled Arrow files under data/exp01_01/analysis/
# that the notebook can load in seconds for pure plotting.
#
# Scope: BTW-specific defaults (xmin=5 for scaling regime, xmax bounded by
# finite-size cutoff per L). Will be generalized when building Manna analysis.
#
# ==============================================================================

using DataFrames
using Arrow
using Statistics
using StatsBase
using Dates
using Printf


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Fixed xmin for size/duration scaling-regime fits (BTW). Auto-xmin unreliable
for BTW regardless of L — see feedback_power_law_fitting memory entry."""
const XMIN_FIXED = 5.0

"""Grid of xmin values used to visualize multiscaling drift."""
const XMIN_GRID = [5, 10, 30, 100, 300]

"""Upper bound on xmax per L for scaling-regime fits — crude L² / constant
estimate of the finite-size cutoff location. Conservative; truncates well
below the cutoff onset."""
const XMAX_BY_L = Dict(64 => 1000.0, 128 => 4000.0, 256 => 16000.0,
                      512 => 64000.0, 1024 => 256000.0)

"""Activity range for the branching-ratio plateau-mean scalar."""
const BX_PLATEAU_RANGE = (2.0, 100.0)

"""High-frequency cutoff for the β_high PSD fit (matches streaming.jl)."""
const F_HIGH_ANALYSIS = 1e-3

"""Default output subdirectory name under data_dir."""
const DEFAULT_ANALYSIS_SUBDIR = "analysis"


# ==============================================================================
# PATH HELPERS
# ==============================================================================

_apath(out_dir::AbstractString, name::AbstractString) =
    joinpath(out_dir, name)


# ==============================================================================
# POOLED SIZE FITS
# ==============================================================================

"""
Pooled size-distribution fits across all seeds for one L.

Arguments
    sizes_pool::Vector{<:Real} — all non-empty avalanche sizes for this L
    L::Int

Returns
    DataFrame with one row per fit type: (L, fit_type, xmin, xmax, alpha,
    sigma_alpha, ks_distance, n_tail, ll_ratio_pl_vs_exp). Fit types:
        auto           — Clauset auto-xmin (known to fail for BTW; included
                         for documentation)
        xmin_5         — manual xmin=5, no xmax (scaling regime + cutoff)
        xmin_5_xmax    — manual xmin=5, xmax per XMAX_BY_L (scaling only)
        xmin_10        — manual xmin=10 for comparison
        xmin_10_xmax   — manual xmin=10 with upper cutoff

Rules
    - Uses fit_power_law and compare_power_law_exponential from diagnostics.jl
    - xmax only applied when a value for L is in XMAX_BY_L
"""
function pooled_size_fits(sizes_pool::Vector{<:Real}, L::Int)
    rows = NamedTuple[]

    # Helper to append a fit row
    function add_fit(fit_type::String, alpha_fit, xmin_used, xmax_used)
        ks = alpha_fit.ks_distance
        n_tail = alpha_fit.n_tail
        cmp = isnan(alpha_fit.alpha) ?
              (log_likelihood_ratio = NaN, lambda_exp = NaN) :
              compare_power_law_exponential(sizes_pool, alpha_fit.xmin, alpha_fit.alpha)
        push!(rows, (
            L = L,
            fit_type = fit_type,
            xmin = Float64(alpha_fit.xmin),
            xmax = isnothing(xmax_used) ? NaN : Float64(xmax_used),
            alpha = alpha_fit.alpha,
            sigma_alpha = alpha_fit.sigma_alpha,
            ks_distance = ks,
            n_tail = n_tail,
            ll_ratio_pl_vs_exp = cmp.log_likelihood_ratio,
        ))
    end

    # Auto-xmin (documented failure for BTW; we compute it for the record)
    auto = fit_power_law(sizes_pool;
                        candidate_xmins = log_spaced_xmin_candidates(sizes_pool))
    add_fit("auto", auto, auto.xmin, nothing)

    # Manual xmin=5 no xmax
    f5 = fit_power_law(sizes_pool; xmin = XMIN_FIXED)
    add_fit("xmin_5", f5, f5.xmin, nothing)

    # Manual xmin=5 with xmax (scaling regime only)
    if haskey(XMAX_BY_L, L)
        f5x = fit_power_law(sizes_pool; xmin = XMIN_FIXED, xmax = XMAX_BY_L[L])
        add_fit("xmin_5_xmax", f5x, f5x.xmin, XMAX_BY_L[L])
    end

    # Manual xmin=10 no xmax
    f10 = fit_power_law(sizes_pool; xmin = 10.0)
    add_fit("xmin_10", f10, f10.xmin, nothing)

    # Manual xmin=10 with xmax
    if haskey(XMAX_BY_L, L)
        f10x = fit_power_law(sizes_pool; xmin = 10.0, xmax = XMAX_BY_L[L])
        add_fit("xmin_10_xmax", f10x, f10x.xmin, XMAX_BY_L[L])
    end

    return DataFrame(rows)
end


"""Log-spaced candidate xmins for auto-xmin search on large pooled datasets
(avoids the O(unique_values) blowup of the default search)."""
function log_spaced_xmin_candidates(data::Vector{<:Real}; n::Int = 50)
    positive = filter(>(0), data)
    isempty(positive) && return Float64[]
    cutoff = quantile(positive, 0.95)
    return exp.(range(log(1.0), log(cutoff), length = n))
end


# ==============================================================================
# PER-SEED SIZE FITS (at fixed xmin)
# ==============================================================================

"""
Per-seed size-distribution fits at a fixed xmin for ensemble error bars.

Arguments
    summaries::DataFrame — all-seeds summary table (from load_ensemble)
    L::Int
    xmin::Real = XMIN_FIXED

Returns
    DataFrame with one row per seed: (L, seed, xmin, alpha, sigma_alpha,
    ks_distance, n_tail)
"""
function per_seed_size_fits(summaries::DataFrame, L::Int;
                            xmin::Real = XMIN_FIXED)
    grouped = groupby(summaries, :seed)
    rows = NamedTuple[]
    for sdf in grouped
        sizes = Float64.(filter(>(0), sdf.size))
        fit = fit_power_law(sizes; xmin = Float64(xmin))
        push!(rows, (
            L = L,
            seed = sdf.seed[1],
            xmin = Float64(xmin),
            alpha = fit.alpha,
            sigma_alpha = fit.sigma_alpha,
            ks_distance = fit.ks_distance,
            n_tail = fit.n_tail,
        ))
    end
    return DataFrame(rows)
end


# ==============================================================================
# MULTISCALING GRID (per-seed × xmin grid)
# ==============================================================================

"""
Per-seed × xmin-grid alpha values. Enables multiscaling drift analysis with
ensemble error bars.

Returns
    DataFrame: (L, seed, xmin, alpha, sigma_alpha, n_tail)
"""
function multiscaling_grid(summaries::DataFrame, L::Int;
                          xmin_grid::Vector = XMIN_GRID)
    grouped = groupby(summaries, :seed)
    rows = NamedTuple[]
    for sdf in grouped
        sizes = Float64.(filter(>(0), sdf.size))
        for xm in xmin_grid
            fit = fit_power_law(sizes; xmin = Float64(xm))
            push!(rows, (
                L = L,
                seed = sdf.seed[1],
                xmin = Float64(xm),
                alpha = fit.alpha,
                sigma_alpha = fit.sigma_alpha,
                n_tail = fit.n_tail,
            ))
        end
    end
    return DataFrame(rows)
end


# ==============================================================================
# AREA FITS
# ==============================================================================

"""
Area-distribution fits. Auto-xmin works cleanly here (no multiscaling).

Returns
    DataFrame: (L, fit_type, seed|NaN, xmin, alpha, sigma_alpha, ks_distance, n_tail)
    Fit types: pooled_auto, per_seed_auto
"""
function area_fits(summaries::DataFrame, L::Int)
    rows = NamedTuple[]

    # Pooled auto-xmin
    areas_pool = Float64.(filter(>(0), summaries.area))
    f_pool = fit_power_law(areas_pool;
                           candidate_xmins = log_spaced_xmin_candidates(areas_pool))
    push!(rows, (
        L = L, fit_type = "pooled_auto",
        seed = missing,
        xmin = f_pool.xmin, alpha = f_pool.alpha,
        sigma_alpha = f_pool.sigma_alpha,
        ks_distance = f_pool.ks_distance, n_tail = f_pool.n_tail,
    ))

    # Per-seed auto-xmin
    for sdf in groupby(summaries, :seed)
        areas = Float64.(filter(>(0), sdf.area))
        f = fit_power_law(areas)
        push!(rows, (
            L = L, fit_type = "per_seed_auto",
            seed = sdf.seed[1],
            xmin = f.xmin, alpha = f.alpha,
            sigma_alpha = f.sigma_alpha,
            ks_distance = f.ks_distance, n_tail = f.n_tail,
        ))
    end

    return DataFrame(rows)
end


# ==============================================================================
# DURATION FITS (manual xmin — auto fails for BTW)
# ==============================================================================

"""
Duration fits. Auto-xmin lands in cutoff for BTW at most L; we use manual xmin.

Returns
    DataFrame: (L, fit_type, seed|missing, xmin, alpha, sigma_alpha, ks_distance, n_tail)
"""
function duration_fits(summaries::DataFrame, L::Int;
                       xmin::Real = XMIN_FIXED)
    rows = NamedTuple[]

    # Pooled manual xmin
    durs_pool = Float64.(filter(>(0), summaries.duration))
    f_pool = fit_power_law(durs_pool; xmin = Float64(xmin))
    push!(rows, (
        L = L, fit_type = "pooled_xmin_fixed",
        seed = missing,
        xmin = Float64(xmin),
        alpha = f_pool.alpha, sigma_alpha = f_pool.sigma_alpha,
        ks_distance = f_pool.ks_distance, n_tail = f_pool.n_tail,
    ))

    # Per-seed manual xmin
    for sdf in groupby(summaries, :seed)
        durs = Float64.(filter(>(0), sdf.duration))
        f = fit_power_law(durs; xmin = Float64(xmin))
        push!(rows, (
            L = L, fit_type = "per_seed_xmin_fixed",
            seed = sdf.seed[1],
            xmin = Float64(xmin),
            alpha = f.alpha, sigma_alpha = f.sigma_alpha,
            ks_distance = f.ks_distance, n_tail = f.n_tail,
        ))
    end

    return DataFrame(rows)
end


# ==============================================================================
# POOLED PSD
# ==============================================================================

"""
Pool per-seed binned PSDs into a single per-L PSD with ensemble std per bin.

Arguments
    micro::DataFrame — micro_stats DataFrame from load_ensemble
    L::Int

Returns
    DataFrame: (L, freq_center, psd_mean, psd_std, n_seeds)
    Only rows where kind=="psd" in micro are used.
"""
function pooled_psd(micro::DataFrame, L::Int)
    psd_rows = filter(row -> row.kind == "psd", micro)
    if isempty(psd_rows)
        return DataFrame(L = Int[], freq_center = Float64[],
                        psd_mean = Float64[], psd_std = Float64[], n_seeds = Int[])
    end
    # Group by freq bin (x column)
    grouped = combine(groupby(psd_rows, :x),
                     :y => mean => :psd_mean,
                     :y => std => :psd_std,
                     :y => length => :n_seeds)
    sort!(grouped, :x)
    rename!(grouped, :x => :freq_center)
    grouped[!, :L] .= L
    select!(grouped, :L, :freq_center, :psd_mean, :psd_std, :n_seeds)
    return grouped
end


# ==============================================================================
# POOLED BRANCHING RATIO
# ==============================================================================

"""
Pool per-seed b(x) into a single per-L b(x) with ensemble std per activity bin.

Returns
    DataFrame: (L, activity, b_mean, b_std, n_seeds)
"""
function pooled_bx(micro::DataFrame, L::Int)
    bx_rows = filter(row -> row.kind == "bx", micro)
    if isempty(bx_rows)
        return DataFrame(L = Int[], activity = Float64[],
                        b_mean = Float64[], b_std = Float64[], n_seeds = Int[])
    end
    grouped = combine(groupby(bx_rows, :x),
                     :y => mean => :b_mean,
                     :y => std => :b_std,
                     :y => length => :n_seeds)
    sort!(grouped, :x)
    rename!(grouped, :x => :activity)
    grouped[!, :L] .= L
    select!(grouped, :L, :activity, :b_mean, :b_std, :n_seeds)
    return grouped
end


# ==============================================================================
# INTER-EVENT TIME CCDFs
# ==============================================================================

"""
Compute CCDFs of inter-event waiting times at each threshold for one L.

Arguments
    summaries::DataFrame — pooled summary DataFrame
    L::Int
    quantiles::Vector{Float64} = [0.50, 0.90, 0.99]

Returns
    DataFrame: (L, quantile, threshold, wait, ccdf)
    CCDF computed across all seeds (treating the full ensemble as one temporal sequence)
    NOTE: this merges across seeds which isn't physically a single time series,
    but gives pooled statistics for the CCDF shape.
"""
function inter_event_ccdfs(summaries::DataFrame, L::Int;
                           quantiles::Vector{Float64} = [0.50, 0.90, 0.99])
    rows = NamedTuple[]
    for sdf in groupby(summaries, :seed)
        series = Float64.(sdf.size)
        nonempty = filter(>(0), series)
        isempty(nonempty) && continue
        for q in quantiles
            thr = quantile(nonempty, q)
            waits = inter_event_times(series, thr)
            length(waits) < 10 && continue
            sorted = sort(Float64.(waits))
            n = length(sorted)
            # Record (wait, CCDF) points
            for (i, w) in enumerate(sorted)
                push!(rows, (
                    L = L,
                    seed = sdf.seed[1],
                    quantile = q,
                    threshold = thr,
                    wait = w,
                    ccdf = (n - i + 1) / n,
                ))
            end
        end
    end
    return DataFrame(rows)
end


# ==============================================================================
# SPATIAL CORRELATION G(r)
# ==============================================================================

"""
Compute G(r) from final_height (only called for L <= 256 due to O(L^4) cost).

Arguments
    heights_df::DataFrame — long-form (row, col, height) from load_ensemble
    L::Int

Returns
    DataFrame: (L, r, G, n_pairs)
"""
function spatial_correlation(heights_df::DataFrame, L::Int)
    M = reconstruct_height_field(heights_df)
    max_r = div(L, 4)
    corr = correlation_function(M; max_r = max_r)
    return DataFrame(
        L = fill(L, length(corr.r)),
        r = corr.r,
        G = corr.G,
        n_pairs = corr.n_pairs,
    )
end


# ==============================================================================
# LOG-BINNED PMFs (for size and area plots)
# ==============================================================================

"""
Compute log-binned PMFs for size and area distributions, pooled across seeds.

Returns
    DataFrame: (L, kind, bin_center, pmf, counts)
    kind ∈ {"size", "area"}
"""
function log_binned_pmfs(summaries::DataFrame, L::Int; n_bins::Int = 50)
    rows = NamedTuple[]
    sizes = Float64.(filter(>(0), summaries.size))
    areas = Float64.(filter(>(0), summaries.area))
    h_s = log_binned_pmf(sizes; n_bins = n_bins)
    h_a = log_binned_pmf(areas; n_bins = n_bins)
    for (bc, pm, cnt) in zip(h_s.bin_centers, h_s.pmf, h_s.counts)
        push!(rows, (L = L, kind = "size", bin_center = bc, pmf = pm, counts = cnt))
    end
    for (bc, pm, cnt) in zip(h_a.bin_centers, h_a.pmf, h_a.counts)
        push!(rows, (L = L, kind = "area", bin_center = bc, pmf = pm, counts = cnt))
    end
    return DataFrame(rows)
end


# ==============================================================================
# FINITE-SIZE EXTRAPOLATION
# ==============================================================================

"""
Weighted linear fit α(L) = α_∞ + c/L for an observable.

Arguments
    L_vals::Vector{<:Real}
    values::Vector{<:Real}   — observable values per L
    sigmas::Vector{<:Real}   — per-L uncertainties; NaN/0 replaced with 1e-6

Returns
    NamedTuple: (alpha_inf, sigma_alpha_inf, c, sigma_c, n_points, chi2, weighted)
"""
function finite_size_extrapolation(L_vals::Vector{<:Real},
                                   values::Vector{<:Real},
                                   sigmas::Vector{<:Real})
    @assert length(L_vals) == length(values) == length(sigmas)
    n = length(L_vals)
    n < 3 && return (alpha_inf = NaN, sigma_alpha_inf = NaN,
                     c = NaN, sigma_c = NaN, n_points = n,
                     chi2 = NaN, weighted = true)

    x = 1.0 ./ Float64.(L_vals)
    y = Float64.(values)
    s = [isnan(σ) || σ < 1e-6 ? 1e-6 : σ for σ in sigmas]
    w = 1.0 ./ s .^ 2
    sw = sum(w); sx = sum(w .* x); sy = sum(w .* y)
    sxx = sum(w .* x .^ 2); sxy = sum(w .* x .* y)
    denom = sw * sxx - sx^2
    c_fit = (sw * sxy - sx * sy) / denom
    a_inf = (sy - c_fit * sx) / sw
    var_a = sxx / denom; var_c = sw / denom
    resid = y .- (a_inf .+ c_fit .* x)
    chi2 = sum(w .* resid .^ 2)
    return (alpha_inf = a_inf,
            sigma_alpha_inf = sqrt(var_a),
            c = c_fit,
            sigma_c = sqrt(var_c),
            n_points = n,
            chi2 = chi2,
            weighted = true)
end


"""
Run the four finite-size extrapolations: size α, area α, duration α, mean_z.

Arguments
    per_seed_size::DataFrame  — from per_seed_size_fits (across all L)
    area::DataFrame           — from area_fits (across all L, pooled_auto rows)
    duration::DataFrame       — from duration_fits (across all L, pooled rows)
    summary::DataFrame        — per-L scalars with mean_z column

Returns
    DataFrame: (observable, alpha_inf, sigma_alpha_inf, c, sigma_c, n_L, chi2)
"""
function all_fss_extrapolations(per_seed_size::DataFrame,
                               area::DataFrame,
                               duration::DataFrame,
                               summary::DataFrame)
    rows = NamedTuple[]

    # Size: mean ± std across seeds per L (fixed xmin=5)
    size_by_L = combine(groupby(per_seed_size, :L),
                       :alpha => mean => :alpha_mean,
                       :alpha => std => :alpha_std)
    fs_size = finite_size_extrapolation(Float64.(size_by_L.L),
                                        size_by_L.alpha_mean,
                                        size_by_L.alpha_std)
    push!(rows, (observable = "size_xmin5",
                 alpha_inf = fs_size.alpha_inf,
                 sigma_alpha_inf = fs_size.sigma_alpha_inf,
                 c = fs_size.c, sigma_c = fs_size.sigma_c,
                 n_L = fs_size.n_points, chi2 = fs_size.chi2))

    # Area: per-seed auto-xmin mean ± std
    area_per_seed = filter(r -> r.fit_type == "per_seed_auto", area)
    area_by_L = combine(groupby(area_per_seed, :L),
                       :alpha => mean => :alpha_mean,
                       :alpha => std => :alpha_std)
    fs_area = finite_size_extrapolation(Float64.(area_by_L.L),
                                        area_by_L.alpha_mean,
                                        area_by_L.alpha_std)
    push!(rows, (observable = "area_auto",
                 alpha_inf = fs_area.alpha_inf,
                 sigma_alpha_inf = fs_area.sigma_alpha_inf,
                 c = fs_area.c, sigma_c = fs_area.sigma_c,
                 n_L = fs_area.n_points, chi2 = fs_area.chi2))

    # Duration: per-seed manual xmin mean ± std
    dur_per_seed = filter(r -> r.fit_type == "per_seed_xmin_fixed", duration)
    dur_by_L = combine(groupby(dur_per_seed, :L),
                      :alpha => mean => :alpha_mean,
                      :alpha => std => :alpha_std)
    fs_dur = finite_size_extrapolation(Float64.(dur_by_L.L),
                                       dur_by_L.alpha_mean,
                                       dur_by_L.alpha_std)
    push!(rows, (observable = "duration_xmin5",
                 alpha_inf = fs_dur.alpha_inf,
                 sigma_alpha_inf = fs_dur.sigma_alpha_inf,
                 c = fs_dur.c, sigma_c = fs_dur.sigma_c,
                 n_L = fs_dur.n_points, chi2 = fs_dur.chi2))

    # Mean height: use per-L scalar from summary, give a small uncertainty
    # (seed-to-seed std of the field mean, ~0 for equilibrated lattice)
    mh_fs = finite_size_extrapolation(Float64.(summary.L),
                                      summary.mean_z,
                                      fill(0.005, nrow(summary)))
    push!(rows, (observable = "mean_z",
                 alpha_inf = mh_fs.alpha_inf,
                 sigma_alpha_inf = mh_fs.sigma_alpha_inf,
                 c = mh_fs.c, sigma_c = mh_fs.sigma_c,
                 n_L = mh_fs.n_points, chi2 = mh_fs.chi2))

    return DataFrame(rows)
end


# ==============================================================================
# FRACTAL DIMENSIONS (D_s, D_a, γ) — top-50% and top-1% variants
# ==============================================================================

"""
Compute fractal-dimension slopes at two subsample variants for one L.

Arguments
    summaries::DataFrame — all-seeds summary table for one L. Must carry
                          `size`, `area`, `max_extent` columns.
    L::Int

Returns
    DataFrame with rows for `:top50` and `:top1` variants and columns:
    (L, variant, D_s, D_a, gamma, gamma_check, n_used)

Rules
    - D_s from log(size) vs log(max_extent) slope
    - D_a from log(area) vs log(max_extent) slope
    - gamma from log(size) vs log(area) slope
    - gamma_check = D_s / D_a (algebraic identity)
    - top50 = avalanches at or above the median size (inclusive)
    - top1 = avalanches at or above the 99th-percentile size (tail only;
      mirrors published moment-ratio methods)
    - Excludes avalanches with max_extent < 2 (discreteness floor)
    - Uses simple OLS on log-log scatter

Usage
    fractal_df = fractal_dimensions(summaries, 1024)
"""
function fractal_dimensions(summaries::DataFrame, L::Int)
    rows = NamedTuple[]
    sizes   = Float64.(summaries.size)
    areas   = Float64.(summaries.area)
    extents = Float64.(summaries.max_extent)
    mask    = (sizes .> 0) .& (extents .>= 2.0)
    if sum(mask) < 100
        for v in (:top50, :top1)
            push!(rows, (L = L, variant = String(v),
                         D_s = NaN, D_a = NaN, gamma = NaN,
                         gamma_check = NaN, n_used = 0))
        end
        return DataFrame(rows)
    end
    s = sizes[mask]; a = areas[mask]; R = extents[mask]

    function _slope(x, y)
        mx = mean(x); my = mean(y)
        return sum((x .- mx) .* (y .- my)) / sum((x .- mx).^2)
    end

    for (variant, q) in ((:top50, 0.5), (:top1, 0.99))
        thresh = quantile(s, q)
        sub = s .>= thresh
        n_used = sum(sub)
        if n_used < 50
            push!(rows, (L = L, variant = String(variant),
                         D_s = NaN, D_a = NaN, gamma = NaN,
                         gamma_check = NaN, n_used = n_used))
            continue
        end
        ls = log.(s[sub]); la = log.(a[sub]); lR = log.(R[sub])
        D_s = _slope(lR, ls)
        D_a = _slope(lR, la)
        gamma = _slope(la, ls)
        push!(rows, (L = L, variant = String(variant),
                     D_s = D_s, D_a = D_a, gamma = gamma,
                     gamma_check = D_s / D_a, n_used = n_used))
    end
    return DataFrame(rows)
end


"""
Finite-size extrapolate fractal dimensions for each variant.

Arguments
    fractal_df::DataFrame — vertically-concatenated output of
                           fractal_dimensions across L values. Must carry
                           (L, variant, D_s, D_a, gamma) columns.

Returns
    DataFrame with one row per (variant, observable) and columns:
    (variant, observable, X_inf, c, n_L)
    where observable ∈ {"D_s", "D_a", "gamma"}

Rules
    - Linear 1/L fit for each (variant, observable) combination
    - Requires at least 3 distinct L values per variant for a fit;
      otherwise returns NaN extrapolation
    - Uses unweighted OLS (no per-L uncertainty stored in fractal_df);
      for weighted extrapolation with error bars, compute per-seed
      D_s/D_a/gamma first and pool.
"""
function fractal_extrapolation(fractal_df::DataFrame)
    rows = NamedTuple[]
    for variant in unique(fractal_df.variant)
        vsub = filter(r -> r.variant == variant, fractal_df)
        isempty(vsub) && continue
        Ls = Float64.(vsub.L)
        for (obs, col) in (("D_s", :D_s), ("D_a", :D_a), ("gamma", :gamma))
            ys = Float64.(vsub[!, col])
            mask = .!isnan.(ys)
            if sum(mask) < 3
                push!(rows, (variant = variant, observable = obs,
                             X_inf = NaN, c = NaN, n_L = sum(mask)))
                continue
            end
            x = 1.0 ./ Ls[mask]
            y = ys[mask]
            n = length(x)
            sx = sum(x); sy = sum(y); sxx = sum(x.^2); sxy = sum(x .* y)
            c_fit = (n * sxy - sx * sy) / (n * sxx - sx^2)
            a_inf = (sy - c_fit * sx) / n
            push!(rows, (variant = variant, observable = obs,
                         X_inf = a_inf, c = c_fit, n_L = n))
        end
    end
    return DataFrame(rows)
end


# ==============================================================================
# BRACKETED-XMIN FSS (size distribution only, uses multiscaling_grid output)
# ==============================================================================

"""
Finite-size extrapolation at multiple xmin values — implements the bracketed-
reporting methodology (see `feedback_xmin_bracketed_reporting` memory).

Arguments
    multiscaling_df::DataFrame — combined multiscaling_grid output across L
                                (columns: L, seed, xmin, alpha, ...)
    xmins::Vector{Int} = [5, 10] — the xmin values to bracket

Returns
    DataFrame: (xmin, alpha_inf, sigma_alpha_inf, c, sigma_c, n_L, chi2)
    plus summary row with (xmin = :bracket_width) giving the α_∞ range
    between the low and high xmin extrapolations.

Rules
    - For each xmin in the grid, compute per-L mean ± std across seeds,
      then call `finite_size_extrapolation` with those as weighted inputs.
    - The bracket_width row is α_inf(max xmin) − α_inf(min xmin); its
      sign matters (finite-size cutoff bias pushes higher xmin α_inf up).
"""
function fss_extrapolation_bracketed(multiscaling_df::DataFrame;
                                     xmins::Vector = [5, 10])
    rows = NamedTuple[]
    inf_by_xmin = Dict{Float64, Float64}()
    for xm in xmins
        xm_f = Float64(xm)
        sub = filter(r -> r.xmin == xm_f, multiscaling_df)
        isempty(sub) && continue
        by_L = combine(groupby(sub, :L),
                      :alpha => mean => :alpha_mean,
                      :alpha => std  => :alpha_std)
        nrow(by_L) < 3 && continue
        fs = finite_size_extrapolation(Float64.(by_L.L),
                                       by_L.alpha_mean,
                                       by_L.alpha_std)
        push!(rows, (xmin = xm_f,
                     alpha_inf = fs.alpha_inf,
                     sigma_alpha_inf = fs.sigma_alpha_inf,
                     c = fs.c, sigma_c = fs.sigma_c,
                     n_L = fs.n_points, chi2 = fs.chi2))
        inf_by_xmin[xm_f] = fs.alpha_inf
    end
    # Bracket width row (α_∞ at max xmin − α_∞ at min xmin)
    if length(inf_by_xmin) >= 2
        xm_low, xm_high = extrema(keys(inf_by_xmin))
        width = inf_by_xmin[xm_high] - inf_by_xmin[xm_low]
        push!(rows, (xmin = -1.0,  # sentinel marker for "bracket width"
                     alpha_inf = width,
                     sigma_alpha_inf = NaN,
                     c = NaN, sigma_c = NaN,
                     n_L = length(inf_by_xmin), chi2 = NaN))
    end
    return DataFrame(rows)
end


# ==============================================================================
# SUMMARY STATS PER L
# ==============================================================================

"""Per-L scalar summary for quick overview and FSS."""
function summary_stats(summaries::DataFrame, diagnostics::DataFrame,
                      L::Int; final_height::Union{Nothing, AbstractMatrix} = nothing)
    nonempty = filter(>(0), summaries.size)
    dur_nonempty = filter(>(0), summaries.duration)
    return (
        L = L,
        n_seeds = nrow(diagnostics),
        n_recorded = nrow(summaries),
        n_nonempty = length(nonempty),
        mean_size = isempty(nonempty) ? NaN : mean(nonempty),
        median_size = isempty(nonempty) ? NaN : median(nonempty),
        max_size = isempty(nonempty) ? 0 : maximum(nonempty),
        mean_duration = isempty(dur_nonempty) ? NaN : mean(dur_nonempty),
        max_duration = isempty(dur_nonempty) ? 0 : maximum(dur_nonempty),
        mean_z = isnothing(final_height) ? NaN : mean(final_height),
        beta_high_mean = mean(diagnostics.beta_high),
        beta_high_std = std(diagnostics.beta_high),
        hurst_mean = mean(skipmissing(diagnostics.hurst_H)),
        hurst_std = std(skipmissing(diagnostics.hurst_H)),
        excess_kurtosis_mean = mean(diagnostics.excess_kurtosis_raw),
        branching_plateau_mean = mean(skipmissing(diagnostics.branching_plateau_mean)),
        total_wallclock_s = sum(diagnostics.wallclock_s),
    )
end


# ==============================================================================
# SANITY CHECKS
# ==============================================================================

"""
Verify ensemble integrity before spending time on heavy fits. Returns a Vector
of warning strings; empty vector means all checks passed.

Rules
    - All seeds converged
    - Mean z across seeds within 0.05 of expected (2.125 for BTW)
    - No zero-avalanche seeds
    - All seeds have similar n_nonempty (within 2×)
"""
function sanity_check_ensemble(diagnostics::DataFrame, summaries::DataFrame, L::Int;
                              expected_mean_z::Real = 2.125,
                              mean_z_tol::Real = 0.05)
    warnings = String[]

    n_unconverged = sum(.!diagnostics.converged)
    if n_unconverged > 0
        push!(warnings, "L=$L: $n_unconverged/$(nrow(diagnostics)) seeds did not converge")
    end

    if :mean_z in propertynames(diagnostics)
        mz_vals = filter(!isnan, diagnostics.mean_z)
        if !isempty(mz_vals)
            mz = mean(mz_vals)
            if abs(mz - expected_mean_z) > mean_z_tol
                push!(warnings, "L=$L: mean_z=$mz differs from expected $expected_mean_z by >$mean_z_tol")
            end
        end
    end

    per_seed_counts = combine(groupby(summaries, :seed), nrow => :n)
    if !isempty(per_seed_counts.n)
        ratio = maximum(per_seed_counts.n) / max(minimum(per_seed_counts.n), 1)
        if ratio > 2.0
            push!(warnings, "L=$L: per-seed avalanche count ratio $ratio > 2 (uneven simulation)")
        end
    end

    n_nonempty_per_seed = combine(groupby(summaries, :seed),
                                  :size => (s -> count(>(0), s)) => :n_nonempty)
    zero_seeds = filter(r -> r.n_nonempty == 0, n_nonempty_per_seed)
    if nrow(zero_seeds) > 0
        push!(warnings, "L=$L: $(nrow(zero_seeds)) seed(s) have zero non-empty avalanches — simulator broken?")
    end

    return warnings
end


# ==============================================================================
# WRITE HELPERS
# ==============================================================================

function _write_if_nonempty(df::DataFrame, path::AbstractString)
    mkpath(dirname(path))
    if nrow(df) > 0
        Arrow.write(path, df)
    end
end


# ==============================================================================
# TOP-LEVEL RUNNER
# ==============================================================================

"""
Run full analysis pipeline on a completed ensemble.

Arguments
    data_dir::AbstractString = DEFAULT_OUT_DIR   — where ensemble Arrows live
    out_subdir::AbstractString = DEFAULT_ANALYSIS_SUBDIR — subdir under data_dir
    L_values::Union{Nothing, Vector{Int}} = nothing — default: auto-discover
                                                     from summaries/ filenames
    xmin_fixed::Real = XMIN_FIXED
    xmin_grid::Vector = XMIN_GRID
    expected_mean_z::Real = 2.125
    mean_z_tol::Real = 0.05

Returns
    nothing — all results written under data_dir/out_subdir/.

Rules
    - Runs sanity_check_ensemble for every L, warns on failures
    - Writes 12 Arrow files (see analysis_manifest for list)
    - analysis.log captures timing per stage

Usage
    run_btw_analysis()
    run_btw_analysis(data_dir="data/exp01_01_test")
"""
function run_btw_analysis(;
        data_dir::AbstractString = DEFAULT_OUT_DIR,
        out_subdir::AbstractString = DEFAULT_ANALYSIS_SUBDIR,
        L_values::Union{Nothing, Vector{Int}} = nothing,
        xmin_fixed::Real = XMIN_FIXED,
        xmin_grid::Vector = XMIN_GRID,
        expected_mean_z::Real = 2.125,
        mean_z_tol::Real = 0.05)

    out_dir = joinpath(data_dir, out_subdir)
    mkpath(out_dir)
    log_path = joinpath(out_dir, "analysis.log")
    logio = open(log_path, "a")

    Ls = if isnothing(L_values)
        _discover_L_values(data_dir)
    else
        L_values
    end

    t_start = time()
    stage_times = NamedTuple[]

    all_pooled_size = DataFrame[]
    all_per_seed_size = DataFrame[]
    all_multiscaling = DataFrame[]
    all_area = DataFrame[]
    all_duration = DataFrame[]
    all_pooled_psd = DataFrame[]
    all_pooled_bx = DataFrame[]
    all_iet = DataFrame[]
    all_corr = DataFrame[]
    all_pmfs = DataFrame[]
    all_summary = NamedTuple[]
    all_warnings = String[]

    function banner(msg)
        ts = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
        line = "[$ts] $msg"
        println(line); flush(stdout)
        println(logio, line); flush(logio)
    end

    banner("=== run_btw_analysis start  data_dir=$data_dir  out=$out_dir  Ls=$Ls ===")

    for L in Ls
        banner("--- L=$L ---")
        t_L = time()

        loaded = load_ensemble(data_dir, L)
        summaries = loaded.summaries
        diagnostics = loaded.diagnostics
        micro = loaded.micro

        # Sanity checks
        warnings = sanity_check_ensemble(diagnostics, summaries, L;
                                        expected_mean_z = expected_mean_z,
                                        mean_z_tol = mean_z_tol)
        if isempty(warnings)
            banner("  sanity OK")
        else
            for w in warnings
                banner("  WARN $w")
            end
            append!(all_warnings, warnings)
        end

        # Pooled size fits
        t0 = time()
        sizes_pool = Float64.(filter(>(0), summaries.size))
        push!(all_pooled_size, pooled_size_fits(sizes_pool, L))
        banner("  pooled_size_fits         $(round(time()-t0, digits=1))s")

        # Per-seed size fits at fixed xmin
        t0 = time()
        push!(all_per_seed_size,
              per_seed_size_fits(summaries, L; xmin = xmin_fixed))
        banner("  per_seed_size_fits       $(round(time()-t0, digits=1))s")

        # Multiscaling grid
        t0 = time()
        push!(all_multiscaling,
              multiscaling_grid(summaries, L; xmin_grid = xmin_grid))
        banner("  multiscaling_grid        $(round(time()-t0, digits=1))s")

        # Area fits
        t0 = time()
        push!(all_area, area_fits(summaries, L))
        banner("  area_fits                $(round(time()-t0, digits=1))s")

        # Duration fits
        t0 = time()
        push!(all_duration, duration_fits(summaries, L; xmin = xmin_fixed))
        banner("  duration_fits            $(round(time()-t0, digits=1))s")

        # Pooled PSD
        t0 = time()
        push!(all_pooled_psd, pooled_psd(micro, L))
        banner("  pooled_psd               $(round(time()-t0, digits=1))s")

        # Pooled b(x)
        t0 = time()
        push!(all_pooled_bx, pooled_bx(micro, L))
        banner("  pooled_bx                $(round(time()-t0, digits=1))s")

        # Inter-event CCDFs
        t0 = time()
        push!(all_iet, inter_event_ccdfs(summaries, L))
        banner("  inter_event_ccdfs        $(round(time()-t0, digits=1))s")

        # Log-binned PMFs
        t0 = time()
        push!(all_pmfs, log_binned_pmfs(summaries, L))
        banner("  log_binned_pmfs          $(round(time()-t0, digits=1))s")

        # Spatial correlation — expensive, only for L <= 256
        if L <= 256 && !isnothing(loaded.heights)
            t0 = time()
            push!(all_corr, spatial_correlation(loaded.heights, L))
            banner("  spatial_correlation      $(round(time()-t0, digits=1))s")
        else
            banner("  spatial_correlation      skipped (L>256 or no heights)")
        end

        # Summary stats
        fh = isnothing(loaded.heights) ? nothing : reconstruct_height_field(loaded.heights)
        push!(all_summary, summary_stats(summaries, diagnostics, L; final_height = fh))

        push!(stage_times, (L = L, total_s = time() - t_L))
        banner("  L=$L total: $(round(time() - t_L, digits=1))s")
    end

    # Consolidate per-L DataFrames
    pooled_size_df = isempty(all_pooled_size) ? DataFrame() : reduce(vcat, all_pooled_size)
    per_seed_size_df = isempty(all_per_seed_size) ? DataFrame() : reduce(vcat, all_per_seed_size)
    multiscaling_df = isempty(all_multiscaling) ? DataFrame() : reduce(vcat, all_multiscaling)
    area_df = isempty(all_area) ? DataFrame() : reduce(vcat, all_area)
    duration_df = isempty(all_duration) ? DataFrame() : reduce(vcat, all_duration)
    psd_df = isempty(all_pooled_psd) ? DataFrame() : reduce(vcat, all_pooled_psd)
    bx_df = isempty(all_pooled_bx) ? DataFrame() : reduce(vcat, all_pooled_bx)
    iet_df = isempty(all_iet) ? DataFrame() : reduce(vcat, all_iet)
    corr_df = isempty(all_corr) ? DataFrame() : reduce(vcat, all_corr)
    pmfs_df = isempty(all_pmfs) ? DataFrame() : reduce(vcat, all_pmfs)
    summary_df = DataFrame(all_summary)

    # Finite-size extrapolation across all observables
    t0 = time()
    fss_df = all_fss_extrapolations(per_seed_size_df, area_df, duration_df, summary_df)
    banner("all_fss_extrapolations     $(round(time()-t0, digits=1))s")

    # Write outputs
    _write_if_nonempty(pooled_size_df,   _apath(out_dir, "pooled_size_fits.arrow"))
    _write_if_nonempty(per_seed_size_df, _apath(out_dir, "per_seed_size_fits.arrow"))
    _write_if_nonempty(multiscaling_df,  _apath(out_dir, "multiscaling_grid.arrow"))
    _write_if_nonempty(area_df,          _apath(out_dir, "area_fits.arrow"))
    _write_if_nonempty(duration_df,      _apath(out_dir, "duration_fits.arrow"))
    _write_if_nonempty(psd_df,           _apath(out_dir, "pooled_psd.arrow"))
    _write_if_nonempty(bx_df,            _apath(out_dir, "pooled_bx.arrow"))
    _write_if_nonempty(iet_df,           _apath(out_dir, "inter_event_ccdfs.arrow"))
    _write_if_nonempty(corr_df,          _apath(out_dir, "correlation.arrow"))
    _write_if_nonempty(pmfs_df,          _apath(out_dir, "log_binned_pmfs.arrow"))
    _write_if_nonempty(summary_df,       _apath(out_dir, "summary_stats.arrow"))
    _write_if_nonempty(fss_df,           _apath(out_dir, "fss_extrapolation.arrow"))

    # Manifest
    manifest = DataFrame(
        timestamp = [Dates.format(now(), "yyyy-mm-dd HH:MM:SS")],
        data_dir = [String(data_dir)],
        L_values = [string(Ls)],
        xmin_fixed = [Float64(xmin_fixed)],
        xmin_grid = [string(xmin_grid)],
        n_warnings = [length(all_warnings)],
        total_wallclock_s = [time() - t_start],
    )
    Arrow.write(_apath(out_dir, "analysis_manifest.arrow"), manifest)

    banner("=== run_btw_analysis finished in $(round(time() - t_start, digits=1))s  warnings=$(length(all_warnings)) ===")
    close(logio)
    return nothing
end


# ==============================================================================
# MANNA ANALYSIS RUNNER
# ==============================================================================

"""
Run the full Manna ensemble analysis, producing all pre-computed Arrow files
that the notebook's fast-path loads.

Arguments
    data_dir::AbstractString = "data/exp01_02" — ensemble root directory
    out_subdir::AbstractString = DEFAULT_ANALYSIS_SUBDIR — analysis/ under data_dir
    L_values::Union{Nothing, Vector{Int}} = nothing — auto-discover if nothing
    xmin_fixed::Real = XMIN_FIXED — primary xmin for single-xmin outputs (5.0)
    xmin_grid::Vector = XMIN_GRID — [5, 10, 30, 100, 300] for multiscaling
    xmins_bracket::Vector = [5, 10] — xmins for bracketed FSS reporting
    expected_mean_z::Real = 0.70 — empirical driven-open-boundary stationary
                                   density (published fixed-energy ρ_c = 0.683;
                                   driven offset is ~3-5% above ρ_c)
    mean_z_tol::Real = 0.1 — sanity-check tolerance on mean_z

Returns
    nothing — all outputs written to disk as Arrow files

Rules
    - Mirrors run_btw_analysis file layout. Notebook fast-path reads all
      Arrow files via load_analysis and displays them.
    - Adds two Manna-specific outputs beyond the BTW set:
        * fractal_dimensions.arrow — D_s, D_a, γ at (L, top50/top1 variant)
        * fractal_extrapolation.arrow — 1/L extrapolation per variant
        * fss_extrapolation_bracketed.arrow — α_∞ at xmin=5 AND xmin=10
          (the primary methodology per feedback_xmin_bracketed_reporting)
    - Spatial correlation computed only for L <= 256 (expensive)
    - Per-seed heights available only for seed=1 of each L

Usage
    run_manna_analysis()
    run_manna_analysis(data_dir="data/exp01_02_test",
                       L_values=[128, 256])
"""
function run_manna_analysis(;
        data_dir::AbstractString = DEFAULT_MANNA_OUT_DIR,
        out_subdir::AbstractString = DEFAULT_ANALYSIS_SUBDIR,
        L_values::Union{Nothing, Vector{Int}} = nothing,
        xmin_fixed::Real = XMIN_FIXED,
        xmin_grid::Vector = XMIN_GRID,
        xmins_bracket::Vector = [5, 10],
        expected_mean_z::Real = 0.70,
        mean_z_tol::Real = 0.1)

    out_dir = joinpath(data_dir, out_subdir)
    mkpath(out_dir)
    log_path = joinpath(out_dir, "analysis.log")
    logio = open(log_path, "a")

    Ls = if isnothing(L_values)
        _discover_L_values(data_dir)
    else
        L_values
    end

    t_start = time()
    stage_times = NamedTuple[]

    all_pooled_size = DataFrame[]
    all_per_seed_size = DataFrame[]
    all_multiscaling = DataFrame[]
    all_area = DataFrame[]
    all_duration = DataFrame[]
    all_pooled_psd = DataFrame[]
    all_pooled_bx = DataFrame[]
    all_iet = DataFrame[]
    all_corr = DataFrame[]
    all_pmfs = DataFrame[]
    all_summary = NamedTuple[]
    all_fractal = DataFrame[]
    all_warnings = String[]

    function banner(msg)
        ts = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
        line = "[$ts] $msg"
        println(line); flush(stdout)
        println(logio, line); flush(logio)
    end

    banner("=== run_manna_analysis start  data_dir=$data_dir  out=$out_dir  Ls=$Ls ===")
    banner("    xmins_bracket=$xmins_bracket  expected_mean_z=$expected_mean_z")

    for L in Ls
        banner("--- L=$L ---")
        t_L = time()

        loaded = load_ensemble(data_dir, L)
        summaries = loaded.summaries
        diagnostics = loaded.diagnostics
        micro = loaded.micro

        # Sanity checks (Manna tolerances)
        warnings = sanity_check_ensemble(diagnostics, summaries, L;
                                        expected_mean_z = expected_mean_z,
                                        mean_z_tol = mean_z_tol)
        if isempty(warnings)
            banner("  sanity OK")
        else
            for w in warnings
                banner("  WARN $w")
            end
            append!(all_warnings, warnings)
        end

        # Pooled size fits (auto, manual 5, manual 10, scaling-regime)
        t0 = time()
        sizes_pool = Float64.(filter(>(0), summaries.size))
        push!(all_pooled_size, pooled_size_fits(sizes_pool, L))
        banner("  pooled_size_fits         $(round(time()-t0, digits=1))s")

        # Per-seed size fits — at BOTH xmin values in bracket (vcat'd)
        t0 = time()
        for xm in xmins_bracket
            push!(all_per_seed_size,
                  per_seed_size_fits(summaries, L; xmin = Float64(xm)))
        end
        banner("  per_seed_size_fits×$(length(xmins_bracket))     $(round(time()-t0, digits=1))s")

        # Multiscaling grid (captures xmin=5, 10, 30, 100, 300 per seed)
        t0 = time()
        push!(all_multiscaling,
              multiscaling_grid(summaries, L; xmin_grid = xmin_grid))
        banner("  multiscaling_grid        $(round(time()-t0, digits=1))s")

        # Area fits (pooled auto + per-seed auto)
        t0 = time()
        push!(all_area, area_fits(summaries, L))
        banner("  area_fits                $(round(time()-t0, digits=1))s")

        # Duration fits (manual xmin)
        t0 = time()
        push!(all_duration, duration_fits(summaries, L; xmin = xmin_fixed))
        banner("  duration_fits            $(round(time()-t0, digits=1))s")

        # Pooled PSD
        t0 = time()
        push!(all_pooled_psd, pooled_psd(micro, L))
        banner("  pooled_psd               $(round(time()-t0, digits=1))s")

        # Pooled b(x)
        t0 = time()
        push!(all_pooled_bx, pooled_bx(micro, L))
        banner("  pooled_bx                $(round(time()-t0, digits=1))s")

        # Inter-event CCDFs
        t0 = time()
        push!(all_iet, inter_event_ccdfs(summaries, L))
        banner("  inter_event_ccdfs        $(round(time()-t0, digits=1))s")

        # Log-binned PMFs
        t0 = time()
        push!(all_pmfs, log_binned_pmfs(summaries, L))
        banner("  log_binned_pmfs          $(round(time()-t0, digits=1))s")

        # Fractal dimensions (top50 and top1 variants)
        t0 = time()
        push!(all_fractal, fractal_dimensions(summaries, L))
        banner("  fractal_dimensions       $(round(time()-t0, digits=1))s")

        # Spatial correlation — expensive, only for L <= 256
        if L <= 256 && !isnothing(loaded.heights)
            t0 = time()
            push!(all_corr, spatial_correlation(loaded.heights, L))
            banner("  spatial_correlation      $(round(time()-t0, digits=1))s")
        else
            banner("  spatial_correlation      skipped (L>256 or no heights)")
        end

        # Summary stats
        fh = isnothing(loaded.heights) ? nothing : reconstruct_height_field(loaded.heights)
        push!(all_summary, summary_stats(summaries, diagnostics, L; final_height = fh))

        push!(stage_times, (L = L, total_s = time() - t_L))
        banner("  L=$L total: $(round(time() - t_L, digits=1))s")
    end

    # Consolidate per-L DataFrames
    pooled_size_df   = isempty(all_pooled_size) ? DataFrame() : reduce(vcat, all_pooled_size)
    per_seed_size_df = isempty(all_per_seed_size) ? DataFrame() : reduce(vcat, all_per_seed_size)
    multiscaling_df  = isempty(all_multiscaling) ? DataFrame() : reduce(vcat, all_multiscaling)
    area_df          = isempty(all_area) ? DataFrame() : reduce(vcat, all_area)
    duration_df      = isempty(all_duration) ? DataFrame() : reduce(vcat, all_duration)
    psd_df           = isempty(all_pooled_psd) ? DataFrame() : reduce(vcat, all_pooled_psd)
    bx_df            = isempty(all_pooled_bx) ? DataFrame() : reduce(vcat, all_pooled_bx)
    iet_df           = isempty(all_iet) ? DataFrame() : reduce(vcat, all_iet)
    corr_df          = isempty(all_corr) ? DataFrame() : reduce(vcat, all_corr)
    pmfs_df          = isempty(all_pmfs) ? DataFrame() : reduce(vcat, all_pmfs)
    fractal_df       = isempty(all_fractal) ? DataFrame() : reduce(vcat, all_fractal)
    summary_df       = DataFrame(all_summary)

    # Standard FSS extrapolations (size@xmin5, area, duration, mean_z)
    t0 = time()
    # Use xmin=5 rows for the standard FSS size row
    per_seed_size_5 = filter(r -> r.xmin == Float64(xmin_fixed), per_seed_size_df)
    fss_df = all_fss_extrapolations(per_seed_size_5, area_df, duration_df, summary_df)
    banner("all_fss_extrapolations     $(round(time()-t0, digits=1))s")

    # Bracketed FSS for size (xmin=5 and xmin=10 from multiscaling_grid)
    t0 = time()
    fss_bracket_df = fss_extrapolation_bracketed(multiscaling_df;
                                                 xmins = xmins_bracket)
    banner("fss_extrapolation_bracketed  $(round(time()-t0, digits=1))s")

    # Fractal-dimension extrapolations (top50 and top1)
    t0 = time()
    fractal_ext_df = fractal_extrapolation(fractal_df)
    banner("fractal_extrapolation        $(round(time()-t0, digits=1))s")

    # Write outputs
    _write_if_nonempty(pooled_size_df,     _apath(out_dir, "pooled_size_fits.arrow"))
    _write_if_nonempty(per_seed_size_df,   _apath(out_dir, "per_seed_size_fits.arrow"))
    _write_if_nonempty(multiscaling_df,    _apath(out_dir, "multiscaling_grid.arrow"))
    _write_if_nonempty(area_df,            _apath(out_dir, "area_fits.arrow"))
    _write_if_nonempty(duration_df,        _apath(out_dir, "duration_fits.arrow"))
    _write_if_nonempty(psd_df,             _apath(out_dir, "pooled_psd.arrow"))
    _write_if_nonempty(bx_df,              _apath(out_dir, "pooled_bx.arrow"))
    _write_if_nonempty(iet_df,             _apath(out_dir, "inter_event_ccdfs.arrow"))
    _write_if_nonempty(corr_df,            _apath(out_dir, "correlation.arrow"))
    _write_if_nonempty(pmfs_df,            _apath(out_dir, "log_binned_pmfs.arrow"))
    _write_if_nonempty(summary_df,         _apath(out_dir, "summary_stats.arrow"))
    _write_if_nonempty(fss_df,             _apath(out_dir, "fss_extrapolation.arrow"))
    _write_if_nonempty(fss_bracket_df,     _apath(out_dir, "fss_extrapolation_bracketed.arrow"))
    _write_if_nonempty(fractal_df,         _apath(out_dir, "fractal_dimensions.arrow"))
    _write_if_nonempty(fractal_ext_df,     _apath(out_dir, "fractal_extrapolation.arrow"))

    # Manifest
    manifest = DataFrame(
        timestamp = [Dates.format(now(), "yyyy-mm-dd HH:MM:SS")],
        data_dir = [String(data_dir)],
        L_values = [string(Ls)],
        xmin_fixed = [Float64(xmin_fixed)],
        xmin_grid = [string(xmin_grid)],
        xmins_bracket = [string(xmins_bracket)],
        expected_mean_z = [Float64(expected_mean_z)],
        n_warnings = [length(all_warnings)],
        total_wallclock_s = [time() - t_start],
        model = ["manna"],
    )
    Arrow.write(_apath(out_dir, "analysis_manifest.arrow"), manifest)

    banner("=== run_manna_analysis finished in $(round(time() - t_start, digits=1))s  warnings=$(length(all_warnings)) ===")
    close(logio)
    return nothing
end


"""Auto-discover L values by scanning summary filenames under data_dir/summaries/."""
function _discover_L_values(data_dir::AbstractString)
    sum_dir = joinpath(data_dir, "summaries")
    isdir(sum_dir) || error("No summaries directory at $sum_dir")
    pattern = r"^summary_L(\d+)_seed\d+\.arrow$"
    Ls = Set{Int}()
    for f in readdir(sum_dir)
        m = match(pattern, f)
        isnothing(m) || push!(Ls, parse(Int, m[1]))
    end
    return sort(collect(Ls))
end


# ==============================================================================
# LOADERS (for notebook)
# ==============================================================================

"""
Load the pre-computed analysis Arrow files into a NamedTuple of DataFrames.

Arguments
    analysis_dir::AbstractString — typically "data/exp01_01/analysis"

Returns
    NamedTuple with fields matching each Arrow file (empty DataFrames if
    a file is missing). Fields: pooled_size, per_seed_size, multiscaling,
    area, duration, psd, bx, inter_event, correlation, pmfs, summary,
    fss, manifest.

Usage
    A = load_analysis("data/exp01_01/analysis")
    A.fss          # finite-size extrapolation results
    A.pooled_size  # pooled power-law fits per L
"""
function load_analysis(analysis_dir::AbstractString)
    function _load_or_empty(name)
        p = joinpath(analysis_dir, name)
        return isfile(p) ? DataFrame(Arrow.Table(p)) : DataFrame()
    end
    return (
        pooled_size          = _load_or_empty("pooled_size_fits.arrow"),
        per_seed_size        = _load_or_empty("per_seed_size_fits.arrow"),
        multiscaling         = _load_or_empty("multiscaling_grid.arrow"),
        area                 = _load_or_empty("area_fits.arrow"),
        duration             = _load_or_empty("duration_fits.arrow"),
        psd                  = _load_or_empty("pooled_psd.arrow"),
        bx                   = _load_or_empty("pooled_bx.arrow"),
        inter_event          = _load_or_empty("inter_event_ccdfs.arrow"),
        correlation          = _load_or_empty("correlation.arrow"),
        pmfs                 = _load_or_empty("log_binned_pmfs.arrow"),
        summary              = _load_or_empty("summary_stats.arrow"),
        fss                  = _load_or_empty("fss_extrapolation.arrow"),
        fss_bracketed        = _load_or_empty("fss_extrapolation_bracketed.arrow"),
        fractal              = _load_or_empty("fractal_dimensions.arrow"),
        fractal_extrapolation = _load_or_empty("fractal_extrapolation.arrow"),
        manifest             = _load_or_empty("analysis_manifest.arrow"),
    )
end
