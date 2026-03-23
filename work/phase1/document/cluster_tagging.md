# Cluster Tagging — Post-Reclassification Results

## Overview

16 clusters produced from the filtered pool (after removing global, regional, subregional, sparse, experimental, and historical slugs). Clusters are topic-driven with no significant geographic or ht_region alignment.

## Cluster Validity Assessment

### Legitimate Clusters (13)

Strong internal cohesion — mean intra-cluster Jaccard ≥ 0.68, density (pct pairs > 0.5) ≥ 70%.

| Cluster | Slugs | Dominant | Mean J | Density | Proposed Label |
|---------|-------|----------|--------|---------|---------------|
| 16 | 17 | YRI | 1.000 | 100% | youth_resilience |
| 15 | 33 | WWBI | 0.908 | 100% | bureaucracy |
| 9 | 19 | WDI | 0.839 | 100% | development_tertiary |
| 11 | 27 | LIS | 0.813 | 72% | inequality |
| 12 | 19 | NELDA | 0.796 | 90% | elections_factual |
| 10 | 24 | GOL | 0.794 | 90% | governance_expert |
| 2 | 153 | WDI | 0.774 | 96% | development_core |
| 14 | 30 | WVS | 0.769 | 86% | values_opinion |
| 13 | 16 | WDI | 0.738 | 88% | development_africa |
| 1 | 72 | CPDS | 0.733 | 79% | comparative_politics |
| 5 | 66 | BTI | 0.718 | 69% | governance_transformation |
| 3 | 38 | IAEP | 0.702 | 90% | cross_national_surveys |
| 6 | 50 | WDI | 0.680 | 82% | development_secondary |

### Questionable Clusters (3)

Weak or bimodal internal structure — not considered legitimate for downstream analysis.

| Cluster | Slugs | Dominant | Mean J | Density | Issue |
|---------|-------|----------|--------|---------|-------|
| 7 | 41 | WJP | 0.723 | 52% | Bimodal — median 1.0 but only 52% density. Two subclusters forced together. Block-diagonal heatmap expected. |
| 4 | 18 | BL | 0.867 | 89% | Mean looks strong but min 0.177 is very low. 1-2 slugs don't belong. |
| 8 | 32 | WARC | 0.694 | 88% | Weakest large cluster. Conflict data has inherently uneven coverage. May be as good as it gets for this topic. |

**Decision:** Clusters 4, 7, and 8 are excluded from the tagged set. Their slugs remain in the data but are not assigned a topic label. Future work may split these with tighter clustering dials or manual inspection.

## Strength Metrics

| Metric | Meaning |
|--------|---------|
| **mean_jaccard** | Average pairwise Jaccard similarity within cluster. Higher = slugs cover more of the same countries. |
| **median_jaccard** | Middle value. When median >> mean, tight core with loose outliers. |
| **min_jaccard** | Weakest pair. Low min with high mean = 1-2 slugs barely belong. |
| **pct_above_50 (density)** | % of pairs with Jaccard > 0.5. Below 70% = cluster loosely held together. |

## WDI Fragmentation

WDI splits into 3 legitimate clusters:
- **Cluster 2** (153 slugs, 99% coverage) — core development indicators
- **Cluster 6** (50 slugs, 86% coverage) — secondary development indicators
- **Cluster 9** (19 slugs, 89% coverage) — tertiary development indicators
- **Cluster 13** (16 slugs, 63% coverage) — Africa-weighted WDI subset

This fragmentation is correct — different WDI indicators have different country coverage patterns despite sharing a prefix.

## Next Steps

1. Assign topic labels to the 13 legitimate clusters
2. Examine slugs from questionable clusters individually — some may merge into legitimate clusters with manual review
3. Use tagged clusters for Phase 2 variable mapping
