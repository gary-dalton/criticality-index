# ==============================================================================
# EXPERIMENT 01 — SOC SIGNATURE DIAGNOSTICS
# ==============================================================================
#
# Diagnostic functions for detecting empirical signatures of Self-Organized
# Criticality. Designed to be applied to synthetic sandpile data first
# (Experiment 01) to validate against known SOC properties, then re-used on
# governance time series.
#
# Signatures covered:
#   1. Power-law event distribution (MLE per Clauset, Shalizi, Newman 2009)
#   2. Diverging correlation length (height-height correlation)
#   3. Scale invariance (PSD, Hurst, DFA)
#   4. Fractal structure (box-counting on avalanche frontiers)
#   5. Fat-tailed changes (kurtosis, GPD)
#
# Complementary:
#   - Activity-dependent branching ratio (Michiels van Kessenich et al. 2010)
#   - Inter-event time distribution
#
# References:
#   Clauset, Shalizi, Newman (2009). SIAM Review 51, 661.
#   Michiels van Kessenich et al. (2010). Phys. Rev. E 81, 016109.
#
# ==============================================================================

using Statistics
using StatsBase
using FFTW


# ==============================================================================
# LOG-BINNED PMF (FOR VISUALIZATION)
# ==============================================================================

"""
Log-binned probability mass function for heavy-tailed data.

Arguments
    data::Vector{<:Real} — positive-valued sample
    n_bins::Int = 50     — number of log-spaced bins

Returns
    NamedTuple with:
        bin_centers — geometric centers of bins
        pmf         — count in bin / (bin_width * total_count), i.e.
                      an estimate of P(x) at each bin center
        counts      — raw counts per bin

Rules
    - Linear binning wastes bins in the tail (mostly empty); log binning
      spreads bin widths so each decade gets equal resolution
    - Bins that are empty are dropped before returning
    - Bin width normalization (dividing by bin width) is essential to get
      a correct PMF — otherwise the apparent slope on log-log is distorted

Usage
    h = log_binned_pmf(sizes)
    # Plot: plot(h.bin_centers, h.pmf, xaxis=:log, yaxis=:log)
"""
function log_binned_pmf(data::Vector{<:Real}; n_bins::Int = 50)
    positive = filter(x -> x > 0, data)
    if length(positive) < 10
        return (bin_centers = Float64[], pmf = Float64[], counts = Int[])
    end
    x_min = minimum(positive)
    x_max = maximum(positive)
    edges = exp.(range(log(x_min), log(x_max + 1), length = n_bins + 1))

    counts = zeros(Int, n_bins)
    for x in positive
        # Find bin for x
        b = searchsortedlast(edges, x)
        b = clamp(b, 1, n_bins)
        counts[b] += 1
    end

    N = length(positive)
    bin_centers = Float64[]
    pmf = Float64[]
    kept_counts = Int[]
    for b in 1:n_bins
        if counts[b] > 0
            width = edges[b + 1] - edges[b]
            push!(bin_centers, sqrt(edges[b] * edges[b + 1]))  # geometric center
            push!(pmf, counts[b] / (width * N))
            push!(kept_counts, counts[b])
        end
    end
    return (bin_centers = bin_centers, pmf = pmf, counts = kept_counts)
end


# ==============================================================================
# SIGNATURE 1 — POWER-LAW DISTRIBUTION (Clauset MLE)
# ==============================================================================

"""
Maximum likelihood estimate of the power-law exponent for discrete data.

Arguments
    data::Vector{<:Real} — sample of positive values
    xmin::Real           — lower bound of the power-law tail (data >= xmin used)

Returns
    NamedTuple with:
        alpha       — MLE exponent estimate
        sigma_alpha — standard error of alpha
        n_tail      — number of observations with x >= xmin

Rules
    - Uses the discrete MLE approximation (Clauset et al. 2009 eq. 3.7):
        alpha ~ 1 + n / sum(log(x_i / (xmin - 0.5)))
    - Standard error: sigma_alpha = (alpha - 1) / sqrt(n)
    - Returns alpha = NaN if insufficient data (n_tail < 2)

Usage
    fit = fit_power_law_mle(sizes, 1.0)
"""
function fit_power_law_mle(data::Vector{<:Real}, xmin::Real)
    tail = filter(x -> x >= xmin, data)
    n = length(tail)
    if n < 2
        return (alpha = NaN, sigma_alpha = NaN, n_tail = n)
    end
    # Discrete MLE approximation
    alpha = 1.0 + n / sum(log.(tail ./ (xmin - 0.5)))
    sigma_alpha = (alpha - 1.0) / sqrt(n)
    return (alpha = alpha, sigma_alpha = sigma_alpha, n_tail = n)
