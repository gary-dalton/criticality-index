# Real-Data Considerations — Methodology Caveats for Empirical Application

## Purpose

This document captures methodological considerations that arise when applying the synthetic-validation signature battery (distorted SOC detection, power-law fits, fractal dimensions, branching ratio, spectral analysis) to real-world governance data. Synthetic data from the Manna simulator is idealized — every avalanche is recorded, every toppling is counted, events are perfectly timestamped. Real governance data has none of these properties.

Each section below addresses one class of real-data artifact, its distinguishability from true physical distortion, and the operational recipe for handling it.

---

## 1. Under-Reporting of Small Events

The most pervasive real-data artifact. Small crises, minor protests, local disruptions, marginal policy changes — these are chronically under-counted in every available dataset, while large events (wars, coups, systemic banking crises) are reliably recorded.

### 1.1 What it does to the observed distribution

- **Physics:** small events exist but aren't recorded.
- **Apparent distribution:** truncated at the low end; above some detection threshold `x_detect` the recorded distribution approximates the true distribution.
- **Apparent α:** naive fitting with xmin below `x_detect` biases α high (the fit tries to compensate for missing low-end weight by increasing the steepness).

### 1.2 The CSOC-mimicry problem

Under-reporting produces a low-end-truncated distribution — superficially identical to the **CSOC-like signature** of suppressed-release dynamics (see [`distorted_soc_signatures.md`](distorted_soc_signatures.md) Part II.1). This is a serious inferential trap: a purely statistical artifact masquerades as a physical regime classification.

However, the mimicry is **incomplete**. The distorted-SOC catalog specifies CSOC as a *bundle* of co-occurring observations, many of which under-reporting cannot produce:

