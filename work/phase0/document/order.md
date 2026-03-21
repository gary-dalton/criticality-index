# Order (O): the Ordering Force

This document describes the **Order** subsystem of the model and serves two purposes:

1. **Supporting-article narrative:** what “Order” means in the criticality framing and why these indicators were chosen.  
2. **Developer documentation:** a clear contract for the functions that will live in `work/phase0/functions/order.jl`.


---

## 1) Concept: what “Order” measures

In the model, **Order (O)** is the set of forces that **damp**, **constrain**, and **regularize** social dynamics so that disturbances do not propagate unchecked.

In physicalist terms, think of O as the civilization’s ability to absorb kinetic energy (conflict, coercion, violence) and prevent it from turning into runaway disorder. A system can have high “activity” while remaining ordered if it has strong damping and reliable constraint transmission.

---

## 2) Order Elements (planned)

Order is implemented as a multi-element construct (audited element-by-element):

1. **Safety** (Damping Force) — *implemented / documented here*  
2. Constraints (Governor / Limit) — *planned*  
3. (additional elements as defined in your architecture) — *planned*

Each element is computed from one or more **sensor slugs**, after which elements are combined into an overall Order value.

---

## 3) Element 1 — Safety (Damping Force)

### 3.1 Why “Safety” is the first-order damping proxy
Safety is the most direct empirical signature of whether a society’s “damping layer” is functioning:

- Low safety (high political terror, killings, violent repression) implies the damping mechanism is either failing **or becoming parasitic** (state violence acting as destabilizing heat rather than stabilizing friction).
- High safety implies disturbances can be processed without escalating into lethal or coercive breakdown.

### 3.2 Sensor audit summary (from the development thread)

**Original slugs considered**
- `wdi_homs` — homicide rate  
  - *Suitability:* high (direct violence)  
  - *Quality:* moderate (under-reporting, lag)  
  - *Availability:* problematic (high missingness across regions/years)  
- `pts_avg` — Political Terror Scale  
  - *Suitability:* high (state-sponsored violence)  
  - *Quality:* high (Amnesty + US State Dept reporting base)  
  - *Availability:* excellent (broad coverage from ~1976 onward)  
- `iep_gti` — Global Terrorism Index  
  - *Suitability:* moderate for “damping” (often better treated as a **shock/flicker** signal)  
  - *Quality:* high but volatile year-to-year  
  - *Availability:* limited for long time-series work

**Key engineering constraint:** `wdi_homs` missingness is high enough to induce artifacts in **velocity** and **flicker** calculations (false “shuddering” caused by data gaps), and can break country loops if not handled carefully.

### 3.3 Recommended slug set for Safety

**Primary (baseline damping, long coverage)**
- `pts_avg`

**Secondary (direct political killing / coercion proxy)**
- `vdem_clpgov` (freedom from political killings), if present in your dataset  
  *(If your schema differs, use the V-Dem equivalent you have available.)*

**Tertiary (state fragility / security channel)**
- `fsi_sl` (Fragile States Index: legitimacy/security-related component), if present  
  *(Use cautiously due to methodological differences across sources.)*

**Explicit decision point**
- `iep_gti` should typically be treated as a **trigger / flicker indicator**, not part of baseline Safety damping, because it is (a) highly event-driven and (b) short-horizon in many datasets.

> If you decide to keep `iep_gti` inside Safety anyway, document it explicitly as “damping stress” and expect it to behave more like an impulse input than a structural measure.

---

## 4) Computation: from slugs to a Safety score

### 4.1 Directionality (sign conventions)
Safety should be oriented so that:
- **higher Safety score = more damping / safer**
- **lower Safety score = less damping / more violent/coercive conditions**

Most raw slugs are “bad-is-high” (e.g., terror/killings). Implementation should invert these into a “good-is-high” orientation after normalization.

### 4.2 Normalization (recommended)
To make heterogeneous sources comparable, each input series should be transformed into a common scale (e.g., 0–100 or z-score). Pick one convention and use it consistently across O.

