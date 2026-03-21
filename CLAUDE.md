# Criticality Index — Project Context

A multi-phase research project applying Self-Organized Criticality (SOC) theory to Quality of Government (QoG) data to identify empirical signatures of criticality in governance systems. Written in Julia, run in JupyterLab via Docker.

## Current Phase
**Phase 0: Preprocessing** (advanced) — Data loading, metadata enrichment, and geographic mapping are complete. Variable clustering is in active development. See `.claude/phases/` for phase-specific context.

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
- `work/phase0/` — All Phase 0 functions and documents
- `work/data/` — Data files (gitignored)
- `work/p00_*.ipynb` — Phase 0 notebooks (pNN_SS_name convention)
- `document/` — Cross-phase documentation
- `work/test/` — Test suite (all phases); run with `docker compose exec jupyter julia work/test/runtests.jl`

## Phase Files
Phase-specific context lives in `.claude/phases/`:
- `phase0-preprocessing.md` — **[CURRENT]** Preprocessing data files, metadata, and adjuncts
- `phase1-model-definition.md` — Model Definition (Conceptual & Mathematical)
- `phase2-variable-mapping.md` — Variable Mapping (Slug Selection)
- `phase3-locked-analysis.md` — Locked Analysis
- `phase4-synthesis.md` — Synthesis & Writing