end


"""
Fit a power-law distribution to sample data.

Arguments
    data::Vector{<:Real}                     — sample of positive values
    xmin::Union{Nothing, Real} = nothing     — if provided, fix xmin to this value
                                              (skips the KS-minimization search)
    candidate_xmins::Union{Nothing, Vector} = nothing — xmin values to search
                                              (default: unique values in data
                                              up to the 95th percentile). Ignored
                                              if xmin is provided explicitly.
    xmax::Union{Nothing, Real} = nothing     — if provided, exclude data above this
                                              (useful for truncating finite-size
                                              cutoff regions that distort the fit)

Returns
    NamedTuple with:
        xmin        — xmin used (either provided or found by KS minimization)
        alpha       — MLE alpha at xmin
        sigma_alpha — standard error
        ks_distance — KS distance between empirical and fitted power-law CDF
        n_tail      — number of observations in the tail (xmin <= x <= xmax)

Rules
    - If xmin is provided: fit MLE alpha on data in [xmin, xmax], compute KS
    - If xmin is not provided: for each candidate, fit MLE + compute KS,
      return the xmin with minimum KS distance (Clauset et al. 2009 method)
    - Providing xmin manually is essential when the automatic search lands in
      a finite-size cutoff region rather than the true scaling regime
    - xmax is useful for BTW-like systems where the upper tail curves away
      from power-law behavior due to finite L

Usage
    fit = fit_power_law(sizes)                           # auto xmin search
    fit = fit_power_law(sizes; xmin=10)                  # manual xmin
    fit = fit_power_law(sizes; xmin=10, xmax=1000)       # scaling regime only
"""
function fit_power_law(data::Vector{<:Real};
                       xmin::Union{Nothing, Real} = nothing,
                       candidate_xmins::Union{Nothing, Vector} = nothing,
                       xmax::Union{Nothing, Real} = nothing)
    if !isnothing(xmin)
        # Manual xmin — single fit
        tail = if isnothing(xmax)
            filter(x -> x >= xmin, data)
        else
            filter(x -> xmin <= x <= xmax, data)
        end
        n_tail = length(tail)
        if n_tail < 50
            return (xmin = Float64(xmin), alpha = NaN, sigma_alpha = NaN,
                    ks_distance = NaN, n_tail = n_tail)
        end
        mle = fit_power_law_mle(collect(tail), xmin)
        ks = isnan(mle.alpha) ? NaN : ks_distance_power_law(tail, xmin, mle.alpha)
        return (xmin = Float64(xmin), alpha = mle.alpha,
                sigma_alpha = mle.sigma_alpha, ks_distance = ks,
                n_tail = n_tail)
    end

    # Automatic xmin search via KS minimization
    data_capped = isnothing(xmax) ? data : filter(x -> x <= xmax, data)
    sorted_unique = sort(unique(data_capped))
    if isnothing(candidate_xmins)
        cutoff = quantile(data_capped, 0.95)
        candidate_xmins = filter(x -> x <= cutoff, sorted_unique)
    end

    best_xmin = NaN
    best_ks = Inf
    best_alpha = NaN
    best_sigma = NaN
    best_n_tail = 0

    for xm in candidate_xmins
        tail = filter(x -> x >= xm, data_capped)
        n_tail = length(tail)
        if n_tail < 50
            continue
        end

        fit = fit_power_law_mle(collect(tail), xm)
        if isnan(fit.alpha) || fit.alpha <= 1.0
            continue
        end

        ks = ks_distance_power_law(tail, xm, fit.alpha)
        if ks < best_ks
            best_ks = ks
            best_xmin = xm
            best_alpha = fit.alpha
            best_sigma = fit.sigma_alpha
            best_n_tail = n_tail
        end
    end

    return (xmin = best_xmin,
            alpha = best_alpha,
            sigma_alpha = best_sigma,
            ks_distance = best_ks,
            n_tail = best_n_tail)
