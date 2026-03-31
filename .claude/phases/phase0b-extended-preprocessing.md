# Phase 0b — Extended Preprocessing

External data sources acquired after Phase 0 to support the SOC model's graph-theoretic, subnational, and exogenous shock components.

## Status: In Progress

## Data Sources

| Dataset | File | Status | Purpose |
|---------|------|--------|---------|
| **EM-DAT** | `public_emdat_incl_hist_2026-03-26.xlsx` | Processing | Exogenous shocks (E component), backtesting |
| **DOSE V2.11** | `DOSE_V2.11.csv` | Processing | Subnational GDP (Signatures 3 & 4) |
| **SHDI V10.0** | `Subnational HDI Data v10.0.csv` | Acquired, pending | Subnational HDI (Signatures 3 & 4) |
| **Laeven & Valencia** | `wp18206.zip` | Acquired, pending | Banking/currency/debt crisis dates (backtesting) |
| **CEPII GeoDist** | `geo_cepii.dta`, `dist_cepii.dta` | Acquired, pending | Geographic network edges (ρ component) |
| **CEPII Gravity** | `Gravity_csv_V202211.zip` | Acquired, pending | Trade network edges (ρ component) |

## Deferred (after model proves predictive)

| Dataset | Purpose |
|---------|---------|
| **BIS Locational Banking Stats** | Financial contagion network edges |
| **ACLED** | High-frequency conflict event data |

## Dataset Summaries

### QoG Standard Time-Series (Phase 0)
The backbone of the project. 2,010 slugs across ~200 countries, 1946–2023 (varies by slug). Annual country-level panel covering governance, economics, conflict, demographics, and more. Preprocessed in Phase 0 into augmented Arrow format with `ident_` namespace and cleaned country codes. All Phase 1 slug classification (temporal profiles, penetration, clustering) operates on this dataset.

### EM-DAT — International Disaster Database
24,074 disaster events (post-1950), 231 countries (196 matched to QoG). Event-level records with disaster type, deaths, and total affected. Aggregated to country-year for model integration. **Role:** exogenous shock markers for the E (Excitation) component. Natural disasters are the closest thing to a controlled experiment in governance — the same earthquake hits two neighboring countries with different institutional configurations, and we observe how their systems respond. Also provides event-level data for testing Signature 1 (power-law distribution of disaster impacts). Pre-2000 events carry a reporting bias flag (`is_historic`).

### DOSE V2.11 — Database of Subnational Economic Output
46,851 region-year rows, 83 countries, 1,661 first-admin regions, 1953–2020. Subnational GDP per capita (constant 2015 USD), sectoral breakdown (agriculture, manufacturing, services), population, and climate variables (annual temperature, precipitation). **Role:** secondary confirmation layer for Signatures 3 (scale invariance) and 4 (fractal structure). NOT a primary input to the model.

**Coverage characteristics:** Data density is temporally unbalanced. Dense annual coverage (40+ years) is concentrated in the US, China, Mexico, Australia, Europe, and parts of East Asia. Post-Soviet countries start ~1990. Africa and Middle East often have fewer than 10 years per region. The majority of observations fall in the 1990–2020 period.

**Secondary test framing:** DOSE (and SHDI) are used as confirmation, not as primary signature tests. The analytical sequence is: (1) test primary signatures (1–3, 5) using QoG slugs which have broad global coverage, (2) for countries that pass primary signatures, check Signature 4 using DOSE where subnational data exists, (3) countries that pass AND have dense DOSE coverage provide the strongest evidence. This avoids the coverage bias of claiming "only countries with subnational GDP data exhibit criticality."

### SHDI V10.0 — Subnational Human Development Index (pending)
Subnational HDI at first-admin level, 1,800+ regions in 160+ countries, 2000–present. Same secondary confirmation role as DOSE. Better country coverage than DOSE but shorter temporal depth (2000+ only).

### Laeven & Valencia — Systemic Crisis Database (pending)
Banking, currency, and sovereign debt crisis dates, 1970–2023, ~190 countries. Binary country-year indicators. **Role:** discrete regime-shift markers for backtesting. When the model identifies a country as moving from sub-critical to super-critical, do Laeven & Valencia crisis dates align?

