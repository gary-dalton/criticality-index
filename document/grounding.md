# Grounding the Criticality Hypothesis (CH)

This document explains the **grounding layer** implemented in `work/grounding.jl`: a set of *independent diagnostics* that test whether a country-year time series exhibits empirical signatures consistent with **criticality** (often discussed in statistical mechanics and complex systems, including self-organized criticality).

The grounding layer is intended to support an article-style narrative *and* serve as developer documentation for how the Julia functions are meant to be used.

---

## 1) Motivation: we do not know what state a system is in

The core index computes a state estimate (your civilization “state vector” / distance-to-criticality). But that estimate is not, by itself, proof that the underlying system is actually near a critical regime.

**Grounding** is the step that tries to answer:

> *When the index says “near critical,” do we also observe classic empirical signatures of criticality in **independent** measurements?*

### Independence rule (non-negotiable)
The diagnostics in `work/grounding.jl` must use **validation slugs** that are **not used** to compute the state vector itself.

Reason: if a variable helps *define* the state, then using it again to *validate* the state is circular (“grading our own homework”).

---

## 2) The five empirical signatures of criticality

The grounding layer operationalizes the following five signatures:

1. **Power-law distribution of events**  
2. **Diverging correlation length** (system-wide coupling; local perturbations correlate globally)  
3. **Scale invariance** (similar dynamics across aggregation scales)  
4. **Fractal structure** (a spatial/topological version of scale invariance)  
5. **No characteristic event size** (extremes are not exponentially suppressed; “avalanches” at all sizes)

In practice, (1) and (5) are tightly related: “no characteristic size” is often evidenced by heavy tails / power-law-like scaling.

---

## 3) What criticality “provides” (interpretation layer)

This project uses criticality as a *functional* regime that tends to support:

- **Stability without rigidity**
- **Flexibility without chaos**
- **Memory without locking**
- **Exploration without breakdown**

These are not computed directly; they are the interpretive rationale for why validating critical signatures is valuable.

---

## 4) Validation slugs (kept independent from the index)

The grounding layer was designed around these **independent validation slugs**:

| CH signature (target) | Validation slug (example) | What it “observes” |
|---|---|---|
| Power law / avalanches | `vdem_subvrs` | magnitude of government response to domestic unrest |
| Diverging correlation | `vdem_labvrs` and `vdem_relig` | labor and religious action/strength as a sub-swarm synchronization channel |
| Scale invariance | `vdem_localgov` (plus a national comparator) | cross-scale similarity of governance dynamics |
| No characteristic size | `vdem_v3polsoc` (via year-to-year “jumps”) | heavy tails in polarization changes |

> Note: “fractal structure” is discussed conceptually here; its robust measurement typically requires spatial or network geometry not always present in country-year panels. If your dataset later includes subnational grids or network edges, fractal diagnostics can be added.

---

## 5) What `work/grounding.jl` computes

Unlike the main index sensors (which return “scores”), grounding functions return **diagnostic coefficients** plus a **boolean flag** indicating whether a specified acceptance rule is met.

Common patterns:

- Windowed time slices ending at `current_year`
- Missing-data tolerance (minimum sample size)
- Returned results as named tuples, e.g. `(alpha=..., is_critical=...)`

### Acceptance criteria are *tunable*
Thresholds (e.g., “alpha between 0.8 and 1.5”) are **engineering defaults**, not physical constants. They should be validated via:
- sensitivity analysis,
- backtesting against known historical episodes,
- and (ideally) formal goodness-of-fit tests.

---

## 6) Function reference (conceptual contract)

The sections below describe the intended behavior of the functions as developed. If `work/grounding.jl` differs, update either this doc or the code so they match.

### 6.1 `validate_power_law` — Avalanche / power-law signature
**Slug:** `vdem_subvrs`  
**Description:** Government Response to Domestic Unrest  
**Reason:** In a system at the critical slope, the government's reaction to unrest shouldn't be "standardized." It should range from tiny administrative adjustments to massive structural shifts, with no "average" response size.  
**Goal:** detect scale-free “event magnitudes” consistent with avalanche dynamics.

**Inputs (typical):**
- `df_country::DataFrame` — one country’s time series (must include `year` and `vdem_subvrs`)
- `current_year::Int`
- `window::Int=20`

**Output (typical):**
- `alpha` — estimated slope/parameter proxy from a log-log regression / rank-frequency approximation
- `is_critical::Bool` — whether `alpha` falls in an “acceptable” band

