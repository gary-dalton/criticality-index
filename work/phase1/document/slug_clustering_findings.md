# Slug Clustering Findings

## Overview

Slug clustering groups QoG variables by their country coverage patterns using Jaccard similarity on binary presence matrices. The goal is to identify sets of slugs that act upon similar sets of countries, where missingness is treated as signal.

**Method:** Binary presence (density-thresholded) → Jaccard similarity → top-k neighbor graph → label propagation clustering

**Default configuration:** `presence_min_pct=0.10`, `min_country_coverage=0.05`, `k=20`, `min_sim=0.10`

**Result:** 1,147 slugs clustered into 29 groups (737 global slugs set aside).

---

## Cluster Types

### Institutional clusters (single data source)

Clusters dominated by a single prefix — the data source determines coverage.

| Cluster | Prefix | Slugs | Countries | Region | ht_region J |
|---------|--------|-------|-----------|--------|-------------|
| 12 | EU | 134 | 38 (19%) | Europe 95% | 0.444 |
| 13 | EU | 61 | 35 (18%) | Europe 94% | 0.442 |
| 14 | EU | 15 | 27 (14%) | Europe 96% | 0.385 |
| 3 | AII + IIAG | 58 | 58 (29%) | Africa 91% | **0.814** |
| 4 | AII | 26 | 11 (6%) | Africa 100% | 0.224 |
| 22 | JW | 26 | 171 (86%) | Global | 0.250 |
| 26 | WWBI | 40 | 62 (31%) | Multi-regional | 0.253 |
| 27 | YRI | 17 | 43 (22%) | Europe 56% | 0.296 |
| 16 | GCB | 16 | 14 (7%) | Europe 64% | 0.278 |

**EU splits into 3 clusters** (134, 61, 15 slugs) reflecting different EU survey programs with different country coverage depths.

**AII/IIAG** (Africa Integrity Index / Ibrahim Index of African Governance) produces the strongest ht_region alignment at J=0.814 — almost perfectly matching ht_region 4 (Sub-Saharan Africa).

### Topic-driven clusters (multiple sources, global reach)

Clusters formed by slugs from different data sources that happen to cover the same countries. Low ht_region alignment — they cut across QoG's regional taxonomy.

| Cluster | Dominant | Topic | Slugs | Countries | ht_region J |
|---------|----------|-------|-------|-----------|-------------|
| 9 | WDI+ICTD+OPRI | Economic/development | 122 | 194 (97%) | 0.253 |
| 5 | IAEP+ROSS+WDI | Surveys, mixed | 78 | 195 (98%) | 0.251 |
| 15 | WDI | Development indicators | 66 | 184 (92%) | 0.233 |
| 7 | BTI+WDI+GWF | Governance transformation | 65 | 165 (83%) | 0.281 |
| 19 | NELDA+IDEA | Elections/factual | 20 | 189 (95%) | 0.246 |
| 17 | GOL+GTM | Expert governance | 24 | 166 (83%) | 0.236 |
| 2 | BR+WDI | Democracy/development | 30 | 193 (97%) | 0.254 |

### Regional/multi-regional clusters

| Cluster | Dominant | Slugs | Countries | Region | ht_region J |
|---------|----------|-------|-----------|--------|-------------|
| 10 | CPDS+EU+ESS | 91 | 47 (24%) | Europe 75% | 0.451 |
| 8 | IDENT+FAO | 19 | 200 (100%) | Global | 0.245 |
| 1 | SGI+AID | 33 | 51 (26%) | Europe 63% | 0.444 |
| 20 | WVS+WDI | 38 | 54 (27%) | Europe 41% | 0.410 |
| 18 | LIS+GTR | 42 | 93 (47%) | Europe 37% | 0.224 |
| 25 | WARC | 20 | 114 (57%) | Multi-regional | 0.217 |

---

## ht_region Alignment

Only 2 out of 29 clusters show strong alignment (Jaccard ≥ 0.50) with any `ht_region` group:

- **Cluster 3** (J=0.814) → ht_region 4 (Sub-Saharan Africa) — AII/IIAG data
- **Cluster 8** (J=0.561) → ht_region 5 (Western Europe & North America) — identity/FAO data

**Conclusion:** `ht_region` captures data availability patterns for Africa-specific and OECD-specific sources, but the majority of clusters — especially large global ones — have no meaningful ht_region alignment. This confirms that `ht_region` is a politico-geographic likeness indicator for a subset of the data, not a universal structural axis for the dataset.

---

## Dial Sensitivity

| Config | Slugs | Clusters | Largest | Smallest | Median | ht_region strong |
|--------|-------|----------|---------|----------|--------|-----------------|
| **Default** (pmin=0.10, k=20, msim=0.10) | 1,147 | 29 | 139 | 9 | 26 | 2 |
| Strict presence (pmin=0.20) | 990 | 25 | 120 | 12 | 29 | 0 |
| Loose presence (pmin=0.05) | 1,366 | 32 | 162 | 12 | 28 | 2 |
| Tight clusters (k=10, msim=0.20) | 1,147 | 46 | 134 | 5 | 18 | 3 |
| Loose clusters (k=30, msim=0.05) | 1,147 | 14 | 220 | 17 | 67 | 2 |
| High min coverage (mcc=0.10) | 1,066 | 24 | 147 | 15 | 34 | 2 |
| All tight (pmin=0.20, mcc=0.10, k=10, msim=0.20) | 813 | 33 | 84 | 8 | 17 | 0 |
| All loose (pmin=0.05, mcc=0.02, k=30, msim=0.05) | 1,381 | 19 | 290 | 19 | 44 | 2 |

**Key observations:**

- **`presence_min_pct`** controls how many slugs enter clustering (990–1,366). Stricter thresholds exclude Africa-specific sources that report briefly — strong ht_region matches disappear at pmin=0.20.
- **`k` and `min_sim`** control cluster granularity without changing which slugs participate. Tight settings (k=10, msim=0.20) produce 46 small clusters; loose settings (k=30, msim=0.05) merge into 14 large ones.
- **ht_region alignment is consistently low** (0–3 strong matches out of 14–46 clusters) across all configurations. This finding is robust and not an artifact of threshold choice.
- **Default settings** (29 clusters, 1,147 slugs) provide a balanced view. The EU splits into 3 meaningful subclusters; Africa sources cluster tightly; global sources form distinct topic groups.

---

## Implications for Phase 2 (Variable Mapping)

1. **Global slugs** (~737) cover 95%+ of countries and can be used as universal indicators across all analyses.
2. **Institutional clusters** (EU, AII, CPDS, etc.) are region-locked — they should only be used for countries within their coverage footprint.
3. **Topic clusters** (economic, governance, election data) span most countries and can serve as cross-cutting analytical dimensions.
4. **Missingness patterns** are themselves informative — countries absent from a cluster likely lack the institutional reporting infrastructure that produces those indicators.
5. **ht_region** should not be used as a structural grouping variable for analysis. The UN geographic regions provide a proper geographic foundation; ht_region can be used as one analytical variable among many.