### CEPII GeoDist + Gravity (pending)
Bilateral geographic distances, contiguity, language, colonial ties (static); annual bilateral trade flows 1948–2019 (panel). **Role:** network edges for the ρ (density/coupling) component. Geographic proximity = physical nearest neighbors; trade flows = economic nearest neighbors. Together they define the multi-layer network for graph-theoretic analysis.

## Data Decisions

### Temporal Floor (TEMPORAL_FLOOR = 1950)

All datasets are filtered to 1950+ at load time. Pre-1950 data has severe reporting bias across all sources and predates the post-WWII institutional order (UN, Bretton Woods, decolonization) that defines modern governance measurement. Defined as a project-wide constant in `work/constants.jl`.

### EM-DAT Column Drops (40% missingness threshold)

Columns below 40% completeness were dropped during preprocessing. Kept columns and their completeness:

| Column | Pre-2000 | Post-2000 | Decision |
|--------|----------|-----------|----------|
| `total_deaths` | 78.7% | 80.5% | **Kept** |
| `total_affected` | 56.3% | 74.7% | **Kept** — aggregate of injured + affected + homeless |
| `no_injured` | 26.5% | 37.5% | Dropped |
| `no_affected` | 35.2% | 46.5% | Dropped — redundant with total_affected |
| `no_homeless` | 12.7% | 8.1% | Dropped |
| `total_damage_adj_k` | 24.7% | 19.3% | Dropped |
| `magnitude` | 17.8% | 20.2% | Dropped |

Missingness was checked for temporal dependence (pre-2000 vs post-2000). The pattern is structural, not primarily temporal — reporting improved only marginally after 2000 for most columns.

**Country code alignment:** EM-DAT has 231 ISO3 codes, QoG has 202. 196 matched (97% of QoG). The 35 unmatched EM-DAT codes are overseas territories (Bermuda, Guam, Puerto Rico, etc.), historical entities (DFR = West Germany, YMN = North Yemen), and special regions (Hong Kong, Macao, Palestine). These are not in our model's country set. Join key: `iso3 = ident_ccodealp`.

**Note on `is_historic` flag:** EM-DAT marks pre-2000 events as historic due to lesser data quality from uneven reporting coverage. EM-DAT recommends excluding pre-2000 data from trend analyses — the apparent increase in disaster frequency over time is largely a reporting artifact. We retain pre-2000 events (post-1950) because our use case is per-country-year shock identification, not disaster frequency trends. The `is_historic` flag is carried in the data for downstream filtering if needed.

**Note on economic impact:** The 40% threshold eliminated `total_damage_adj_k` (economic damage in constant USD), which would have been a direct measure of shock magnitude. However, at ~22% completeness, any analysis using it would be biased toward well-documented wealthy-country disasters. The economic impact of disasters is better captured through QoG slugs (GDP growth dips, trade disruptions), which measure the *system's response* to the shock rather than the shock's nominal price tag — and with far better coverage. The retained measures (event count, deaths, total affected) capture shock frequency and severity.

## Directory Structure

- `work/phase00b/functions/` — Preprocessing functions
  - `load_phase00b.jl` — Module loader
  - `emdat_data.jl` — EM-DAT load, aggregate, Arrow export
  - `dose_data.jl` — DOSE load, aggregate, Arrow export
  - `network_data.jl` — CEPII preprocessing (not yet active)
  - `subnational_data.jl` — SHDI preprocessing (not yet active)
- `work/p00b_emdat.ipynb` — EM-DAT exploration notebook
- `work/p00b_dose.ipynb` — DOSE exploration notebook

## Output Files (Arrow)

| File | Description |
|------|-------------|
| `data/emdat_events.arrow` | Event-level disaster records (post-1950) |
| `data/emdat_country_year.arrow` | Aggregated country-year (event count, deaths, affected) |
| `data/dose_subnational.arrow` | Region-year panel (GDP, sectoral, climate) |
| `data/dose_national.arrow` | Population-weighted country-year aggregate |
