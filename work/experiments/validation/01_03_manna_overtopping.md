# Experiment 01.03: Manna + CSOC Threshold Elevation + Overtopping

## Purpose

Implement and test the overtopping extension to CSOC on the Manna (stochastic, C-DP universality) model. Three concrete goals:

1. **Detect CSOC signatures** in a system where they are guaranteed by construction (threshold elevation) and cleaner than on BTW (multiscaling-free Manna substrate).
2. **Locate the absorbing barrier in parameter space** by mapping the (T, α, recovery_rate) phase space and finding the boundary between "recovering CSOC" and "runaway structural failure."
3. **Falsify or confirm** the quantitative predictions of the overtopping extension (see `../ideas/overtopping.md` Part VII).

## Dependencies

- **Experiment 01.02 (plain Manna) must pass first.** Plain Manna validates the simulation pipeline on the C-DP universality class and resolves whether auto-xmin works on simple-scaling systems. If 01.02 shows auto-xmin works cleanly on Manna, use it here; if not, fall back to manual `xmin=5` per the BTW lesson (see `feedback_power_law_fitting` memory).
- **Reuses `streaming.jl` infrastructure.** `summarize_seed`, `write_seed`, `load_ensemble`, `run_btw_ensemble` are model-agnostic. New simulator plugs into the existing Arrow storage pipeline without restructuring the pipeline itself.
- **Reuses `analysis.jl` diagnostics** where applicable (power-law fits, b(x), PSD, FSS extrapolation). New per-site σ diagnostics are added on top.

## Three Model Variants

Build and test in order. Each stage validates the previous before adding complexity.

### Model A: Plain Manna (baseline, covered by Exp 01.02)

Standard Manna: stochastic toppling at `z_i ≥ z_c` with z_c = 2. Reference for what "natural SOC" looks like on this substrate. Already covered; not reimplemented here.

### Model B: Manna + Threshold Elevation (CSOC baseline)

Adds a single parameter T (uniform across sites). Modified toppling condition:

```
topple site i when z_i ≥ z_c + T
```

Everything else identical to plain Manna. The σ field is absent (equivalent to σ_i ≡ 1 permanently). This produces pure CSOC: small avalanches suppressed, deficit accumulates, large events occur when accumulated deficit overcomes the elevated threshold.

Purpose: verify that threshold elevation alone produces the distinctive CSOC signatures on Manna (truncation at low end, excess at high end, quasi-periodic large events, spectral knee). Establishes the baseline against which the full extension (Model C) is compared.

### Model C: Manna + Threshold Elevation + Structural Integrity (full extension)

Adds the σ field and damage/recovery dynamics. Toppling condition:

```
effective_threshold_i = z_c + T · σ_i
topple site i when z_i ≥ effective_threshold_i
```

Damage rule (applied mid-cascade):

```
during avalanche at site i:
    track n_topples_i (cumulative this avalanche)
    if n_topples_i > E_crit and this site just toppled:
        σ_i ← σ_i · (1 − α)
```

Recovery rule (applied between grain drops):

```
for all i:
    σ_i ← min(1.0, σ_i + recovery_rate)
```

Full model specification in `../ideas/overtopping.md` Part III.

Purpose: test whether the σ-damage mechanism produces:
- Sudden runaway failure above a critical combination of (T, α, recovery_rate)
- Quantitative phase-space structure matching the extension's predictions
- Σ recovery trajectory matching `recovery_rate` timescale
- Post-failure dynamics qualitatively different from pre-failure

## Parameter Sweeps

### Initial exploration grid

Fix system size L = 128 for initial exploration (keeps runtime manageable). Sweep:

| Parameter | Values | Rationale |
|-----------|--------|-----------|
| T (suppression) | 0, 1, 3, 10 | T=0 is plain Manna; T=10 is strongly CSOC |
| α (damage rate) | 0, 0.01, 0.1, 0.5 | α=0 is Model B (no damage); α=0.5 is very fragile |
| recovery_rate | 0, 1e-4, 1e-2 | Very slow, slow, fast recovery |
| E_crit | 5 (fixed initially) | Site must topple 5+ times in one avalanche to damage. Can be swept after initial results. |

4 × 4 × 3 = 48 parameter combinations. With ~20 seeds per combination and N_record = 100K per seed, roughly 1000 seed-runs at L=128 — several hours of compute.

### Refinement sweeps (after initial results)

Based on initial grid, expect to refine:

- **Finer grid in (T, α) around the absorbing-barrier boundary** to locate it quantitatively.
- **E_crit sweep at selected (T, α)** to understand its role in the damage threshold.
- **L scaling** at selected (T, α, recovery_rate) to see how the phase-space boundaries depend on system size.

Refined grids are not committed upfront — they come from inspecting the initial grid results.

## What to Measure

### Signature battery (standard)

