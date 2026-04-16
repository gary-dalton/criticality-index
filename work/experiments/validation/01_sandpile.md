# Experiment 01: Synthetic Sandpile — SOC Signature Validation

## Purpose

Validate that our diagnostic functions correctly detect all five empirical signatures of SOC in a system where criticality is guaranteed by construction. The Bak-Tang-Wiesenfeld (BTW) sandpile is the canonical SOC system — if our tools fail here, they cannot be trusted on governance data.

This experiment produces ground truth for Experiment 02 (percolation) and all subsequent experiments.

---

## The Model: BTW Sandpile

### Definition

A deterministic cellular automaton on an L x L square lattice with open boundary conditions.

**State:** Each site (i, j) holds an integer height z(i,j) >= 0.

**Driving:** At each timestep, one randomly chosen site receives a grain:
```
z(i,j) → z(i,j) + 1
```

**Toppling rule:** If z(i,j) >= z_c (critical threshold, typically z_c = 4 for a 2D square lattice), the site topples:
```
z(i,j)  → z(i,j) - 4
z(i±1,j) → z(i±1,j) + 1
z(i,j±1) → z(i,j±1) + 1
```

**Boundary dissipation:** Sites at the lattice edge lose grains that would go off-grid. This is the only energy exit — the "edge of the table."

**Avalanche:** A single grain addition may trigger zero, one, or many topplings. The total number of topplings before the system re-stabilizes is the avalanche size s. The number of distinct timesteps during which at least one toppling occurs is the avalanche duration T.

### Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| L | 64, 128, 256 | Lattice side length. Run all three for finite-size scaling |
| z_c | 4 | Critical threshold (fixed by 2D square lattice geometry) |
| N_transient | 10^5 | Grains to drop before recording (system must reach steady state) |
| N_record | 10^6 | Avalanches to record after transient |

### Implementation Notes

- **Deterministic.** The BTW sandpile is fully deterministic given the sequence of grain drop locations. Use a seeded RNG for the drop site sequence to ensure reproducibility.
- **Separation of timescales.** All topplings from a single grain complete before the next grain is added. This is the "infinitely slow driving" condition required for SOC.
- **No parallel toppling.** Process topplings sequentially (standard BTW). Parallel toppling variants exist but change the universality class.

---

## What We Measure

### Per Avalanche

| Quantity | Symbol | Definition |
|----------|--------|------------|
| Size | s | Total number of topplings |
| Duration | T | Number of sequential toppling waves |
| Area | a | Number of distinct sites that toppled |
| Linear extent | r | Maximum distance from initial site to any toppled site |

### Signature 1: Power-Law Event Distribution

**Diagnostic:** Fit the avalanche size distribution P(s) to a power law using maximum likelihood estimation (Clauset et al. 2009 method).

**Expected result:**
- P(s) ~ s^(-tau) with tau approximately 1.1-1.3 for 2D BTW
- Log-log plot shows linearity over at least 2 decades
- KS test does not reject power-law hypothesis
- Comparison with log-normal and exponential alternatives: power law preferred or comparable

**Acceptance criteria:**
- tau_MLE in [0.9, 1.5]
- KS p-value > 0.05
- Log-likelihood ratio favors power law over exponential

**Also measure:**
- Duration distribution P(T) ~ T^(-alpha)
- Area distribution P(a) ~ a^(-tau_a)
- Scaling relation: check (alpha - 1)/(tau - 1) against theoretical prediction

### Signature 2: Diverging Correlation Length

**Diagnostic:** Measure spatial correlations in the height field z(i,j) at steady state.

**Expected result:**
- Height-height correlation function G(r) decays as power law, not exponential
- Correlation length xi is comparable to system size L (diverging)
- Mutual information between distant sites remains non-negligible

**Method:**
- Compute G(r) = <z(0)z(r)> - <z>^2 averaged over all site pairs at distance r
- Fit to power-law decay vs exponential decay
- Compare across L = 64, 128, 256 — if xi scales with L, correlation length is diverging