end


"""
Kolmogorov-Smirnov distance between empirical CDF of tail data and
the theoretical power-law CDF with parameters (xmin, alpha).

Arguments
    tail::Vector{<:Real} — data points with x >= xmin
    xmin::Real           — lower bound of the power law
    alpha::Real          — power-law exponent (alpha > 1)

Returns
    Float64 — maximum vertical distance between empirical and theoretical CDFs

Rules
    - Theoretical CDF for continuous power law: F(x) = 1 - (x/xmin)^(1-alpha)
    - Uses continuous approximation; sufficient for xmin not too small
"""
function ks_distance_power_law(tail::Vector{<:Real}, xmin::Real, alpha::Real)
    n = length(tail)
    sorted_tail = sort(tail)
    empirical_cdf = (1:n) ./ n
    theoretical_cdf = 1.0 .- (sorted_tail ./ xmin) .^ (1.0 - alpha)
    return maximum(abs.(empirical_cdf .- theoretical_cdf))
end


"""
Compare power-law fit against an exponential alternative via log-likelihood ratio.

Arguments
    data::Vector{<:Real} — sample
    xmin::Real           — lower bound
    alpha::Real          — fitted power-law exponent

Returns
    NamedTuple with:
        log_likelihood_ratio — positive favors power law, negative favors exponential
        lambda_exp           — fitted exponential rate parameter

Rules
    - Both distributions fit only to x >= xmin
    - Exponential MLE: lambda = 1 / (mean(tail) - xmin)
    - LR > 0: data better described by power law than exponential

Usage
    cmp = compare_power_law_exponential(sizes, fit.xmin, fit.alpha)
"""
function compare_power_law_exponential(data::Vector{<:Real}, xmin::Real, alpha::Real)
    tail = filter(x -> x >= xmin, data)
    n = length(tail)
    if n < 2 || isnan(alpha)
        return (log_likelihood_ratio = NaN, lambda_exp = NaN)
    end

    # Power-law log-likelihood (continuous approximation)
    ll_pl = n * log(alpha - 1) - n * log(xmin) - alpha * sum(log.(tail ./ xmin))

    # Exponential MLE (shifted by xmin)
    lambda = 1.0 / (mean(tail) - xmin)
    ll_exp = n * log(lambda) - lambda * sum(tail .- xmin)

    return (log_likelihood_ratio = ll_pl - ll_exp, lambda_exp = lambda)
end


# ==============================================================================
# SIGNATURE 2 — SPATIAL CORRELATION
# ==============================================================================

"""
Compute the radially averaged height-height correlation function.

Arguments
    field::Matrix{<:Real} — 2D scalar field (e.g., sandpile heights)
    max_r::Int            — maximum radial distance to compute (default: L/4)

Returns
    NamedTuple with:
        r       — Vector of radial distances (1:max_r)
        G       — Vector of correlation values G(r) = <z(0)z(r)> - <z>^2
        n_pairs — Vector of pair counts at each distance

Rules
    - G(r) is averaged over all site pairs separated by approximately r
      (rounded Euclidean distance)
    - Mean field is subtracted: G(r) = mean(z_i * z_j) - mean(z)^2 for |i-j| ~ r
    - Slow O(L^4) implementation; suitable for L <= 256

Usage
    corr = correlation_function(result.final_height)
"""
function correlation_function(field::Matrix{<:Real}; max_r::Union{Nothing, Int} = nothing)
    L = size(field, 1)
    if size(field, 2) != L
        error("correlation_function requires square field")
    end
    if isnothing(max_r)
        max_r = div(L, 4)
    end

    mean_field = mean(field)
    mean_sq = mean_field^2

    sum_g = zeros(Float64, max_r)
    n_pairs = zeros(Int, max_r)

    @inbounds for i1 in 1:L, j1 in 1:L
        z1 = field[i1, j1]
        for i2 in 1:L, j2 in 1:L
            if i1 == i2 && j1 == j2
                continue
            end
            d = sqrt((i1 - i2)^2 + (j1 - j2)^2)
            r_idx = round(Int, d)
            if 1 <= r_idx <= max_r
                sum_g[r_idx] += z1 * field[i2, j2]
                n_pairs[r_idx] += 1
            end
        end
    end

    G = [n_pairs[r] > 0 ? sum_g[r] / n_pairs[r] - mean_sq : 0.0 for r in 1:max_r]
    return (r = collect(1:max_r), G = G, n_pairs = n_pairs)
