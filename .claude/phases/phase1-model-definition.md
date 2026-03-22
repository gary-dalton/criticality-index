# Phase 1: Model Definition (Conceptual & Mathematical)

**Objective:** Define the topology, node properties (mass/density), and edge dynamics (information flow/entropy).

**Constraint:** Open exploration. Cite theoretical principles (e.g., "Percolation Thresholds," "Shannon Entropy") or QoG variable definitions.

**Data Handling:** Cite Variable Definitions/Codebooks. Do not modify source data.

**Status:** In progress — slug clustering and country missingness scoring implemented. Next: examine results, reduce slugs for Phase 2.

## Slug Clustering (Implemented)

Grouping slugs by country coverage patterns using Jaccard similarity on binary presence matrices. This determines which sets of variables act upon similar sets of countries — foundational for model topology.

- **Module:** `work/phase1/functions/slug_clustering.jl`
- **Loader:** `work/phase1/functions/load_phase1.jl`
- **Notebook:** `work/p01_01_slug_clustering.ipynb`
- **Approach:** Binary presence (density-thresholded), Jaccard similarity, label propagation clustering
- **Key output:** `data/slug_clusters.csv` — slug-to-cluster assignments with labels

Configurable dials:
- `presence_min_pct` (default 0.10) — minimum reporting density per (slug, country)
- `presence_max_pct` (default 0.95) — upper bound for flagging near-global slugs
- `min_country_coverage` (default 0.05) — slug must cover this fraction of countries
- `k` (default 20) — top-k Jaccard neighbors
- `min_sim` (default 0.10) — minimum Jaccard to create edge

## Country Missingness Scoring (Implemented)

Temporal missingness scoring per (country, year) relative to UN subregion peers. Classifies each country-year as dissolved, microstate, failed, degraded, reporting, or strong.

- **Module:** `work/phase1/functions/country_missingness.jl`
- **Notebook:** `work/p01_02_country_missingness.ipynb`
- **Key output:** `data/country_missingness_flags.csv` — ggis_rowid-keyed status flags
- **Also produces:** Revised slug penetration with failed/dissolved/micro excluded from denominator

Key constants: DISSOLVED_STATES (DDR, CSK, YUG, USSR, YMD, Tibet), microstate <100K pop, failed <40% coverage + 20ppt below peers, degraded = 15ppt drop in rolling 3-year window.

## Next Steps

1. Run missingness notebook — examine country status classifications
2. **Re-run clustering with filtered country set** — exclude failed/dissolved/micro countries from the presence matrix for cleaner clusters
3. Reduce slugs for Phase 2: globals + high-penetration (revised denominator)

## Findings Document

`work/phase1/document/slug_clustering_findings.md` — cluster types, ht_region alignment analysis, dial sensitivity.

## Theoretical Foundation
Five empirical signatures of criticality (see `work/phase0/document/grounding.md`):
1. Power-law distribution of events
2. Diverging correlation length across sectors
3. Scale invariance (local vs national governance)
4. Fractal structure (future — spatial data)
5. No characteristic event size (fat-tailed distributions)

## Prototyped Validation Functions
In `work/phase0/functions/grounding.jl`:
- `validate_power_law()` — α near 1.0 (scale-free)
- `validate_correlation_divergence()` — ρ > 0.70 (coupling)
- `validate_scale_invariance()` — Similarity > 0.85
- `validate_event_scaling()` — Kurtosis > 1.5

## Dependencies
- Requires Phase 0 preprocessing complete (data loaded, metadata enriched)
- Variable selection feeds into Phase 2

## Key Reference
- `work/phase0/document/grounding.md` — Full theoretical grounding
- `work/phase0/document/order.md` — Order/damping subsystem (safety sensors, lattice failure multiplier)
