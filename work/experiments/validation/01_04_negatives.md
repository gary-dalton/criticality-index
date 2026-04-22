# Experiment 01.04: Negative Controls — Signature Rejection on Non-SOC Systems

## Purpose

Experiments 01.01 (BTW) and 01.02 (Manna) validated that our signature battery *detects* SOC on systems where criticality is guaranteed by construction. This experiment validates that the same battery *rejects* non-SOC systems — demonstrating that the diagnostics have real discriminating power, not just bias toward accepting everything they're given.

Concrete objectives:

1. **Validation by counter-example.** Each signature must reject at least one non-SOC regime for it to contribute discriminating power. Signatures that accept everything are useless.
2. **Build a rejection matrix.** For each (signature × non-SOC regime) pair, document whether the signature rejects the regime and with what specificity. Enables principled interpretation of real-data failures.
3. **Identify signature redundancy and uniqueness.** Some signatures may reject the same regimes in the same way (redundant); others may uniquely reject specific regimes. The matrix exposes this structure.

> **Why this matters for downstream work.** When Phase 3 governance data shows only partial signature agreement, we need to know which failures are physically meaningful vs. which are artifact-driven. This experiment gives the meaning-map for partial agreement patterns.

---

## The Four Negative Regimes

Each regime is a specific way of being "not SOC." The signatures should reject all four in specific diagnostic patterns.

### Regime 1: Poisson synthetic (no simulator)

Purely statistical negative: event sizes drawn from an exponential distribution, no spatial correlations, no temporal structure. Represents "random events" — the null hypothesis against which any claim of structure must be tested.

**Generation:** `poisson_catalog(N; rate, size_scale)` function (pure stats; no lattice).
- Sizes: Exponential(1/size_scale)
- Durations: Exponential(1/duration_scale) × some correlation with size (or independent — try both)
- Wave profiles: Gaussian activity of total size/duration
- Area: ≈ size (single toppling per site)
- No lattice → no G(r), but the spatial-correlation signature can be stubbed with zero.

**Expected rejections:**
- **Signature 1 (P(s) power-law):** ✓ reject — Clauset log-likelihood-ratio favors exponential over power-law.
- **Signature 2 (G(r)):** N/A without lattice; or trivial zero if we layer Poisson timings on a lattice.
- **Signature 3 (PSD):** ✓ reject — white noise, β ≈ 0.
- **Signature 4 (fractal):** ✓ reject — γ ≈ 1, D_s ≈ D_a ≈ 2 (no multiple-toppling).
- **Signature 5 (kurtosis):** ✓ reject — low excess kurtosis, near-Gaussian first differences.
- **b(x):** ✓ reject — no activity-conditional structure; plateau absent or spurious.

### Regime 2: Subcritical (bulk dissipation ε)

A sandpile (BTW or Manna) where each grain during a toppling has probability ε of being lost to the void (in addition to boundary dissipation). For ε > 0, cascades die before reaching system size; the system is genuinely below criticality.

**Parameters:**
- ε ∈ {0.01, 0.05, 0.10} — sweep to see regime transition
- Both BTW and Manna substrates
- L = 128 (FSS not needed for rejection; one lattice size)
- 20 seeds per (substrate, ε) combination
- N_record = 100,000 per seed

**Expected rejections:**
- **Signature 1:** ✓ reject — P(s) has exponential decay or cutoff at scale s* ~ 1/ε; not power-law at all scales.
- **Signature 2:** ✓ reject — G(r) decays exponentially; correlation length ξ ~ 1/√ε is finite, not diverging.
- **Signature 3:** ✓ reject — PSD β ≈ 0 (white noise); no long-range correlations.
- **Signature 4:** Partial reject — γ still ≈ 1 (single topplings still happen), but max avalanche size bounded. Not a clean rejection mode.
- **Signature 5:** ✓ reject — low kurtosis, doesn't grow with L.
- **b(x):** ✓ reject — b(x) < 1 everywhere; no broad critical plateau.

### Regime 3: Supercritical (excess grain distribution)

A sandpile where each toppling distributes MORE grains than it receives. BTW: removes 4, distributes 5 (1 extra injected). Manna: removes 2, distributes 3. The system gains energy at every toppling; cascades grow unboundedly absent a safety mechanism.

**Safety:** need a `max_avalanche_size` cap (e.g., 10·L²) to prevent infinite loops. Cascades that hit the cap are recorded separately as "runaway" events.

