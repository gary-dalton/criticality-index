# Feasibility Assessment: What Can Be Tested and With What Data

## Purpose

This document separates what is testable from what is aspirational, and maps each claim to the data and methods required to test it. Intellectual honesty demands knowing where the boundaries are before starting.

---

## Tier 1: Testable with QoG Data (This Project)

These are the claims the main project tests. Annual country-level panel data, ~200 countries, 1946-2023.

### The Five Empirical Signatures

| Signature | Testable? | Method | Constraint |
|-----------|-----------|--------|------------|
| 1. Power-law distribution | Yes, with caveats | MLE + KS on year-over-year changes in governance indicators | ~70 years max per country. MLE needs 50-100+ observations for reliable fitting. 20-year windows are marginal. Cross-country pooling helps but introduces heterogeneity |
| 2. Diverging correlation length | Yes | Mutual information between indicator pairs across sectors | Annual resolution sufficient for detecting cross-sector coupling. Requires enough slugs per country-year |
| 3. Scale invariance | Partially | Compare local (subnational) vs. national dynamics | Requires DOSE/SHDI subnational data. Only ~10 countries have 40+ years of subnational data. Most start at 2000 |
| 4. Fractal structure | Partially | Subnational distribution matching + network renormalization | Subnational: same coverage limitation as Sig 3. Network: requires CEPII data integration (Phase 1b.3) |
| 5. Fat-tailed changes | Yes | Excess kurtosis + GPD fitting on first differences | Works with annual data. Kurtosis is sensitive to sample size but computable |

### Complementary Diagnostics

| Diagnostic | Testable? | Constraint |
|-----------|-----------|------------|
| Branching ratio (sigma) | No | Requires high-frequency event-level data with causal linkage. Annual country-level data cannot identify which events triggered which |
| Inter-event times | Partially | Computable for crises (Laeven & Valencia) and disasters (EM-DAT). Limited to these event types |

### C_d Computation and Backtesting

| Claim | Testable? | Method |
|-------|-----------|--------|
| C_d = E - O measures distance from criticality | Yes | Construct from QoG slugs, calibrate against signature ground truth |
| Power delivery maximized at criticality | Yes | Correlate C_d with governance outcome measures |
| Trajectory (d1, d2) provides early warning | Yes | Time derivatives of C_d, compare to historical crises |
| Phase state classification | Yes | Threshold-based from calibrated C_d |
| Mass threshold / activation threshold | Partially | Identify via signature absence in microstates. Cannot directly measure p_c in governance |

**Bottom line:** The core project — does governance exhibit SOC, can we measure C_d — is feasible with QoG data. Signatures 1, 2, 5 are directly testable. Signatures 3 and 4 are testable where subnational data exists. The branching ratio is data-constrained.

---

## Tier 2: Testable with Synthetic Experiments (Experiments 01-06)

These validate the theoretical framework and diagnostic tools on systems where the answer is known.

| Claim | Experiment | Feasibility |
|-------|-----------|-------------|
| Our diagnostic functions correctly detect SOC | 01 (sandpile) | Fully feasible. Known system, known exponents |
| Percolation threshold is detectable | 02 (percolation) | Fully feasible. Known p_c for 2D square lattice |
| Activation threshold exists for SOC on diluted lattice | 03 (activation) | Feasible. Novel result — the relationship between p* and p_c is the finding |
| Absorbing barrier exists and is measurable | 04 (overload) | Feasible with degradation model. Whether it's a sharp transition or gradual is the finding |
| CSOC signatures are detectable and distinct | 05 (CSOC/ISOC) | Feasible. Whether signatures are distinguishable at realistic data volumes is the key question |
| ISOC signatures are detectable and distinct | 05 (CSOC/ISOC) | Same |
| Coupled SOC produces emergent behavior | 06 (coupled) | Feasible. Novel experiment |

**Bottom line:** All synthetic experiments are computationally feasible. The question is not "can we run them" but "do the results support the theoretical claims."

---

## Tier 3: Testable Only with Domain-Specific High-Frequency Data (Future Work)

These require data beyond QoG's annual country-level panel.

### CSOC/ISOC in Governance

| Claim | Data Required | Available? |
|-------|--------------|------------|
| CSOC accumulation-release cycle in governance | Multi-decade event-level data with identifiable suppression mechanisms | Partially. Financial crises (L&V) have onset dates. But the accumulation phase is precisely when nothing is visible |
| ISOC continuous amplification in governance | High-frequency governance indicators + identifiable amplification source | Not currently. Would need ACLED (daily conflict), financial market data, or similar |
| CSOC vs. genuine sub-criticality | Time series long enough to observe multiple accumulation-release cycles per country | Marginal. 70 years might capture 2-3 cycles if the period is ~20-30 years |
| ISOC vs. genuine super-criticality | Perturbation-response data showing history dependence | Not available in QoG. Would need event-level response data |

### Branching Ratio

