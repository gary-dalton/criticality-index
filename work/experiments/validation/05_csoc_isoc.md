# Experiment 05: CSOC and ISOC — Suppression, Amplification, and Distinguishability

## Purpose

Apply suppression (Capacitive SOC) and amplification (Inductive SOC) to the validated sandpile system. Test three claims:

1. CSOC produces the distorted signatures predicted by the framework (truncated small events, quasi-periodic large events, spectral knee, etc.)
2. ISOC produces its predicted signatures (inflated large events, continuous activity, steepened spectrum, etc.)
3. CSOC and ISOC are distinguishable from each other, from natural SOC, and from genuine sub/super-criticality

This is the experiment that determines whether the CSOC/ISOC framework is empirically testable.

---

## The Models

All models use the BTW sandpile on a fully connected lattice (p = 1, L = 128) as the SOC substrate, validated in Experiment 01. Each model modifies one aspect of the dynamics.

### Model A: Natural SOC (Baseline)

Standard BTW sandpile. No modifications. This is the control — all other models are compared against it.

### Model B: Capacitive SOC (Suppression)

Small avalanches are artificially suppressed. The suppression mechanism prevents energy release below a threshold, forcing deficit accumulation.

**Mechanism — Toppling Suppression:**

After a grain is added and topplings begin, if the avalanche size has not yet reached s_suppress, all topplings are reversed (grains returned to pre-topple configuration). The grain that was added remains, increasing local height.

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| s_suppress | 5, 10, 25, 50, 100 | Minimum avalanche size to "allow." Below this, the event is suppressed |

**What this does:**
- Small stress releases are blocked
- Energy accumulates in sites that would have toppled
- Heights grow beyond their natural SOC values
- Eventually a trigger produces an avalanche above s_suppress — this is "allowed" and cascades through a pre-loaded system

**Alternative mechanism — Threshold Elevation:**

Raise the toppling threshold z_c locally for a fraction of sites, making them harder to topple.

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| z_c_elevated | 5, 6, 8, 10 | Elevated threshold (normal = 4) |
| fraction_elevated | 0.1, 0.25, 0.5, 0.75 | Fraction of sites with elevated threshold |

**Run both mechanisms** and compare. If CSOC signatures are mechanism-agnostic (as the framework claims), both should produce the same signature profile.

### Model C: Inductive SOC (Amplification)

Cascading is artificially amplified. The amplification mechanism adds energy during propagation, sustaining cascades beyond natural boundaries.

**Mechanism — Propagation Boost:**

When a site topples, it distributes more grains than it received. Instead of losing 4 and giving 1 to each neighbor, it loses 4 but gives (1 + boost) to each neighbor (or a subset).

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| boost | 0.25, 0.5, 1.0, 2.0 | Extra grains per neighbor per toppling |
| boost_probability | 0.1, 0.25, 0.5, 1.0 | Fraction of topplings that receive the boost |

**Note:** boost must be handled carefully to maintain energy conservation accounting. The extra grains are "injected" — they represent external excitation entering the system during propagation, not spontaneous energy creation.

**Alternative mechanism — Threshold Lowering:**

Lower the toppling threshold z_c for sites neighboring an active toppling, making cascade propagation easier.

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| z_c_excited | 3, 2, 1 | Lowered threshold for neighbors of toppling sites |
| excitation_duration | 1, 3, 5 | How many toppling waves the lowered threshold persists |

**Run both mechanisms** and compare. Same logic as CSOC: if ISOC is mechanism-agnostic, both should produce the same profile.

### Model D: Genuine Subcritical (Comparison)

Increase dissipation so the system is genuinely below criticality. Each toppling loses d grains to the void in addition to boundary losses.

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| d_bulk | 0.5, 1.0, 2.0 | Grains lost per toppling (beyond boundary) |

### Model E: Genuine Supercritical (Comparison)

Each toppling distributes more than z_c grains total (grains created, not just redistributed). The system is genuinely above criticality.

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| grains_distributed | 5, 6, 8 | Total grains sent to neighbors (normal = 4) |