**Parameters:**
- BTW: grains_distributed ∈ {5, 6}
- Manna: grains_distributed ∈ {3} (z_c = 2, so 3 is the minimum excess)
- L = 128
- 20 seeds per variant
- N_record = 50,000 (smaller because individual cascades are larger)
- max_avalanche_size = 10·L² = 163,840

**Expected rejections:**
- **Signature 1:** ✓ reject — dominated by system-spanning events; no clean power-law regime; pile-up at s_max.
- **Signature 2:** ✓ reject — long-range correlations but not of the SOC type; large active region permanently.
- **Signature 3:** ✓ reject — β > 2 (red noise), not the SOC β ≈ 1.5–1.6 roll-off.
- **Signature 4:** Weak reject — γ may still be > 1, but the D_s, D_a structure breaks down.
- **Signature 5:** Mixed — kurtosis likely very high (dominated by system-spanning outliers), but that's a different fat-tail structure than SOC.
- **b(x):** ✓ reject — b(x) > 1 everywhere; cascades never die out.

### Positive controls (no new data — reuse)

- **Natural BTW** — `work/data/exp01_01/` 100-seed ensemble
- **Natural Manna** — `work/data/exp01_02/` 100-seed ensemble

These are the "signatures must accept" reference. A signature that rejects natural SOC is a bug, not a diagnostic. Both ensembles already pass all signatures (Exp 01.01 and 01.02 Results sections); here we re-pass them through the same analysis pipeline as the negatives for a direct apples-to-apples comparison.

---

## The Rejection Matrix

Primary deliverable. For each (signature × regime) cell, report:

- **Accept/Reject classification:** did the signature's acceptance criterion pass or fail on this regime?
- **Discriminating strength:** distance between this regime's measurement and the acceptance threshold (in standard deviations of the natural SOC ensemble, if possible).
- **Failure mode:** qualitative note on *how* the signature rejected (e.g., "α outside range," "spectrum shows β > 2," "b(x) everywhere below 1").

Schematic (fill in after run):

| Signature | Nat. BTW | Nat. Manna | Poisson | BTW subcrit | BTW supercrit | Manna subcrit | Manna supercrit |
|-----------|----------|------------|---------|-------------|---------------|---------------|-----------------|
| P(s) power-law | ✓ | ✓ | ✗ (exp preferred) | ✗ (exp cutoff) | ✗ (saturation) | ✗ (exp cutoff) | ✗ (saturation) |
| G(r) power-law | ✓ | ✓ | N/A | ✗ (exp decay) | ? | ✗ (exp decay) | ? |
| PSD β in range | ✓ | ✓ | ✗ (β=0) | ✗ (β=0) | ✗ (β>2) | ✗ (β=0) | ✗ (β>2) |
| D_s, D_a consistent | ✓ | ✓ | ✗ (γ=1) | Partial | Partial | ✗ (γ=1) | Partial |
| Kurtosis grows with L | ✓ | ✓ | ✗ (K~0) | ✗ (bounded) | Mixed | ✗ (bounded) | Mixed |
| b(x) plateau at 1 | ✓ | ✓ | ✗ (no plateau) | ✗ (b<1) | ✗ (b>1) | ✗ (b<1) | ✗ (b>1) |
| xmin-bracket narrow | ✓ (<0.05) | ✓ (<0.02) | N/A | N/A | N/A | N/A | N/A |

The filled matrix tells us:

- **Any signature that's always ✓ or always ✗:** useless (accepts or rejects everything; no discriminating power).
- **Signatures whose failure mode is regime-specific:** most useful — they don't just say "not SOC," they say *which kind* of non-SOC.
- **Redundant signatures:** if two signatures give identical accept/reject patterns across all regimes, one of them is redundant for classification (though both may be worth reporting as independent evidence).

---

## Implementation

Follows the three-phase workflow established in 01.01 and 01.02: explore → ensemble → analyze.

### Simulator modifications

**`sandpile.jl`** — add two new kwargs to `btw_sandpile` and `btw_sandpile_adaptive`:

```julia
bulk_dissipation::Float64 = 0.0        # Per-grain probability of void-loss during toppling
grains_distributed::Int = 4            # Total grains sent to neighbors per toppling (default = z_c)
```

In `run_avalanche!`, after a toppling:
- For each of `grains_distributed` grains (not `z_c`):
  - With probability `bulk_dissipation`, grain is annihilated (increment `n_dissipated`).
  - Otherwise, sent to a neighbor (BTW: deterministic, but with `grains_distributed > z_c` the distribution needs defining — e.g., cyclic through the 4 neighbors twice).
