# Experiment 01: Synthetic Sandpile — SOC Signature Validation

## Purpose

Validate that our diagnostic functions correctly detect empirical signatures of SOC in systems where criticality is guaranteed by construction. We run two canonical SOC models — the deterministic BTW sandpile and the stochastic Manna model — to establish ground truth for all subsequent experiments.

This experiment produces validated diagnostic tools for Experiment 02 (percolation) and all subsequent experiments.

---

## Why Two Models

The **BTW sandpile** (Bak, Tang, Wiesenfeld 1987) is the original and most widely cited SOC model, but it has known complications: **multiscaling** in the avalanche size distribution (Tebaldi, De Menech, Stella 1999) and anomalous spectral properties. These are artifacts of its deterministic toppling rule, not general properties of SOC.

The **Manna model** (Manna 1991) uses stochastic toppling and exhibits clean simple finite-size scaling. It belongs to the conserved directed percolation (C-DP) universality class, which encompasses many other stochastic sandpile models (Dickman et al. 2000). Its stochastic dynamics are more representative of real-world systems where noise is always present.

Running both serves two purposes:
1. If our diagnostics work on both, they are robust across universality classes
2. Differences between the two reveal which diagnostic results are universal SOC properties and which are model-specific

---

## Model A: BTW Sandpile

### Definition

A deterministic cellular automaton on an L x L square lattice with open boundary conditions (Bak, Tang, Wiesenfeld 1987; Dhar 1999).

**State:** Each site (i, j) holds an integer height z(i,j) >= 0.

**Driving:** At each timestep, one randomly chosen site receives a grain:
```
z(i,j) → z(i,j) + 1
```

**Toppling rule:** If z(i,j) >= z_c (critical threshold, z_c = 4 for 2D square lattice), the site topples:
```
z(i,j)  → z(i,j) - 4
z(i±1,j) → z(i±1,j) + 1
z(i,j±1) → z(i,j±1) + 1
```

**Boundary dissipation:** Sites at the lattice edge lose grains that would go off-grid. This is the only energy exit.

**Abelian property:** The final stable configuration and total toppling counts are independent of toppling order (Dhar 1990). This means sequential or parallel toppling give the same avalanche statistics. Parallel toppling (all unstable sites topple simultaneously) defines the natural "wave" structure for duration measurement and is computationally faster.

**Avalanche:** A single grain addition may trigger zero, one, or many topplings. The total number of topplings before the system re-stabilizes is the avalanche size s. The number of parallel toppling waves is the avalanche duration T.

### Known Complications

**Multiscaling.** The BTW avalanche size distribution does not obey simple finite-size scaling. Tebaldi, De Menech, and Stella (1999) showed that moment ratios require a full nonlinear multifractal spectrum rather than collapsing onto a single scaling function. The avalanche *area* distribution does obey simple scaling; the *toppling number* (size) distribution does not. This means a single exponent tau_s is an approximation, not an exact characterization. The wave decomposition approach (Ktitarev et al. 2000) provides cleaner scaling for individual toppling waves than for whole avalanches.

**Spectral properties.** The BTW model does **not** produce clean 1/f noise despite the original 1987 claim. Chhimpa et al. (2025) found the high-frequency spectral exponent is approximately 1.56, with three distinct frequency regimes (flat at low frequency, hump at intermediate, 1/f^alpha at high frequency). The slow-driving limit produces approximately 1/f^2 behavior, not 1/f.

**Height correlations.** Height-height correlations in 2D BTW involve logarithmic corrections connected to logarithmic conformal field theory (Piroux and Ruelle 2005; Jeng 2005).

**Universality class.** The BTW model is **not** in the directed percolation universality class, and is **not** in the C-DP (Manna) universality class. It appears to occupy its own universality class characterized by multiscaling — a consequence of its deterministic toppling rule preserving autocorrelations between wave series.

## Model B: Manna Sandpile

### Definition

A stochastic cellular automaton on an L x L square lattice with open boundary conditions (Manna 1991).