---

## What We Measure

For every model and parameter setting, compute the full diagnostic battery from Experiment 01. The analysis is organized around the predictions from the CSOC and ISOC framework documents.

### 5a. Distribution Shape

**Method:** Fit P(s) across the full range. Compare distribution shape across all models.

| Model | Predicted P(s) Shape |
|-------|---------------------|
| Natural SOC | Clean power law |
| CSOC | Truncated at low end (below s_suppress), excess at high end |
| ISOC | Inflated at high end, possible elevation of small events |
| Subcritical | Exponential decay |
| Supercritical | Dominated by system-spanning events |

**Key plot:** Overlay P(s) for all five models on a single log-log plot. The CSOC and ISOC distortions should be visually distinct from each other and from the genuine sub/super-critical distributions.

**Quantitative test:** Fit a two-component model (power law + bump/cutoff) to CSOC and ISOC distributions. The characteristic scale at the suppression/amplification threshold should be identifiable.

### 5b. Temporal Structure

**Method:** Compute inter-event intervals for large avalanches (s > s_threshold) and plot the autocorrelation function.

| Model | Predicted Temporal Structure |
|-------|------|
| Natural SOC | No characteristic timescale, scale-free inter-event times |
| CSOC | Quasi-periodic: long quiet accumulation → burst → quiet. Second timescale visible |
| ISOC | Continuous activity, no accumulation phase, short depletion-recovery timescale |
| Subcritical | Long, exponential inter-event times |
| Supercritical | Continuous, no structure |

**Key plot:** Autocorrelation of large-event occurrence. CSOC should show periodic peaks. ISOC should show rapid decay.

**Quantitative test:** Fit inter-event time distribution to power law, exponential, and stretched exponential. CSOC should show excess probability at a characteristic interval.

### 5c. Spectral Analysis

**Method:** Compute PSD of the avalanche size time series.

| Model | Predicted Spectrum |
|-------|-------------------|
| Natural SOC | 1/f with beta ≈ 1 |
| CSOC | Knee at high frequency (suppression scale), flattening below |
| ISOC | Steepened, excess low-frequency power |
| Subcritical | White noise (beta ≈ 0) |
| Supercritical | Red noise (beta > 2) |

**Key plot:** PSD for all five models overlaid. The spectral distortions should be in opposite directions for CSOC vs. ISOC.

### 5d. Branching Ratio Dynamics

**Method:** Compute sigma in sliding windows over the avalanche sequence.

| Model | Predicted sigma(t) |
|-------|-------------------|
| Natural SOC | Stationary, sigma ≈ 1 |
| CSOC | Non-stationary: < 1 during accumulation, spikes > 1 during release |
| ISOC | Persistently > 1, with transient dips after large events |
| Subcritical | Stationary, sigma < 1 |
| Supercritical | Stationary, sigma > 1 |

**Key plot:** sigma(t) for CSOC and ISOC overlaid. The non-stationarity pattern should be distinct.

**Quantitative test:** Stationarity tests (ADF, KPSS) on sigma(t). Natural SOC and genuine sub/supercritical should be stationary. CSOC should be non-stationary.

### 5e. Exponent Consistency

**Method:** Extract tau (size), alpha (duration), and check the scaling relation (alpha-1)/(tau-1).

| Model | Predicted Exponent Consistency |
|-------|-------------------------------|
| Natural SOC | Scaling relation satisfied |
| CSOC | Scaling relation violated |
| ISOC | Scaling relation violated |
| Subcritical | Exponents undefined (no power law) |
| Supercritical | Exponents undefined |

**Key test:** The direction of violation differs between CSOC and ISOC. CSOC truncates small events → tau appears steeper. ISOC inflates large events → tau appears shallower.

### 5f. Avalanche Shape Collapse

**Method:** Extract temporal profiles of avalanches at different sizes. Rescale and test for collapse.

