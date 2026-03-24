# Slug Selection Strategy

## Purpose

Define the rules for selecting QoG slugs into the SOC model's six measurables (O, E, M, ρ, σ², U). Slug selection must satisfy three orthogonal constraints simultaneously:

1. **Coverage tier** — which countries does the slug cover?
2. **Temporal profile** — does the slug have enough history for backtesting?
3. **Conceptual fit** — does the slug measure what the component needs?

## 1. Coverage Tier Strategy

Primary target: **global_95** (≥95% population-weighted penetration).

| Tier | Penetration | Role | Use case |
|------|------------|------|----------|
| `global_95` | ≥95% pop-weighted | **Primary pool** | Default for all model components |
| `global_90` | ≥90% pop-weighted | **Fallback** | Only when global_95 has no candidate for a component |
| `partial` (clustered) | <90%, clustered | **Targeted analysis** | Country-profile-specific studies (e.g., "post-Soviet only") |
| `regional` / `subregional` | High in 1–2 regions | **Excluded from global model** | May inform regional sub-models later |
| `sparse` | <sparse threshold | **Excluded** | Insufficient coverage |

**Rule:** The global model uses only global_95 slugs. If a conceptual slot has zero global_95 candidates, escalate to global_90 before compromising the concept. Never pull partial/regional slugs into the global model.

## 2. Temporal Profile Strategy

For backtesting, slugs must cover historical episodes of interest (e.g., Soviet collapse ~1989, Asian financial crisis ~1997, Arab Spring ~2011, COVID ~2020). This requires temporal depth, not just current coverage.

### Temporal Profiles (from Phase 1 reclassification)

| Profile | Count | Definition | Backtesting value |
|---------|-------|-----------|-------------------|
| `anchor` | 119 | Long-running, continuous, current | **Highest** — backbone of the time series |
| `current` | 240 | Actively updated, may have shorter history | **High** — good for recent episodes |
| `modern` | 887 | Started recently, current | **Medium** — limited backtesting depth |
| `legacy` | 240 | No longer updated (dead) | **Conditional** — valuable only if joinable with a successor |
| `experimental` | 355 | Dropped in Phase 1 | **Excluded** |
| `historical` | 168 | Dropped in Phase 1 | **Excluded** |

### Preference Order for Backtesting

1. **Anchor slugs** — preferred whenever available. These are the temporal backbone.
2. **Current slugs with good history** — `min_year` early enough to cover target episodes.
3. **Legacy + successor joins** — a legacy slug joined with its current replacement to create a continuous series. Requires:
   - Same prefix (same data source)
   - Overlapping or adjacent `max_year`/`min_year`
   - Compatible measurement methodology (verified manually)
4. **Modern slugs** — acceptable for recent-window analysis but cannot anchor backtesting.

### Temporal Windows for Backtesting

| Window | Years | Key episodes covered |
|--------|-------|---------------------|
| Deep | 1970–present | Oil shocks, Cold War end, Soviet collapse |
| Standard | 1990–present | Post-Cold War transitions, Asian crisis, 9/11, Arab Spring, COVID |
| Recent | 2005–present | Global financial crisis, Arab Spring, COVID, Ukraine |

**Rule:** Each model component must have at least one anchor or long-history-current slug that reaches back to 1990 (standard window). The deep window is desirable but not required for all components.

## 3. Conceptual Mapping Strategy

Each slug must map to exactly one of the six measurables. The mapping is based on what the slug **measures**, not its source prefix.

### Component → Concept → Slug Pool Logic

| Component | Concept | What to look for in slugs |
|-----------|---------|--------------------------|
| **O** (Order) | Institutional constraint, rule of law, regulatory quality | Governance quality indices, rule of law scores, regulatory indicators |
| **E** (Excitation) | External perturbation, stress, shocks | Conflict intensity, trade volatility, migration pressure, natural disaster exposure |
| **M** (Mass) | System inertia, institutional thickness | Population, GDP, government size, bureaucratic depth |
| **ρ** (Density) | Coupling, connectivity, transmission channels | Trade openness, internet penetration, urbanization, infrastructure density |
| **σ²** (Entropy) | Disorder, heterogeneity, fragmentation | Ethnic fractionalization, income inequality, political polarization |
| **U** (Potential) | Latent capacity, stored energy, development headroom | Education levels, human capital, natural resource endowment, R&D investment |

**Rule:** A slug's conceptual assignment is determined by domain judgment, not by its prefix. The same prefix (e.g., `wdi_`) may contribute slugs to multiple components.

### Provenance Preferences

Not all data sources are equally reliable. Prefer slugs from sources with:
- Transparent methodology
- Consistent measurement over time (no methodology breaks)
- Primary data collection (not indices-of-indices)

| Provenance tier | Examples | Preference |
|-----------------|---------|------------|
| **Official statistics** | WDI, UN, WHO, ILO | Preferred — primary measurement |
| **Expert surveys** | V-Dem, WGI, BTI | Acceptable — systematic methodology |
| **Composite indices** | HDI, FSI, EIU Democracy | Caution — may duplicate inputs, methodology opaque |
| **Event/factual** | UCDP conflict, COW | Preferred for E component — direct observation |

**Rule:** Avoid composite indices that bundle concepts across multiple components. Prefer disaggregated measures. An index that combines "rule of law" and "corruption" conflates O and σ² — use the sub-indicators instead if available.

## 4. Combined Selection Algorithm

A slug is selected for the model if and only if it passes all three filters:

```
SELECTED = (coverage_tier ∈ {global_95})
         ∧ (temporal_profile ∈ {anchor, current, modern} OR legacy_with_valid_join)
         ∧ (conceptual_mapping assigned to exactly one component)
```

### Priority within a component

When multiple slugs compete for a conceptual slot within a component:

1. **Anchor + global_95** — first choice
2. **Current (long history) + global_95** — second choice
3. **Legacy-joined + global_95** — third choice (creates a synthetic continuous series)
4. **Modern + global_95** — last resort (limits backtesting depth)

### Redundancy budget

Multiple slugs per component are expected (each component is an aggregate). But:
- Avoid redundant slugs that measure the same thing from the same source
- Prefer complementary perspectives (e.g., O gets both "rule of law score" and "regulatory quality score" — related but distinct facets)
- Flag high-correlation pairs (r > 0.95) for manual review — likely duplicates

## 5. Legacy Join Protocol

When a legacy slug can extend a current/modern slug's history:

1. **Identify candidates:** Same prefix, overlapping or adjacent year ranges, same conceptual domain
2. **Validate overlap:** Where year ranges overlap, compute correlation on shared years. Require r ≥ 0.90.
3. **Join method:** Use the legacy slug for years before the successor's `min_year`. Use the successor for all subsequent years. In overlap years, use the successor (more recent methodology).
4. **Document the join:** Record legacy slug, successor slug, join year, overlap correlation in a join manifest.

## 6. Grounding Firewall

The index slug set and the grounding slug set must be **disjoint** — no slug can appear in both. This prevents circular validation. However, no slugs are pre-committed to either role. Assignment happens during slug selection based on conceptual fit, coverage, and the need for domain-independent validation.

The five empirical signatures of criticality (power-law, correlation divergence, scale invariance, flicker, fat tails) are **tests applied to model outputs**. Grounding validates whether the model's composite outputs exhibit SOC signatures.

## Next Steps

1. Cross-reference global_95 slugs with temporal profiles to get the actual candidate pool size
2. Map candidates to the six components using `qog_slugs_temporal.csv` descriptions and prefix metadata
3. Identify legacy join opportunities within the candidate pool
4. Build the selection notebook (`p02_slug_selection.ipynb`)