- Supercritical note: when `grains_distributed > z_c`, the site injects excess energy. Typical convention: cycle through neighbors deterministically (neighbor 1 gets floor(grains_distributed/4)+1 if extras remain, etc.).

**`manna_sandpile.jl`** — same kwargs. For Manna, `grains_distributed > z_c` just means `for _ in 1:grains_distributed: pick random neighbor` (natural extension of the random-dispatch rule).

Safety: `max_avalanche_size::Int = 10 * L * L` kwarg that halts the cascade if exceeded. Hit-cap avalanches recorded with a `truncated::Bool = true` field or by setting size = -1 as a sentinel.

### Poisson synthetic generator

New file `work/experiments/validation/negatives.jl` — contains:

```julia
function poisson_catalog(N; size_scale=100.0, seed=nothing) → Vector{AvalancheRecord}
```

Generates N synthetic `AvalancheRecord` entries with:
- `size` drawn from `Exponential(size_scale)` (rounded to int)
- `duration` drawn from `Exponential(size_scale / 10)` (rough scaling)
- `area ≈ size` (single toppling per site, γ = 1)
- `max_extent ≈ sqrt(area)` (compact)
- `wave_profile` = flat activity of total `size` spread over `duration` waves
- `n_dissipated` drawn from `Exponential(1.0)` (mean 1 per conservation, but not correlated with size like real SOC)

The point: reproduce the statistical *shape* of a catalog without any of the correlations that make SOC special.

### Ensemble runner

**`run_negatives_ensemble.jl`** in validation/:

```
For each regime × parameter combination:
  Run btw_sandpile_adaptive or manna_sandpile_adaptive with modified kwargs
  Write summaries/diagnostics/micro_stats Arrow per seed
  Output path: work/data/exp01_04/<model>_<variant>_<param>/
```

For Poisson: generate catalogs in memory, write same Arrow format for uniformity.

### Analysis pre-compute

**Extension of `analysis.jl`** — new function `run_negatives_analysis()` that:

1. For each regime, loads its ensemble and runs the full signature battery (reuses existing helpers: `pooled_size_fits`, `pooled_psd`, `pooled_bx`, `fractal_dimensions`, etc.)
2. Compares each signature's output to the natural-SOC reference (from `work/data/exp01_01/analysis/` and `work/data/exp01_02/analysis/`)
3. Builds the rejection matrix as an Arrow table

Output: `work/data/exp01_04/analysis/rejection_matrix.arrow` + per-regime signature outputs.

### Notebook

**`work/exp01_04_negatives.ipynb`** — same three-phase structure:

- Explore: run one small-L smoke test of each regime to verify the simulator modifications work.
- Analyze: load all ensembles + the rejection matrix; produce:
  - P(s) overlay plot showing natural vs each negative
  - PSD overlay
  - σ(t) non-stationarity for non-SOC
  - b(x) comparison
  - Shape collapse attempts per regime
  - Rejection matrix as an annotated table
- Fast-path section (12 in earlier notebooks): load pre-computed Arrow, produce all comparison plots in seconds.

---

## Expected runtime

| Step | Compute |
|------|---------|
| Simulator modifications | ~1 hour coding + syntax check |
| 4 negatives ensembles (L=128, 20 seeds each, small avalanches) | ~2 hours total in headless container |
| Poisson generation | <1 minute |
| Analysis pre-compute | ~15 minutes |
| Total | ~3 hours + coding |

Small compared to 01.02's 6h ensemble; negatives are easier to simulate.

---

## Results & Findings

*Not yet run. Will be populated after the ensemble + analysis complete.*

Expected structure (placeholder):

- **Rejection matrix** — the filled table, with numerical failure distances where possible.
- **Overlay plots** per signature showing natural vs each regime.
- **Redundancy / uniqueness analysis** — cluster signatures by their rejection pattern; identify which ones carry unique information.
- **Weakest signatures** — any signature that rejects fewer than 3 of the 4 regime types is flagged as needing strengthening or replacement.

---

## Decisions Propagated (anticipated)

After this experiment, we expect to have:

1. **The rejection matrix** as a reusable reference — when any downstream experiment reports a signature failure, this matrix interprets what it means.
2. **Signature-confidence levels** — each signature gets a classification of "strong discriminator" / "weak discriminator" / "redundant with X." Informs how much weight to give each when combining signatures into a regime claim.
3. **Minimum sufficient signature set** — the smallest set of signatures that uniquely classifies all four regime types + natural SOC. Useful for Phase 3 when governance data has signature availability gaps (can we still make a claim if only 3 of 6 signatures are measurable?).
4. **Failure mode catalog** — qualitative notes on *how* each regime fails each signature. Lets us distinguish "distribution is exponential not power-law" from "distribution is power-law but with wrong exponent."