| Feature | True CSOC / suppressed-release | Under-reporting artifact |
|---------|--------------------------------|---------------------------|
| Low-end distributional truncation | Yes | Yes |
| High-end excess (deficit redistribution) | **Yes** | **No** — no physical redistribution |
| Characteristic scale at threshold | Yes (physical) | Yes (detection limit) |
| Quasi-periodic large events | **Yes** | **No** |
| Spectral knee | **Yes** | **No** (censored spectrum is still the true spectrum at measurable frequencies) |
| Non-stationary σ(t) | **Yes** | **No** |
| Deep quiescence post-large-event | **Yes** | **No** |
| σ appears subcritical during accumulation, supercritical during release | **Yes** | **No** |
| Avalanche shape collapse fails | **Yes** | **No** (shape is a property of recorded events; under-reporting doesn't distort it) |

The single-observable α cannot distinguish CSOC from under-reporting. **The full signature bundle can.**

### 1.3 Operational recipe

**(a) Determine the under-reporting threshold empirically.**

For any real dataset, run a break-point analysis on the log-binned distribution: find the size `x_detect` below which the empirical distribution deviates from the expected power-law form (undercount shows as a flattening or dip of P(x) at small x). Use xmin above `x_detect` in all subsequent fits.

**(b) Bracket the xmin in the plausible scaling regime, not at arbitrary fixed values.**

For synthetic data we use xmin ∈ {5, 10} because the small-s kink is at s ≈ 3-5 and the cutoff is at s >> 10⁴. For real governance data the scaling regime is different. A reasonable default: compute the bracket at the 25th and 50th percentile of recorded events. The bracketed-reporting rule (see `feedback_xmin_bracketed_reporting` memory) applies; only the bracket values shift.

**(c) Never claim CSOC-like regime classification from α alone.**

The regime claim requires **co-occurrence of at least three independent signatures from the bundle** ([`distorted_soc_signatures.md`](distorted_soc_signatures.md) Part I — the evidentiary standard). α-based truncation plus one or more of: quasi-periodicity, non-stationary σ, post-large-event quiescence, or spectral knee. Without these, report only "distribution shape consistent with truncation (physical or artifactual); cannot discriminate without further signatures."

**(d) Prefer area and duration distributions when available.**

Area (spatial extent, affected population count, etc.) and duration (event span in time) are less vulnerable to under-reporting than count-based size measures. If a crisis is recorded at all, its extent and duration are usually accurate. α_area and α_duration can be compared to natural-SOC predictions with less under-reporting anxiety than α_size.

**(e) The xmin-bracket width is ambiguous in real data.**

In synthetic Manna, a bracket width ≳ 0.05 between α(xmin=5) and α(xmin=10) would be a CSOC-like detection signal (see [`distorted_soc_signatures.md`](distorted_soc_signatures.md) II.1). In real data, large bracket width can mean:
- True multiscaling or CSOC distortion (physical)
- Severe under-reporting noise (artifactual)
- Insufficient sample size in the tail

Large bracket width is a *flag for further investigation*, not a detection claim in real data.

### 1.4 Proposed validation experiment

Before trusting the signature battery on real data, validate it on **artificially-under-reported synthetic Manna data**:

**Model F (proposed addition to Experiment 05 or Experiment 01.04):** apply a censoring function `P_record(s) = 1 - exp(-s/s_censor)` to the natural-Manna catalog (retains large events with probability ≈ 1, drops small events with probability approaching 1 as s → 0). Sweep `s_censor ∈ {1, 5, 10, 30, 100}`. Run the full signature battery on the censored catalog.

**Expected outcome:** the single-observable signatures (α, spectral β, kurtosis) will mimic CSOC as `s_censor` grows, but the multi-signature bundle (σ(t) stationarity, shape collapse, post-event quiescence, quasi-periodicity) will *fail* to match CSOC predictions — because no physical redistribution is happening, only censoring.

**If validated**: we have a quantitative recipe for distinguishing real distortion from artifact in governance data.

**If the full bundle also mimics CSOC under censoring**: we have a real problem. Some signatures (e.g., σ(t) stationarity) may be corrupted by under-reporting in ways we haven't anticipated. Need additional discriminants — possibly moment-ratio tests, or comparisons across different independent data sources measuring the same underlying events.

This experiment is cheap: we already have 100-seed Manna Arrow catalogs; applying a censoring filter and re-running diagnostics is ~1 hour of compute. Recommended as an addition to the Exp 05 program before Phase 3 governance work.

---

## 2. Heterogeneous Temporal Grids

*(Placeholder — to be expanded as we encounter the issue in Phase 2/3 governance data.)*

Governance data comes in mixed cadences: annual surveys (V-Dem, QoG), event streams (EM-DAT disasters with date of occurrence), quarterly macroeconomic indicators (WDI), monthly (inflation, exchange rates), daily (stock market). SOC signature detection assumes a coherent time series at uniform cadence. Coarsening everything to annual loses event-scale temporal structure (inter-event times, PSD); keeping high-cadence data requires interpolating coarse data which injects its own artifacts.

Operational implications to be worked out during Phase 2.

---

## 3. Categorical vs Continuous Variables

*(Placeholder — to be expanded as we encounter the issue.)*

Many governance variables are categorical or ordinal (regime type, severity class, survey Likert scales). Power-law analysis requires a continuous-valued quantity. Either: (a) convert categorical to continuous via score (e.g., V-Dem polyarchy index), losing category-specific information; or (b) restrict signature detection to variables that are natively continuous (inflation rate, debt/GDP, displacement flow counts). Both options have trade-offs.

Operational implications to be worked out during Phase 2.

---

## 4. Reporting Schema Mismatches Across Sources

*(Placeholder — to be expanded as we encounter the issue.)*

EM-DAT counts deaths and affected populations per event; DOSE measures subnational GDP; Laeven & Valencia records binary systemic crisis. None of these measure the "same" thing — they are different observables of a shared underlying socio-economic criticality. How to combine? When does a cross-source signature agreement mean something physical vs. when does it just reflect shared coverage biases?

Operational implications to be worked out during Phase 2.

---

## 5. Missingness Patterns

*(Placeholder — to be expanded during Phase 1b/2 work.)*

Phase 1 classification already identified 10 country-status categories by missingness profile. Systematic missingness (entire country eras absent, entire variables unreleased in given windows) produces signature distortions that differ from random missingness. Operational recipe requires categorizing countries and variables by missingness type and deciding which combinations support which signature tests.

Hooks into Phase 1b (structural integration / coverage matrix) and the cluster-informed slug strategy.

---

## Related documents

- [`distorted_soc_signatures.md`](distorted_soc_signatures.md) — the signature catalog being applied to real data. Part I's evidentiary standard (co-occurrence required) is the key defense against artifact-mimicry problems.
- [`overtopping.md`](overtopping.md), [`liquefaction.md`](liquefaction.md) — primary mechanism formalisms whose detection we're trying to enable
- [`energy_accounting.md`](energy_accounting.md) — richer instrumentation (per-bond flux, PE snapshots) becomes more important in real-data settings where single-variable measures are compromised
- [`../validation/05_suppression_amplification.md`](../validation/05_suppression_amplification.md) — the validation experiment where Model F (artificial under-reporting) would fit
- `feedback_xmin_bracketed_reporting` memory — the xmin-bracket methodology that still applies to real data (with data-specific bracket values)

## Open questions

1. For governance data, what is a reasonable default `x_detect` heuristic? Probably source-specific (EM-DAT has its own minimum-disaster threshold; Laeven-Valencia is binary so the question is N/A).
2. Is there a quantitative test for distinguishing CSOC from under-reporting that doesn't require the full bundle? Perhaps a moment-ratio test that is sensitive to redistribution but not to censoring?
3. How much of Phase 3 locked-analysis should be gated on successful Model F validation?
