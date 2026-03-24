# Slug Strategy

**Status:** Draft. Follows from model architecture (2a).
**Purpose:** Define the methodology for mapping model sub-components to QoG slugs. This document specifies eligibility rules, not specific slug assignments — those are in `slug_mapping.md` after the selection notebook (2c).

---

## 1. Slug Landscape (from Phase 1 Classification)

### 1.1 Coverage Tiers

| Tier | Count | Criterion | Role |
|------|-------|-----------|------|
| **Global_95** | ~544 | Population-weighted penetration ≥ 0.95 | Primary pool for global index |
| **Global_90** | ~24 | Penetration 0.90–0.95 | Secondary pool — minor coverage gaps |
| **Partial** | ~740 | Penetration 0.05–0.90, no drop reason | Clustering pool — informative for country profiles, not for global index |
| **Sparse** | ~14 | Penetration < 0.05 | Excluded |
| **Dropped** | ~544+144 | Experimental (355) + historical (168) + manual exclusions (24) | Excluded |

**Selection target:** Global_95 is the primary pool. Global_90 is acceptable as fallback. Partial-tier slugs are excluded from the global index but may inform sub-analyses.

### 1.2 Temporal Profiles

| Profile | Total | In Global_95 | Description |
|---------|-------|-------------|-------------|
| **Anchor** | 119 | ~52 | Long-running, continuous. Best for backtesting. |
| **Modern** | 887 | ~199 | Started recently but broadly adopted. Good current coverage. |
| **Current** | 240 | ~16 | Actively updated. |
| **Legacy** | 240 | ~98 | No longer updated. Can extend time series via joins with successors. |
| **Experimental** | 355 | 0 | Dropped. |
| **Historical** | 168 | 0 | Dropped. |

### 1.3 Provenance

| Provenance | Count | Description |
|------------|-------|-------------|
| **SURVEY** | ~1097 | Mass public opinion, household surveys, perception data |
| **EXPERT** | ~286 | Subject-matter expert assessments (V-Dem, BTI, WJP) |
| **OFFICIAL** | ~240 | Government/IGO administrative statistics (WDI, IMF, OECD) |
| **EVENT/FACTUAL** | ~167 | Discrete countable occurrences (elections, conflicts, coups) |
| **IMPUTED** | ~134 | Academic modeling, historical reconstruction, interpolation |
| **PHYSICAL** | ~76 | Geospatial, environmental, demographic realities |

### 1.4 Country-Profile Clusters (9 labeled)

| Label | Slugs | What it tells you |
|-------|-------|-------------------|
| `near_global_excl_microstates` | ~37 | Near-universal minus microstates — academic expert data |
| `assessable_governance_institutions` | ~41 | States open to external rule-of-law assessment (WJP) |
| `near_global` | ~26 | Covers all but dissolved/micro/failed |
| `codifiable_electoral_machinery` | ~24 | States with functioning electoral systems |
| `moderate_institutional_visibility` | ~22 | Cabinet/historical data — documented governance |
| `mature_labor_statistics` | ~33 | Advanced statistical office infrastructure |
| `established_democracies_open_parliament` | ~17 | Parliamentary composition data |
| `capable_willing_reporters` | ~10 | Voluntary IMF fiscal reporters |
| `untagged` | ~380+ | Weak cohesion — not used for downstream mapping |

---

## 2. Eligibility Rules by Component

### 2.1 O (Ordering / Dissipation)

**Coverage:** Global_95 required. Backtesting depends on these slugs having deep temporal coverage.
**Temporal:** Anchor or current-with-history strongly preferred. Legacy acceptable if joinable with successor and measurement continuity is verified.
**Provenance:** EXPERT + EVENT/FACTUAL preferred. Ordering is about institutional quality and factual records of constraint enforcement — expert assessment and event counting are the most direct measurement methods.

| Sub-component | Measurement concept | Likely slug sources | Provenance |
|---------------|-------------------|--------------------| -----------|
| Physical security | Violence levels, political terror, military capacity under civilian control | PTS, UCDP, FSI security, BICC, WDI military | EXPERT, EVENT/FACTUAL, OFFICIAL |
| Constraint enforcement | Rule of law, executive constraints, judicial independence | V-Dem, WJP, WGI, Polity | EXPERT |
| Social/religious constraint | Interpersonal trust, social cohesion, religious norms | WVS, V-Dem civil society | SURVEY, EXPERT |
| Expression of disagreement | Press freedom, civil liberties, protest space | V-Dem, FH, RSF | EXPERT |
| Anti-privilege capture | Corruption control, regulatory quality, military regime flags (inverse) | V-Dem, WGI, TI, BTI, CHISOLS | EXPERT, EVENT/FACTUAL |

**Military as O (guideline):** Military capacity under civilian control is physical security — the state's monopoly on organized violence. Candidate slugs: `wdi_expmil`, `wdi_afp`, `bicc_gmi`, `wvs_confaf`. When the military captures the state (`chisols_mil`, `chisols_indmil`), it crosses from O to E — the damping mechanism becomes a driving force.