**Acceptance criteria:**
- Power-law decay fits better than exponential decay (AIC or BIC)
- xi/L ratio approximately constant across system sizes

### Signature 3: Scale Invariance (1/f Noise)

**Diagnostic:** Compute the power spectral density of the avalanche size time series.

**Expected result:**
- S(f) ~ 1/f^beta with beta approximately 1.0
- Hurst exponent H > 0.5 (persistent, long-range correlations)
- DFA confirms constant scaling exponent across time windows

**Method:**
- Construct time series: s_1, s_2, ..., s_N (avalanche sizes in sequence)
- Compute PSD via FFT
- Fit beta from log-log slope
- Compute Hurst exponent via R/S analysis or DFA

**Acceptance criteria:**
- beta in [0.5, 1.5]
- H in [0.5, 1.0]
- DFA scaling exponent approximately constant across decades

### Signature 4: Fractal Structure

**Diagnostic:** Measure the fractal dimension of avalanche clusters.

**Expected result:**
- Avalanche spatial footprints have fractal dimension D_f < 2 (less than space-filling)
- Size-area scaling: s ~ a^gamma with gamma related to D_f
- Box-counting dimension of large avalanche footprints is non-integer

**Method:**
- For large avalanches (s > s_min), record the set of toppled sites
- Apply box-counting: count N(epsilon) boxes of side epsilon needed to cover the toppled region
- Fit N(epsilon) ~ epsilon^(-D_f)
- Check size-area scaling s ~ a^(D_s/D_f) where D_s is the dynamical exponent

**Acceptance criteria:**
- D_f in [1.5, 2.0) for 2D BTW
- Box-counting plot is linear in log-log over at least 1.5 decades

### Signature 5: Fat-Tailed Changes (Leptokurtosis)

**Diagnostic:** Compute year-over-year (step-over-step) changes in rolling activity measures and test for fat tails.

**Expected result:**
- First differences of rolling avalanche activity have excess kurtosis >> 0
- Distribution of step changes is leptokurtic (heavy tails, sharp peak)
- GPD fit to upper tail confirms power-law-like tail behavior

**Method:**
- Compute rolling mean avalanche size over windows of width W (e.g., W = 100, 1000)
- Take first differences of the rolling mean
- Compute excess kurtosis (K - 3)
- Fit Generalized Pareto Distribution to extreme values

**Acceptance criteria:**
- Excess kurtosis > 1.5
- GPD shape parameter xi > 0 (heavy tail)

### Complementary: Branching Ratio

**Diagnostic:** Estimate sigma from avalanche propagation.

**Expected result:**
- sigma approximately 1.0 at steady state

**Method:**
- During each avalanche, record the number of topplings at each generation (wave)
- sigma = mean(n_topplings at wave t+1 / n_topplings at wave t)
- Average over all avalanches with T > 1

**Acceptance criteria:**
- sigma in [0.95, 1.05]

### Complementary: Inter-Event Time Distribution

**Diagnostic:** Examine waiting times between avalanches above a size threshold.

**Expected result:**
- For threshold s > s_min, inter-event times follow power-law or stretched exponential
- No characteristic waiting time

**Method:**
- Choose several thresholds s_min (e.g., 10th, 50th, 90th percentile of s)
- Compute waiting times (number of grain drops between qualifying avalanches)
- Fit to power law, stretched exponential, and exponential
- Compare fits

**Acceptance criteria:**
- Power law or stretched exponential preferred over pure exponential for large-event thresholds

---

## Negative Controls

These verify that our diagnostics correctly *reject* non-SOC systems.

### Control 1: Random (Poisson) Events

Generate a synthetic event series with sizes drawn from an exponential distribution. All five signature tests should fail.

**Expected:** tau_MLE outside acceptance range or KS rejects; H near 0.5; kurtosis near 0; sigma meaningless.