**Important notes:**
- Simple log-log regression is a *rough* estimator. A more rigorous approach uses maximum-likelihood estimation + goodness-of-fit comparisons.

---

### 6.2 `validate_correlation_divergence` — Diverging correlation length proxy
**Slug 1:** `vdem_labvrs` (paired with a second independent timeseries)  
**Description 1:** Labor Union Action/Strength  
**Slug 2:** `vdem_relig` (paired with a second independent timeseries)  
**Description 2:** Religious Organizations Action/Strength  
**Reason:** When a system is critical, a strike in a small transport sector shouldn't just stay local; it should correlate with shifts in unrelated sectors (e.g., religion, manufacturing or tech).  
**Goal:** detect unusually strong coupling that suggests a long correlation length.

**Inputs (typical):**
- `df_country::DataFrame` with `year` and at least two columns to correlate
- `current_year::Int`
- (often a `window`, e.g., 10 years)

**Output (typical):**
- `correlation` — Pearson (or Spearman) correlation over the window
- `is_diverging::Bool` — thresholded on absolute correlation magnitude (e.g., `abs(ρ) > 0.75`)

**Important notes:**
- Correlation is a proxy. True “correlation length” is a spatial concept; in panel data this is best treated as a pragmatic diagnostic rather than a literal ξ estimate.
- Prefer *independent* comparator series (not used in the state vector).

---

### 6.3 `validate_scale_invariance` — Cross-scale self-similarity proxy
**Slug:** `vdem_localgov` + a national-level comparator  
**Description:** Local Government Index  
**Reason:** A scale-invariant civilization should look the same at the municipal level as it does at the national level. If the "governance pattern" is a fractal, the same rules of order and excitation should apply regardless of the "box" size.  
**Goal:** test whether normalized dynamics look similar across “scales.”

**Inputs (typical):**
- `df_country::DataFrame` with `year`, `vdem_localgov`, and a national comparator (e.g., `vdem_execcon` or another independent national governance measure)
- `current_year::Int`
- `window::Int` (e.g., 15 years)

**Output (typical):**
- `similarity` — a heuristic similarity score (example: comparing coefficients of variation)
- `is_invariant::Bool` — thresholded similarity

**Important notes:**
- This is a proxy for scale invariance in the absence of true multi-resolution measurements. If you later build municipal/regional/national series explicitly, this test can be upgraded substantially.

---

### 6.4 `validate_event_scaling` — “No characteristic event size” via jumps
**Slug:** `vdem_v3polsoc`  
**Description:** Political Polarization  
**Reason:** In a rigid, sub-critical system, polarization usually moves in predictable, slow increments. At criticality, the "jumps" in polarization can be tiny or massive—the "Avalanche" of social sorting.  
**Goal:** detect heavy-tailed behavior in *changes* (first differences), not in levels.

**Method (thread-derived):**
1. window the time series
2. compute year-over-year changes (“jumps”)
3. compute excess kurtosis (or another tail metric)
4. declare “scale-free-ish” if tails are sufficiently heavy

**Inputs (typical):**
- `df_country::DataFrame` with `year`, `vdem_v3polsoc`
- `current_year::Int`
- `window::Int=20`

**Output (typical):**
- `kurtosis` — excess kurtosis estimate
- `is_scale_free::Bool` — e.g., `kurtosis > 1.5`

**Important notes:**
- Kurtosis is sensitive to sample size and outliers. Consider also reporting:
  - tail index estimators,
  - Hill estimator on upper tails,
  - or quantile ratios (robust, interpretable).

---

## 7) How to use grounding results

### Recommended integration pattern
For each country-year:

1. compute the main index value(s) (your `D_c` or equivalent)
2. compute grounding diagnostics from `work/grounding.jl`
3. set a grounding flag, e.g.:

> `grounded = is_critical && is_diverging && is_invariant && is_scale_free`

Interpretation:
- If the index indicates “near critical” **and** `grounded == true`, the CH claim is supported by independent evidence.
- If the index indicates “near critical” but `grounded == false`, treat the CH claim as unverified (or potentially a model artifact).

### Example (illustrative)
Replace column names to match your actual DataFrame schema.

````julia
using DataFrames

# df_country: DataFrame with :year and the validation slugs
year = 2005

pl = validate_power_law(df_country, year; window=20)
cc = validate_correlation_divergence(df_country, year)   # may have its own window
si = validate_scale_invariance(df_country, year)
es = validate_event_scaling(df_country, year; window=20)

grounded = pl.is_critical && cc.is_diverging && si.is_invariant && es.is_scale_free