**Risk:** O sub-components are EXPERT-heavy. This is inherent to the concept — institutional quality is not directly measurable from administrative statistics. Diversify across expert sources (V-Dem, WJP, WGI, BTI, FH) to avoid single-source dependence.

### 2.2 E (Excitation / Driving)

**Coverage:** Global_95 required for core sub-components. Interstate competition may require network layer (Phase 0b).
**Temporal:** Anchor preferred for backtesting. Economic indicators (WDI) tend to have good temporal depth.
**Provenance:** OFFICIAL + EVENT/FACTUAL + PHYSICAL preferred. Driving forces are observable through administrative statistics, event records, and physical measurements.

| Sub-component | Measurement concept | Likely slug sources | Provenance |
|---------------|-------------------|--------------------| -----------|
| Economic demands | GDP growth, trade pressure, unemployment, resource scarcity | WDI, IMF, PWT | OFFICIAL |
| Social mobilization | Civil society participation, protest, demographic pressure | V-Dem, WDI population | EXPERT, OFFICIAL |
| Interstate competition | Geopolitical pressure, arms trade, alliance obligations, active conflict | WDI military, SIPRI, COW, ATOP, UCDP | OFFICIAL, EVENT/FACTUAL |
| Religious mobilization | Religious organization strength, faith-based political action | V-Dem religion indicators | EXPERT |
| Communication pathways | Internet penetration, media reach, mobile coverage | WDI ICT, ITU | OFFICIAL, PHYSICAL |

**Military as E (guideline):** Arms trade (`wdi_armexp`, `wdi_armimp`) measures military energy crossing borders. Alliance obligations (`atop_defensive`, `atop_offensive`) create forced nearest-neighbor coupling. Active conflict (`ucdp_type1`–`ucdp_type4`) is the most extreme excitation. Non-state armed actors (`chisols_warlord`) inject correlated excitation outside institutional channels.

**Note:** E's network diffusion term (neighbor excitation spillover) comes from Phase 0b, not from QoG slugs.

### 2.3 M (Mass / Inertia)

**Coverage:** Global_95 required.
**Temporal:** Shorter history acceptable — mass describes system state, not criticality dynamics.
**Provenance:** OFFICIAL + PHYSICAL preferred. Stock variables measured by administrative statistics and physical observation.

| Sub-component | Measurement concept | Likely slug sources | Provenance |
|---------------|-------------------|--------------------| -----------|
| Human capital | Education enrollment/completion, life expectancy, health | WDI, UNDP, UNESCO | OFFICIAL |
| Institutional depth | Polity age, institutional complexity, constitutional longevity, military-state fusion | Polity, V-Dem, CPDS, WGOV | EXPERT, IMPUTED |
| Demographic mass | Population, age structure, dependency ratios | WDI, UN Population | OFFICIAL, PHYSICAL |
| Natural capital | Resource rents, arable land, environmental quality | WDI, FAO | OFFICIAL, PHYSICAL |

### 2.4 U (Internal Energy)

**Coverage:** Global_95 required for economic kinetic and resource potential. Human potential and social thermal may require cluster-informed slugs.
**Temporal:** Shorter history acceptable.
**Provenance:** OFFICIAL + PHYSICAL preferred.

| Sub-component | Measurement concept | Likely slug sources | Provenance |
|---------------|-------------------|--------------------| -----------|
| Economic kinetic | GDP, trade flows, government expenditure | WDI, PWT, IMF | OFFICIAL |
| Resource potential | Resource rents, reserves, sovereign wealth | WDI, Ross | OFFICIAL |
| Human potential | Labor participation, underemployment, education-job mismatch | WDI, ILO | OFFICIAL |
| Social thermal | Unresolved grievances, unprocessed demands, tension | FSI, V-Dem | EXPERT |

**Risk:** Social thermal energy is the hardest to measure directly. Proxy indicators (Fragile States Index components, V-Dem social polarization) are the best available.

### 2.5 S (Entropy / Information)

**Coverage:** Global_95 required for economic and political measures. Social heterogeneity may have sparser coverage.
**Temporal:** Shorter history acceptable.
**Provenance:** OFFICIAL + SURVEY + PHYSICAL mix. Diversity measures draw from multiple data-generation methods.

| Sub-component | Measurement concept | Likely slug sources | Provenance |
|---------------|-------------------|--------------------| -----------|
| Economic diversity | Sectoral complexity, export diversification | WDI, UNCTAD | OFFICIAL |
| Political pluralism | Party fractionalization, civil liberties, media diversity | DPI, V-Dem, FH | EXPERT, OFFICIAL |
| Social heterogeneity | Ethnic/linguistic diversity, Gini, income shares | AL, SWIID, WDI | PHYSICAL, OFFICIAL |
| Institutional variety | Federalism, subnational layers, independent agencies | V-Dem, DPI, WGI | EXPERT |

### 2.6 ρ (Density / Coupling) — Hybrid Component

**QoG sub-components (within-country coupling):**
**Coverage:** Global_95.
**Provenance:** OFFICIAL + PHYSICAL.

| Sub-component | Measurement concept | Likely slug sources |
|---------------|-------------------|--------------------|
| Physical infrastructure | Electricity access, transport | WDI |
| Communications | Internet penetration, broadband, mobile | WDI, ITU |