All signatures from the BTW pipeline apply:

- Avalanche size distribution (manual xmin=5 or auto if 01.02 confirms auto works on Manna)
- Avalanche area distribution (auto-xmin should work cleanly — simple scaling)
- Avalanche duration distribution
- Microscopic-time PSD and β_high
- Hurst exponent from microscopic activity series
- Activity-dependent branching ratio b(x)
- Excess kurtosis of size differences
- Inter-event time CCDFs

Pooled across seeds per parameter combination. Ensemble error bars from per-seed fits.

### σ-specific diagnostics (new for this experiment)

Beyond the standard battery, track:

| Diagnostic | Definition | What it reveals |
|-----------|------------|-----------------|
| `sigma_mean(t)` | Spatial mean of σ over the lattice at time t | Does structural integrity trend down, stabilize, or recover? |
| `sigma_min(t)` | Minimum σ over the lattice at time t | Where is the weakest point? Pre-failure indicator. |
| `sigma_std(t)` | Spatial std of σ | Is damage spatially uniform or concentrated? |
| `damage_per_event` | Change in sigma_mean immediately after each large event | How much does a typical large event cost the structure? |
| `recovery_trajectory` | sigma_mean(t) after a large event, normalized | Does σ recover exponentially toward 1 on the recovery_rate timescale? |
| `runaway_flag` | True if sigma_mean drops below 0.1 and stays there for > 10 avalanches | Absorbing-barrier-crossed indicator |
| `event_size_vs_damage` | Correlation between avalanche size and post-event σ degradation | Tests falsifiability prediction #2 |
| `interval_vs_sigma_min` | Correlation between current sigma_min and time to next large event | Tests falsifiability prediction #3 |

These are stored as long-form Arrow tables under `micro_stats/` or a new `sigma_stats/` subdirectory.

### Phase-space classification

For each (T, α, recovery_rate) combination, assign a regime label based on the ensemble behavior:

- **Near-natural** — avalanche distribution close to Manna's natural scaling; σ remains near 1
- **CSOC-recovering** — CSOC signatures present (truncation, quasi-periodicity, large events); σ damages then recovers; no runaway
- **Marginal** — behavior fluctuates between recovering and runaway across seeds
- **Runaway** — σ drops monotonically toward 0 and avalanche dynamics break down

A per-combination regime classification produces a phase-space map.

## Phase-Space Map as Primary Result

The headline deliverable of this experiment is a 2D heatmap in (T, α) space (at fixed recovery_rate), with cells colored by regime. The boundary between CSOC-recovering and Runaway is the absorbing barrier at that recovery_rate value. Repeating at multiple recovery_rate values produces a 3D phase diagram.

This is the first quantitative location of the absorbing barrier for any SOC system. Previously it was only asserted to exist (architecture §5.5).

## Runaway-Detection Halt Condition

Runaway seeds should be detected early rather than wasting compute on simulations that have already failed. Extend `run_manna_overtopping_ensemble` with a sanity check modeled on BTW's zero-avalanche warning:

```
if sigma_mean drops below sigma_halt_threshold (e.g. 0.05)
   AND remains below for more than runaway_persistence (e.g. 10_000 grain drops):
    record the event, emit [RUNAWAY] log line, optionally halt the seed
```

Whether to halt or continue after runaway is a knob. Two useful modes:

- **Halt on runaway** — saves time; the seed is already at the absorbing state, remaining simulation adds nothing informative. Mark the seed as "runaway" and move on.
- **Continue through runaway** — allows observation of post-failure dynamics. Useful for studying whether the system reaches a new steady state (liquefaction regime) or simply stops doing anything.

Initial implementation supports both via a kwarg, defaulting to continue-and-record so we capture post-failure behavior in the first run.

## Reuse

### Code reuse (from existing pipeline)

From `streaming.jl`: `summarize_seed`, `write_seed`, `load_ensemble`, `log_progress`, `write_manifest`, `seed_already_done`. Ensemble runner pattern is copied from `run_btw_ensemble` with the new parameter grid.

From `analysis.jl`: all standard diagnostics. The analysis function gains σ-specific additions but the skeleton is identical.

From `diagnostics.jl`: `fit_power_law`, `microscopic_activity_series`, `power_spectrum`, `hurst_rs`, `branching_ratio_activity_dependent`, `fat_tail_kurtosis`, `log_binned_pmf`. No changes needed.

### New code

| Path | Purpose |
|------|---------|
| `work/experiments/validation/manna_sandpile.jl` | Plain Manna simulator (Exp 01.02) |
| `work/experiments/validation/manna_overtopping.jl` | Extended Manna with σ field (this experiment, Model C) |
| `work/experiments/validation/run_manna_ensemble.jl` | Ensemble runner wrapper (plain) |
| `work/experiments/validation/run_manna_overtopping_ensemble.jl` | Ensemble runner wrapper (with parameter sweeps) |

