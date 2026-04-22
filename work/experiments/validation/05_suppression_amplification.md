# Experiment 05: Suppression, Amplification, and Distinguishability

> **See also:**
> - [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md) — the signature catalog (CSOC-like / ISOC-like detection categories). This experiment is the empirical test of whether those categories are measurable and discriminable.
> - [`../ideas/overtopping.md`](../ideas/overtopping.md) — primary mechanistic formalism for suppressed-release dynamics.
> - [`../ideas/liquefaction.md`](../ideas/liquefaction.md) — symmetric mechanism for amplified-cascade dynamics.
> - [`01_03_manna_overtopping.md`](01_03_manna_overtopping.md) — Manna-substrate implementation. Model B of 01_03 is a Manna-specific instance of Model B here (suppression); Model C adds structural fragility (the full overtopping extension).

## Purpose

Apply **suppression** and **amplification** mechanisms to the validated sandpile system and test three claims:

1. Suppression mechanisms produce **CSOC-like signatures** (truncated small events, quasi-periodic large events, spectral knee, etc.) per `distorted_soc_signatures.md` Part II.
2. Amplification mechanisms produce **ISOC-like signatures** (inflated large events, continuous activity, steepened spectrum, etc.) per `distorted_soc_signatures.md` Part III.
3. CSOC-like and ISOC-like signature bundles are distinguishable from each other, from natural SOC, and from genuine sub/super-criticality.

This experiment determines whether the signatures catalog is empirically testable on a controlled BTW substrate before being applied to governance data. It is paired with `01_03_manna_overtopping.md`, which runs the same logic on the Manna substrate with a richer set of mechanisms (including structural damage).

---

## Framing: Mechanism vs. Signature

This experiment distinguishes **mechanisms** from **signatures**:

- A **mechanism** is a specific dynamical rule (e.g., suppress topplings below a size threshold; elevate toppling threshold; boost propagation). Mechanisms are what the simulator does.
- A **signature** is a measurable statistical pattern in the output (e.g., power-law truncation + spectral knee + non-stationary σ). Signatures are what the analysis detects.

The `distorted_soc_signatures.md` catalog treats CSOC-like and ISOC-like as *signature bundles* — observational categories independent of which mechanism produced them. The `overtopping.md` and `liquefaction.md` docs specify primary mechanisms that are *expected* to produce these signatures. This experiment tests the link: do the mechanisms produce the signatures, and are the signatures discriminable?

---

## The Models

All models use the BTW sandpile on a fully connected lattice (p = 1, L = 128) as the SOC substrate, validated in Experiment 01. Each model modifies one aspect of the dynamics.

### Model A: Natural SOC (Baseline)

Standard BTW sandpile. No modifications. This is the control — all other models are compared against it.

### Model B: Suppression

Small avalanches are systematically suppressed. The suppression mechanism prevents energy release below a threshold, forcing deficit accumulation. Expected signature profile: **CSOC-like** per `distorted_soc_signatures.md` Part II.

**Mechanism B.1 — Toppling Suppression:**

After a grain is added and topplings begin, if the avalanche size has not yet reached s_suppress, all topplings are reversed (grains returned to pre-topple configuration). The grain that was added remains, increasing local height.

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| s_suppress | 5, 10, 25, 50, 100 | Minimum avalanche size to "allow." Below this, the event is suppressed |

**What this does:**
- Small stress releases are blocked
- Energy accumulates in sites that would have toppled
- Heights grow beyond their natural SOC values
- Eventually a trigger produces an avalanche above s_suppress — this is "allowed" and cascades through a pre-loaded system

**Mechanism B.2 — Threshold Elevation:**

Raise the toppling threshold z_c locally for a fraction of sites, making them harder to topple.

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| z_c_elevated | 5, 6, 8, 10 | Elevated threshold (normal = 4) |
| fraction_elevated | 0.1, 0.25, 0.5, 0.75 | Fraction of sites with elevated threshold |

**Run both mechanisms** and compare. If the CSOC-like signature is mechanism-agnostic, both should produce the same signature profile at matched suppression intensity.

### Model C: Amplification

Cascades are systematically amplified. The amplification mechanism adds energy during propagation, sustaining cascades beyond natural boundaries. Expected signature profile: **ISOC-like** per `distorted_soc_signatures.md` Part III.

**Mechanism C.1 — Propagation Boost:**

When a site topples, it distributes more grains than it received. Instead of losing 4 and giving 1 to each neighbor, it loses 4 but gives (1 + boost) to each neighbor (or a subset).

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| boost | 0.25, 0.5, 1.0, 2.0 | Extra grains per neighbor per toppling |
| boost_probability | 0.1, 0.25, 0.5, 1.0 | Fraction of topplings that receive the boost |