**State:** Each site (i, j) holds an integer height z(i,j) >= 0.

**Driving:** Same as BTW — one grain to a random site per timestep.

**Toppling rule:** If z(i,j) >= z_c (z_c = 2 for the standard Manna model), the site topples:
```
z(i,j) → z(i,j) - 2
Two grains are each sent to a randomly chosen neighbor (independently, with replacement)
```

**Key difference:** The stochastic redistribution breaks the deterministic correlations that cause multiscaling in BTW. The Manna model belongs to the conserved directed percolation (C-DP) universality class and exhibits clean simple finite-size scaling.

**Boundary dissipation:** Same as BTW — grains sent off-grid are lost.

---

## Parameters

| Parameter | BTW | Manna | Notes |
|-----------|-----|-------|-------|
| L | 64, 128, 256 | 64, 128, 256 | Run all three for finite-size scaling |
| z_c | 4 | 2 | Fixed by model definition |
| N_transient | L^2 * 10 | L^2 * 10 | Must exceed several × L^2 for steady state. For L=256: ~650,000 |
| N_record | 10^6 | 10^6 | Published studies use 10^5 to 10^7 |

### Transient Sizing

The lattice has L^2 sites, each needing to reach approximately the critical density (mean height ~17/8 ≈ 2.125 for BTW). At minimum, ~L^2 × z_c grains are needed just to fill the lattice, plus additional grains for self-organization. Published studies use L^2 to 10 × L^2 grains as transient (Pruessner 2012). Setting N_transient = 10 × L^2 provides margin.

### Sample Size for Power-Law Fitting

The Clauset-Shalizi-Newman (2009) methodology requires at minimum ~10,000 events for a rough estimate, and 50,000-100,000+ for robust fitting with goodness-of-fit tests. For the BTW model's multiscaling, even more data is needed to distinguish multiscaling from simple scaling. N_record = 10^6 provides comfortable margin for all lattice sizes.

---

## What We Measure

### Per Avalanche

| Quantity | Symbol | Definition |
|----------|--------|------------|
| Size | s | Total number of topplings |
| Duration | T | Number of parallel toppling waves |
| Area | a | Number of distinct sites that toppled |
| Linear extent | r | Maximum distance from initial site to any toppled site |
| Wave profile | {n_1, n_2, ..., n_T} | Number of topplings per wave (for branching ratio) |

### Signature 1: Power-Law Event Distribution

**Diagnostic:** Fit the avalanche size distribution P(s) to a power law using maximum likelihood estimation (Clauset, Shalizi, Newman 2009).

**Expected results:**

| Quantity | BTW | Manna | Source |
|----------|-----|-------|--------|
| tau_s (size exponent) | ~1.2 (effective; multiscaling) | ~1.27 | Grassberger 2002; Dickman et al. 2002 |
| tau_t (duration exponent) | ~1.4-1.5 | ~1.50 | Ktitarev et al. 2000; Dickman et al. 2002 |
| tau_a (area exponent) | ~1.37 | ~1.34 | De Menech et al. 1998 |

**Acceptance criteria:**
- KS test does not reject power-law hypothesis (p-value > 0.05)
- Log-likelihood ratio favors power law over exponential
- tau_s within 20% of published values
- For BTW: check for multiscaling by computing moment ratios at different L values. If moments don't collapse, multiscaling is confirmed

**Also measure:**
- Scaling relation: check (tau_t - 1)/(tau_s - 1) against theoretical prediction
- For Manna: this should be satisfied. For BTW: it should fail (diagnostic of multiscaling)

### Signature 2: Diverging Correlation Length

**Diagnostic:** Measure spatial correlations in the height field z(i,j) at steady state.

**Expected result:**
- Height-height correlation function G(r) decays as power law, not exponential
- Correlation length xi is comparable to system size L (diverging)
- Mutual information between distant sites remains non-negligible
- BTW: expect logarithmic corrections to the power-law decay (Piroux and Ruelle 2005)

