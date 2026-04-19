# Experiment validation workflow

The validation experiments (BTW, Manna, percolation, …) share a three-phase workflow: explore in Jupyter, run ensembles in a headless Julia container, analyze in Jupyter. This document explains the what and how.

---

## Three phases

### 1. Explore (Jupyter, `MODE = :explore`)

For iterating on new diagnostics, testing simulator changes, sanity checks.

- Small in-kernel runs (one seed, `L = 64` or smaller, often reduced `N_record`).
- `results[L]` carries raw `AvalancheRecord`s so mid-development diagnostics that need `wave_profile` data work naturally.
- The notebook does not load from disk in this mode — it simulates live.
- Memory stays bounded; the Jupyter kernel can be restarted without losing days of compute.

Open `work/exp01_01_btw_sandpile.ipynb`, set `MODE = :explore` in the Mode cell near the top, run top-to-bottom.

### 2. Ensemble (headless Julia container)

For the long batch runs that produce publication-grade data.

- Runs outside Jupyter entirely — in a dedicated Julia 1.12.3 container defined by `docker-compose.julia.yml`.
- One seed's avalanche catalog in memory at a time; wave-profile data summarized and discarded per seed.
- Per-seed Arrow files written under `work/data/<experiment>/`.
- Resumable: re-running skips seeds whose summary file already exists.
- Progress logged to stdout and `run.log`.

Start the container (one-time per session):
```bash
docker compose -f docker-compose.julia.yml up -d
```

Shell in:
```bash
docker compose -f docker-compose.julia.yml exec julia bash
```

Run the BTW ensemble with defaults (`DEFAULT_L_SEEDS`, `DEFAULT_N_RECORD`, `DEFAULT_OUT_DIR`):
```bash
root@julia_compute:/work# julia --project experiments/validation/run_btw_ensemble.jl
```

Or a custom smoke test via one-liner:
```bash
root@julia_compute:/work# julia --project -e '
    include("experiments/validation/load_validation.jl")
    run_btw_ensemble(L_seeds=Dict(64=>3), n_record=10_000,
                     out_dir="data/exp01_01_test")'
```

Interactive REPL for ad-hoc work:
```bash
root@julia_compute:/work# julia --project
```

Stop the container when done:
```bash
docker compose -f docker-compose.julia.yml down
```

Either container (Jupyter or this one) can install Julia packages and the other will see them — they share the depot at host path `/home/gary/projects/julia_depot`.

### 3. Analyze (Jupyter, `MODE = :analyze`)

For producing the final power-law fits, finite-size extrapolations, and ensemble error bars.

- Reads the per-seed Arrow files produced in phase 2 via `load_ensemble`.
- `results[L]` carries summary vectors, diagnostics, and micro-stats — not raw `wave_profile`s (those are discarded in phase 2). Cells that would have needed `wave_profile` read pre-binned equivalents from `micro_stats/`.
- Power-law fits use informed `xmin` choices per L (manual `xmin=5` for scaling regime; auto only at L ≥ 1024). Per-seed fits are pooled for ensemble error bars.

In the notebook, set `MODE = :analyze` in the Mode cell. Section 2 loads from `ENSEMBLE_DATA_DIR` (default `data/exp01_01`). Sections 3 onward work uniformly across both modes.

---

## Arrow file layout

For BTW at `work/data/exp01_01/` (pattern replicated for other experiments):

```
data/exp01_01/
  summaries/summary_L{L}_seed{S}.arrow
      one row per avalanche; columns: L, seed, idx, size, duration, area, max_extent

  diagnostics/diag_L{L}_seed{S}.arrow
      single-row per-seed scalar diagnostics:
      beta_high, hurst_H, excess_kurtosis_raw, branching_plateau_mean,
      n_burnin_grains, converged, wallclock_s, n_avalanches, n_nonempty

  micro_stats/micro_L{L}_seed{S}.arrow
      long-form (L, seed, kind, x, y) with kind in {"psd", "bx", "rs"};
      psd: log-binned microscopic PSD (freq_center, psd_mean)
      bx:  activity-dependent branching ratio (activity_level, b_of_x)
      rs:  Hurst R/S points (scale, rs_value)

  heights/height_L{L}_seed1.arrow
      long-form final lattice heights; written only for seed 1 of each L
      so spatial correlation can be computed in analysis mode

  manifest_L{L}.arrow
      aggregated per-seed diagnostics rows for quick overview of the ensemble
      (one row per seed for each L)

  waves/waves_L1024_seed1.arrow
      raw per-wave topplings for L=1024 seed 1 ONLY
      columns: avalanche_idx, wave_idx, topplings (~500 MB)
      kept for ad-hoc inspection and as a reproducibility check

  run.log
      line-per-seed progress log appended across runs
```

---

## Extending to a new experiment

Copy the pattern for a new validation experiment (e.g., Manna, percolation):

1. Add the simulator to `work/experiments/validation/` (e.g., `manna_sandpile.jl`) and register it in `load_validation.jl`.

2. Write a runner wrapper modeled on `run_btw_ensemble.jl`:
   - Define experiment-specific constants (analog of `DEFAULT_L_SEEDS`).
   - Reuse most of `streaming.jl` — `summarize_seed`, `write_seed`, `log_progress` are model-agnostic because they consume an `AvalancheRecord`-like catalog.
   - Add model-specific writer logic only if the record struct differs.

3. Put the notebook at `work/exp01_02_manna_sandpile.ipynb` (or similar), copied from `exp01_01` with the simulator call swapped.

4. Invoke from the Julia container:
   ```bash
   julia --project experiments/validation/run_manna_ensemble.jl
   ```

The storage layout, MODE split, and container setup are unchanged.

---

## Recovery and rerunning

### Skip vs. rerun seeds

`run_btw_ensemble` checks for `summaries/summary_L{L}_seed{S}.arrow` before running each seed. If it exists, the seed is skipped entirely.

To force a rerun of one seed: delete its summary file.
```bash
rm work/data/exp01_01/summaries/summary_L256_seed7.arrow
```
Re-run the ensemble; seed 7 at L=256 will be recomputed. Other seeds remain skipped.

To force a full rerun: delete the whole `data/exp01_01/` directory (or pick a new `out_dir`).

### Validating a partial run

After a partial run (e.g., only L=128 completed), the manifest at `manifest_L128.arrow` aggregates everything so far. Open in Jupyter:
```julia
using Arrow, DataFrames
DataFrame(Arrow.Table("data/exp01_01/manifest_L128.arrow"))
```

Check `converged` column — every seed should be true. If any is false, delete those seeds' summary files and rerun.

### Storage safety

The ensemble data lives under `work/data/` which is gitignored. It is NOT under version control. Back it up separately if the run was expensive. For a single overnight BTW run that's ~1-2 GB; keep a snapshot on the host filesystem outside Docker volumes until the analysis is finalized.

---

## Common gotchas

- **Jupyter and Julia container both running, both try `Pkg.add`.** Race on the shared depot's `compiled/` cache. Install packages from only one container at a time.
- **Julia version drift.** Both containers must run 1.12.3 (same minor version minimum). If they diverge, precompilation gets rebuilt — slow but not incorrect.
- **Stopping Jupyter while kernel holds large data.** The kernel's memory is lost. Always run ensembles in the Julia container, not in Jupyter, so stopping Jupyter is consequence-free.
- **Auto-xmin Clauset fits.** For BTW, auto-xmin only finds the scaling regime at L ≥ 1024. At smaller L use `xmin=5` manually. Manna and other simply-scaling systems don't have this problem.