| Model | Predicted Shape Collapse |
|-------|------------------------|
| Natural SOC | Collapses onto universal function |
| CSOC | Fails — large events have deficit-driven profiles |
| ISOC | Fails — large events have excitation-sustained profiles |

**Key plot:** Shape collapse attempts for all models. The failure modes should differ visually between CSOC and ISOC.

### 5g. History Dependence

**Method:** Condition future event statistics on recent past. After a large event (s > 90th percentile), how do the next N events differ from the unconditional distribution?

| Model | Predicted Post-Large-Event Behavior |
|-------|-------------------------------------|
| Natural SOC | No systematic change (memoryless at the event level) |
| CSOC | Deep quiescence — reduced activity, accumulation resumes |
| ISOC | Transient reduction then rapid recovery — depletion dip |
| Subcritical | No change (events independent) |
| Supercritical | No change (continuously active) |

**Key test:** This is identified in the ISOC document as the "clearest behavioral signature distinguishing Inductive SOC from true supercriticality."

### 5h. Suppression/Amplification Removal Test

**Method:** Run CSOC or ISOC for a long period, then remove the suppression/amplification mechanism. Observe recovery dynamics.

**CSOC removal prediction:** System returns to natural SOC signatures. Deficit discharges through a burst of small events. Recovery timescale depends on accumulated deficit.

**ISOC removal prediction:** System relaxes toward natural SOC. Event sizes decrease, sigma → 1, PSD returns to 1/f. Recovery timescale depends on depletion depth.

**Neither sub/supercritical should show this recovery** — their parameters define their state intrinsically. Removing a nonexistent intervention changes nothing.

---

## Distinguishability Matrix

The core deliverable: can an observer who sees only the signature data determine which model generated it?

| Diagnostic | SOC vs CSOC | SOC vs ISOC | CSOC vs ISOC | CSOC vs Sub | ISOC vs Super |
|-----------|-------------|-------------|--------------|-------------|---------------|
| P(s) shape | Truncation at low end | Inflation at high end | Opposite distortions | Excess large events in CSOC | History dependence in ISOC |
| Temporal structure | Quasi-periodicity appears | Continuous, no accumulation | Slow cycle vs. fast recovery | Quasi-periodicity vs. none | Post-event dip vs. none |
| PSD | Knee at high freq | Excess at low freq | Opposite spectral distortions | Periodic peak vs. flat | Steepened vs. red noise |
| sigma(t) | Non-stationary | Persistently elevated | Oscillating vs. elevated | Non-stationary vs. constant | Transient dips vs. constant |
| Exponents | Steeper tau | Shallower tau | Opposite direction | Both violate, but CSOC has excess large events | Both violate, but ISOC has depletion signature |
| Shape collapse | Fails (deficit-driven) | Fails (excitation-sustained) | Different failure modes | Different failure modes | Different failure modes |
| History dependence | Deep quiescence | Depletion dip | Duration and depth of post-event effect | CSOC has it, sub doesn't | ISOC has it, super doesn't |
| Intervention removal | Returns to SOC | Returns to SOC | Both return | CSOC returns, sub doesn't | ISOC returns, super doesn't |

---

## Mechanism Agnosticism Test

A critical claim of the CSOC/ISOC framework: signatures depend on the *effect* (suppression/amplification), not the *mechanism*.

**Test:** For each of CSOC and ISOC, compare the two implementation mechanisms (toppling suppression vs. threshold elevation; propagation boost vs. threshold lowering). If the framework is correct, both mechanisms should produce statistically indistinguishable signature profiles when calibrated to the same effective suppression/amplification intensity.

**Method:** Match mechanisms by equating their effect on total avalanche count or mean avalanche size, then compare all signature diagnostics via statistical tests (KS for distributions, correlation for time series).

**Failure:** If different mechanisms produce qualitatively different signatures at matched intensity, the framework's mechanism-agnostic claim fails and signatures are mechanism-dependent.

---

