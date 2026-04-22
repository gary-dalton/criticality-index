# Experiments — Index

Parallel track to the main QoG phases. Validation experiments on synthetic SOC systems, designed to test and calibrate the signature battery on systems where ground truth is known before applying to governance data.

Two parallel subdirectories:

- [`validation/`](validation/) — experiment designs, simulators, diagnostics, headless runners, and per-experiment results documents
- [`ideas/`](ideas/) — theoretical framework: mechanisms, detection signatures, energy accounting, real-data methodology

Notebooks are at the repo's `work/` root with the `exp*_*.ipynb` pattern.

---

## Validation experiments

Design, run, analyze. Each doc includes Purpose, Design, Implementation, Results & Findings (when run), Decisions propagated, and Next Experiment.

| # | Experiment | Design doc | Notebook | Status |
|---|-----------|------------|----------|--------|
| 01.01 | **BTW sandpile** — canonical SOC validation; discovered auto-xmin failure under BTW multiscaling | [`validation/01_01_btw_sandpile.md`](validation/01_01_btw_sandpile.md) | [`work/exp01_01_btw_sandpile.ipynb`](../exp01_01_btw_sandpile.ipynb) | Done (α∞ = 1.2000 ± 0.0004) |
| 01.02 | **Manna sandpile** — C-DP universality; validates auto-xmin on simple-scaling substrate; establishes bracketed-reporting rule | [`validation/01_02_manna_sandpile.md`](validation/01_02_manna_sandpile.md) | [`work/exp01_02_manna_sandpile.ipynb`](../exp01_02_manna_sandpile.ipynb) | Done (α∞ ∈ [1.265, 1.278]) |
| 01.03 | **Negative controls** — validation by counter-example. Rejection tests on Poisson, bulk-dissipation subcritical, and excess-distribution supercritical on both BTW and Manna substrates. Builds rejection matrix for signature discrimination. | [`validation/01_03_negatives.md`](validation/01_03_negatives.md) | — | Designed |
| 01.04 | **Manna + overtopping** — threshold-elevation baseline (Model B), structural-integrity damage (Model C); locates absorbing barrier in (T, α, recovery_rate) phase space | [`validation/01_04_manna_overtopping.md`](validation/01_04_manna_overtopping.md) | — | Designed |
| 01.05 | **Manna + liquefaction** — ISOC-side corollary to overtopping. π pore-pressure analog, cyclic-driving amplification, effective-threshold lowering, post-event densification. Mirror of 01.04 on the amplification side. | [`validation/01_05_manna_liquefaction.md`](validation/01_05_manna_liquefaction.md) | — | Skeleton |
| 02 | **Synthetic percolation** — validate p_c measurement tools, cluster-size distribution, fractal dimension on random lattices | [`validation/02_percolation.md`](validation/02_percolation.md) | — | Designed |
| 03 | **Activation threshold (sandpile on percolation lattice)** — find p* where SOC emerges; test whether activation energy has a quantitative definition | [`validation/03_activation_threshold.md`](validation/03_activation_threshold.md) | — | Designed |
| 04 | **Absorbing barrier (overloaded joined system)** — push sandpile-on-lattice past criticality; find fracture/ruin boundary | [`validation/04_absorbing_barrier.md`](validation/04_absorbing_barrier.md) | — | Designed |
| 05 | **Suppression, amplification, distinguishability** — apply suppression (CSOC-like) and amplification (ISOC-like) mechanisms on BTW substrate; test signature-bundle discriminability | [`validation/05_suppression_amplification.md`](validation/05_suppression_amplification.md) | — | Designed |
| 06 | **Coupled SOC systems** — energy leakage between lattices; test whether coupling alone produces ISOC-like signatures without explicit amplification | [`validation/06_coupled_soc.md`](validation/06_coupled_soc.md) | — | Designed |

---

## Ideas / theoretical framework

Background theory and methodology that cuts across experiments.