**Method:**
- Compute G(r) = <z(0)z(r)> - <z>^2 averaged over all site pairs at distance r
- Fit to power-law decay vs exponential decay
- Compare across L = 64, 128, 256 — if xi scales with L, correlation length is diverging

**Acceptance criteria:**
- Power-law decay fits better than exponential decay (AIC or BIC)
- xi/L ratio approximately constant across system sizes

### Signature 3: Scale Invariance (Spectral Analysis)

**Diagnostic:** Compute the power spectral density of the avalanche size time series.

**Expected result:**

| Quantity | BTW | Manna | Source |
|----------|-----|-------|--------|
| PSD exponent (beta) | ~1.56 (high-freq regime); three distinct regimes | ~1.0 (cleaner 1/f) | Chhimpa et al. 2025; Christensen & Moloney 2005 |
| Hurst exponent (H) | > 0.5 | > 0.5 | — |

**Note:** BTW does **not** produce clean 1/f noise. The PSD has three regimes: flat at low frequency, hump at intermediate, and ~1/f^1.56 at high frequency (Chhimpa et al. 2025). This is a known property of the model, not a diagnostic failure. The Manna model should produce cleaner 1/f behavior.

**Method:**
- Construct time series: s_1, s_2, ..., s_N (avalanche sizes in sequence)
- Compute PSD via FFT
- Fit beta from log-log slope (check for regime breaks)
- Compute Hurst exponent via R/S analysis or DFA
- DFA should confirm constant scaling exponent across time windows

**Acceptance criteria:**
- BTW: PSD shows structured non-white-noise behavior; beta > 1 in high-frequency regime
- Manna: beta in [0.7, 1.5]; closer to 1/f
- Both: H > 0.5 (persistent, long-range correlations)
- DFA scaling exponent approximately constant across decades

### Signature 4: Fractal Structure

**Diagnostic:** Measure the spatial structure of avalanche clusters.

**Expected result:**

| Quantity | BTW | Manna | Source |
|----------|-----|-------|--------|
| Cluster fractal dimension | ~2 (compact, space-filling) | ~1.7-1.8 | Dhar 1999; Christensen & Moloney 2005 |
| Frontier fractal dimension | ~1.25 | ~1.3 | Moghimi-Araghi et al. 2009 |
| Size-area scaling (s ~ a^gamma) | gamma > 1 (multiple topplings per site) | gamma ≈ 1 | — |

**Important correction:** BTW avalanche clusters are approximately **compact** (space-filling, D_f ≈ 2) in 2D. The *frontier* (boundary) of the cluster is fractal with D_f ≈ 1.25, connected to conformal invariance (Moghimi-Araghi et al. 2009). The value D_f ≈ 1.7 that appears in some SOC references is from 2D percolation clusters, not BTW.

**Method:**
- For large avalanches (s > 90th percentile), record the set of toppled sites
- Measure cluster area vs. linear extent: a ~ r^D_cluster
- Extract the frontier (boundary sites) and apply box-counting: N(epsilon) ~ epsilon^(-D_frontier)
- Measure size-area scaling: s vs. a (gamma > 1 for BTW because sites can topple multiple times)

**Acceptance criteria:**
- Box-counting of frontier is linear in log-log over at least 1.5 decades
- D_frontier < 2 (frontier is fractal even if cluster is compact)
- Size-area scaling exponent gamma is consistent across L values

### Signature 5: Fat-Tailed Changes (Leptokurtosis)

**Diagnostic:** Compute step-over-step changes in rolling activity measures and test for fat tails.

**Expected result:**
- First differences of rolling avalanche activity have excess kurtosis >> 0
- Distribution of step changes is leptokurtic (heavy tails, sharp peak)
- GPD fit to upper tail confirms heavy-tail behavior

**Method:**
- Compute rolling mean avalanche size over windows of width W (e.g., W = 100, 1000)
- Take first differences of the rolling mean
- Compute excess kurtosis (K - 3)
- Fit Generalized Pareto Distribution to extreme values