**Note:** boost must be handled carefully to maintain energy conservation accounting. The extra grains are "injected" — they represent external excitation entering the system during propagation, not spontaneous energy creation. See `../ideas/energy_accounting.md` for the E_in bookkeeping.

**Mechanism C.2 — Threshold Lowering:**

Lower the toppling threshold z_c for sites neighboring an active toppling, making cascade propagation easier.

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| z_c_excited | 3, 2, 1 | Lowered threshold for neighbors of toppling sites |
| excitation_duration | 1, 3, 5 | How many toppling waves the lowered threshold persists |

**Run both mechanisms** and compare. Same logic as Model B: if the ISOC-like signature is mechanism-agnostic, both should produce the same profile.

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

For every model and parameter setting, compute the full diagnostic battery from Experiment 01. The analysis is organized around the predictions from `distorted_soc_signatures.md` — specifically Part II for CSOC-like and Part III for ISOC-like.

### 5a. Distribution Shape

**Method:** Fit P(s) across the full range. Compare distribution shape across all models.

| Model | Predicted P(s) Shape |
|-------|---------------------|
| Natural SOC | Clean power law |
| Suppression | Truncated at low end (below s_suppress), excess at high end — CSOC-like |
| Amplification | Inflated at high end, possible elevation of small events — ISOC-like |
| Subcritical | Exponential decay |
| Supercritical | Dominated by system-spanning events |

**Key plot:** Overlay P(s) for all five models on a single log-log plot. The CSOC-like and ISOC-like distortions should be visually distinct from each other and from the genuine sub/super-critical distributions.

**Quantitative test:** Fit a two-component model (power law + bump/cutoff) to the distorted distributions. The characteristic scale at the suppression/amplification threshold should be identifiable.

### 5b. Temporal Structure

**Method:** Compute inter-event intervals for large avalanches (s > s_threshold) and plot the autocorrelation function.

| Model | Predicted Temporal Structure |
|-------|------|
| Natural SOC | No characteristic timescale, scale-free inter-event times |
| Suppression | Quasi-periodic: long quiet accumulation → burst → quiet. Second timescale visible |
| Amplification | Continuous activity, no accumulation phase, short depletion-recovery timescale |
| Subcritical | Long, exponential inter-event times |
| Supercritical | Continuous, no structure |

**Key plot:** Autocorrelation of large-event occurrence. Suppression should show periodic peaks. Amplification should show rapid decay.

**Quantitative test:** Fit inter-event time distribution to power law, exponential, and stretched exponential. Suppression should show excess probability at a characteristic interval.

### 5c. Spectral Analysis

**Method:** Compute PSD of the avalanche size time series.

| Model | Predicted Spectrum |
|-------|-------------------|
| Natural SOC | 1/f with beta ≈ 1 |
| Suppression | Knee at high frequency (suppression scale), flattening below |
| Amplification | Steepened, excess low-frequency power |
| Subcritical | White noise (beta ≈ 0) |
| Supercritical | Red noise (beta > 2) |

**Key plot:** PSD for all five models overlaid. The spectral distortions should be in opposite directions for suppression vs. amplification.

### 5d. Branching Ratio Dynamics

**Method:** Compute σ in sliding windows over the avalanche sequence.

| Model | Predicted σ(t) |
|-------|-------------------|
| Natural SOC | Stationary, σ ≈ 1 |
| Suppression | Non-stationary: < 1 during accumulation, spikes > 1 during release |
| Amplification | Persistently > 1, with transient dips after large events |
| Subcritical | Stationary, σ < 1 |
| Supercritical | Stationary, σ > 1 |

**Key plot:** σ(t) for suppression and amplification overlaid. The non-stationarity pattern should be distinct.

**Quantitative test:** Stationarity tests (ADF, KPSS) on σ(t). Natural SOC and genuine sub/supercritical should be stationary. Suppression should be non-stationary.

### 5e. Exponent Consistency

**Method:** Extract τ_s (size), τ_t (duration), and check the scaling relation (τ_t−1)/(τ_s−1).

| Model | Predicted Exponent Consistency |
|-------|-------------------------------|
| Natural SOC | Scaling relation satisfied |
| Suppression | Scaling relation violated |
| Amplification | Scaling relation violated |
| Subcritical | Exponents undefined (no power law) |
| Supercritical | Exponents undefined |

**Key test:** The direction of violation differs. Suppression truncates small events → τ_s appears steeper. Amplification inflates large events → τ_s appears shallower.