| Data Source | Resolution | Feasibility |
|-------------|-----------|-------------|
| ACLED (conflict events) | Daily, geo-located | Would allow sigma estimation for conflict cascades. Deferred |
| Financial market data | Intraday to daily | Would allow sigma for financial contagion. Not in project scope |
| EM-DAT (disasters) | Event-level, ~24k events | Could provide rough sigma for disaster cascades. Temporal resolution marginal |

### Network Cascade Propagation

| Claim | Data Required | Available? |
|-------|--------------|------------|
| Crises propagate through trade/geographic network | Bilateral time-series of crisis indicators with temporal ordering | Partially. CEPII trade data + L&V crisis dates could test whether crises in trading partners precede domestic crises |
| Cascade chain length in the international system | Same + sufficient events for statistical power | Marginal. Limited number of global crisis episodes |

**Bottom line:** CSOC/ISOC dynamics in governance are theoretically interesting but empirically constrained by data resolution. The synthetic experiments (Tier 2) establish whether the signatures are detectable *in principle*. Testing them in governance data requires either purpose-collected high-frequency data or creative use of existing event-level datasets (EM-DAT, L&V, potentially ACLED).

---

## Tier 4: Not Currently Testable (Speculative)

These are ideas that cannot be tested with any currently available data or methods. They are worth developing theoretically but should not be promised as deliverables.

| Concept | Why Not Testable |
|---------|-----------------|
| Percolation threshold as cascade termination condition (dual role of p_c) | Requires formal mathematical derivation, then simulation confirmation. No empirical data can test this directly — it's a property of the model, not of governance |
| Maximum energy boundary (upper operational envelope) | Requires formal derivation of what "maximum transmissible cascade energy" means for a network. The concept may not have a single well-defined value |
| Structural damage from ISOC (pathway remodeling) | Would require longitudinal network data showing structural changes correlated with crisis events. No such dataset exists for governance |
| Intentional tuning toward criticality | Requires establishing that criticality is measurable (Tier 1) and that CSOC/ISOC are real (Tier 2/3) before tuning can be tested |
| Combined CSOC + ISOC (simultaneous suppression and amplification) | Theoretically specifiable, computationally testable on synthetic systems, but no governance data could distinguish this from noise |

**Bottom line:** These are research directions, not testable claims. They inform the theoretical framework and motivate future data collection. They should be clearly labeled as speculative in any publication.

---

## Key Constraints Across All Tiers

### Temporal Resolution

QoG is annual. Most SOC diagnostics were developed for systems with thousands to millions of observations (earthquake catalogs, neural recordings, financial tick data). Governance data has ~70 observations per country at best. This limits:
- Power-law fitting (MLE needs 50-100+ points)
- Spectral analysis (frequency resolution limited by series length)
- Temporal structure analysis (cycle detection needs multiple cycles)
- Branching ratio estimation (impossible without event-level data)

### The Entanglement Problem

In governance, the "intervention mechanism" (O) and the "system dynamics" are entangled — you cannot measure one independently of the other. CSOC/ISOC testing requires identifying the suppression/amplification mechanism independently of the event data. Possible mitigations:
- Natural experiments: externally imposed changes in O (regime change, treaty, sanctions)
- Instrumental variables: O varies for reasons unrelated to system state
- Synthetic experiments: the mechanism is controlled by construction

None of these fully solve the problem for governance data. The entanglement is acknowledged, not resolved.

### Sample Size

~200 countries. Some analyses (cross-sectional comparison, pooled distributions) benefit from this. Others (per-country signature testing) don't — each country is a single time series. The Phase 1 clustering (9 country-profile clusters) helps by grouping similar countries, but within-cluster sample sizes are still small (9-40 countries per cluster).

### Stationarity

Governance systems are non-stationary. Institutions change, borders shift, economies restructure. A 70-year time series is not 70 observations of the same system — it's a trajectory through state space. This limits:
- Distribution fitting (assumes stationarity within the fitting window)
- Spectral analysis (assumes stationarity)
- Any analysis that pools across time

Windowed analysis (20-year rolling windows) is the standard mitigation, but it reduces the effective sample size further.

---

## Implications for the Project

1. **The core project (QoG + C_d) is feasible.** Signatures 1, 2, 5 are testable. C_d is computable. Backtesting is viable. This is what the project delivers.

2. **CSOC/ISOC are a separate research program.** They require synthetic experiments (feasible, planned) and domain-specific data (partially available, partially deferred). They are not part of the core project's deliverables.

3. **Synthetic experiments serve both programs.** Experiments 01-03 validate the tools for the core project. Experiments 04-06 extend into CSOC/ISOC territory. The tool validation is shared.

4. **Speculative concepts (Tier 4) are worth keeping in the ideas folder.** They guide thinking and motivate future work. They should not be presented as testable claims in any publication.

5. **The falsifiability document's demand for pre-registered predictions applies to Tiers 1 and 2.** Tier 3 is hypothesis generation. Tier 4 is theoretical development. Only Tiers 1 and 2 have the data and tools to do hypothesis testing.