end


# ==============================================================================
# SIGNATURE 3 — SCALE INVARIANCE (PSD, HURST, DFA)
# ==============================================================================

"""
Power spectral density of a time series via FFT.

Arguments
    series::Vector{<:Real} — time series data
    fs::Real = 1.0         — sampling frequency

Returns
    NamedTuple with:
        freq — frequencies (positive only)
        psd  — power spectral density at each frequency

Rules
    - One-sided PSD (positive frequencies only)
    - Mean is subtracted before FFT
    - Returns abs2(FFT) / (n * fs) for power normalization

Usage
    spec = power_spectrum(sizes)
"""
function power_spectrum(series::Vector{<:Real}; fs::Real = 1.0)
    x = Float64.(series) .- mean(series)
    n = length(x)
    X = fft(x)
    psd = abs2.(X) ./ (n * fs)
    freq = fftfreq(n, fs)
    # One-sided
    half = div(n, 2)
    return (freq = freq[2:half], psd = psd[2:half])
end


"""
Estimate the spectral exponent beta from PSD ~ 1/f^beta in a frequency range.

Arguments
    freq::Vector{<:Real}    — frequencies
    psd::Vector{<:Real}     — power spectral density values
    freq_range::Tuple = (NaN, NaN) — (f_min, f_max) for fit; default: middle 80%

Returns
    NamedTuple with:
        beta       — slope of log10(PSD) vs log10(freq) (negated)
        intercept  — fit intercept
        n_used     — number of frequency points used

Rules
    - Fits log10(psd) = -beta * log10(freq) + intercept via OLS
    - Default frequency range excludes lowest 10% (transient effects) and
      highest 10% (Nyquist effects)
"""
function spectral_exponent(freq::Vector{<:Real}, psd::Vector{<:Real};
                           freq_range::Tuple = (NaN, NaN))
    if isnan(freq_range[1]) || isnan(freq_range[2])
        f_lo = quantile(freq, 0.10)
        f_hi = quantile(freq, 0.90)
    else
        f_lo, f_hi = freq_range
    end

    mask = (freq .>= f_lo) .& (freq .<= f_hi) .& (psd .> 0)
    log_f = log10.(freq[mask])
    log_p = log10.(psd[mask])

    n = length(log_f)
    if n < 5
        return (beta = NaN, intercept = NaN, n_used = n)
    end

    # OLS slope
    mean_x = mean(log_f)
    mean_y = mean(log_p)
    slope = sum((log_f .- mean_x) .* (log_p .- mean_y)) / sum((log_f .- mean_x) .^ 2)
    intercept = mean_y - slope * mean_x

    return (beta = -slope, intercept = intercept, n_used = n)
end