### 5f. Avalanche Shape Collapse

**Method:** Extract temporal profiles of avalanches at different sizes. Rescale and test for collapse.

| Model | Predicted Shape Collapse |
|-------|------------------------|
| Natural SOC | Collapses onto universal function |
| Suppression | Fails — large events have deficit-driven profiles |
| Amplification | Fails — large events have excitation-sustained profiles |

**Key plot:** Shape collapse attempts for all models. The failure modes should differ visually between suppression and amplification.

### 5g. History Dependence

**Method:** Condition future event statistics on recent past. After a large event (s > 90th percentile), how do the next N events differ from the unconditional distribution?

| Model | Predicted Post-Large-Event Behavior |
|-------|-------------------------------------|
| Natural SOC | No systematic change (memoryless at the event level) |
| Suppression | Deep quiescence — reduced activity, accumulation resumes |
| Amplification | Transient reduction then rapid recovery — depletion dip |
| Subcritical | No change (events independent) |
| Supercritical | No change (continuously active) |

**Key test:** Per `liquefaction.md`, history dependence is the clearest behavioral signature distinguishing amplified-cascade SOC from true supercriticality.

### 5h. Suppression/Amplification Removal Test

**Method:** Run Model B or Model C for a long period, then remove the suppression/amplification mechanism. Observe recovery dynamics.

**Suppression removal prediction:** System returns to natural SOC signatures. Deficit discharges through a burst of small events. Recovery timescale depends on accumulated deficit.

**Amplification removal prediction:** System relaxes toward natural SOC. Event sizes decrease, σ → 1, PSD returns to 1/f. Recovery timescale depends on depletion depth.

**Neither sub/supercritical should show this recovery** — their parameters define their state intrinsically. Removing a nonexistent intervention changes nothing.

---

## Distinguishability Matrix

The core deliverable: can an observer who sees only the signature data determine which model generated it?

| Diagnostic | SOC vs Sup. | SOC vs Amp. | Sup. vs Amp. | Sup. vs Sub | Amp. vs Super |
|-----------|-------------|-------------|--------------|-------------|---------------|
| P(s) shape | Truncation at low end | Inflation at high end | Opposite distortions | Excess large events in Sup. | History dependence in Amp. |
| Temporal structure | Quasi-periodicity appears | Continuous, no accumulation | Slow cycle vs. fast recovery | Quasi-periodicity vs. none | Post-event dip vs. none |
| PSD | Knee at high freq | Excess at low freq | Opposite spectral distortions | Periodic peak vs. flat | Steepened vs. red noise |
| σ(t) | Non-stationary | Persistently elevated | Oscillating vs. elevated | Non-stationary vs. constant | Transient dips vs. constant |
| Exponents | Steeper τ_s | Shallower τ_s | Opposite direction | Both violate, but Sup. has excess large events | Both violate, but Amp. has depletion signature |
| Shape collapse | Fails (deficit-driven) | Fails (excitation-sustained) | Different failure modes | Different failure modes | Different failure modes |
| History dependence | Deep quiescence | Depletion dip | Duration and depth of post-event effect | Sup. has it, Sub. doesn't | Amp. has it, Super doesn't |
| Intervention removal | Returns to SOC | Returns to SOC | Both return | Sup. returns, Sub. doesn't | Amp. returns, Super doesn't |

("Sup." = Suppression / Model B; "Amp." = Amplification / Model C.)

---

## Mechanism-Agnosticism Test

A critical claim of the signatures catalog: the CSOC-like and ISOC-like bundles depend on the *effect* (suppression/amplification) rather than the specific *mechanism* implementing it. This claim is testable.

**Test:** For each of Models B and C, compare the two implementation mechanisms (toppling suppression vs. threshold elevation for B; propagation boost vs. threshold lowering for C). If the signatures are mechanism-agnostic, both mechanisms within a model should produce statistically indistinguishable signature profiles when calibrated to the same effective suppression/amplification intensity.

**Method:** Match mechanisms by equating their effect on total avalanche count or mean avalanche size, then compare all signature diagnostics via statistical tests (KS for distributions, correlation for time series).

**Failure:** If different mechanisms produce qualitatively different signatures at matched intensity, the mechanism-agnostic claim fails and signatures become mechanism-dependent — a significant restriction on how the catalog can be applied to governance data where mechanisms are unknown.

---