## Experimental Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| Full diagnostic battery | DataFrame | All diagnostics for all models and parameters |
| Distribution overlays | Plots | P(s) for all five models |
| Temporal structure | Plots | Autocorrelation and inter-event distributions |
| PSD comparison | Plots | All models overlaid |
| Sigma dynamics | Plots | sigma(t) for CSOC, ISOC, and controls |
| Shape collapse attempts | Plots | Success/failure for each model |
| Distinguishability matrix | Table | Which pairs are distinguishable and by which diagnostics |
| Mechanism agnosticism test | Table | Within-CSOC and within-ISOC mechanism comparison |
| Recovery dynamics | Plots | Post-removal recovery trajectories |

---

## Implementation Plan

1. **Build modified sandpiles** — `work/experiments/validation/modified_sandpile.jl`
   - `btw_csoc_suppress(L, s_suppress; ...)` — toppling suppression
   - `btw_csoc_threshold(L, z_c_elevated, fraction; ...)` — threshold elevation
   - `btw_isoc_boost(L, boost, boost_prob; ...)` — propagation boost
   - `btw_isoc_excite(L, z_c_excited, duration; ...)` — threshold lowering
   - `btw_subcritical(L, d_bulk; ...)` — bulk dissipation
   - `btw_supercritical(L, grains_distributed; ...)` — excess distribution
   - All return standard avalanche catalogs for diagnostic compatibility

2. **Build comparison diagnostics** — extend `work/experiments/validation/diagnostics.jl`
   - `compare_distributions(catalogs, labels)` → overlay plots + KS tests
   - `temporal_structure(catalog)` → autocorrelation, inter-event analysis
   - `sigma_dynamics(catalog, window)` → sigma(t) with stationarity tests
   - `shape_collapse(catalog)` → rescaled profiles + collapse quality metric
   - `history_dependence(catalog, threshold)` → post-large-event statistics
   - `removal_test(model, removal_time)` → pre/post removal diagnostics
   - `mechanism_agnosticism(catalogs_a, catalogs_b)` → statistical comparison

3. **Run experiments** — `work/experiments/validation/05_run_csoc_isoc.jl` or notebook
   - All five models at all parameter settings
   - Full diagnostic battery
   - Distinguishability matrix
   - Mechanism agnosticism tests
   - Recovery tests
   - Generate comprehensive comparison

---

## Success Criteria

The experiment succeeds if:

1. CSOC produces the predicted signature profile (truncated small events, quasi-periodicity, spectral knee, non-stationary sigma)
2. ISOC produces the predicted signature profile (inflated large events, continuous activity, steepened spectrum, history-dependent sigma)
3. CSOC and ISOC are distinguishable from each other by at least 3 independent diagnostics
4. Both are distinguishable from natural SOC
5. Both are distinguishable from their "lookalike" (CSOC from subcritical, ISOC from supercritical)
6. Both return to natural SOC when the intervention is removed
7. Signatures are mechanism-agnostic (both implementations produce consistent profiles)

The experiment partially succeeds if signatures are detectable but some pairs are not reliably distinguishable. This would indicate which diagnostics have discriminating power and which don't — useful for designing governance data tests.

The experiment fails if CSOC and ISOC cannot be distinguished from their genuine sub/supercritical counterparts. This would be a serious challenge to the framework's empirical utility, though not necessarily to its theoretical coherence.

---

## Dependencies

- Experiments 01-03 validated (sandpile, percolation, activation threshold)
- Full diagnostic toolkit from previous experiments
- Julia packages: same as previous experiments

## Future Directions

- **Combined CSOC + ISOC:** Suppression of small events and amplification of large events simultaneously (noted as a future direction in the ISOC framework document)
- **CSOC/ISOC on diluted lattice:** How do suppression/amplification interact with the activation threshold?
- **CSOC/ISOC with lattice degradation:** Does suppression or amplification change the location of the absorbing barrier?
- **Intentional tuning:** Active feedback control that steers the system toward criticality (the governance dashboard concept)
- **Application to governance data:** Use the validated signature profiles to classify empirical governance time series