Recommended engineering default:
- robust scaling within-country (median/IQR) or bounded min–max with clipping
- keep a record of any clipping to avoid silently saturating values

### 4.3 Missingness handling (non-negotiable)
Safety must be computable even when some slugs are missing.

Recommended pattern:
- compute each component if sufficient data exists in the relevant window
- combine with **renormalized weights** over available components
- return diagnostics about what was used

---

## 5) The “Lattice Failure” multiplier (constraint transmission)

### 5.1 Rationale
If the system’s **rule-of-law / enforcement substrate** collapses, the rest of Order does not merely weaken linearly—it can **fail to transmit**. In other words, nominal safety institutions do not function as damping if constraint enforcement is absent.

This is modeled as a **non-linear penalty** applied to the aggregated Order (or to Safety specifically, depending on architecture).

### 5.2 Mathematical form
Let `O_weighted_sum` be the combined (normalized) Safety value before transmission penalties.

Define a transmission function `Φ(O_rol)` such that:
- `Φ ≈ 1` when rule-of-law is healthy (e.g., above ~50 on a 0–100 scale)
- `Φ → 0` quickly as rule-of-law approaches a floor (e.g., ~20)

Then:
\[
O_{final} = O_{weighted\_sum} \cdot \Phi(O_{rol})
\]

A practical default is a sigmoid/logistic:
\[
\Phi(x) = \frac{1}{1 + e^{-k(x - x_0)}}
\]
where:
- `x0` is the midpoint (e.g., 50)
- `k` controls steepness (e.g., 0.15–0.30 if `x` is 0–100)

> **Note:** you must choose the actual rule-of-law slug used for `O_rol` (e.g., WGI rule of law, V-Dem rule-of-law composite, or another enforcement proxy present in QoG). This slug is part of the Order computation, not a grounding/validation channel.

---

## 6) Function contracts (for `work/phase0/functions/order.jl`)

These are the intended behaviors. If the code differs, update either the implementation or this document so they match.

### 6.1 `order_safety` — compute the Safety (Damping) element
**Goal:** compute a single Safety score for a country-year using the approved slug set and missingness-aware weighting.

**Inputs (typical):**
- `df_country::DataFrame` — one country’s time series
- `current_year::Int`
- keyword args such as:
  - `window::Int=20`
  - `slugs::Vector{Symbol} = [:pts_avg, :vdem_clpgov, :fsi_sl]`
  - `weights = Dict(:pts_avg=>0.5, :vdem_clpgov=>0.3, :fsi_sl=>0.2)`
  - `min_obs::Int=8`

**Outputs (typical):**
A named tuple including:
- `safety::Float64` — normalized “good-is-high” Safety score
- `used_slugs::Vector{Symbol}` — which components were available
- `component_scores::Dict{Symbol,Float64}` — per-slug normalized/inverted values
- `is_valid::Bool` — whether minimum data requirements were met

### 6.2 `phi_lattice_failure` — transmission penalty based on rule-of-law
**Goal:** compute `Φ(O_rol)`.

**Inputs (typical):**
- `rol_score::Real` (assumed already normalized to 0–100)
- keywords: `x0::Real=50`, `k::Real=0.2`, `floor::Real=0` (optional clamp)

**Output:**
- `phi::Float64` in `[0,1]`

### 6.3 `order_final` — combine Safety with transmission penalty
**Goal:** produce final Order value for the year.

**Inputs (typical):**
- `safety_result` from `order_safety`
- `rol_score` for the same window/year

**Output (typical):**
- `order::Float64`
- `phi::Float64`
- `is_valid::Bool`

---

## 7) Open decisions / next steps

1. **Confirm the slug list actually present in the QoG extract** you are using:
   - Do you have `vdem_clpgov` and `fsi_sl` in your current merged dataset?
2. **Decide where `iep_gti` lives:**
   - (preferred) move it to a **trigger/flicker** subsystem rather than baseline damping
3. **Choose the rule-of-law slug** for `O_rol` so the transmission penalty is well-defined.
4. Proceed to **Element 2: Constraints (Governor/Limit)** with the same sensor audit process (suitability, quality, availability).

---