## Experimental Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| Full diagnostic battery | DataFrame | All diagnostics for all models and parameters |
| Distribution overlays | Plots | P(s) for all five models |
| Temporal structure | Plots | Autocorrelation and inter-event distributions |
| PSD comparison | Plots | All models overlaid |
| σ dynamics | Plots | σ(t) for Models B, C, and controls |
| Shape collapse attempts | Plots | Success/failure for each model |
| Distinguishability matrix | Table | Which pairs are distinguishable and by which diagnostics |
| Mechanism-agnosticism test | Table | Within-B and within-C mechanism comparison |
| Recovery dynamics | Plots | Post-removal recovery trajectories |

---

## Implementation Plan

1. **Build modified sandpiles** — `work/experiments/validation/modified_sandpile.jl`
   - `btw_suppress_size(L, s_suppress; ...)` — toppling suppression
   - `btw_suppress_threshold(L, z_c_elevated, fraction; ...)` — threshold elevation
   - `btw_amplify_boost(L, boost, boost_prob; ...)` — propagation boost
   - `btw_amplify_excite(L, z_c_excited, duration; ...)` — threshold lowering
   - `btw_subcritical(L, d_bulk; ...)` — bulk dissipation
   - `btw_supercritical(L, grains_distributed; ...)` — excess distribution
   - All return standard avalanche catalogs for diagnostic compatibility

2. **Build comparison diagnostics** — extend `work/experiments/validation/diagnostics.jl`
   - `compare_distributions(catalogs, labels)` → overlay plots + KS tests
   - `temporal_structure(catalog)` → autocorrelation, inter-event analysis
   - `sigma_dynamics(catalog, window)` → σ(t) with stationarity tests
   - `shape_collapse(catalog)` → rescaled profiles + collapse quality metric
   - `history_dependence(catalog, threshold)` → post-large-event statistics
   - `removal_test(model, removal_time)` → pre/post removal diagnostics
   - `mechanism_agnosticism(catalogs_a, catalogs_b)` → statistical comparison

3. **Run experiments** — `work/experiments/validation/05_run_suppression_amplification.jl` or notebook
   - All five models at all parameter settings
   - Full diagnostic battery
   - Distinguishability matrix
   - Mechanism-agnosticism tests
   - Recovery tests
   - Generate comprehensive comparison

---

## Success Criteria

The experiment succeeds if:

1. Model B produces the predicted CSOC-like signature profile (truncated small events, quasi-periodicity, spectral knee, non-stationary σ).
2. Model C produces the predicted ISOC-like signature profile (inflated large events, continuous activity, steepened spectrum, history-dependent σ).
3. The two signature profiles are distinguishable from each other by at least 3 independent diagnostics.
4. Both are distinguishable from natural SOC.
5. Both are distinguishable from their "lookalike" (suppression from subcritical, amplification from supercritical).
6. Both return to natural SOC when the intervention is removed.
7. Signatures are mechanism-agnostic (both implementations within each model produce consistent profiles).

The experiment partially succeeds if signatures are detectable but some pairs are not reliably distinguishable. This would indicate which diagnostics have discriminating power and which don't — useful for designing governance data tests.

The experiment fails if the distorted signatures cannot be distinguished from their genuine sub/supercritical counterparts. This would be a serious challenge to the empirical utility of the signatures catalog, though not necessarily to its theoretical coherence.

---

## Relationship to 01_03 (Manna substrate)

This experiment and [`01_03_manna_overtopping.md`](01_03_manna_overtopping.md) are complementary:

- **05 (this doc, BTW):** broad test of the signature bundles across both suppression and amplification, including genuine sub/super controls. BTW substrate known to multiscale — complicates power-law fits but provides the strongest sub/super controls (BTW is the canonical SOC system).
- **01_03 (Manna):** focused on suppression mechanisms specifically (Models B and C), with structural damage (σ field) in Model C. C-DP universality — cleaner scaling, auto-xmin viable. Does not test amplification.

Together they give substrate-independence (BTW + Manna both produce the signatures) and mechanism-richness (suppression-only mechanisms in 05; suppression + structural damage in 01_03).

---

## Dependencies

- Experiments 01-03 validated (sandpile, percolation, activation threshold)
- Full diagnostic toolkit from previous experiments
- Julia packages: same as previous experiments
- Signatures catalog: `../ideas/distorted_soc_signatures.md`

## Future Directions

- **Combined suppression + amplification:** Suppression of small events and amplification of large events simultaneously.
- **Suppression/amplification on diluted lattice:** How do these mechanisms interact with the activation threshold?
- **Suppression with structural damage on BTW:** Cross-substrate version of 01_03 Model C.
- **Intentional tuning:** Active feedback control that steers the system toward criticality (the governance dashboard concept).
- **Application to governance data:** Use the validated signature profiles to classify empirical governance time series.
