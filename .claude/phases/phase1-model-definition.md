# Phase 1: Model Definition (Conceptual & Mathematical)

**Objective:** Define the topology, node properties (mass/density), and edge dynamics (information flow/entropy).

**Constraint:** Open exploration. Cite theoretical principles (e.g., "Percolation Thresholds," "Shannon Entropy") or QoG variable definitions.

**Data Handling:** Cite Variable Definitions/Codebooks. Do not modify source data.

**Status:** In progress — slug clustering and country missingness scoring implemented. Next: examine results, reduce slugs for Phase 2.

## Execution Order

```
p01_01 Country Missingness  →  manual review  →  p01_02 Slug Reclassification  →  p01_03 Slug Clustering
```

## Step 1: Country Missingness Scoring (Implemented)

Temporal missingness scoring per (country, year) relative to UN subregion peers. Classifies each country-year into 10 statuses.

- **Module:** `work/phase1/functions/country_missingness.jl`
- **Notebook:** `work/p01_01_country_missingness.ipynb`
- **Key output:** `data/country_missingness_flags.csv` — ggis_rowid-keyed status flags
- **Methodology:** `work/phase1/document/country_missingness_methodology.md`

10 statuses: dissolved, political_exclusion (Taiwan), self_exclusion (USSR, North Korea), nascent, collision, microstate, failed, degraded, reporting, strong.

**MANUAL GATE:** Review classifications before proceeding to Step 2.

## Step 2: Slug Reclassification (Implemented)

Recomputes slug penetration using clean denominators and temporal windows that avoid reporting lag. Classifies slugs by UN region/subregion vectors.

- **Module:** `work/phase1/functions/slug_reclassification.jl`
- **Notebook:** `work/p01_02_slug_reclassification.ipynb` (to be created)
- **Key outputs:** Revised penetration per slug, UN vectors, filtered clustering pool

Temporal windows: anchor/modern/current = mean of [now-7, now-5]; legacy = last 5 years at death. Drops experimental + historical + who_roadtrd.

## Step 3: Slug Clustering (Implemented)

Grouping slugs by country coverage patterns using Jaccard similarity on binary presence matrices.

- **Module:** `work/phase1/functions/slug_clustering.jl`
- **Notebook:** `work/p01_03_slug_clustering.ipynb`
- **Key output:** `data/slug_clusters.csv` — slug-to-cluster assignments with labels
- **Findings:** `work/phase1/document/slug_clustering_findings.md`

Re-run with filtered pool from Step 2 for topic-driven clusters (geographic noise removed).

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