"""
Estimate the Hurst exponent via rescaled-range (R/S) analysis.

Arguments
    series::Vector{<:Real} — time series
    n_scales::Int = 20     — number of window sizes to evaluate

Returns
    NamedTuple with:
        H        — estimated Hurst exponent
        scales   — window sizes used
        rs_vals  — R/S values at each scale

Rules
    - For each window size n: split series into non-overlapping windows,
      compute R/S in each, average
    - H = slope of log(<R/S>) vs log(n)
    - H = 0.5: random walk; H > 0.5: persistent; H < 0.5: anti-persistent

Usage
    h = hurst_rs(sizes)
"""
function hurst_rs(series::Vector{<:Real}; n_scales::Int = 20)
    N = length(series)
    if N < 100
        return (H = NaN, scales = Int[], rs_vals = Float64[])
    end

    # Geometrically spaced window sizes from 10 to N/4
    min_n = 10
    max_n = div(N, 4)
    scales = unique(round.(Int, exp.(range(log(min_n), log(max_n), length=n_scales))))

    rs_vals = Float64[]
    valid_scales = Int[]

    for n in scales
        n_windows = div(N, n)
        if n_windows < 2
            continue
        end
        rs_window = Float64[]
        for w in 0:(n_windows - 1)
            window = series[(w * n + 1):((w + 1) * n)]
            mu = mean(window)
            y = cumsum(window .- mu)
            R = maximum(y) - minimum(y)
            S = std(window)
            if S > 0
                push!(rs_window, R / S)
            end
        end
        if !isempty(rs_window)
            push!(rs_vals, mean(rs_window))
            push!(valid_scales, n)
        end
    end

    if length(valid_scales) < 5
        return (H = NaN, scales = valid_scales, rs_vals = rs_vals)
    end

    log_n = log.(Float64.(valid_scales))
    log_rs = log.(rs_vals)
    mean_x = mean(log_n)
    mean_y = mean(log_rs)
    H = sum((log_n .- mean_x) .* (log_rs .- mean_y)) / sum((log_n .- mean_x) .^ 2)
    return (H = H, scales = valid_scales, rs_vals = rs_vals)
end


# ==============================================================================
# SIGNATURE 4 — FRACTAL STRUCTURE (BOX-COUNTING)
# ==============================================================================

"""
Box-counting fractal dimension of a 2D point set.

Arguments
    sites::Vector{Tuple{Int, Int}} — set of (i, j) coordinates
    L::Int                         — bounding lattice side length
    box_sizes::Vector{Int} = [1, 2, 4, 8, 16, 32, 64] — box edge lengths

Returns
    NamedTuple with:
        D_f       — fractal dimension (slope of log N vs log(1/eps))
        box_sizes — box sizes used
        counts    — N(eps) for each box size

Rules
    - For each box size eps: tile L x L grid into boxes of side eps,
      count N(eps) = number of boxes containing at least one site
    - Fit log(N) vs log(1/eps) by OLS to get D_f
    - Skips box sizes >= L (only one box) or with too few points

Usage
    bc = box_counting(toppled_sites, 128)
"""
function box_counting(sites::Vector{Tuple{Int, Int}}, L::Int;
                      box_sizes::Vector{Int} = [1, 2, 4, 8, 16, 32, 64])
    valid_sizes = filter(eps -> eps < L, box_sizes)
    counts = Int[]
    used_sizes = Int[]

    for eps in valid_sizes
        occupied = Set{Tuple{Int, Int}}()
        for (i, j) in sites
            box_i = div(i - 1, eps) + 1
            box_j = div(j - 1, eps) + 1
            push!(occupied, (box_i, box_j))
        end
        push!(counts, length(occupied))
        push!(used_sizes, eps)
    end

    if length(used_sizes) < 3
        return (D_f = NaN, box_sizes = used_sizes, counts = counts)
    end

    log_inv_eps = -log.(Float64.(used_sizes))
    log_n = log.(Float64.(counts))
    mean_x = mean(log_inv_eps)
    mean_y = mean(log_n)
    D_f = sum((log_inv_eps .- mean_x) .* (log_n .- mean_y)) /
          sum((log_inv_eps .- mean_x) .^ 2)
    return (D_f = D_f, box_sizes = used_sizes, counts = counts)
end


# ==============================================================================
# SIGNATURE 5 — FAT-TAILED CHANGES (KURTOSIS)
# ==============================================================================

"""
Excess kurtosis of first differences of a time series.

Arguments
    series::Vector{<:Real} — time series
    window::Int = 1        — width of rolling mean before differencing
                             (1 = raw differences)

Returns
    NamedTuple with:
        excess_kurtosis — kurt(diffs) - 3 (Gaussian baseline = 0)
        n_diffs         — number of difference values

Rules
    - If window > 1: compute rolling mean of width window, then difference
    - Excess kurtosis > 0: heavier tails than Gaussian
    - Excess kurtosis > 1.5 is acceptance threshold for SOC fat tails

Usage
    fat = fat_tail_kurtosis(sizes; window=100)
"""
function fat_tail_kurtosis(series::Vector{<:Real}; window::Int = 1)
    if window > 1
        rolling = [mean(series[i:(i + window - 1)]) for i in 1:(length(series) - window + 1)]
        diffs = diff(rolling)
    else
        diffs = diff(Float64.(series))
    end
    n = length(diffs)
    if n < 10
        return (excess_kurtosis = NaN, n_diffs = n)
    end
    return (excess_kurtosis = kurtosis(diffs), n_diffs = n)
