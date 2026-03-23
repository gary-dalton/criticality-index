# Criticality Index — Project Context

A multi-phase research project applying Self-Organized Criticality (SOC) theory to Quality of Government (QoG) data to identify empirical signatures of criticality in governance systems. Written in Julia, run in JupyterLab via Docker.

## Current Phase
**Phase 1: Model Definition** — Complete. Country missingness scoring (10 statuses), slug reclassification (clean denominator, UN vectors), and slug clustering (9 labeled country-profile clusters) all done. Ready for Phase 2. See `.claude/phases/` for details.

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

## Collaboration
- Plan first, then confirm before taking action
- See `document/ai-instructions.md` for full collaboration style guide
- Challenge ideas when they violate fundamental principles — domain precision over politeness

## Key Documentation
- `document/ai-instructions.md` — Technical collaboration rules (cross-phase)
- `work/phase0/document/grounding.md` — 5 empirical signatures of criticality
- `work/phase0/document/order.md` — Order/damping subsystem
- `work/phase0/document/qog_augmentation_guide.md` — Full preprocessing pipeline
- `work/phase0/document/new-chat-summary.md` — Project onboarding summary

## Directory Structure
- `work/phase0/` — Phase 0 functions and documents (preprocessing)
- `work/phase1/` — Phase 1 functions (model definition, slug clustering)
- `work/data/` — Data files (gitignored)
- `work/p00_*.ipynb` — Phase 0 notebooks, `work/p01_*.ipynb` — Phase 1 notebooks
- `document/` — Cross-phase documentation
- `work/test/` — Test suite (all phases); run with `docker compose exec -w /home/jovyan/work jupyter julia test/runtests.jl`

## Phase Files
Phase-specific context lives in `.claude/phases/`:
- `phase0-preprocessing.md` — Preprocessing data files, metadata, and adjuncts (complete)
- `phase1-model-definition.md` — Model Definition — missingness, reclassification, clustering (complete)
- **Next:** Phase 2 — Variable Mapping (Slug Selection)
- `phase2-variable-mapping.md` — Variable Mapping (Slug Selection)
- `phase3-locked-analysis.md` — Locked Analysis
- `phase4-synthesis.md` — Synthesis & Writing
