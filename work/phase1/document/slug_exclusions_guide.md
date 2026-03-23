# Slug Exclusions — Manual Tagging Guide

## Purpose

Some slugs should be excluded from analysis even if they survive automated filtering. The `data/slug_exclusions.csv` file provides a hand-curated list of slugs to drop, with documented reasons.

## File Format

`data/slug_exclusions.csv`:

| Column | Type | Description |
|--------|------|-------------|
| `slug` | String | Exact slug name (e.g., `dev_altv1`) |
| `exclusion_reason` | String | Category tag for the exclusion |
| `notes` | String | Human-readable explanation |

## Exclusion Reason Categories

| Reason | Meaning | Example |
|--------|---------|---------|
| `sparse_regional` | Sparse AND limited to a specific region | EU dentist counts covering 3 countries |
| `historical_research` | Historical research data points, not ongoing measurement | Gleditsch tax shares from 1800/1850 |
| `single_country` | Reported for only one country | Hadenius institutional variables |
| `single_year` | Reported for only one year globally | WHO road traffic deaths 2021 |

## How to Use

### Adding exclusions

1. Run `p01_02_slug_reclassification.ipynb`
2. Review the "Sparse Slugs" section
3. For slugs that should be excluded, add rows to `data/slug_exclusions.csv`
4. Re-run the notebook — excluded slugs will show as `drop_reason = "manual:<reason>"`

### When to exclude

Exclude a slug if:
- It covers very few countries AND those countries are all in one region (sparse + regional)
- It's a one-off historical data point, not a time series
- It covers only one country (no cross-national comparison possible)
- It was reported in a single year (no temporal analysis possible)

### When NOT to exclude

Do NOT exclude a slug just because:
- It has low global penetration (it might be important regionally)
- It's a legacy variable (historical backtesting needs these)
- It's from an unfamiliar data source (investigate first)

## Pipeline Integration

The `compute_revised_penetration()` function in `slug_reclassification.jl` loads this file automatically. Manual exclusions are checked BEFORE temporal profile filtering, so a manually excluded slug is dropped regardless of its profile.

Drop reasons in the output show as `manual:<exclusion_reason>` (e.g., `manual:sparse_regional`).

## Current Exclusions

As of initial tagging:

| Slugs | Reason | Notes |
|-------|--------|-------|
| `dev_altv1`, `dev_othv1`, `dev_regv1`, `dev_tv1` | sparse_regional | Electoral Volatility — Western Europe specific |
| `eu_headenththab`, `eu_headentnr`, `eu_headentp`, `eu_heahbedlthabp`, `eu_heahbedothhabp`, `eu_resnonpf`, `eu_resnonpt`, `eu_trinlw` | sparse_regional | EU health/research/transport — few Western EU countries |
| `gtr_centaxdir1800`, `gtr_centaxdir1850`, `gtr_centaxgdp1800`, `gtr_centaxind1800` | historical_research | Tax research from 1800/1850 |
| `h_f`, `h_j`, `h_l1`, `h_l2` | single_country | Hadenius institutional — one country only |
| `who_roadtrd` | single_year | WHO road traffic deaths — 2021 only |