`streaming.jl`'s `summarize_seed` may need an extension that captures σ trajectories for Model C seeds — a small addition rather than a rewrite. Likewise `analysis.jl` needs σ-specific post-processing but reuses all existing signature diagnostics.

## Implementation Plan (Sequencing)

1. **Stage 1: Plain Manna (Exp 01.02).** Build `manna_sandpile.jl` and `run_manna_ensemble.jl`. Validate signatures against published C-DP values (τ_s ~ 1.27, τ_t ~ 1.50). Determine whether auto-xmin works on Manna. Complete before any CSOC work.

2. **Stage 2: CSOC baseline (Model B).** Add threshold elevation to the Manna simulator. Sweep T at fixed L = 128 with ~20 seeds per T. Verify CSOC signatures emerge as expected (truncation at low end, excess at high end, spectral knee, quasi-periodic large events). This stage has no σ field; it's the simplest extension.

3. **Stage 3: Full overtopping (Model C).** Add σ field, damage rule, recovery rule. Implement the runaway-detection halt condition. Run the initial (T, α, recovery_rate) grid. Produce the phase-space map.

4. **Stage 4: Refinement.** Based on Stage 3 results, run targeted refinement sweeps. Fit quantitative predictions (event size ↔ damage, interval ↔ σ_min). Decide whether initial falsifiability predictions hold.

5. **Stage 5: L scaling.** Repeat selected (T, α, recovery_rate) points at L ∈ {64, 256, 512} to characterize L-dependence of phase-space boundaries.

Each stage commits before the next starts. If a stage produces anomalous results, stop and diagnose before adding more complexity.

## Success Criteria

### For Model B (CSOC baseline)

- Avalanche size distribution at high T shows truncation below T and excess above (CSOC signature Part IV.1 of framework).
- Inter-event intervals for large events show characteristic quasi-periodicity absent in Model A (plain Manna).
- Spectral knee appears at a frequency corresponding to the quasi-periodic cycle.

If these are present, CSOC is correctly implemented on Manna.

### For Model C (full extension)

**Primary success criterion** — the (T, α) phase-space map shows a clear boundary between CSOC-recovering and Runaway regimes. "Clear" means:

- For each grid cell, at least 80% of seeds fall into the same regime classification.
- The boundary is narrow (width of one grid cell or less at resolution of initial grid).
- The boundary position changes systematically with recovery_rate across the three recovery_rate values tested.

**Secondary success criteria** — the falsifiability predictions from the extension doc (Part VII) hold:

1. Phase transition is sharp in (T, α) space.
2. Event size correlates with post-event σ degradation above E_crit.
3. Inter-event interval lengthens with cumulative damage.
4. Runaway onset is sudden at a critical σ value.
5. Recovery_rate rescues parameter combinations that would otherwise run away.

Meeting all five is "the overtopping extension is confirmed." Meeting 1-3 but not 4-5 is "mechanism is roughly correct but the sharp-transition claim is too strong." Meeting none is "the mechanism is wrong" — in which case, back to the drawing board with updated ideas.

### For the broader project

If Stage 3 produces a clean phase diagram with a locatable absorbing barrier, this is the first quantitative empirical (simulated) instance of the absorbing barrier — a concept the architecture has asserted but not demonstrated. It would justify investing in the extension as part of the main framework.

If Stage 3 fails to produce a clean phase diagram, the extension returns to `ideas/` as a refined but still-speculative proposal, and we learn something important about the difficulty of locating absorbing barriers even in controlled simulations.

## Dependencies

- Julia packages: same as BTW pipeline (`Distributions.jl`, `StatsBase.jl`, `FFTW.jl`, `Arrow.jl`, `DataFrames.jl`, `Plots.jl`).
- No external data required.
- Docker container: headless Julia from `docker-compose.julia.yml`.
- Storage: analogous to BTW. Path root `work/data/exp01_03/`.

## Related Documents

- `../ideas/overtopping.md` — theoretical framework for this experiment
- `../ideas/capacitive_SOC_framework.md` Part VIII and new Suppression-Structure-Fragility section — where this extension sits in the CSOC hierarchy
- `04_absorbing_barrier.md` — abstract framing of what this experiment concretely measures
- `05_csoc_isoc.md` — Model B of that doc is the multi-model analog of this experiment's Model B
- `01_sandpile.md` — BTW experiment whose methodology this extends

## Next Experiment

If this experiment succeeds in locating the absorbing barrier for Manna, the next logical step is **Experiment 01.04: Coupled Manna + Overtopping** — apply the same structural-fragility mechanism to the coupled-SOC setup from `06_coupled_soc.md`. This would test whether inter-system coupling can trigger structural failures in otherwise-stable systems (governance-relevant: does a neighbor's crisis destabilize you enough to push past the absorbing barrier?).
