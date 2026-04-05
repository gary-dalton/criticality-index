# Summary for New Chat

**Project:** criticality-index — Quality of Government (QoG) modeling, Phase 0  
**Last updated:** Jan 2025

---

## Project Context

- **Goal:** Phase 0 of a QoG modeling project: ingest three metadata CSVs, normalize schemas, run a strict 3-way isomorphism check, and produce a unified enriched metadata dictionary.
- **Stack:** Julia 1.10+, DataFrames, CSV. Jupyter notebooks / interactive REPL.
- **Principle:** Raw data immutability (work on copies).

---

## Key File: `work/phase0/functions/qog_metadata_enrichment.jl`

**Purpose:** Phase 0 metadata pipeline: ingestion → normalization → ID alignment → isomorphism validation → unification & enrichment.

**Inputs (constants at top):**
- `PATH_STATA_SLUGS` = `data/qog_metadata_manifest.csv` — [variable, label, prefix]
- `PATH_PDF_SLUGS` = `data/qog_slugs.csv` — [slug, prefix, description, type, provenance]
- `PATH_ARROW_SLUGS` = `data/ggis_arrow_slugs.csv` — [slug, prefix, type]

**Output:** `PATH_METADATA_ENRICHED` = `data/qog_metadata_enriched.csv` — [slug, prefix, label, description, type, provenance]

**Pipeline (4 steps):**
1. **`ingest_and_normalize()`** — Load CSVs, lowercase columns and slug/prefix, rename Stata `variable` → `slug`, apply `SLUG_CORRECTIONS`.
2. **`align_id_variables!(stata_df, pdf_df, arrow_df)`** — Stata: add `ident_` prefix where needed; PDF: add ID rows from Arrow.
3. **`validate_isomorphism(stata_df, pdf_df, arrow_df)`** — Filter Arrow by `EXCLUDED_PREFIXES`, build (slug, prefix) sets, apply `DEPRECATED_SLUGS` / `UNDOCUMENTED_SLUGS`, compare; on failure print diagnostics and throw.
4. **`unify_and_enrich(stata_df, pdf_df, arrow_df)`** — Outer join on slug, fill ggis_ slugs from `GGIS_METADATA`, finalize schema.

**Main entry:** `enrich_metadata(; save=true, output_path=PATH_METADATA_ENRICHED)` — runs all 4 steps and optionally writes CSV.

**Helpers:** `quick_check()`, `inspect_exceptions()`, `show_usage()`.

**Exception constants:** `EXCLUDED_PREFIXES`, `SLUG_CORRECTIONS`, `DEPRECATED_SLUGS`, `UNDOCUMENTED_SLUGS`, `GGIS_METADATA`, `ID_VARIABLES` — used to handle known mismatches and custom slugs.

---

## Julia Docstring Convention (Required for This Project)

**Constants:** One-line triple-quoted docstring immediately above the constant.
```julia
"""Brief description of the constant's purpose."""
const CONSTANT_NAME = value
```

**Functions:** All four sections are **required** — no function signature inside the docstring; start with a brief summary.

```julia
"""
Brief one-line summary.

Arguments:
- arg1: Description
- (or "None" if no arguments)

Returns:
- return_value: Description

Rules:
- Important point 1
- Important point 2

Usage:
    example_call()
    another_example()
"""
function function_name(args...)
```

- **Arguments** — list every argument (or state "None").
- **Returns** — what the function returns.
- **Rules** — behavior, invariants, implementation notes.
- **Usage** — one or more example calls (indented 4 spaces).

---

## Related Files

- **`work/phase0/functions/qog_augmented_standard.jl`** — Augmentation/standardization; defines `PATH_TS_RAW`, `PATH_DATA_DIR`, `PATH_MANIFEST_RESULT`, `convert_csv_to_arrow`, etc. Docstrings there follow the same style (brief summary, no signature line, structured sections).
- **`work/data/`** — CSVs and Arrow files; paths in enrichment script are relative (e.g. from `work/` when run from notebook).
- **`document/internal/ai-instructions.md`** — Cross-phase collaboration rules.
- **`document/publication/`** — `soc_model_architecture.md`, `soc_companion_guide.md`, `grounding.md`, `order.md`.
- **`work/phase0/document/`** — `qog_augmentation_guide.md`, etc.

---

## Conventions Established in This Chat

1. **Docstrings:** Required sections for functions are Arguments, Returns, Rules, Usage. No function signature on the first line of the docstring.
2. **Constants:** Each has its own triple-quoted docstring above it (no inline-only comments for the main path/control constants).
3. **Phase 0 scope:** Enrichment script is ingestion + normalization + validation + unification only; no temporal/penetration logic in the main pipeline.

Use this summary to onboard a new chat quickly.