**Acceptance criteria:**
- Excess kurtosis > 1.5
- GPD shape parameter xi > 0 (heavy tail)

### Complementary: Branching Ratio

**Diagnostic:** Estimate the branching ratio from avalanche wave structure.

**Expected result:**
- Broad regime where b(x) ≈ 1 when conditioned on activity level (Michiels van Kessenich et al. 2010)
- The branching ratio is **activity-dependent**, not a single global value. A naive global average can miss the critical structure

**Method:**
- During each avalanche, record the number of topplings at each wave: {n_1, n_2, ..., n_T}
- Compute wave-to-wave ratio: b_t = n_{t+1} / n_t for each wave transition
- Bin by activity level (n_t) and compute b(x) = mean ratio at activity level x
- Also compute naive global average for comparison

**Acceptance criteria:**
- Existence of a broad regime where b(x) ≈ 1 (within ±0.1)
- This regime spans at least one decade of activity levels
- Introducing bulk dissipation (Control 2) should destroy this broad regime

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

Generate a synthetic event series with sizes drawn from an exponential distribution. All signature tests should fail.

**Expected:** tau_MLE outside acceptance range or KS rejects; H near 0.5; kurtosis near 0; b(x) shows no broad critical regime.

### Control 2: Subcritical Sandpile

Run the BTW sandpile with strong bulk dissipation (e.g., each toppling loses 1 grain to the void in addition to boundary losses). The system should not self-organize to criticality.

**Expected:** Exponential or truncated distribution; short correlation length; b(x) < 1 everywhere; no broad critical regime. Compare to Control 1 — the subcritical sandpile should look qualitatively different from random (it has spatial structure) but should fail the same signature tests.

### Control 3: Supercritical System

Modify the sandpile so that toppling distributes 5 grains to neighbors (more than the 4 removed from the toppling site). The system gains energy at each toppling.

**Expected:** Dominated by system-spanning events; b(x) > 1; no stable power law. Note: this system may require careful handling to prevent unbounded growth.

---

## Finite-Size Scaling

Run at L = 64, 128, 256 and verify:

- Exponents are approximately constant across sizes (universality)
- Maximum avalanche size scales as L^(D*z) where D is the spatial dimension and z is the dynamic exponent. For BTW: s_max ~ L^3 approximately (Christensen & Moloney 2005)
- Cutoff in P(s) shifts rightward with increasing L
- Correlation length xi scales proportionally to L
- **For Manna:** Attempt data collapse using standard finite-size scaling. This should succeed
- **For BTW:** Attempt same data collapse. This should fail for the size distribution (confirming multiscaling) but succeed for the area distribution

This comparison between models is itself a diagnostic: it distinguishes universal SOC properties from BTW-specific artifacts.

---

## BTW vs. Manna Comparison

A key output of this experiment: which diagnostic results are universal and which are model-specific?

| Diagnostic | Expected: Universal? | Notes |
|-----------|---------------------|-------|
| Power-law P(s) | Yes (both models) | But BTW has multiscaling; Manna has clean scaling |
| Diverging correlation length | Yes | BTW has logarithmic corrections |
| PSD / 1/f noise | **No** | BTW: ~1/f^1.56, multi-regime. Manna: closer to 1/f |
| Fractal cluster structure | Partially | BTW clusters are compact; Manna may differ |
| Fat-tailed changes | Yes | Both should show leptokurtosis |
| Branching ratio | Yes | Both should show broad b(x) ≈ 1 regime |
| Finite-size scaling collapse | **No** | BTW fails (multiscaling); Manna succeeds |

Diagnostics that agree across both models are robust for application to governance data. Diagnostics that disagree indicate sensitivity to the universality class — interpret with caution in empirical applications.

---