**Network sub-components (between-country coupling):**
Source: Phase 0b network data (CEPII GeoDist + BACI trade). NOT from QoG slugs.

| Sub-component | Metric | Source |
|---------------|--------|--------|
| Degree centrality | Number/strength of connections | Trade + geographic network |
| Betweenness centrality | Position on critical paths | Trade + geographic network |
| Community membership | Bloc affiliation | Community detection on network |
| Military alliance edges (potential) | Alliance-based nearest-neighbor coupling | ATOP (`atop_defensive`, `atop_offensive`, `atop_number`) |

---

## 3. Cross-Cutting Constraints

### 3.1 Grounding Firewall

The index slug set and the grounding slug set must be **disjoint** — no slug can appear in both. This prevents circular validation (using a variable to both define and validate the state).

Which specific slugs go into which set is a **slug selection decision**, not a pre-committed constraint. Any slug in the eligible pool is a candidate for either role until assigned. The selection notebook (p02_03) will partition slugs into index vs. grounding sets based on conceptual fit, coverage, and the need for domain-independent validation sets.

### 3.2 No Slug Reuse

A slug may appear in **at most one** component. No double-counting across O, E, M, U, S, ρ.

### 3.3 Source Diversity

No single data source prefix should dominate any component. If 4 of 5 sub-components in O use V-Dem slugs, diversify — even if V-Dem has the best coverage.

### 3.4 Missingness-Aware Weighting

Each sub-component should have ≥2 candidate slugs (primary + fallback). When a country-year is missing the primary slug, the component is computed from available slugs with renormalized weights. The aggregation pattern follows `order.md` section 4.3 — compute each available component, renormalize over what exists, return diagnostics.

### 3.5 Directionality Convention

All slugs must be oriented **good-is-high** after normalization. Bad-is-high raw slugs (e.g., political terror, corruption indices where higher = worse) are inverted during data assembly (Phase 3a). Directionality must be documented per slug in `slug_mapping.csv`.

---

## 4. Temporal Strategy (Detail)

### 4.1 Criticality Measurement (O, E, Grounding)

These slugs must support backtesting across historical episodes. Temporal depth is critical.

| Priority | Profile | Rationale |
|----------|---------|-----------|
| **Preferred** | Anchor | Long-running, continuous. The only profiles that span pre-1990 events (Soviet collapse). |
| **Good** | Current with history | Actively updated and backward-looking. Covers post-2000 episodes (Arab Spring, color revolutions). |
| **Acceptable** | Legacy joined with successor | Extends coverage by chaining a dead slug with its replacement. Must verify measurement continuity at the join point — same methodology, same scale, same coding rules. |
| **Avoid** | Modern-only, short-lived | Insufficient depth. Cannot validate criticality dynamics over meaningful historical windows. |

### 4.2 Physics Model (M, U, S, ρ)

These slugs describe system state at a point in time. Deep backtesting is less critical.

| Priority | Profile | Rationale |
|----------|---------|-----------|
| **Good** | Any current or modern slug with ≥10 years of data | Sufficient for state description and short-window dynamics. |
| **Acceptable** | Legacy with moderate history | Still usable if the dead period is recent and the indicator remains conceptually valid. |

### 4.3 Network Data Temporal Constraint

CEPII BACI trade data starts ~1995. Between-country network analysis is limited to post-1995. Geographic network (GeoDist) is static. This means:
- Network-enhanced grounding signatures have shorter temporal reach than QoG-only signatures
- Pre-1995 backtesting uses QoG-only (within-country) signatures

---

## 5. Selection Process (for notebook p02_03)

For each sub-component:

1. **Query** the enriched metadata for candidate slugs matching the measurement concept
2. **Filter** by coverage tier (global_95 first), temporal profile (anchor preferred for O/E), provenance (per component preference)
3. **Evaluate** each candidate: penetration score, temporal coverage, codebook description (verify it measures what we think), directionality
4. **Check** grounding firewall (not reserved for validation)
5. **Check** no-reuse constraint (not already assigned to another component)
6. **Select** primary + fallback slugs
7. **Document** rationale, directionality, known limitations

Output: `work/data/slug_mapping.csv` with schema:
```
component, sub_component, slug, role, directionality, provenance, coverage_tier, temporal_profile, notes
```

---

## 6. Known Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| O is EXPERT-heavy | Single measurement method bias | Diversify across expert sources (V-Dem, WJP, WGI, BTI, FH) |
| Social thermal energy (U) hard to measure | Weak proxy for internal tension | Use multiple indirect indicators; flag as lower confidence |
| Institutional depth (M) may require IMPUTED data | Reconstruction artifacts | Document provenance clearly; sensitivity test with/without |
| Ethnic/linguistic diversity (S) is slow-changing | Low temporal variance | Accept as near-constant structural feature |
| Network data starts ~1995 | Limits between-country backtesting | Use QoG-only signatures for pre-1995; acknowledge constraint |
| Set B grounding slugs (non-V-Dem) may be sparse | Weaker cross-domain validation | Accept partial domain independence if full independence unavailable |
