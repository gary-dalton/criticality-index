# Country Missingness Scoring — Methodology

## Purpose

Score each (country, year) observation by its global slug coverage relative to UN subregion peers. Classify country-years into statuses that determine whether they should be included in slug penetration denominators and analytical pools.

## Data Units

`wpp_pop` (UN World Population Prospects) is reported in **thousands**. A value of 63 means 63,000 people. The microstate threshold of 100 means 100,000 people.

## Classification Priority

Statuses are assigned in strict priority order. The first matching rule wins.

### 1. Dissolved

**Rule:** `ident_ccode` in `CM_DISSOLVED_STATES` AND `ident_year >= dissolution_year - CM_DISSOLUTION_LAG`

Catches both the dissolution event and the pre-dissolution data decline (typically 5 years of degrading coverage as institutions break down).

| Entity | ccode | Dissolution Year | Flag From |
|--------|-------|-----------------|-----------|
| DDR (East Germany) | 278 | 1990 | 1985 |
| Czechoslovakia | 200 | 1992 | 1987 |
| Yugoslavia | 891 | 1992 | 1987 |
| USSR | 810 | 1991 | 1986 |
| Yemen Democratic | 720 | 1990 | 1985 |
| Tibet | 9156 | 1959 | 1954 |

**Pre-dissolution data is valid.** DDR data from 1960-1984 is classified as reporting/strong, not dissolved. Only the final decline period is flagged.

### 2. Nascent

**Rule:** `ident_year < country_birth_year + CM_NASCENT_YEARS` (default 5 years)

Newly independent countries lack data infrastructure. Low coverage in their first years reflects institutional immaturity, not state failure.

Examples:
- Congo (COD) 1960 — independence year, one failed year was actually nascent
- Malaysia (MYS) 1960-1962 — newly independent, building reporting capacity
- Zimbabwe (ZWE) 1960-1965 — pre-independence era (Rhodesia), limited international data
- South Sudan (SSD) 2011-2015 — newest state, data programs still onboarding

### 3. Collision

**Rule:** `ident_year` is in the country's `collision_years` set (from `ggis_spine_collision`)

When multiple political entities share the same `ident_ccode` in a given year (e.g., Vietnam and South Vietnam both mapping to ccode 704 during 1955-1976), data attribution is ambiguous. Coverage metrics are unreliable for these years.

Examples:
- Vietnam (VNM) 1963-1976 — overlaps with South Vietnam (VDR)
- Serbia (SRB) 1992-2005 — data attributed to Yugoslavia/FRY/Serbia & Montenegro

Collision years should not contribute to penetration denominators because we cannot cleanly attribute the data to a single sovereign entity.

### 4. Microstate

**Rule:** `max(wpp_pop) < CM_MICROSTATE_POP_THRESHOLD` (default 100 = 100,000 people)

States below the population threshold are excluded because most international data programs don't systematically cover them. Their absence from a slug doesn't indicate the slug is incomplete.

Microstates identified (~11): Monaco, Liechtenstein, San Marino, Palau, Nauru, Tuvalu, Marshall Islands, Andorra, and similar entities with peak populations under 100,000.

### 5. Failed

**Rule:** `global_coverage_pct < CM_FAILED_THRESHOLD` (default 0.40) AND `peer_deviation < CM_FAILED_DEVIATION` (default -0.20)

Both conditions must be met:
- The country covers fewer than 40% of global slugs in that year
- The country is 20+ percentage points below its UN subregion peer average

This dual threshold prevents false positives. A country in a low-coverage subregion might have 35% coverage but still be near its peers — that's not failure, that's a regional data gap. Only countries that are significantly worse than their neighbors qualify.

Examples: Truly failed or isolated states where institutional reporting has broken down.

### 6. Degraded

**Rule:** Rolling 3-year coverage average dropped ≥ `CM_DEGRADED_DROP` (default 0.15) from prior 3-year average AND peer deviation also worsened by ≥ half that amount.

**Peer-relative requirement is critical.** If all countries in a subregion lose coverage in 2020-2023 (because data hasn't been published yet), that's global reporting lag — not country-specific degradation. Degradation is only flagged when a country's coverage drops while its peers' coverage holds steady or drops less.

This catches countries going dark gradually (e.g., a state experiencing institutional decline over several years) without false-flagging the universal 2020s reporting lag.

### 7. Reporting

**Rule:** Does not meet any exclusion criteria above, but `peer_deviation < 0` (below subregion average).

Normal reporting country with adequate data. Below peer average but not pathologically so.

### 8. Strong

**Rule:** `peer_deviation >= 0` (at or above subregion average).

Well-covered country — at or above its subregion peer average in global slug reporting.

## Constants (Configurable)

| Constant | Default | Unit | Description |
|----------|---------|------|-------------|
| `CM_DISSOLVED_STATES` | Dict | — | Known dissolved states with dissolution years |
| `CM_DISSOLUTION_LAG` | 5 | years | Flag dissolved from dissolution_year minus this |
| `CM_NASCENT_YEARS` | 5 | years | First N years of data = nascent |
| `CM_MICROSTATE_POP_THRESHOLD` | 100 | thousands | wpp_pop below this = microstate |
| `CM_REPORTING_LAG_YEARS` | 4 | years | Recent years with expected incomplete data |
| `CM_FAILED_THRESHOLD` | 0.40 | fraction | Coverage below this triggers failed check |
| `CM_FAILED_DEVIATION` | -0.20 | fraction | Peer deviation below this confirms failed |
| `CM_DEGRADED_DROP` | 0.15 | fraction | Rolling window drop to trigger degraded |
| `CM_ROLLING_WINDOW` | 3 | years | Window size for degradation detection |

## Pipeline

```
Step 0: build_country_profiles(df)
        → per-country: birth/death year, dissolved, microstate, collision flags

Step 1: score_country_missingness(df, meta_df, profiles)
        → per (country, year): global_coverage_pct, subregion_peer_avg, peer_deviation

Step 2: classify_country_status(profiles, scores)
        → per (country, year): country_status (8 categories)

Step 3: build_missingness_flags(df, status)
        → per ggis_rowid: joinable flag columns

Step 4: recalculate_slug_penetration(df, meta_df, status)
        → per slug: original vs revised penetration using clean denominator
```

## Downstream Use

- **Denominator cleaning:** Exclude dissolved, microstate, failed, and collision country-years from slug penetration calculations
- **Analytical filtering:** Only `reporting` + `strong` country-years enter backtesting pools
- **Nascent awareness:** Nascent years can be included in analysis but should not penalize a slug's penetration score
- **Temporal flexibility:** All classifications are per-year, enabling flexible backtesting windows

## Key Design Decisions

1. **No row deletion.** Flags are stored as a separate dataset keyed by `ggis_rowid`. The augmented Arrow file is never modified.
2. **Temporal, not categorical.** A country can be nascent in 1960, strong in 2000, and degraded in 2020. Status is per-year.
3. **Peer-relative degradation.** Prevents false flagging from global reporting lag.
4. **Manual review gate.** Automated classifications are proposals. The exclusion list is hand-curated before downstream recalculation.
