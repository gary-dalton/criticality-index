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

### SHDI V10.0

65,031 rows (6,069 national + 58,962 subnational), 188 countries, 1,993 regions, 1990–2023. QoG alignment: 186 of 202 matched (92%). 16 unmatched QoG codes are historical entities plus microstates. Join key: `isocode3 = ident_ccodealp`.

**Missingness:** Core HDI variables (shdi, healthindex, edindex, incindex) are 100% complete. Gender-disaggregated indices (shdif/m, sgdi) are 29% missing pre-2005 but only 3% post-2005. Income gender split (lgnicf/m) worst at 23%/3%. `datasource` column is 100% empty — dropped.

**Country coverage advantage over DOSE:** 188 countries (vs DOSE's 83) but shorter temporal depth (1990+ vs 1953+). The 72 countries present in both allow cross-validation of subnational dispersion measures.

### Phase 1 Status Predicts External Dataset Coverage

Cross-referencing Phase 1 country statuses with Phase 0b dataset coverage flags confirms that QoG missingness status is a general country characteristic, not QoG-specific:

| Status | n | EM-DAT | DOSE | SHDI | GeoDist | Gravity | L&V |
|--------|---|--------|------|------|---------|---------|-----|
| strong | 130 | 100% | 56% | 99% | 99% | 100% | 77% |
| reporting | 54 | 100% | 17% | 94% | 93% | 100% | 33% |
| microstate | 11 | 64% | 0% | 55% | 82% | 100% | 0% |
| self_exclusion | 2 | 100% | 0% | 0% | 50% | 100% | 0% |
| failed | 2 | 100% | 0% | 0% | 0% | 100% | 0% |

Strong countries have near-universal external coverage. "Reporting" countries drop to 17% DOSE and 33% L&V. Microstates, failed, and self-exclusion states have minimal subnational or crisis data. EM-DAT and Gravity remain high even for weak states because they're observed externally (disasters happen regardless of reporting capacity; trade partners report bilateral flows).

The primary analytical pool is the 130 strong + 54 reporting countries (91%). The mass threshold for C_d (microstates + failed + nascent) aligns naturally with data availability — countries below the threshold also lack the data to compute meaningful indices.

### QoG as Country Driver — Validation

51 country codes appear in external datasets but not in QoG's 202. All are overseas territories (ABW, AIA, BMU, GLP, PRI, REU, etc.), historical codes (ANT, DFR, YMN), or special entities (HKG, MAC, VAT, PSE, XKO). **No sovereign states are missing from the model.** Territory data is partially captured through their sovereign's QoG entry (e.g., French overseas departments are in FRA's data).

Borderline cases: PSE (Palestine, has SHDI + Gravity), XKO (Kosovo, has SHDI only), HKG (Hong Kong, has EM-DAT/GeoDist/Gravity). These cannot be added without QoG spine data. Their exclusion is acknowledged but does not affect the model's coverage of sovereign states.

Only 1 QoG country has NO external dataset coverage: XTI (Tibet) — a synthetic entity (ccode 9156) not recognized in any international data system. 68 countries have all 6 external datasets.

**Gender gap insight:** SHDI's gender-disaggregated indicators reveal subnational gender inequality. The largest gender gaps (F - M SHDI, 2020) are Yemen (-0.27), Afghanistan (-0.19), Iraq (-0.14) — states expected to be sub-critical or super-critical. Countries where women are ahead span different economic levels but share institutional investments in women's education (Honduras, Vietnam, Poland, Baltics). For the model: gender gap may be an indicator of ordering effectiveness — suppressing women's development is a form of privilege capture (O sub-component: constraint on privilege capture).

**GDP CV vs HDI CV insight:** Correlation between DOSE GDP dispersion and SHDI HDI dispersion is 0.513 across the 72 shared countries — positively related but far from identical. The gap between the two is itself a measure of how effectively a state uses ordering to distribute human development outcomes across its territory, independent of economic geography. Examples: Argentina has high GDP CV (0.52, economy concentrated in Buenos Aires) but near-zero HDI CV (0.006, health and education distributed evenly). Ukraine similar pattern (GDP CV 0.65, HDI CV 0.02). This is the O lever at work — redistribution policy can decouple economic inequality from human development inequality.

## Directory Structure

- `work/phase00b/functions/` — Preprocessing functions
  - `load_phase00b.jl` — Module loader
  - `emdat_data.jl` — EM-DAT load, aggregate, Arrow export
  - `dose_data.jl` — DOSE load, aggregate, Arrow export
  - `shdi_data.jl` — SHDI load, Arrow export
  - `cepii_geodist_data.jl` — GeoDist load, ggis_shared_lineage derivation, Arrow export
  - `cepii_gravity_data.jl` — Gravity load (selective columns), Arrow export
  - `laeven_valencia_data.jl` — L&V load, crisis panel expansion, outcomes cleaning, Arrow export
- `work/p00b_emdat.ipynb` — EM-DAT exploration notebook
- `work/p00b_dose.ipynb` — DOSE exploration notebook
- `work/p00b_cepii_geodist.ipynb` — CEPII GeoDist exploration notebook
- `work/p00b_cepii_gravity.ipynb` — CEPII Gravity exploration notebook
- `work/p00b_shdi.ipynb` — SHDI exploration notebook
- `work/p00b_laeven_valencia.ipynb` — Laeven & Valencia exploration notebook

## Output Files (Arrow)

| File | Description |
|------|-------------|
| `data/emdat_events.arrow` | Event-level disaster records (post-1950) |
| `data/emdat_country_year.arrow` | Aggregated country-year (event count, deaths, affected) |
| `data/dose_subnational.arrow` | Region-year panel (GDP, sectoral, climate) |
| `data/dose_national.arrow` | Population-weighted country-year aggregate |
| `data/shdi_v10.arrow` | Subnational HDI (national + subnational rows) |
| `data/lv_crisis_panel.arrow` | Country-year crisis flags (463 crisis-active years, 123 countries) |
| `data/lv_outcomes.arrow` | Crisis episode outcomes (151 episodes, fiscal costs, output losses) |
| `data/cepii_geo_countries.arrow` | Country-level geographic metadata (238 countries) |
| `data/cepii_geodist.arrow` | Bilateral dyadic pairs (50,176 pairs, distances + cultural ties) |

### CEPII GeoDist ISO3 Remapping

GeoDist uses legacy ISO3 codes for three countries. Remapped during preprocessing:

| GeoDist code | QoG code | Country |
|-------------|----------|---------|
| ROM | ROU | Romania |
| ZAR | COD | DR Congo |
| TMP | TLS | Timor-Leste |

After remapping: 190 of 202 QoG countries matched (94%). Remaining unmatched QoG codes are historical entities (CSK, DDR, SUN, VDR, YMD, SCG), post-GeoDist splits (MNE, SRB, SSD), microstates (LIE, MCO), and an internal code (XTI).

### Derived Edge: ggis_shared_lineage

CEPII's `comcol` variable uses a narrow post-1945 definition that misses dominion-era colonial relationships (Australia, NZ, Canada, South Africa, etc.). We derive a broader edge: `ggis_shared_lineage = 1` when two countries share ANY colonizer from geo_cepii's `colonizer1`–`colonizer4` fields.

This captures institutional transmission channels — shared legal traditions, administrative patterns, and language that persist long after independence. Example: Australia gains 81 shared-lineage partners (the full British empire network) vs. 0 from CEPII's `comcol`.

| Metric | comcol (CEPII) | ggis_shared_lineage (derived) |
|--------|---------------|-------------------------------|
| Total pairs | 5,886 | 9,394 |
| AUS partners | 0 | 81 |

Colonial powers by former colony count (from geo_cepii): GBR dominates, followed by FRA, ESP, NLD, PRT.

### CEPII Gravity

87 columns, ~4.6M rows (post-1950), 1950–2020, 243 countries. Loaded with selective column read (30 columns), same ISO3 remap as GeoDist (ROM→ROU, ZAR→COD, TMP→TLS). QoG alignment: 194 of 202 matched (96%). 8 unmatched are historical entities. Zero active QoG countries missing from 2019 BACI.

**Trade flow sources and temporal coverage:**

| Source | Available From | Best Use |
|--------|---------------|----------|
| `tradeflow_baci` | ~2000 | **Primary.** Reconciled COMTRADE. Most reliable. |
| `tradeflow_imf_d` | ~1950 | **Pre-2000 fallback.** Best historical coverage. |
| `tradeflow_comtrade_o/d` | ~1960 | **Dropped.** Redundant with BACI post-2000, worse than IMF pre-2000. |
| `manuf_tradeflow_baci` | ~2000 | **Dropped.** Identical coverage to BACI, narrow manufacturing subset. |

**Supplementary edge columns:**

| Column | Missing Post-1990 | Decision |
|--------|-------------------|----------|
| `comrelig` (common religion) | 36.1% | **Kept.** Unique cultural coupling dimension, like colonial lineage. |
| `diplo_disagreement` (UN voting) | 48.0% | **Kept.** Unique diplomatic distance measure, not captured elsewhere. |
| `scaled_sci_2021` (Facebook Social Connectedness) | 49.8% | **Dropped.** Single-year snapshot (2021), not time series. Half missing. |

**Network characteristics (2019 BACI, QoG-matched):**
- 192 nodes, 14,809 edges, density 0.808
- Unweighted degree has ceiling effect (top countries all at 191) — not useful for ρ differentiation
- Weighted degree (trade volume) spans 5 orders of magnitude (~$10M to ~$2.3T, log-normal) — the real structure
- Trade concentration reveals dependency: BTN→IND (90%), SSD→CHN (88%), MEX→USA (75%), CAN→USA (73%)
- USA and CHN are gravity wells — multiple dependent states each
- Temporal stability: Jaccard >0.8 from 2001+ (BACI era). Pre-2000 noisier (IMF/COMTRADE inconsistency).

**Key insight for ρ:** Use weighted degree or trade intensity (trade/GDP), not binary edges. Also capture trade concentration (top partner share) — a country dependent on one partner has fundamentally different coupling than one with diversified trade.

### Output Files (Gravity)

| File | Description |
|------|-------------|
| `data/cepii_gravity.arrow` | Annual bilateral trade panel (post-1950, 30 selected columns) |
| `data/cepii_gravity_countries.arrow` | Country lookup (252 countries, existence dates, hegemonic spheres) |

### Laeven & Valencia — Systemic Crisis Database

152 banking crisis episodes across 123 countries, 1976–2015. Source: IMF WP/18/206 Excel file inside wp18206.zip. Two sheets used: "Crisis Years" (wide format, comma-separated years per crisis type) and "Crisis Resolution and Outcomes" (episode-level fiscal costs, output losses).

**Data transformation:** The original "Crisis Years" sheet stores multiple crisis years in single cells (e.g., "1980, 1989, 1995, 2001"). This was exploded into a country-year panel: one row per year a crisis was active (start through end), yielding 463 crisis-active country-year rows. The "Crisis Resolution and Outcomes" sheet provides episode-level severity measures.

**Country name → ISO3 mapping:** Dataset uses country names, not ISO3 codes. 93 of 118 unique names matched QoG directly. 25 required manual remapping (e.g., "Korea" → KOR, "Congo, Dem Rep" → COD, "United States" → USA). All 118 resolved. Country names also had trailing whitespace and footnote annotations ("Argentina 8/", "Armenia 4/") that were stripped.

**Outcome measure cleaning:** Numeric columns contained "..." and "…" (ellipsis) for missing values, stored as strings alongside Float64 values (type `Any`). Cleaned to proper `Union{Missing, Float64}`.

**Outcome missingness by decade:**

| Measure | 1970s | 1980s | 1990s | 2000s | 2010s |
|---------|-------|-------|-------|-------|-------|
| output_loss_pct | 0% | 0% | 23% | 0% | 25% |
| fiscal_cost_pct_gdp | 67% | 50% | 51% | 0% | 25% |
| peak_npls_pct | 67% | 45% | 28% | 0% | 0% |
| public_debt_increase_pct | 0% | 10% | 16% | 0% | 0% |

2000s episodes have zero missing across all four key measures. Pre-2000 missingness is concentrated in post-Soviet transitions (Georgia, Armenia, Azerbaijan, Belarus), conflict states (Liberia, Bosnia, Eritrea), and small/fragile states — countries too disrupted to track their own crisis costs. The missingness IS signal.

**Validation:** Spot-checked known crises against published literature values:
- Argentina 2001: output loss 71%, fiscal cost 9.6%, NPLs 20.1% ✓
- United States 2007: output loss 30%, fiscal cost 4.5%, NPLs 5.0% ✓
- Indonesia 1997: output loss 69%, fiscal cost 56.8%, NPLs 32.5% ✓

**Crisis clustering:** Major visible waves: 2008 (22 countries — GFC), 1991-1995 peak (26-30 — post-Soviet + Latin America), 1997-1998 (21-26 — Asian Financial Crisis). Temporal clustering alone does not prove contagion — cross-referencing with trade network data needed to distinguish contagion from coincidence (e.g., 1996: Bulgaria, Czech Republic, Jamaica, Yemen — likely independent events).