| Document | Purpose |
|----------|---------|
| [`ideas/overtopping.md`](ideas/overtopping.md) | Primary mechanism for **suppressed-release** SOC: σ integrity field, flux-driven damage, slow recovery. Concrete realization of the absorbing-barrier concept. |
| [`ideas/liquefaction.md`](ideas/liquefaction.md) | Mirror mechanism for **amplified-cascade** SOC. Symmetric counterpart to overtopping. |
| [`ideas/distorted_soc_signatures.md`](ideas/distorted_soc_signatures.md) | Detection catalog. Defines **CSOC-like** and **ISOC-like** signature bundles as adjective-form observational categories. The empirical evidentiary standard for regime claims. |
| [`ideas/energy_accounting.md`](ideas/energy_accounting.md) | Two-reservoir framework: grain PE/KE/DE + structural PE/KE/DE. KE as the coupling channel. Percolation extension (per-bond flux, dynamic topology). |
| [`ideas/real_data_considerations.md`](ideas/real_data_considerations.md) | Governance-data artifacts that mimic distorted signatures (under-reporting first; placeholders for time grids, categorical vars, etc.). Model F proposal to validate the battery under censoring. |
| [`ideas/architecture_mapping.md`](ideas/architecture_mapping.md) | Links the experiments framework to the SOC Model Architecture (C_d, E, O, etc.). |
| [`ideas/falsifiability_requirements.md`](ideas/falsifiability_requirements.md) | Methodological requirements for claims to be falsifiable. |
| [`ideas/feasibility.md`](ideas/feasibility.md) | Scoping of what's feasible to test with available tooling/data. |
| [`ideas/soc_study_guide.md`](ideas/soc_study_guide.md) | Introductory guide to SOC concepts and terminology. |
| [`ideas/energy_depletion_percolation_research_paths.md`](ideas/energy_depletion_percolation_research_paths.md) | Literature map for the "p_c as termination condition" proposition. |

---

## Infrastructure

| Document | Purpose |
|----------|---------|
| [`validation/WORKFLOW.md`](validation/WORKFLOW.md) | Three-phase workflow: explore (notebook) → ensemble (headless) → analyze (headless + notebook fast-path). |
| [`validation/sandpile.jl`](validation/sandpile.jl) | BTW simulator + shared `AvalancheRecord`, `NEIGHBOR_OFFSETS_2D`, `run_avalanche!` |
| [`validation/manna_sandpile.jl`](validation/manna_sandpile.jl) | Manna simulator (parallel-wave stochastic toppling) |
| [`validation/diagnostics.jl`](validation/diagnostics.jl) | Power-law fits, PSD, branching ratio, kurtosis, R/S Hurst, inter-event |
| [`validation/streaming.jl`](validation/streaming.jl) | Per-seed Arrow I/O, `run_btw_ensemble`, `run_manna_ensemble` |
| [`validation/analysis.jl`](validation/analysis.jl) | Pooled fits, FSS extrapolation, `run_btw_analysis`, `run_manna_analysis` |
| [`validation/load_validation.jl`](validation/load_validation.jl) | Module entry point |
| [`validation/run_btw_ensemble.jl`](validation/run_btw_ensemble.jl) | Thin wrapper for headless container — Exp 01.01 ensemble |
| [`validation/run_btw_analysis.jl`](validation/run_btw_analysis.jl) | Thin wrapper — Exp 01.01 analysis pre-compute |
| [`validation/run_manna_ensemble.jl`](validation/run_manna_ensemble.jl) | Thin wrapper — Exp 01.02 ensemble |
| [`validation/run_manna_analysis.jl`](validation/run_manna_analysis.jl) | Thin wrapper — Exp 01.02 analysis pre-compute |
| [`validation/figures/`](validation/figures/) | Rendered plots from each experiment (per-experiment subdirectories) |

---

## Methodology decisions that propagate across experiments

Captured in [user's memory](../../~/.claude/projects/...) and referenced here for visibility:

- **Bracketed-xmin reporting:** for power-law α reporting, compute α_∞ at both xmin=5 and xmin=10; report the range. Never cite a single-xmin value as "the" exponent. Applies to size and duration (auto-xmin OK for area).
- **Multi-signature co-occurrence:** regime classification (natural vs CSOC-like vs ISOC-like) requires ≥ 3 independent signatures from the bundle. α alone is never sufficient.
- **Protocol matters:** driven open-boundary vs fixed-energy Manna give different stationary densities; always cite which protocol.
- **Under-reporting mimics suppression:** real-data artifacts produce low-end truncation that looks like CSOC-like signature at the α level but lacks the redistribution-dependent accompaniments (spectral knee, quasi-periodicity, non-stationary σ). Require the full bundle.