## Experimental Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| Avalanche catalogs (BTW + Manna) | Arrow files | Raw data: size, duration, area, extent, wave profile per avalanche |
| Signature results | DataFrame | Per-signature diagnostic values and pass/fail, both models |
| Model comparison | Table | Which diagnostics agree/disagree between BTW and Manna |
| Diagnostic plots | PNG | Log-log distributions, PSD, DFA, box-counting, correlation function |
| Negative control results | DataFrame | Same diagnostics on non-SOC controls |
| Finite-size scaling | DataFrame + plots | Exponents, cutoffs, data collapse attempts across L values |
| Multiscaling test | DataFrame + plots | Moment ratios for BTW showing multiscaling |

---

## Implementation Plan

1. **Build sandpile simulators** — `work/experiments/validation/sandpile.jl`
   - `btw_sandpile(L, N_transient, N_record; seed)` → avalanche catalog
   - `manna_sandpile(L, N_transient, N_record; seed)` → avalanche catalog
   - Both record s, T, a, r, and per-wave toppling counts per avalanche
   - Parallel toppling for both (natural wave structure; Abelian property guarantees same final state for BTW)

2. **Build diagnostic functions** — `work/experiments/validation/diagnostics.jl`
   - These are the functions that will later be applied to governance data
   - `fit_power_law(data)` → (tau, xmin, ks_pvalue, comparison_results)
   - `correlation_function(height_field)` → (G_r, fit_type, xi)
   - `spectral_analysis(time_series)` → (beta, hurst, dfa_exponent, regime_breaks)
   - `fractal_dimension(footprints)` → (D_cluster, D_frontier, box_counting_data)
   - `fat_tail_test(changes)` → (kurtosis, gpd_shape, is_fat_tailed)
   - `branching_ratio(wave_counts)` → (b_of_x, global_mean, regime_width)
   - `inter_event_times(sizes, thresholds)` → (fits, best_model)
   - `multiscaling_test(catalogs_by_L)` → (moment_ratios, is_multiscaling)

3. **Run experiments** — `work/experiments/validation/01_run_sandpile.jl` or notebook
   - Execute BTW and Manna at L = 64, 128, 256
   - Run all diagnostics on both
   - Run negative controls
   - Finite-size scaling and data collapse
   - BTW vs. Manna comparison
   - Generate plots and summary table

4. **Verify against published values:**

   **BTW (2D square lattice):**
   | Quantity | Published Value | Source |
   |----------|----------------|--------|
   | tau_s | ~1.2 (effective; multiscaling) | Grassberger 2002 |
   | tau_t | ~1.4-1.5 | Ktitarev et al. 2000 |
   | tau_a | ~1.37 | De Menech et al. 1998 |
   | D_cluster | ~2 (compact) | Dhar 1999 |
   | D_frontier | ~1.25 | Moghimi-Araghi et al. 2009 |
   | PSD beta | ~1.56 (high-freq) | Chhimpa et al. 2025 |
   | Mean height | 17/8 = 2.125 (exact) | Dhar 1999 |
   | Branching ratio | b(x) ≈ 1 in broad regime | Michiels van Kessenich et al. 2010 |

   **Manna (2D square lattice):**
   | Quantity | Published Value | Source |
   |----------|----------------|--------|
   | tau_s | ~1.27 | Dickman et al. 2002 |
   | tau_t | ~1.50 | Dickman et al. 2002 |
   | Universality class | C-DP | Dickman et al. 2002 |

---

## Success Criteria

The experiment succeeds if:

1. Power-law signatures are detected in both BTW and Manna sandpiles with values consistent with published literature
2. Known BTW complications (multiscaling, non-1/f spectrum) are reproduced — this validates that our diagnostics are sensitive enough to detect these subtleties
3. Manna model shows clean finite-size scaling where BTW does not
4. All signatures are correctly rejected in the negative controls
5. The diagnostic functions are robust and reusable for subsequent experiments
6. The BTW-Manna comparison clearly identifies which diagnostics are universal vs. model-specific

The experiment fails if:
- Signatures give false negatives on known SOC systems → bug in diagnostic function
- Signatures give false positives on negative controls → diagnostic is not discriminating
- BTW and Manna produce identical results → our diagnostics lack sensitivity to universality class differences

