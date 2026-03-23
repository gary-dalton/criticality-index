# Phase 1: Model Definition (Conceptual & Mathematical)

**Objective:** Define the topology, node properties (mass/density), and edge dynamics (information flow/entropy).

**Constraint:** Open exploration. Cite theoretical principles (e.g., "Percolation Thresholds," "Shannon Entropy") or QoG variable definitions.

**Data Handling:** Cite Variable Definitions/Codebooks. Do not modify source data.

**Status:** Complete. Country missingness scoring, slug reclassification, and slug clustering all implemented and labeled.

## Execution Order

```
p01_01 Country Missingness  →  manual review  →  p01_02 Slug Reclassification  →  p01_03 Slug Clustering  →  interactive labeling
```

## Results Summary

### Slug Disposition (2,010 total)

| Category | Slugs | Description |
|----------|-------|-------------|
| Global (95%) | ~543 | Population-weighted ≥95% penetration |
| Global (90%) | ~24 | Population-weighted 90-95% |
| Regional/Subregional | ~239 | Geographically concentrated (EU, ESS, etc.) |
| Sparse | ~14 | Below 5% penetration |
| Dropped | ~544 | Experimental, historical, manual exclusions |
| Labeled clusters | 9 clusters | Country-profile labels assigned |
| Untagged clusters | 7 clusters | Weak cohesion, not labeled |

### Labeled Cluster Tags (Country Profiles)

| Cluster | Label | Description |
|---------|-------|-------------|
| 3 | `near_global_excl_microstates` | Covers all but microstates |
| 6 | `near_global_excl_microstates` | Same pattern, different slugs |
| 7 | `assessable_governance_institutions` | States open enough for rule-of-law assessment |
| 8 | `capable_willing_reporters` | IMF fiscal compliance reporters |
| 9 | `near_global` | Covers all but dissolved/micro/failed |
| 10 | `codifiable_electoral_machinery` | States with functioning electoral systems |
| 12 | `moderate_institutional_visibility` | Cabinet/historical data available |
| 15 | `mature_labor_statistics` | Detailed labor force survey infrastructure |
| 16 | `established_democracies_open_parliament` | Parliamentary age/gender data |

### Country Status Classification (10 statuses)

dissolved, political_exclusion (Taiwan), self_exclusion (USSR, North Korea), nascent, collision, microstate, failed, degraded, reporting, strong.

## Key Outputs

| File | Description |
|------|-------------|
| `data/country_missingness_flags.csv` | Per-row (ggis_rowid) country status flags |
| `data/slug_exclusions.csv` | Hand-curated slug exclusion list (24 slugs) |
| `data/slug_reclassification.csv` | Revised penetration per slug |
| `data/clustering_pool.csv` | Filtered slug list for clustering |
| `data/slug_clusters_tagged.csv` | Cluster assignments with country-profile labels |

## Modules

| Module | Role |
|--------|------|
| `work/phase1/functions/country_missingness.jl` | 10-status country-year classification |
| `work/phase1/functions/slug_reclassification.jl` | Clean denominator, revised penetration, UN vectors |
| `work/phase1/functions/slug_clustering.jl` | Jaccard/binary clustering with label propagation |
| `work/phase1/functions/load_phase1.jl` | Single loader for all Phase 1 modules |

## Documentation

| Document | Content |
|----------|---------|
| `work/phase1/document/country_missingness_methodology.md` | 10 status categories, priority order, constants |
| `work/phase1/document/slug_exclusions_guide.md` | Manual tagging guide, exclusion categories |
| `work/phase1/document/slug_clustering_findings.md` | Initial clustering findings (pre-reclassification) |
| `work/phase1/document/cluster_tagging.md` | Cluster validity assessment and labels |

## Key Decisions

1. **Population-weighted penetration** — mass matters in SOC framework. A slug missing China/India is genuinely less useful.
2. **ht_region is likeness, not geography** — UN regions/subregions used for geographic analysis instead.
3. **Cluster labels describe country profiles**, not data sources — "what kind of country gets measured" not "what database is it from."
4. **WDI fragmentation is correct** — different WDI indicators have different coverage patterns.
5. **Missingness is signal** — absence from a cluster reveals institutional capacity.
6. **Untagged clusters excluded** — 7 clusters with weak cohesion not used in downstream analysis.

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
- Requires Phase 0 preprocessing complete (augmented Arrow with checksum)
- Slug clusters and country flags feed into Phase 2 variable mapping