end


# ==============================================================================
# COMPLEMENTARY — ACTIVITY-DEPENDENT BRANCHING RATIO
# ==============================================================================

"""
Activity-dependent branching ratio b(x) for an avalanche catalog.

Arguments
    catalog::Vector{AvalancheRecord} — avalanche records with wave profiles
    n_bins::Int = 20                 — number of activity-level bins (log-spaced)

Returns
    NamedTuple with:
        activity_levels — bin centers (geometric)
        b_of_x          — mean branching ratio in each bin
        n_in_bin        — sample count per bin

Rules
    - For each avalanche: extract wave-to-wave ratios b_t = n_{t+1} / n_t
    - Bin by source activity n_t (log-spaced)
    - b(x) ≈ 1 across a broad activity range is the SOC signature
      (Michiels van Kessenich et al. 2010)

Usage
    bx = branching_ratio_activity_dependent(catalog)
"""
function branching_ratio_activity_dependent(catalog;
                                            n_bins::Int = 20)
    activities = Int[]
    ratios = Float64[]
    for a in catalog
        if a.duration < 2
            continue
        end
        for t in 1:(a.duration - 1)
            n_t = a.wave_profile[t]
            n_next = a.wave_profile[t + 1]
            if n_t > 0
                push!(activities, n_t)
                push!(ratios, n_next / n_t)
            end
        end
    end

    if isempty(activities)
        return (activity_levels = Float64[], b_of_x = Float64[], n_in_bin = Int[])
    end

    # Log-spaced bins
    a_min = max(1, minimum(activities))
    a_max = maximum(activities)
    if a_max <= a_min
        return (activity_levels = [Float64(a_min)], b_of_x = [mean(ratios)],
                n_in_bin = [length(ratios)])
    end
    edges = exp.(range(log(a_min), log(a_max + 1), length = n_bins + 1))

    activity_levels = Float64[]
    b_of_x = Float64[]
    n_in_bin = Int[]

    for b in 1:n_bins
        lo, hi = edges[b], edges[b + 1]
        mask = (activities .>= lo) .& (activities .< hi)
        if sum(mask) >= 5
            push!(activity_levels, sqrt(lo * hi))  # geometric center
            push!(b_of_x, mean(ratios[mask]))
            push!(n_in_bin, sum(mask))
        end
    end

    return (activity_levels = activity_levels, b_of_x = b_of_x, n_in_bin = n_in_bin)
end


"""Global mean branching ratio across all wave transitions.

Provided for comparison with activity-dependent measure (Section 5.6 of
the experiment design — naive global average can miss critical structure)."""
function branching_ratio_global(catalog)
    ratios = Float64[]
    for a in catalog
        if a.duration < 2
            continue
        end
        for t in 1:(a.duration - 1)
            n_t = a.wave_profile[t]
            n_next = a.wave_profile[t + 1]
            if n_t > 0
                push!(ratios, n_next / n_t)
            end
        end
    end
    return isempty(ratios) ? NaN : mean(ratios)
end


# ==============================================================================
# COMPLEMENTARY — INTER-EVENT TIMES
# ==============================================================================

"""
Compute waiting times between avalanches above a size threshold.

Arguments
    sizes_in_order::Vector{<:Real} — avalanche sizes in temporal order
                                     (one entry per grain drop, including
                                      zero for empty avalanches)
    threshold::Real                — minimum size to count as an "event"

Returns
    Vector{Int} — number of timesteps between successive events with size >= threshold

Rules
    - Returns N - 1 waiting times for N events above threshold
    - Returns empty vector if fewer than 2 events

Usage
    waits = inter_event_times(all_sizes, quantile(all_sizes, 0.9))
"""
function inter_event_times(sizes_in_order::Vector{<:Real}, threshold::Real)
    event_indices = findall(s -> s >= threshold, sizes_in_order)
    if length(event_indices) < 2
        return Int[]
    end
    return diff(event_indices)
end