### Control 2: Subcritical Sandpile

Run the BTW sandpile with strong dissipation (e.g., each toppling loses 1 grain to the void, not just at boundaries). The system should not self-organize to criticality.

**Expected:** Exponential or truncated distribution; short correlation length; sigma < 1.

### Control 3: Supercritical System

Modify the sandpile so that toppling distributes 5 grains (more than received). The system should run away.

**Expected:** Dominated by system-spanning events; sigma > 1; no stable power law.

---

## Finite-Size Scaling

Run at L = 64, 128, 256 and verify:

- tau is approximately constant across sizes (universal exponent)
- Maximum avalanche size scales as L^D where D is the avalanche dimension
- Cutoff in P(s) shifts rightward with increasing L
- Correlation length xi scales proportionally to L

This confirms that signatures are genuine SOC properties, not finite-size artifacts.

---

## Experimental Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| Avalanche catalog | Arrow file | Raw data: size, duration, area, extent per avalanche |
| Signature results | Named tuple / DataFrame | Per-signature diagnostic values and pass/fail |
| Diagnostic plots | PNG | Log-log distributions, PSD, DFA, box-counting, correlation function |
| Negative control results | DataFrame | Same diagnostics on non-SOC controls |
| Finite-size scaling | DataFrame + plots | Exponents and cutoffs across L values |

---

## Implementation Plan

1. **Build the sandpile simulator** — `work/experiments/validation/sandpile.jl`
   - `btw_sandpile(L, N_transient, N_record; seed)` → avalanche catalog
   - Record s, T, a, r, and per-wave toppling counts for each avalanche

2. **Build diagnostic functions** — `work/experiments/validation/diagnostics.jl`
   - These are the functions that will later be applied to governance data
   - `fit_power_law(data)` → (tau, xmin, ks_pvalue, comparison_results)
   - `correlation_function(height_field)` → (G_r, fit_type, xi)
   - `spectral_analysis(time_series)` → (beta, hurst, dfa_exponent)
   - `fractal_dimension(footprints)` → (D_f, box_counting_data)
   - `fat_tail_test(changes)` → (kurtosis, gpd_shape, is_fat_tailed)
   - `branching_ratio(wave_counts)` → sigma
   - `inter_event_times(sizes, thresholds)` → (fits, best_model)

3. **Run experiments** — `work/experiments/validation/01_run_sandpile.jl` or notebook
   - Execute sandpile at L = 64, 128, 256
   - Run all diagnostics
   - Run negative controls
   - Finite-size scaling analysis
   - Generate plots and summary table

4. **Verify against known results** — Compare our exponents to published BTW values:
   - tau ≈ 1.1-1.3 (2D BTW)
   - alpha ≈ 1.3-1.5 (duration exponent)
   - D_f ≈ 1.7 (fractal dimension)
   - beta ≈ 1.0 (1/f noise)
   - sigma ≈ 1.0 (branching ratio)

---

## Success Criteria

The experiment succeeds if:

1. All five signatures are detected in the BTW sandpile with values consistent with published literature
2. All five signatures are correctly rejected in the negative controls
3. Finite-size scaling confirms universal exponents
4. The diagnostic functions are robust and reusable for subsequent experiments

The experiment fails if any signature gives a false negative on the BTW sandpile or a false positive on the negative controls. Failure indicates a bug in the diagnostic function, not in SOC theory.

---

## Dependencies

- Julia packages: `Distributions.jl`, `StatsBase.jl`, `FFTW.jl`, `LsqFit.jl`, `Arrow.jl`, `DataFrames.jl`
- No external data required — entirely synthetic
- No GPU required — BTW sandpile is sequential by construction

## Next Experiment

**Experiment 02: Synthetic Percolation** — validate percolation threshold detection on random lattices, establishing the p_c measurement tools needed for Experiment 03 (joined sandpile-percolation system).
