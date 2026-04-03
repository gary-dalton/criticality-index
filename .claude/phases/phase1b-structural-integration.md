# Phase 1b — Structural Integration

**Objective:** Make all Phase 0b datasets joinable to QoG's country spine. Build master references so downstream phases can combine datasets without per-analysis remapping.

**Status:** In progress. 1b.1 and 1b.4 complete. 1b.2, 1b.3, 1b.5 pending.

## Completed

### 1b.1 — Master Country Reference (COMPLETE)

**Output:** `data/ggis_country_master.arrow` — 202 countries × 27 columns.

Built from QoG spine (`ident_ccodealp` as authoritative key) + geographic lookup (UN regions, continents) + Phase 1 country status (modal + latest) + coverage flags for all 6 external datasets + existence dates per source.

Key findings:
- 68 countries have all 6 external datasets
- 1 country (XTI/Tibet) has no external coverage
- Phase 1 status predicts external coverage (strong=near-universal, reporting=drops in DOSE/L&V)
- QoG as country driver validated: 51 external-only codes are all territories/historical — no sovereign states missing
- Top 30 by population: 24/30 have all 6 datasets
- Top 30 by GDP: 22/30 have all 6 datasets

### 1b.4 — Phase 1 Status Extraction (FOLDED INTO 1b.1)

Extracted per-country status from row-level `country_missingness_flags.csv`:
- `phase1_modal_status` — most frequent status across years
- `phase1_latest_status` — most recent year's status
- `mean_slug_coverage` — average QoG slug coverage
- `n_distinct_statuses` — whether status changed over time

Distribution: 130 strong, 54 reporting, 11 microstate, 2 self_exclusion, 2 failed, 1 political_exclusion, 1 nascent, 1 collision.

## Completed (continued)

### 1b.2 — Coverage Matrix (COMPLETE)

**Output:** `data/ggis_coverage_matrix.arrow` — 12,391 country-year rows × 10 columns.

Boolean flags per dataset per country-year. Summary functions for temporal window analysis and population-weighted penetration.

Key findings:
- Mean 3.92 datasets per country-year; max 7 (all datasets + active crisis)
- Standard window (1990+) is the convergence point: major countries average 5.5–5.9 datasets
- External dataset temporal profiles mirror slug profiles: EM-DAT ≈ anchor, SHDI ≈ current, BACI ≈ modern
- Population-weighted penetration: DOSE covers 82.5% of world population despite only 82 countries (41%). EM-DAT/SHDI/GeoDist/Gravity all at 99.7–100%.
- L&V at 3.7% of country-years (crisis-active only) but 87.6% population-weighted country coverage

## Pending

### 1b.3 — Bilateral Edge Consolidation

Standardize origin/destination column names across GeoDist (`iso_o`/`iso_d`) and Gravity (`iso3_o`/`iso3_d`). Build convenience loader returning all network layers aligned to QoG-matched countries only.

### 1b.5 — Country Birth/Merge/Split Reference

Cross-reference Gravity countries existence dates with QoG historical entities and Phase 1 dissolved/nascent statuses. Map predecessor → successor states.

## Key Files

| File | Description |
|------|-------------|
| `work/phase01b/functions/country_master.jl` | Master reference builder |
| `work/phase01b/functions/coverage_matrix.jl` | Coverage matrix builder + summary functions |
| `work/phase01b/functions/load_phase01b.jl` | Phase 1b module loader |
| `work/p01b_structural_integration.ipynb` | Exploration and verification notebook |
| `data/ggis_country_master.arrow` | Output: 202 countries × 27 columns |
| `data/ggis_coverage_matrix.arrow` | Output: 12,391 country-years × 10 columns |
| `work/constants.jl` | `ISO3_REMAP` dict (unified, referenced by all loaders) |

## Known Issues

- `ggis_geographic_lookup.csv` had a duplicate SUN entry (USSR + "Sudan Unified" with wrong ISO3). Fixed manually by removing the erroneous row. File is hand-built (no automated generator), so the fix is permanent.
- SHDI uses `isocode3` while all other datasets use `iso3` — not yet standardized in the Arrow files. The master reference handles this internally via per-dataset column awareness.