---

## Open Questions

1. **Poisson lattice layering.** Should we run Poisson events on a lattice (so we can measure G(r) and compare directly) or keep it purely statistical? Lattice-layered Poisson is more comparable to SOC; pure statistical is cleaner. Probably do both as subvariants of Regime 1.

2. **Supercritical safety cap.** At what `max_avalanche_size` do we halt? 10·L² is conservative. If most events hit the cap, we're measuring the cap rather than the dynamics. Sensitivity analysis during the `:explore` phase.

3. **ε sweep granularity for subcritical.** Is ε ∈ {0.01, 0.05, 0.10} enough? Might want ε = 0.001 to see the "nearly-SOC" boundary — where the rejection becomes marginal. If budget allows, add ε = 0.001 and ε = 0.5 for the full range.

4. **Relationship to Exp 05.** Exp 05 (Suppression/Amplification) has Models D (genuine subcritical) and E (genuine supercritical) as controls for the distortion experiments. Is there overlap/duplication? Answer: Exp 05 runs Models D/E on BTW only for distortion-control purposes; Exp 01.04 runs them on both BTW and Manna as rejection-battery validation. Same mechanism, different scope. If we run 01.04 first, Exp 05 can reuse the data.

5. **Should the rejection matrix be a "credibility score" rather than binary?** Each cell could carry a p-value or signal-to-noise ratio instead of ✓/✗. More informative; more complex. Start binary, upgrade to quantitative if the binary matrix proves too coarse.

---

## References

### Primary sources

- **Clauset, A., Shalizi, C. R., Newman, M. E. J.** (2009). "Power-law distributions in empirical data." *SIAM Review* 51, 661. Log-likelihood-ratio test for power-law vs exponential — the core of Poisson rejection.
- **Vespignani, A., Zapperi, S.** (1997). "Order parameter, scaling and universality in non-abelian sandpile models." *Phys. Rev. Lett.* 78, 4793. Subcritical sandpile with bulk dissipation.
- **Dickman, R., Muñoz, M. A., Vespignani, A., Zapperi, S.** (2000). "Paths to self-organized criticality." *Braz. J. Phys.* 30, 27. Fixed-energy vs driven; subcritical and supercritical regimes.

### Methodology

- **Michiels van Kessenich, L., Bohlin, L., de Arcangelis, L.** (2010). Activity-conditional branching ratio — the primary test for cascade marginality; should reject both sub- and supercritical cleanly.

### Textbook

- **Pruessner, G.** (2012). *Self-Organised Criticality.* Cambridge. Chapter on model variants and their diagnostics.

---

## Dependencies

- Exp 01.01 (BTW) validated ensemble as positive control
- Exp 01.02 (Manna) validated ensemble as positive control
- Simulator infrastructure (`sandpile.jl`, `manna_sandpile.jl`, `streaming.jl`, `analysis.jl`) extended with subcritical/supercritical kwargs
- New: `negatives.jl` for Poisson synthetic generation
- Julia packages: same as Exp 01.01/01.02

---

## Next Experiments

This experiment closes the 01 series (sandpile signature validation, both by positive detection and by negative rejection). Next:

**Experiment 02: Synthetic Percolation** — see [`02_percolation.md`](02_percolation.md). Prerequisite for activation-threshold and absorbing-barrier experiments.

**Experiment 01.03: Manna + Overtopping** — see [`01_03_manna_overtopping.md`](01_03_manna_overtopping.md). Can run in parallel with 01.04 since they don't share infrastructure.

**Future validation-of-validation:** Once Exp 05 (Suppression/Amplification) runs, compare its Models D/E rejection results against 01.04's rejection results as a double-check — same physical regime, different experimental framings.

---

## Related documents

- [`01_01_btw_sandpile.md`](01_01_btw_sandpile.md) — positive-control reference for BTW
- [`01_02_manna_sandpile.md`](01_02_manna_sandpile.md) — positive-control reference for Manna
- [`05_suppression_amplification.md`](05_suppression_amplification.md) — Models D/E there are the same physical regimes; complementary test scope (distortion control vs rejection validation)
- [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md) — detection-category specification. The rejection matrix tells us how to distinguish natural SOC from the different failure modes.
- [`../ideas/real_data_considerations.md`](../ideas/real_data_considerations.md) — Under-reporting artifacts. The rejection matrix from 01.04 is part of the disambiguation toolkit.
