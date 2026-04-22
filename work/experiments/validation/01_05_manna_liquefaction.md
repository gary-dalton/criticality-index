# Experiment 01.05: Manna + Liquefaction (Skeleton)

> **Status: SKELETON.** Design is intentionally lighter than 01.04 (overtopping) because liquefaction itself is still being formalized. The mechanism per [`../ideas/liquefaction.md`](../ideas/liquefaction.md) is theoretical-skeleton, not simulation-ready. This experiment doc records the *intended* shape of the experiment so the design pipeline aligns with the overtopping pipeline once liquefaction is concrete enough to build.

## Purpose

Implement and test the **liquefaction** mechanism on the Manna (C-DP) substrate as the ISOC-side corollary to overtopping (Exp 01.04). Mirror structure: same substrate, same signature battery, same three-phase workflow, but the mechanism produces ISOC-like signatures (amplification) rather than CSOC-like (suppression).

Three concrete objectives:

1. **Detect ISOC-like signatures** in a system where they are guaranteed by construction (cyclic-driving amplification) and cleaner than on BTW (multiscaling-free Manna substrate).
2. **Locate the liquefaction-activation boundary in precondition space** by mapping the (saturation-analog, density-analog, driving amplitude/frequency) phase space and finding where ISOC-like dynamics activate vs natural SOC persists.
3. **Falsify or confirm** the quantitative predictions of the liquefaction mechanism (see [`../ideas/liquefaction.md`](../ideas/liquefaction.md) Part VI).

This experiment is **paired with** [`01_04_manna_overtopping.md`](01_04_manna_overtopping.md). They are mirror experiments — overtopping on the suppressed-release side, liquefaction on the amplified-cascade side. Together they cover both arms of the distorted-SOC framework.

> **Prerequisites:**
> - [`01_02_manna_sandpile.md`](01_02_manna_sandpile.md) — plain Manna baseline
> - [`01_03_negatives.md`](01_03_negatives.md) — rejection matrix; the "supercritical" rejection signature is the natural counterpart to liquefaction's ISOC-like signature, so the rejection matrix tells us how to *distinguish* liquefaction from genuine supercritical regime
> - [`01_04_manna_overtopping.md`](01_04_manna_overtopping.md) — overtopping experiment provides the structural template

---

## The Liquefaction Mechanism — Brief Recap

(Full specification: [`../ideas/liquefaction.md`](../ideas/liquefaction.md).)

Per-site state augmentation:

- **π_i ∈ [0, π_max]** — pore-pressure analog. High π lowers the effective threshold (amplification).
- **s_i, d_i** — saturation and density preconditions. Liquefaction activates only when `s_i > s_crit` AND `d_i < d_crit`.
- **Cyclic external driver** with amplitude A and frequency ω that pumps π up at activated sites.
- **Modified toppling:** `effective_threshold_i = z_c − T_a · (π_i / π_max)`. T_a is the amplification parameter.
- **Post-event relaxation:** π decays (drainage), d slowly increases (densification — repeated events make the site less susceptible).

The defining feature distinguishing liquefaction from naive amplification: **the cyclic driver destroys local damping (π buildup) during the event itself**, so the cascade is sustained beyond what local stored potential alone would allow.

---

## Three Model Variants (intended)

Mirror of 01.04 structure. Build and test in order.

### Model A: Plain Manna (baseline)

Already covered by Exp 01.02 — natural Manna with no amplification. Reference for what natural SOC looks like.

### Model B: Manna + Threshold Lowering (abstract amplification baseline)

Add a single parameter T_a (uniform across sites) that lowers all toppling thresholds:

```
topple site i when z_i ≥ z_c − T_a
```

The π field is absent (equivalent to π_i ≡ π_max permanently). This produces pure amplification: cascades propagate further than natural SOC because thresholds are easier to cross.

**Purpose:** test whether threshold lowering alone produces distinct ISOC-like signatures, or whether it reduces to natural SOC at a rescaled operating point — analogous to 01.04 Model B's question for suppression. Framework prediction: should produce ISOC-like signatures only weakly, since naive amplification without precondition dynamics doesn't capture the history-dependence and post-event signatures characteristic of true liquefaction.

### Model C: Manna + Liquefaction (full mechanism)