---

## References

### Primary Sources

- **Bak, Tang, Wiesenfeld (1987).** "Self-organized criticality: An explanation of 1/f noise." Physical Review Letters, 59, 381. *Foundational BTW paper.*
- **Manna (1991).** "Two-state model of self-organized criticality." Journal of Physics A, 24, L363. *Stochastic sandpile definition.*
- **Dhar (1990).** "Self-organized critical state of sandpile automaton models." Physical Review Letters, 64, 1613. *Abelian property proof.*
- **Dhar (1999).** "The Abelian sandpile and related models." Physica A, 263, 4-25. arXiv:cond-mat/9808047. *Exact results for BTW: mean height, recurrent configurations.*

### Critical Exponents and Scaling

- **Grassberger (2002).** Unpublished but widely cited numerical estimates for BTW exponents. tau_s ~ 1.2.
- **Tebaldi, De Menech, Stella (1999).** "Multifractal scaling in the Bak-Tang-Wiesenfeld sandpile and edge events." Physical Review Letters, 83, 3952. *Proof of multiscaling in BTW.*
- **De Menech, Stella, Tebaldi (1998).** Cluster analysis giving tau_a ~ 1.37.
- **Ktitarev, Lübeck, Grassberger, Priezzhev (2000).** "Scaling of waves in the Bak-Tang-Wiesenfeld sandpile model." Physical Review E, 61, 81. arXiv:cond-mat/9907157. *Wave decomposition; cleaner scaling for individual waves.*
- **Dickman, Muñoz, Vespignani, Zapperi (2000).** "Paths to self-organized criticality." Brazilian Journal of Physics, 30, 27. *C-DP universality class.*
- **Dickman, Campelo, Vespignani (2002).** Manna model exponents and C-DP class membership.
- **arXiv:2501.17376 (2025).** SOC as continuous phase transition. kappa ~ 1.21 for BTW size exponent.

### Spectral and Fractal Properties

- **Chhimpa et al. (2025).** "Avalanche activity noises in sandpile models." arXiv:2507.21484. *BTW spectral exponent ~1.56; three frequency regimes.*
- **Moghimi-Araghi et al. (2009).** Physical Review E, 79. *Conformal invariance of BTW avalanche frontiers; D_frontier ~ 1.25.*
- **Piroux and Ruelle (2005).** Logarithmic corrections in BTW height correlations.
- **Jeng (2005).** Height correlations and logarithmic conformal field theory.

### Branching Ratio

- **Michiels van Kessenich et al. (2010).** "Activity-dependent branching ratios in stocks, solar x-ray flux, and the Bak-Tang-Wiesenfeld sandpile model." Physical Review E, 81, 016109. arXiv:0910.2447. *Activity-dependent branching ratio; broad b(x) ≈ 1 regime.*

### Methodology

- **Clauset, Shalizi, Newman (2009).** "Power-law distributions in empirical data." SIAM Review, 51, 661. arXiv:0706.1062. *MLE + KS methodology for power-law fitting.*
- **Stumpf and Porter (2012).** "Critical truths about power laws." Science, 335, 665. *Common errors in power-law claims.*

### Textbooks

- **Christensen and Moloney (2005).** *Complexity and Criticality.* Imperial College Press. *Most complete mathematical SOC textbook.*
- **Pruessner (2012).** *Self-Organised Criticality: Theory, Models and Characterisation.* Cambridge University Press. *Comprehensive reference for SOC models and measurement.*

---

## Dependencies

- Julia packages: `Distributions.jl`, `StatsBase.jl`, `FFTW.jl`, `LsqFit.jl`, `Arrow.jl`, `DataFrames.jl`
- No external data required — entirely synthetic
- No GPU required — both models are sequential by construction

## Next Experiment

**Experiment 02: Synthetic Percolation** — validate percolation threshold detection on random lattices, establishing the p_c measurement tools needed for Experiment 03 (joined sandpile-percolation system).
