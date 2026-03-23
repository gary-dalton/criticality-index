# Cluster Tagging — Final Results

## Overview

16 clusters produced from the filtered pool (670 slugs after removing global_95, global_90, regional, subregional, sparse, experimental, historical, and manually excluded slugs). All countries included in the presence matrix. Clusters are labeled by **country profile** — what type of country gets measured — not by data source.

## Labeled Clusters (9)

| Cluster | Slugs | Mean J | Density | Label | Description |
|---------|-------|--------|---------|-------|-------------|
| 16 | 17 | 1.000 | 100% | `established_democracies_open_parliament` | Parliamentary age/gender data — countries with transparent legislative records |
| 8 | 10 | 0.995 | 100% | `capable_willing_reporters` | IMF fiscal compliance — voluntary detailed budget reporting |
| 15 | 33 | 0.908 | 100% | `mature_labor_statistics` | Detailed labor force surveys — advanced statistical infrastructure |
| 3 | 23 | 0.839 | 91% | `near_global_excl_microstates` | Covers all but microstates (academic expert-coded data) |
| 9 | 26 | 0.786 | 100% | `near_global` | Covers all but dissolved/micro/failed — threshold artifact |
| 6 | 14 | 0.798 | 100% | `near_global_excl_microstates` | Same pattern as 3, different topic slugs |
| 10 | 24 | 0.794 | 90% | `codifiable_electoral_machinery` | States with functioning electoral systems; missing = monarchies/one-party |
| 12 | 22 | 0.809 | 82% | `moderate_institutional_visibility` | Cabinet/historical data — countries with documented governance structures |
| 7 | 41 | 0.723 | 52% | `assessable_governance_institutions` | States open enough for rule-of-law assessment (WJP) |

## Unlabeled Clusters (7)

Weak cohesion or mixed composition. Not used in downstream analysis. Slugs remain in the data but are tagged as `untagged`.

| Cluster | Slugs | Mean J | Density | Issue |
|---------|-------|--------|---------|-------|
| 11 | 27 | 0.813 | 72% | Bimodal — tight core with loose members |
| 14 | 30 | 0.769 | 86% | Mixed topic coverage |
| 2 | 151 | 0.758 | 94% | Large mega-cluster — too broad to characterize |
| 13 | 16 | 0.738 | 88% | Mixed WDI subset |
| 1 | 72 | 0.733 | 79% | Mixed comparative politics — min J=0.111 |
| 4 | 72 | 0.689 | 68% | Mixed — low density |
| 5 | 50 | 0.680 | 82% | Borderline cohesion |

## Strength Metrics

| Metric | Meaning |
|--------|---------|
| **mean_jaccard** | Average pairwise Jaccard similarity within cluster |
| **median_jaccard** | Middle value — when median >> mean, tight core with outliers |
| **min_jaccard** | Weakest pair — low min with high mean = 1-2 slugs barely belong |
| **density (pct_above_50)** | % of pairs with Jaccard > 0.5. Below 70% = loosely held |

## Labeling Principle

Labels describe **country profiles** — the type of country that gets measured by the cluster's slugs:

- `near_global*` — covers nearly everyone; missing countries are noise (microstates, dissolved)
- `capable_willing_reporters` — countries that voluntarily report detailed fiscal data to the IMF
- `mature_labor_statistics` — countries with advanced statistical office infrastructure
- `codifiable_electoral_machinery` — countries with functioning electoral systems to code
- `assessable_governance_institutions` — countries open enough for external rule-of-law evaluation
- `moderate_institutional_visibility` — countries with enough governance documentation for researchers
- `established_democracies_open_parliament` — democracies publishing parliamentary composition data

The missing countries in each cluster are as informative as the covered ones — they reveal which states lack the institutional capacity, willingness, or political openness for that type of measurement.

## Key Output

`data/slug_clusters_tagged.csv` — cluster assignments with labels. Untagged slugs marked as `untagged` and excluded from Phase 2 variable mapping.