The full liquefaction extension with π field, cyclic driver, preconditions, and post-event recovery.

**Purpose:** test whether the full mechanism produces:
- Sharp activation boundary in (s, d) precondition space
- Sustained-liquefaction phase under continuous high-A driving
- History-dependent post-event reduction (and gradual recovery)
- Eventual densification that moves the system out of the liquefiable regime
- The full ISOC-like signature bundle from [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md) Part III

### Model D: Manna + Liquefaction + Densification at scale (future extension)

Extends Model C with a full feedback loop where many liquefaction events change the lattice's bulk density, eventually rendering the substrate non-liquefiable. Tests whether the system "grows out of" the liquefiable regime over a longer timescale.

Not part of the initial program; introduced once Model C's basic dynamics are mapped.

---

## Parameter Sweeps (intended)

Initial exploration grid at L = 128 (matches 01.04 starting point):

| Parameter | Initial values | Rationale |
|-----------|---------------|-----------|
| T_a (amplification) | 0, 1, 3 | T_a = 0 is plain Manna; T_a = 3 is strongly amplified |
| A (driving amplitude) | 0, 0.1, 0.5, 1.0 | Cyclic driver strength; A = 0 disables liquefaction |
| ω (driving frequency) | 0.001, 0.01, 0.1 | Rate of cyclic stress cycles |
| decay_rate (π drainage) | 0, 1e-4, 1e-2 | Recovery timescale between events |
| s_crit, d_crit | 0.5, 0.5 | Precondition thresholds; sweep separately later |
| Initial s, d | 0.7, 0.3 | Saturated, loose — meets preconditions |

Phase-space mapping: primary axes (T_a, A, ω) at fixed preconditions; secondary axis precondition plane at fixed driving.

Number of parameter combinations and seed counts to be set after Model B (simpler baseline) gives an idea of variability.

---

## What to Measure

### Standard signature battery

Same as 01.04 — full battery from Exp 01.01/01.02 with bracketed-xmin reporting. Look for ISOC-like rather than CSOC-like signature bundle:

- Avalanche size distribution: **excess at high end** (not low-end truncation); apparent τ shallower than natural Manna's 1.273
- xmin-bracket widening: same diagnostic as for CSOC, but the width direction differs (need to check)
- Spectral knee: **at amplification scale** rather than suppression scale
- Branching ratio: **b(x) > 1** during driving phases, with non-stationarity tracking the cyclic driver
- Inter-event intervals: **continuous activity** during driving rather than the deep quiescence of suppressed-release; characteristic frequency = driving frequency
- Hurst exponent: **elevated** — persistent long-range correlations from amplified large events

### π-field-specific diagnostics (new)

Beyond the standard battery:

| Diagnostic | Definition | What it reveals |
|------------|------------|-----------------|
| `pi_mean(t)` | Spatial mean of π over the lattice | Cyclic driver loading state |
| `pi_max_observed` | Highest π reached during a cycle | Liquefaction depth |
| `liquefied_fraction(t)` | Fraction of sites with π > some threshold | Spatial extent of liquefied state |
| `precondition_satisfied_fraction` | Fraction of sites with s > s_crit AND d < d_crit | Preconditions baseline |
| `densification_trajectory` | Mean d(t) over the simulation | Long-timescale structural change |
| `event_size_vs_pi` | Correlation between avalanche size and pre-event pi_mean | Tests falsifiability prediction #2 |
| `interval_vs_d` | Correlation between current d_mean and time to next large event | Tests falsifiability prediction #5 |

### Phase-space classification

For each parameter combination, classify:

- **No-liquefaction** — natural SOC signatures dominate; π stays low; no activation
- **Episodic liquefaction** — occasional events with full recovery between
- **Sustained liquefaction** — system spends significant time in liquefied state
- **Densified-out** — system gradually moves out of liquefiable regime as densification proceeds

The *primary deliverable* is a phase-space map locating the **liquefaction-activation boundary** and the **sustained-liquefaction boundary**.

---

## Implementation (intended)

Follows the same three-phase workflow established by 01.01, 01.02, 01.04. Skeleton form:

**Simulator:** `manna_liquefaction.jl` (new, parallel to `manna_sandpile.jl`). Parameters for π field, cyclic driver, preconditions. Likely ~200-300 lines based on overtopping precedent.

