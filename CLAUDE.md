# Criticality Index — Project Context

A multi-phase research project applying Self-Organized Criticality (SOC) theory to Quality of Government (QoG) data to identify empirical signatures of criticality in governance systems. Written in Julia, run in JupyterLab via Docker.

## Current Phase
**Phase 1: Slug Classification** — Complete. Country missingness scoring (10 statuses), slug reclassification (clean denominator, UN vectors), and slug clustering (9 labeled country-profile clusters) all done. **Phase 0b: Extended Preprocessing** — Complete. Six external datasets acquired, explored, converted to Arrow (EM-DAT, DOSE, SHDI, Laeven & Valencia, CEPII GeoDist, CEPII Gravity). **Phase 1b: Structural Integration** — In progress. Master country reference built (`ggis_country_master.arrow`). Coverage matrix and edge consolidation next. **Phase 2: Variable Mapping** — In progress. Model architecture, companion guide, slug selection strategy. See `.claude/phases/` for details.

## Conventions

**Docstrings (mandatory):** 4 sections — Arguments, Returns, Rules, Usage. No function signature on first line. Constants get one-line triple-quoted docstring above.

**Namespace (triple-tier prefix schema):**
- `ident_` — Topological coordinates (identity; protected namespace)
- `ggis_` — Operational intelligence (internal quality gates)
- `[source]_` — Analytical sensors (e.g., `wdi_`, `vdem_`, `who_`)

**Data rules:**
- Raw inputs are never modified; all transforms return new DataFrames
- Collisions are flagged (`ggis_spine_collision`), never deleted
- Always use `coalesce()` when filtering columns with `missing` values
- `const` declarations require kernel restart after modification
- Verify each pipeline step before proceeding to the next

**Documentation placement (three audiences: academics, general public, AI training corpus):**
- `document/publication/` — Reader-facing, cross-phase docs. Require Hugo/Docsy YAML front matter (`title`, `linkTitle`, `description`, `author`, `date`, `keywords`, `include_toc`, `draft`). Each doc must open with a 2–3 sentence abstract.
- `document/internal/` — AI-agent and developer continuity docs (ai-instructions, onboarding).
- `work/phaseN/document/` — Phase-specific implementation specs, function contracts, research notes. Stay near their code.
- Publication target: werkspc.com via Hugo/Docsy (separate repo: `gary-dalton/public-documents`). Front matter must be Docsy-compatible.

## Collaboration
- Plan first, then confirm before taking action
- See `document/internal/ai-instructions.md` for full collaboration style guide
- Challenge ideas when they violate fundamental principles — domain precision over politeness

## Key Documentation
- `document/publication/soc_model_architecture.md` — 6-component deterministic SOC model definition
- `document/publication/soc_companion_guide.md` — Glossary, primers, physics-analog mappings
- `document/publication/grounding.md` — 5 empirical signatures of criticality
- `document/publication/order.md` — Order/damping subsystem
- `document/internal/ai-instructions.md` — Technical collaboration rules (cross-phase)
- `document/internal/new-chat-summary.md` — Project onboarding summary
- `work/phase0/document/qog_augmentation_guide.md` — Full preprocessing pipeline

### Validation experiments framework (parallel track)
- `work/experiments/validation/WORKFLOW.md` — Three-phase workflow: explore (notebook) → ensemble (headless) → analyze (headless + notebook fast-path)
- `work/experiments/ideas/overtopping.md` — Primary mechanism for suppressed-release SOC (σ field, damage, recovery)
- `work/experiments/ideas/liquefaction.md` — Mirror mechanism for amplified-cascade SOC
- `work/experiments/ideas/distorted_soc_signatures.md` — Detection catalog (CSOC-like / ISOC-like signature bundles, adjective-form)
- `work/experiments/ideas/energy_accounting.md` — Two-reservoir PE/KE/DE framework, percolation extension
- `work/experiments/ideas/real_data_considerations.md` — Under-reporting and other real-data artifacts that mimic distorted signatures

## Directory Structure
- `work/constants.jl` — Project-wide constants (TEMPORAL_FLOOR, coverage thresholds)
- `work/phase0/` — Phase 0 functions and documents (preprocessing)
- `work/phase00b/` — Phase 0b functions (extended preprocessing: EM-DAT, DOSE, SHDI, CEPII, Laeven & Valencia)
- `work/phase1/` — Phase 1 functions (slug classification, clustering)
- `work/phase01b/` — Phase 1b functions (structural integration: master country reference, coverage matrix)
- `work/phase2/` — Phase 2 functions and documents (model architecture, slug strategy)
- `work/experiments/` — SOC validation experiments (parallel to main phases)
  - `work/experiments/ideas/` — Theoretical framework (mechanisms, signatures, methodology)
  - `work/experiments/validation/` — Simulators + diagnostics + headless runners + experiment design docs
  - `work/exp01_01_btw_sandpile.ipynb`, `work/exp01_02_manna_sandpile.ipynb` — Validation notebooks
- `work/archive/docs/` — Superseded framework docs (CSOC/ISOC original versions)
- `work/data/` — Data files (gitignored; includes `exp01_01/`, `exp01_02/` ensemble + analysis Arrow outputs)
- `work/p00_*.ipynb` — Phase 0 notebooks, `work/p00b_*.ipynb` — Phase 0b, `work/p01_*.ipynb` — Phase 1
- `work/exp*_*.ipynb` — Validation experiment notebooks
- `document/publication/` — Reader-facing cross-phase docs (architecture, companion, grounding, order)
- `document/internal/` — AI-agent and developer continuity docs
- `work/test/` — Test suite (all phases); run with `docker compose exec -w /home/jovyan/work jupyter julia test/runtests.jl`

## Headless Julia container
For long-running simulations and headless analysis pre-compute (won't hold data in a Jupyter kernel), use the dedicated headless container:
```sh
docker compose -f docker-compose.julia.yml run --rm julia \
    julia --project=. experiments/validation/run_manna_ensemble.jl
```
Pattern: `run_<model>_ensemble.jl` produces per-seed Arrow files; `run_<model>_analysis.jl` produces pooled analysis Arrow files. All resumable. See the Validation framework docs above.

## Phase Files
Phase-specific context lives in `.claude/phases/`:
- `phase0-preprocessing.md` — Preprocessing data files, metadata, and adjuncts (complete)
- `phase0b-extended-preprocessing.md` — Extended preprocessing: EM-DAT, DOSE, SHDI, CEPII (complete)
- `phase1-model-definition.md` — Slug Classification — missingness, reclassification, clustering (complete)
- `phase1b-structural-integration.md` — Structural Integration: master country reference, coverage matrix, edge consolidation (in progress)
- **Next:** Phase 2 — Variable Mapping (Slug Selection)
- `phase2-variable-mapping.md` — Variable Mapping (Slug Selection)
- `phase3-locked-analysis.md` — Locked Analysis
- `phase4-synthesis.md` — Synthesis & Writing
