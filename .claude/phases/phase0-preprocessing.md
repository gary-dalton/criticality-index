# Phase 0: Preprocessing

**Objective:** Preprocessing the data files and managing metadata and adjuncts.

**Data Handling:** Do not modify source data; use loaders and enhancers.

**Status:** Complete. All preprocessing, metadata enrichment, and geographic mapping done. 6,204 tests passing. Clustering moved to Phase 1.

## Completed
- QoG data loading & Arrow conversion (`load_augmented_qog()`)
- Identity promotion: raw columns → `ident_` namespace
- Historical country code rescue (VDR, XTI, DDR, etc.)
- Region standardization (QoG 10-region taxonomy + imputation)
- UN geographic sub-region integration
- 3-way metadata unification: Stata + PDF + Arrow isomorphism validation
- Temporal enrichment: birth/death years, 6 temporal profiles (anchor, modern, current, experimental, legacy, historical)
- Geographic enrichment: population-weighted penetration, regional coverage, 3 geographic profiles (global, regional, other)
- PDF codebook parsing: slug extraction, provenance classification (PHYSICAL, SURVEY, EVENT/FACTUAL, IMPUTED, EXPERT, OFFICIAL)

## Legacy (Reference Only)
- `cluster_analysis.jl` and `xcluster_analysis.jl` — previous clustering approach (cosine similarity, ht_region-based). Superseded by Phase 1 slug clustering (Jaccard, binary presence).

## Key Modules
- `work/phase0/functions/qog_augmented_standard.jl` — Main loader & standardization
- `work/phase0/functions/qog_metadata_join.jl` — 3-way metadata unification
- `work/phase0/functions/enrich_metadata.jl` — Temporal & geographic enrichment
- `work/phase0/functions/qog_pdf_extract.jl` — PDF codebook parsing
- `work/phase0/functions/cluster_analysis.jl` — Variable clustering
- `work/phase0/functions/xcluster_analysis.jl` — Experimental clustering variant
- `work/phase0/functions/grounding.jl` — SOC validation functions (prototype)
- `work/phase0/functions/order.jl` — Safety score sensors (prototype)

## Key Documents
- `work/phase0/document/qog_augmentation_guide.md` — Full preprocessing pipeline
- `work/phase0/document/new-chat-summary.md` — Project onboarding summary
- `work/phase0/document/grounding.md` — Criticality signatures (prototype)
- `work/phase0/document/order.md` — Order/damping subsystem (prototype)

## Entry Functions
- `load_augmented_qog()` — Load full standardized dataset
- `enrich_metadata(; save=true)` — Run enrichment pipeline
- `unify_and_join()` — Merge metadata from all sources

## Pipeline Order (strict)
Ingestion → Eviction → Regional Reconstruction → Temporal Auditing

## Key Outputs
- `data/qog_metadata_enriched.csv` — Unified metadata (2,011 rows)
- `data/qog_metadata_plus2.csv` — Extended with temporal + geographic profiles
- `data/qog_std_ts_jan25.arrow` — Standardized time-series