**Ensemble runner:** `run_manna_liquefaction_ensemble.jl` parameterized over (T_a, A, ω, decay_rate, ...).

**Analysis pre-compute:** extension of `analysis.jl` with `run_manna_liquefaction_analysis()`. Reuses existing helpers for the standard battery; adds π-specific diagnostics and the phase-space classifier.

**Notebook:** `work/exp01_05_manna_liquefaction.ipynb` (new, parallel structure to 01.02 and 01.04).

---

## Decisions Propagated (anticipated)

The bracketed-xmin reporting rule from 01.02 applies. The xmin-bracket-widening signature (currently a CSOC-like detection signal per [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md) II.1) needs an ISOC-like analog tested here — does amplification widen the bracket in the same direction as suppression, or differently? An ISOC-specific bracket signature may emerge.

Per-site `n_topples_i` instrumentation (per [`../ideas/energy_accounting.md`](../ideas/energy_accounting.md)) is needed to drive the π-update rule. Same instrumentation as 01.04 Model C.

---

## Open Questions

1. **How to couple the cyclic driver to the Manna substrate?** Manna uses stochastic grain drops as slow driving. A cyclic driver might take the form of periodic bulk grain injection, periodic threshold modulation, or explicit per-site stress increments. Each choice has different consequences for detectability. Settle this before building the simulator.

2. **Are preconditions per-site (s_i, d_i fields) or global (uniform s, d for whole lattice)?** Per-site is more physical but adds 2 × L² state. Global is simpler but loses the spatial heterogeneity that makes liquefaction realistic.

3. **What's the relationship between T_a (amplification) and the natural Manna z_c = 2?** With T_a > 0 and z_c = 2, the effective threshold can drop below 1, which means single-grain sites topple. Below 0 means even empty sites topple — clearly nonsensical. Need a floor (effective_threshold ≥ 0 or ≥ 1).

4. **How does liquefaction interact with overtopping?** Combined experiment (01.06?) — a system with both σ (structural integrity) and π (pore pressure) would have suppressed-release AND amplified-cascade dynamics simultaneously. Speculative but worth scoping.

5. **Soil liquefaction analogy boundaries.** The physical analogy is mnemonic; how far does it constrain the formalism? At what point should we strip the soil-specific language and reformulate in pure dynamical terms?

---

## Status (2026-04-22)

- Doc: skeleton only.
- Mechanism (`../ideas/liquefaction.md`): formalism drafted; not simulation-ready.
- Simulator code: not started.
- Ensemble: not run.
- Analysis: not built.
- Results: none.

To unblock: settle Open Question #1 (cyclic driver coupling) and #2 (per-site vs global preconditions). Once those are decided, the implementation pipeline mirrors 01.04 directly.

---

## Related Documents

- [`../ideas/liquefaction.md`](../ideas/liquefaction.md) — primary mechanism formalism (theoretical-skeleton; not simulation-ready)
- [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md) — Part III specifies the ISOC-like signature bundle this experiment should produce
- [`../ideas/energy_accounting.md`](../ideas/energy_accounting.md) — two-reservoir framework; π is structural energy on the amplification side
- [`01_04_manna_overtopping.md`](01_04_manna_overtopping.md) — mirror experiment on the suppressed-release side; structural template
- [`01_03_negatives.md`](01_03_negatives.md) — rejection matrix; the "genuine supercritical" rejection signature is the boundary that distinguishes liquefaction from naive supercriticality
- [`05_suppression_amplification.md`](05_suppression_amplification.md) — Model C there is the BTW-substrate analog of this experiment

---

## Next Experiments

After this skeleton becomes a real experiment and Model C is run:

**Combined liquefaction + overtopping** (potential Exp 01.06): a system with both σ and π fields tests whether suppression and amplification can coexist or whether one mechanism dominates. Speculative.

**Exp 02 (Synthetic Percolation)** and **Exp 03 (Activation Threshold)** can run in parallel; they don't depend on liquefaction.

**Future:** validate liquefaction signatures on the under-reporting test (Model F from [`../ideas/real_data_considerations.md`](../ideas/real_data_considerations.md)) — same test that's planned for overtopping signatures.
