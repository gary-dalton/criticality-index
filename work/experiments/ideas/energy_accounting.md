---
title: "Energy Accounting in SOC Models — A Falsifiable Wave-Based Framework"
linkTitle: "Energy Accounting"
description: "Three-reservoir energy framework (grain, structural, heat) anchored in C-DP reaction-diffusion. Specifies per-bond flux, activity-wave observables, toppling-order assumptions, and per-experiment operational model rules. Developmental draft."
author: "Gary Dalton"
date: 2026-04-22T00:00:00-05:00
lastmod: 2026-04-23T00:00:00-05:00
include_toc: true
show_comments: false
draft: true
weight: 20
keywords: "energy accounting, reaction-diffusion, C-DP, heat reservoir, structural integrity, sigma field, activity wave, per-bond flux, NESS, falsifiability, Sethna shape collapse, overtopping, liquefaction"
---

# Energy Accounting in SOC Models — A Falsifiable Wave-Based Framework

> **Status: DEVELOPMENTAL DRAFT.** This document is under active iteration. Hard constraints, three-reservoir structure, falsifiability tests, and per-experiment operational rules are committed in concept; specific values, parameter choices, and the precise form of some coupling rules will continue to evolve as the framework is exercised. Treat as the working theory specification, not a final reference.

## Status

This document specifies the **energy framework** for the validation-experiments program: what energy means in our discrete sandpile/percolation models, how it flows between reservoirs, what the activity wave is, and how heat enters the picture. It is a measurement and theoretical-interpretation specification — it does **not** modify the dynamics of natural SOC simulators.

**Hard constraints adopted during framework design:**

1. **Every claim must enact in a falsifiable model.** Every section ends in either a measurable observable or a simulator rule, and includes at least one prediction that could refute the framework if violated.

2. **Energy instrumentation does NOT change natural-SOC dynamics.** For Exp 01.01 (BTW), 01.02 (Manna), 01.03 (Negatives), and 02 (Percolation), the simulator dynamical rules are unchanged. We add measurements only. Re-running 01.02 with new instrumentation must reproduce the existing baseline (α∞ ∈ [1.265, 1.278], β_high = 1.60, b(x) plateau ≈ 1.01, etc.) within ensemble noise. If statistics shift, it's an instrumentation bug — not a discovery. The framework only diverges from natural SOC at experiments where new dynamical rules are explicitly added: 01.04 Overtopping (σ field), 01.05 Liquefaction (π field), 06 Coupled SOC (cross-system flux).

3. **Small/mid-range events build the spatiotemporal fabric; do not snapshot only top-K.** SOC's scale-free property means the long-range correlations and the steady-state σ-damage prediction live in the cumulative aggregate of all events, not just the largest. Per-bond flux and per-site cumulative kinetic energy must be recorded continuously across all events. Per-event spatial snapshots (heavy data) are reserved for top-K events, where they support wave-shape fits.

The previous version of this doc introduced two reservoirs (grain + structural) and noted KE as a coupling channel. That intuition is preserved and extended. What this rewrite adds: a **continuum theory** to anchor the discrete dynamics, a **third reservoir (heat)** for the residual disorder a passing wave leaves behind, an **explicit per-experiment rule set** so model behavior is operationally testable, and a **superposition-principle distinction** between extensive accounting (which superposes) and dynamics (which generally don't).

---

## 1. C-DP continuum theory as the substrate

The Manna stochastic sandpile belongs to the Conserved Directed Percolation (C-DP) universality class (Lübeck 2004; Vespignani, Zapperi, Pietronero 2000; Bonachela & Muñoz 2009). In the continuum limit, two coupled fields evolve:

```
n(x, t)   — activity density (density of unstable / toppling sites)
ρ(x, t)   — energy density   (density of stored grains)
```

obeying coupled reaction-diffusion equations:

```
∂n/∂t = D ∇²n + (ρ − ρ_c) n − μ n²        (activity diffuses and grows where ρ > ρ_c; self-damps)
∂ρ/∂t = D' ∇²(ρ n)                       (grains transported by activity)
```

In words: activity is a wave that propagates through the energy field, locally consuming the excess `(ρ − ρ_c)` as it goes. Where ρ < ρ_c the wave dies (the absorbing state). Where ρ > ρ_c it grows. The `−μ n²` term is the self-damping that makes individual avalanches close (start at zero, peak, return to zero).

This is the **proper "activity wave" framework for Manna**. Our discrete simulator is a finite-L stochastic realization of these PDEs.

### Why this applies to Manna and not BTW

BTW exhibits multiscaling (Tebaldi, De Menech, Stella 1999; confirmed at our 01.01 ensemble where xmin-α drift does not shrink with L) which is not captured by a simple reaction-diffusion limit. The framework's quantitative predictions are therefore **Manna-anchored**. BTW serves as a comparison substrate with known caveats; we do not expect the C-DP RD form to fit BTW data quantitatively, and any apparent agreement should be interpreted as approximate.

### Abelian-in-distribution and trajectory dependence

Manna is abelian-in-distribution (Muñoz, Dickman, Vespignani, Zapperi 1998): pooled avalanche-statistics distributions are independent of toppling order, but **trajectories are not**. Different toppling orders (parallel-wave vs sequential-random vs sequential-by-age) produce the same P(s), τ_s, β_high in expectation, but different specific spacetime patterns of activity and heat deposition.

We use **parallel-wave toppling** in our simulators (see [`sandpile.jl`](../validation/sandpile.jl) and [`manna_sandpile.jl`](../validation/manna_sandpile.jl)). This is a model assumption, not a derivation. Its implications:

- **Order-independent observables** (safe to compare across implementations): P(s), P(t), P(a), τ_s, τ_t, FSS extrapolations, b(x) plateau, β_high.
- **Order-dependent observables** (must be reported with the order rule as a condition): heat-residual spatial pattern, σ-damage map, per-bond flux history, per-event wave-shape profiles.

**Falsifiability — toppling-order sensitivity test (optional).** If we re-run a small Manna ensemble with sequential-random toppling and compare to the parallel-wave baseline, the order-independent observables should match within ensemble noise (<0.5σ); the order-dependent observables may differ in spatial pattern but should match in statistical aggregate (mean, variance). Substantial disagreement on the order-independent observables would refute abelian-in-distribution at our finite L. Test is documented as a future check; not required validation.

---

## 2. Three reservoirs

Energy in this framework is partitioned into three reservoirs, each with its own state variable, continuity equation, and conservation status.

| Reservoir | State variable | Update rule (sketch) | Conservation |
|-----------|---------------|----------------------|--------------|
| **Grain** | `z_i(t)` height field | Discrete topple; perimeter loss | Conserved modulo boundary dissipation |
| **Structural** | `σ_i(t) ∈ [0, 1]` integrity field | Damage on flux > E_crit; slow recovery; (optionally) σ-diffusion | Slow sources/sinks; no global conservation law required |
| **Heat** | `H_i(t) ≥ 0` thermal disorder | Pumped by KE (toppling activity); decays via local cooling rate κ_i; (optionally) diffuses with D_H | Sourced by KE; sinks via cooling |

For natural SOC (01.01, 01.02, 01.03, 02): only the grain reservoir is dynamically active. σ ≡ 1 and H accumulates passively from per-site KE deposits but does not feed back into any rule. Heat is a measured observable, not a causal variable, in natural-SOC experiments.

**Open structural question (not yet settled).** The framework treats heat as a separate reservoir with its own continuity equation and free parameters (`α_H`, `κ_base`, `D_H`). A simpler alternative: heat as a **derived** quantity, `H_i ∝ post-event variance of (z_i,after − z_i,before)`. The two formulations may give equivalent predictions on every observable we can measure, in which case the simpler derived form should be preferred. Phase-D (re-instrumented Manna analysis) should specifically test whether the separate-reservoir formulation predicts anything the derived form does not. If no such observable exists, this doc will be revised to use the derived form. Treat the separate-reservoir framing in §6 as provisional pending that test.

For overtopping (01.04 Model C onwards): σ becomes dynamic. H may optionally couple to σ recovery and damage thresholds.

For liquefaction (01.05): π = H drives threshold lowering. The heat reservoir is the same H field as in overtopping; we keep one variable name and acknowledge it serves both roles depending on the experiment.

### Heat continuity equation

Heat earns its own equation:

```
∂H/∂t = α_H · n(x,t) − κ(x) H + D_H ∇²H
```

with:
- `α_H` — heat-deposition coefficient (KE → H), free parameter to fit
- `κ(x)` — local cooling rate (see §6.1 for connectivity dependence)
- `D_H` — heat diffusivity, optional spatial coupling (default: 0)

Heat is sourced by activity (every toppling deposits incoherent disorder), decays in the absence of activity (cooling), and may diffuse spatially.

**Sign conventions and floors.** All reservoirs are non-negative by construction:

```
z_i ≥ 0     (grain count; clip on dissipation, never negative)
σ_i ∈ [0, 1]  (integrity; clip on damage, σ_i ← max(0, σ_i · (1−α)))
H_i ≥ 0     (heat; clip on cooling, H_i ← max(0, (1−κ_i)·H_i))
```

There are no negative reservoirs in this framework. Energy "leaving" a reservoir is always a positive directed flow to another reservoir or to dissipation. No subtraction-of-energy interpretation; only flows.

**Falsifiability for §2.** In steady state (NESS — see §3), each reservoir's mean must stabilize and energy in must equal energy out per reservoir over a long window. If H grows without bound, κ is too small or α_H too large. If σ collapses to zero in natural SOC where it's supposed to be inactive, instrumentation has a bug. If z drifts after burn-in, the simulator broke. All three are testable via the existing burn-in trace machinery extended to all three reservoirs.

---

## 3. Thermodynamic state — non-equilibrium steady state (NESS)

Our system is **explicitly non-equilibrium**: energy flows in via driving and out via dissipation continuously. Equilibrium-thermodynamic concepts (zero net flux, maximum entropy) do not apply. What applies is **NESS**: stable means and stable flux balance over time.

NESS is defined by three conditions, each measurable:

1. **State stationarity**: ⟨z⟩, ⟨σ⟩, ⟨H⟩ all constant in time after burn-in (within ensemble noise). The current dissipation_rate ≈ 1.0 check generalizes to per-reservoir balance.
2. **Per-reservoir flux balance**: ⟨E_in,r⟩ = ⟨E_out,r⟩ for each reservoir r over a long window.
3. **Equipartition stability**: the ratio of energies E_grain : E_struct : E_heat reaches a stable value determined by coupling parameters.

**Operational test.** Extend the current burn-in trace to track ⟨z⟩, ⟨σ⟩, ⟨H⟩ at log_every intervals. NESS achieved when all three are stable across consecutive_passes windows.

**Falsifiability.** If equipartition does not stabilize, the system is not in NESS and any extracted exponents are suspect. If per-reservoir flux balance fails (e.g., heat accumulates without bound), there's a coupling-rule error or insufficient cooling.

---

## 4. The activity wave as central object

Replace the "grain at height h has PE = h" picture with: **the activity field n(x, t) is the central object; energy is carried by the wave.**

Key wave observables, all computable from the discrete simulator's per-avalanche state:

| Observable | Definition | Where measured |
|------------|------------|----------------|
| Spatial extent | support of `n(x, t)` (set of toppling sites at wave step t) | per wave, top-K events |
| Wave amplitude | `max_x n(x, t)` | per wave |
| Total wave KE (integrated) | `Σ_x n(x, t) = n_in_wave(t)` | already in `wave_profile` |
| Per-bond flux | `j_(i→j)(t)` = grains crossing bond i → j at wave t | new instrumentation, see §5 |
| Wavefront velocity | `Δ⟨max_extent⟩ / Δt` per wave step | derived from extent + duration |
| Wave shape | `n(t/T) / n_max` averaged over duration-binned avalanches | derived from `wave_profile` |

The crucial reframing: our existing `wave_profile` measurement is the **integrated instantaneous kinetic energy of the activity wave**, not a coincidental scalar. Same data, sharper interpretation. β_high (PSD high-frequency exponent) is the **power spectrum of the kinetic-energy signal** over time — same data, sharper interpretation.

### 4.1 Avalanche shape — Sethna mean-field prediction

Mean-field theory (Kuntz & Sethna 2000; Papanikolaou et al. 2011) predicts the average rescaled avalanche shape:

```
⟨n(t/T)⟩ / n_max  =  4 · (t/T) · (1 − t/T)         (parabolic, symmetric, peak at u=0.5)
```

This comes from the deterministic saddle-path solution of the Langevin form `∂n/∂t = (ρ − ρ_c) n − μ n²` with noise → 0. The `−μ n²` term self-damps the wave, closing it (start at zero, peak, return to zero in time T).

**Expected 2D corrections** (Manna is below the upper critical dimension d_c = 4):

- **Asymmetric**: peak at u < 0.5 — early growth is faster than late decay because newly activated sites are spatially correlated with recently activated ones. The qualitative claim is robust for d < d_c systems (Papanikolaou et al. 2011 and follow-ups); specific exponent values quoted in this doc need source verification before being treated as predictions.
- **Power-form fit**: `⟨n(u)⟩ / n_max = C · u^a · (1−u)^b` with `a < b`. Recovers parabolic at a = b = 1. **Exact 2D-Manna values for (a, b) are flagged as TBD** — to be sourced from Papanikolaou et al. 2011 or comparable literature before the Phase-D fit is run. Until verified, the operational test is "shape collapse + qualitative asymmetry consistent with a < b" rather than quantitative agreement with specific numerical (a, b).

**Operational measurement on existing 01.02 Manna data**:

1. Bin avalanches by duration T (e.g., T ∈ [10, 20), [20, 50), [50, 100), …, [500, 1000), …).
2. Within each bin, normalize each avalanche: `n(t/T) / n_max`.
3. Compute average shape per bin.
4. Plot all bins together. **Should collapse onto a single curve** if scaling holds.
5. Fit parabolic and asymmetric power forms; report (a, b) and deviations.

No new instrumentation needed. The existing `wave_profile` data per seed is sufficient.

**Falsifiability**:

1. **Shape collapse across L and duration bins**: if curves don't collapse, simple scaling is broken.
2. **Quantitative deviation from parabolic**: asymmetry direction (a < b) is the robust prediction for 2D systems below d_c. Specific (a, b) values to be sourced from Papanikolaou et al. 2011 or comparable literature before this test is applied as a quantitative refutation; until then, the test is qualitative (asymmetric with a < b) only.
3. **Cross-experiment signature**: under overtopping (01.04 Model C), σ-damaged regions slow late-stage propagation — shape should broaden / develop a late-tail at matched duration. Under amplification (01.05 liquefaction), wave self-sustaining predicts persistent late-tail. Shape becomes a primary CSOC-like / ISOC-like signature discriminator.

This is the **first concrete falsifiability test we can run on existing data** — no new ensembles, no new code beyond a shape-collapse analysis script. Recommended as the validation gate for the C-DP foundation before any further instrumentation.

---

## 5. Per-bond flux and continuity

`j_(i→j)(t)` = grains crossing bond (i, j) from i to j at wave t. New primary observable.

Continuity equation per site (closes the energy balance):

```
∂z_i/∂t + Σ_{j ∈ neighbors(i)} [j_(i→j) − j_(j→i)] = source_i − sink_i
```

The current `n_dissipated` scalar becomes a special case: `n_dissipated = Σ over OOB events of j_(boundary)` for each event.

### 5.1 Bidirectional tracking

Per-bond flux is recorded as **two separate counters per bond**: `j_(i→j)` and `j_(j→i)`.

- Storage: 2 × L² × Int32 per recording window (for a 2D square lattice; one Int per directed bond, ~2L² directed bonds).
- Model complexity: **zero added** — the simulator's grain-transfer rules are unchanged; we just track which direction each grain went.
- Derived quantities:

| Derived quantity | Formula | What it reveals |
|------------------|---------|-----------------|
| Net flux (signed) | `j_(i→j) − j_(j→i)` | Directional preference, pressure-gradient field |
| Total throughput (unsigned) | `j_(i→j) + j_(j→i)` | Effective conductance, load-bearing bonds |
| Anisotropy | `(j_(i→j) − j_(j→i)) / (j_(i→j) + j_(j→i))` | Coherence of wave direction |

**Falsifiability**. In Manna with isotropic dispatch and uniform driving, the time-average net flux at any interior bond should vanish (no preferred direction at NESS); throughput should reveal an L-dependent pattern reflecting the system-spanning character of the largest avalanches. Significant non-zero net flux at NESS would indicate symmetry breaking that the framework doesn't currently account for.

### 5.2 Wave directionality, interference, dissipation

Manna is isotropic *per-grain* (each toppled grain goes to a uniformly random neighbor) but the **wave** is spatially coherent at the field level. Diagnostics:

- **Wave bifurcation/recombination**: per-event count of wave-steps where the activity-field has > 1 connected component. Frequent bifurcation under elevated thresholds (Model C) would indicate σ-coupling fragments the wave.
- **Mutual extinction**: events where activity dies abruptly between waves despite peak > 0 just before. Distinguishes smooth scaling decay from interference-damped events.
- **Self-damping** (from C-DP RD `−μ n²`): high-activity regions predicted to slow wavefront advancement. Testable as `E[wavefront_velocity ∣ n_peak]` (conditional-mean wavefront velocity given peak amplitude) being a decreasing function of n_peak. If absent, the C-DP self-damping form may not apply at our finite L.

All four (counting the bidirectional flux above) are measurement additions, not dynamical changes.

---

## 6. Heat as the residual of a passing wave

Heat accumulates when the activity wave passes through a region and leaves disorder behind. Operational definitions for measurement:

1. **Per-site cumulative KE deposit**: `H_i ← H_i + α_H · n_topples_i` per cascade. (Default rule.)
2. **Pre/post height-field disorder**: variance of `(z_i,after − z_i,before)` across the affected region. Wider = more thermalized.
3. **σ-degradation as latent-heat absorption** (overtopping experiments only): `DE_struct = T · σ · α` per damage event = energy absorbed by the structural reservoir, deposited as local heat. Closure: `W_damage = ΔH_local`.

Default measurement set: **(1) and (3) primary; (2) as a derived diagnostic.**

### 6.1 Heat decay rate κ — connectivity-dependent

Cooling rate per site depends on local connectivity:

```
κ_i = κ_base · (degree_i / degree_max)
```

For a 2D square lattice with all bonds present, `degree_max = 4`. Interior sites cool at full rate κ_base; boundary sites cool slightly slower (degree 2–3); corner sites slowest (degree 2 of 4). For percolation substrates, sites in low-connectivity regions cool slower — heat persists longer where the cluster is sparse.

`κ_base` is a free parameter to be fit from observed H(t) trajectories.

**Phenomenological choice, not derivation.** The connectivity-proportional form is intuitive (more neighbors → more heat-conduction pathways) but is not derived from a microscopic heat-transport law for our lattice. It is a modeling choice that needs sensitivity testing — particularly for Exp 03 (sandpile on percolation), where the rule materially affects activation-energy predictions in low-connectivity cluster regions. On the full 2D square lattice the rule is mostly cosmetic (κ varies only at the L=4 perimeter), but on diluted substrates it is load-bearing. Phase-E should include a sensitivity check: vary the connectivity dependence (e.g., degree^p with p ∈ {0, 0.5, 1, 2}) and report whether activation-energy predictions are robust to the choice. If they aren't, the rule needs justification beyond intuition before Exp 03 conclusions are claimed.

### 6.2 KE → heat default rule

```
H_i ← H_i + α_H · n_topples_i        per cascade, applied at cascade end
H_i ← H_i · (1 − κ_i)                per timestep between cascades
```

Simple. No flux-tracking prerequisite. `α_H = 0` recovers the previous two-reservoir framework (no heat); `α_H` to be calibrated empirically.

**Configurable alternative — flux-divergence rule**: in experiments where per-bond flux is already instrumented (01.04 Model C, 02, 06), an alternative deposit form is:

```
H_i ← H_i + α_H · |∇·j_i| · n_topples_i
```

— heat generated where the wave decelerates / dissipates locally, not where it propagates smoothly. This is more physically grounded (heat = kinetic energy that didn't propagate further) but requires the flux divergence at each site. We document both rules; default is the local-KE form; flux-divergence rule available for empirical comparison.

### 6.3 Reverse heat → KE

Heat-driven thermal activation of toppling:

```
P(spontaneous topple at site i with z_i < z_c) ∝ exp[−(z_c − z_i) / H_i]
```

**Off in natural SOC** (no thermal noise; pure deterministic-threshold dynamics). **On in liquefaction (01.05)**, where it's the mechanism by which heat (=π) lowers the effective threshold. Documented here for completeness; activated only in experiments with explicit heat-coupling.

### 6.4 Falsifiability

- Heat reservoir mean ⟨H⟩ stabilizes at NESS (proves `α_H` and `κ_base` are consistent).
- Per-event heat deposition correlates with peak n_topples_i (proves the source rule fires correctly).
- σ degradation in 01.04 Model C correlates with local H trajectory in the heat-coupled variant (proves the latent-heat-absorption interpretation).
- Removing heat coupling (`α_H = 0`) recovers natural-SOC statistics within ensemble noise (proves heat is genuinely additive, not affecting natural-SOC dynamics).

---

## 7. Grain-drop energy convention

A grain added to site (i, j) at current height z_i carries some amount of energy. The previous framework left this implicit (PE_grain = z_i added per drop, with no kinetic component). The new framework commits to **fixed-height drop** (Option B):

```
Per grain drop at site (i, j) with current height z_i:
    z_drop = drop reference height           (parameter; default 2 · z_c)
    ΔPE_grain   = z_i                          (grain joins stack at height z_i)
    ΔH_i        = α_drop · (z_drop − z_i)      (impact KE thermalizes locally)
    Total ΔE    = z_drop                       (fixed per drop, by conservation)
```

`α_drop ∈ [0, 1]` is the impact-thermalization fraction. `z_drop` is a parameter (default `2·z_c`, well above any reachable site height in NESS).

**Default α_drop is unsettled and requires baseline sweep before commitment.** With `z_drop = 2·z_c` and natural Manna mean ⟨z⟩ ≈ 0.72 < z_c, the per-drop impact KE deposit `(z_drop − z_i) ≈ 3.3` (Manna z_c=2) at α_drop=1.0 may be **substantial relative to per-toppling heat deposit**, plausibly dominating ⟨H⟩ at NESS. That would invert the intended "heat is mostly from avalanche activity" framing. Recommended baseline:

- Sweep `α_drop ∈ {0, 0.5, 1.0}` on natural Manna re-instrumentation.
- Compare resulting ⟨H⟩ at NESS and the ratio of per-drop vs per-toppling heat contributions.
- Pick the α_drop value (or sweep range) for which avalanche-driven heat dominates driving-driven heat by some reasonable factor (or accept that driving-driven heat is irreducible and treat it as a baseline to subtract).

Until this sweep is run, the doc does **not commit to a default α_drop**. Implementation should expose it as a free parameter; α_drop = 0 (no impact heating) is the conservative starting point that recovers the previous framework's behavior.

**Implications**:

- Total energy input per drop is constant (z_drop), independent of where the grain lands.
- Some becomes potential energy (grain joins the stack), some may become heat (kinetic energy of impact, scaled by α_drop).
- **Spatially heterogeneous heating from driving alone** when α_drop > 0: high stacks heat less per drop (small impact KE); empty sites heat more per drop (large impact KE). Even in natural SOC with no avalanche-driven heat coupling, the heat field would develop structure from driving. This is why the baseline sweep matters before committing.

**Sanity check (mandatory)**. With heat reservoir tracked passively (no feedback) at any α_drop, re-running 01.02 Manna must produce identical avalanche statistics to the current ensemble within noise. If it doesn't, either heat is feeding back into dynamics (instrumentation bug) or the grain-drop convention has changed something it shouldn't have.

**Falsifiability**. The α_drop sweep doubles as a falsifiability check: natural-SOC avalanche statistics should remain identical across the sweep (heat is additive instrumentation, no causal feedback). Heat-field statistics should differ predictably: ⟨H⟩ at NESS should scale linearly in α_drop. If ⟨H⟩ doesn't scale linearly or avalanche statistics shift across α_drop, the framework's assumption of additive instrumentation is broken.

---

## 8. Work and power

**Work** in this framework is energy expended by one reservoir against another:

- **Grain-against-structural work**: per damage event, `W_damage = T · σ · α` is the energy the activity wave spends to lower σ from σ to σ·(1−α). In the heat-coupled interpretation, this work becomes heat at the damaged site: `W_damage = ΔH_local`. Closure makes work the explicit mechanism by which kinetic energy converts to thermal energy in the medium.
- **Driving-against-grain work**: per grain drop, `W_drop = z_drop` (the energy input per drop). Decomposes into `ΔPE_grain = z_i` (lifted into stack) and `ΔH_local = α_drop · (z_drop − z_i)` (lost to impact heat).

**Power** is rate of energy flow:

- `P_drive(t)` = rate of energy input from driving = z_drop per timestep at one drop per timestep.
- `P_dissipation(t)` = rate of energy leaving the system (grain OOB + heat cooling).
- `P_internal(t)` during an avalanche = rate of conversion within the wave (KE → H, KE → ΔPE_struct, etc.).

The PSD of `P_internal(t)` (or equivalently of `n_in_wave(t)`, since they're proportional) is the **power spectrum of the activity wave** — what we measure as β_high. Reframing:

> β_high ≈ 1.56 (BTW) / 1.60 (Manna) is **not just a fit exponent**; it's the spectral roll-off of the wave's internal kinetic-energy time series. It quantifies how rapidly the wave's energy distributes across timescales.

This grounds β_high as a genuine power-spectrum measurement, not a curve-fit number.

**Falsifiability**. Total power balance: `⟨P_drive⟩ = ⟨P_dissipation⟩` at NESS (already verified for grains via dissipation_rate ≈ 1.0). Extending to per-reservoir: `⟨P_internal,grain⟩ = α_grain → struct + α_grain → heat + α_grain → dissipation`. If these don't balance, the framework's accounting is incomplete.

---

## 9. σ as spatially-coupled field — optional extensions

The current Model C (overtopping) σ rule is purely site-local. The framework documents three extensions that may be enabled per experiment:

### 9.1 σ-diffusion

```
∂σ/∂t = D_σ ∇²σ + (recovery − damage)
```

Lateral recovery: intact regions help damaged neighbors recover. Physically motivated by fault-healing (seismology) and crack-arrest (materials). Optional; disabled by default.

**Falsifiability**: with σ-diffusion on, damaged sites should show measurable σ recovery beyond what site-local recovery_rate predicts; specifically, σ_i recovery should depend on average σ in a neighborhood of radius √(D_σ · t). If recovery is purely site-local even with D_σ > 0, σ-diffusion is not operating as modeled.

### 9.2 Heat-coupled σ recovery

```
recovery_rate(i) = recovery_base · f(H_i)        with f decreasing in H
```

Hot regions recover slower. Physically motivated by thermal damage in real materials. Optional.

**Falsifiability**: post-event σ trajectories should correlate negatively with local H. If correlation is zero or positive, the heat-coupling assumption is wrong.

### 9.3 Heat-modulated damage threshold

```
E_crit(i) = E_crit_base · g(H_i)        with g decreasing in H
```

Pre-heated regions are easier to damage. Optional.

**Falsifiability**: damage events should localize preferentially to high-H regions. If damage is uniform across H, the heat-modulation isn't operating.

Each extension is enabled via a configuration kwarg; experiments choose which. Default for 01.04 Model C: all three off (purely site-local σ dynamics) in the baseline; sweeps over each extension as the experimental program develops.

---

## 10. Superposition principles

A subtle but operationally important distinction: **what superposes** vs. **what doesn't**.

### 10.1 What superposes (extensive accounting)

Energy, mass, and other extensive properties are additive across both reservoirs and spatial regions:

```
E_total       = E_grain + E_struct + E_heat                   (across reservoirs)
              = Σ_r (E_grain,r + E_struct,r + E_heat,r)        (across regions r)
```

The three-reservoir framework is itself a superposition: total energy is the sum of independent reservoir energies. This is bookkeeping; always valid for extensive quantities.

### 10.2 What does not superpose

- **Distributions** (P(s), G(r), PSD): these are statistical properties of the ensemble, not summable. P(s) over the left half of the lattice + P(s) over the right half ≠ P(s) over the whole lattice, because avalanches cross the boundary.
- **Correlation functions**: G(r) for the combined field is not the sum of per-component G(r), because cross-correlations emerge from coupling.
- **Dynamics under nonlinear couplings**: threshold rules (`if z ≥ z_c: topple`) are nonlinear; the response to two simultaneous loadings is not the sum of responses to each individually.

### 10.3 Weak-coupling benchmark

Each coupling term in the framework has a "what if this coupling were zero" baseline. The system reduces to a simpler one with the coupling off; real predictions are corrections to that baseline.

| Coupling | Baseline (off) | Effect of turning on |
|----------|----------------|----------------------|
| α_H (KE → H) | Two-reservoir framework, heat absent | H accumulates; σ recovery may slow if heat-coupled |
| σ-damage (Model C) | Natural Manna with elevated threshold | σ degrades at high-flux sites; thresholds locally fall |
| σ-diffusion | Site-local σ dynamics | Lateral recovery; damaged regions re-heal from neighbors |
| Heat-σ coupling | Independent heat and σ trajectories | Trajectories correlate; hot regions stay damaged longer |

For weak coupling: framework predicts linear response in the coupling parameter at small values. For strong coupling: nonlinear corrections dominate; superposition is a misleading guide.

### 10.4 Cumulative-flux as superposition-limit prediction (key falsifiability test)

The cumulative `n_topples_i` over the natural-Manna run (recorded across all events, see §11) **is the superposition-limit prediction for where σ damage would localize under Model C**.

If σ-coupling were a small perturbation on natural SOC, then to first order: damage events should occur preferentially at sites with the highest cumulative KE. The σ damage map should correlate strongly with the natural-Manna cumulative-KE map.

Falsifiability test:

1. From the natural-Manna 01.02 ensemble (re-run with cumulative-KE instrumentation), compute the cumulative `n_topples_i` map.
2. Run 01.04 Model C with a small α (weak damage); record the actual σ damage map.
3. Compute spatial correlation between the two maps.

- **High correlation (r > 0.7)**: σ-coupling is a small perturbation. Superposition expansion is valid; framework can extrapolate Model C behavior from natural-SOC measurements perturbatively.
- **Low correlation (r < 0.3)**: σ-coupling is a strong interaction; superposition fails; Model C dynamics qualitatively differ from natural Manna; cannot be predicted from the natural-SOC baseline alone.

This is a clean cross-experiment falsifiability test that ties the energy framework directly to a measurable Model C outcome.

### 10.5 Cross-experiment composition rule

When combining mechanisms (e.g., a speculative future experiment combining overtopping with liquefaction), start from the superposition of independent mechanisms — each producing its own signatures and dynamics — then add interaction terms explicitly. Cross-couplings (σ × π, heat × σ, etc.) become first-class objects of the model rather than emergent surprises.

---

## 11. Operational measurement table

Three classes of observable, with different aggregation strategies and storage costs.

### Class A — Cumulative across ALL events (small-world dynamics)

| Observable | Method | Storage | First needed |
|------------|--------|---------|--------------|
| `j_(i→j)` total over recording window | bidirectional bond counter, accumulated | 2L² Int32 per L per ensemble | 01.02 re-instrumentation; 02; 06 |
| `n_topples_i` cumulative per site | per-site Int counter, accumulated | L² Int32 per L per ensemble | 01.02 re-instrumentation; predicts 01.04 σ damage map (§10.4) |
| Per-event scalars (`n_dissipated`, `peak_n_topples`, `Σ z_at_dissipation`) | computed per avalanche | small, per event in summary table | partial today |

These are cheap (O(L²) per ensemble, not per event) and capture how small/mid avalanches build the spatiotemporal fabric. The per-bond flux **aggregate** is the small-world / effective-conductance signal; the **per-site cumulative KE** is the predictor for σ damage location.

### Class B — Per-event snapshot for top-K largest events (wave-shape fits)

| Observable | Method | Storage | First needed |
|------------|--------|---------|--------------|
| `n_in_wave(t)` (wave_profile) | per-wave count vector | already recorded | 01.01 (have) |
| Activity-field per wave (toppling-site set per wave step) | sparse spatial record per wave | top-K · avg_topples | 01.04 Model C; optional 01.02 re-instrument |
| Pre/post `z` snapshot | full L² snapshot at event boundaries | 2 L² Int per sampled event | 01.04 heat residual; optional Manna baseline |
| Per-event peak `H_i` and `σ_i` | scalars per top-K event | small | 01.04 |

Snapshot heavy spatial fields only for top-K events (typical K = 100 largest per L). Mid and small events feed Class A aggregates.

### Class C — Periodic snapshots (slow-state evolution)

| Observable | Method | Storage | First needed |
|------------|--------|---------|--------------|
| Full `σ` field | snapshot at burn-in trace intervals (e.g., every 1000 grain drops) | L² Float per snapshot | 01.04 Model C |
| Full `H` field | same | L² Float per snapshot | 01.04 Model C; optional 01.02 re-instrument |
| Full `z` field | already periodic in burn-in trace | already done | 01.01/01.02 |

Tracks slow-state evolution of the structural and heat reservoirs across the whole run, separately from per-avalanche activity.

---

## 12. Per-experiment operational model rules

This section translates the framework into specific rules per experiment. Every rule below is concrete enough to implement without further discussion.

### 01.01 BTW

- Energy framework treated as approximate (BTW multiscaling not captured by C-DP RD).
- Class A measurements (cumulative flux, cumulative KE) added; Class B snapshots not strictly required (BTW serves as comparison substrate).
- σ ≡ 1 (no structural reservoir); H accumulates passively.
- No simulator dynamics changes.

### 01.02 Manna

- Re-instrument with Class A (cumulative flux, cumulative KE) and Class C (periodic z, H snapshots).
- Class B (per-event activity-field, pre/post z) optional but recommended for top-K events to enable shape-collapse fits.
- σ ≡ 1; H accumulates passively (`α_H · n_topples_i` per cascade; cooling κ_i).
- **Sanity check**: re-instrumented ensemble must reproduce existing α∞ ∈ [1.265, 1.278], β_high = 1.60, b(x) ≈ 1.01 within ensemble noise. Failure indicates an instrumentation bug.
- Falsifiability: Sethna shape-collapse on the existing wave_profile data (no re-run needed); cumulative-KE map vs Model C damage prediction (cross-experiment test, §10.4).

### 01.03 Negatives

Operational rejection thresholds (referencing the rejection matrix from the experiment design):

- **Subcritical regime**: activity wave dies before reaching boundary. `wave_extent_max < L/2` for >90% of events, and ⟨wavefront velocity⟩ → 0 within first 5 wave steps.
- **Supercritical regime**: wave amplitude grows unboundedly. `peak n_in_wave > C · L²` for >5% of events with C ~ 0.1, and wave shape lacks a well-defined peak (monotonic growth until cap).
- **Poisson regime**: cumulative `j_(i→j)` field has no spatial coherence — autocorrelation in space < 0.1 across all bond pairs at all separations.
- **Heat reservoir is passively measured** — same as 01.02; no coupling.

### 01.04 Overtopping Model C

Active dynamical rules:

- **σ-damage**: `if n_topples_i > E_crit during one cascade: σ_i ← max(0, σ_i · (1 − α))`
- **σ-recovery**: `σ_i ← min(1, σ_i + recovery_base · f(H_i))` per timestep. f(H) optionally decreasing in H (heat-coupled recovery, §9.2).
- **Heat deposit**: `H_i ← H_i + α_H · n_topples_i` per cascade (default rule, §6.2).
- **Heat decay**: `H_i ← max(0, (1 − κ_i) · H_i)` per timestep, with `κ_i = κ_base · (degree_i / 4)`.
- **Effective threshold**: `effective_threshold_i = z_c + T · σ_i` (existing rule).
- Optional extensions (off by default in baseline sweep): σ-diffusion (§9.1), heat-modulated damage threshold (§9.3).

Falsifiability:

1. **Cumulative-KE prediction (§10.4)**: σ damage map should correlate with natural-Manna cumulative `n_topples_i` map at small α. Strong correlation = small perturbation; weak = strong coupling.
2. **Sethna shape distortion**: Model C wave shapes at matched duration should broaden compared to natural Manna (σ-damaged regions slow late-stage propagation).
3. **NESS for all three reservoirs**: σ, z, H should reach stable means in NESS for parameter combinations where the system doesn't run away. Runaway events in (T, α, recovery_base) parameter space define the absorbing-barrier boundary.

### 01.05 Liquefaction

- π = H field. The heat reservoir variable is reused.
- **Activation**: `H_local > H_crit AND s_i > s_crit AND d_i < d_crit AND cyclic-driver-active`.
- **Threshold lowering when activated**: `effective_threshold_i = max(0, z_c − T_a · H_i / H_max)`.
- **Cyclic driver**: per cycle, `H_i ← min(H_max, H_i + Δπ · A · activation_indicator_i)`.
- **Recovery**: H decays via κ_i after driving stops (same κ rule as 01.04).
- **Densification**: `d_i ← min(d_max, d_i + consolidation_rate · damage_events_at_i)`.

Reverse heat → KE coupling (§6.3) is **on** for this experiment: thermal activation of toppling at sub-threshold sites becomes a non-trivial contribution to dynamics.

Falsifiability: removing driving and waiting for H to dissipate must restore natural-SOC signatures. Densification must shift the precondition boundary observably across ensembles.

### 02 Synthetic Percolation

- No avalanche dynamics; baseline measurement of cluster structure on diluted lattice.
- Energy framework predicts: connectivity-dependent κ_i = κ_base · (degree_i / 4) in low-connectivity regions of the cluster. Heat persists longer in sparse cluster regions.
- No reservoir activity beyond structural (cluster topology only).

### 03 Activation Threshold (sandpile on percolation)

- **Activation energy** = minimum activity-wave amplitude that produces a spanning cascade on the current cluster topology.
- **Operationalized**: drop grains at increasing rates; measure rate at which 50% of events span the cluster.
- Predicted: `E_activation = f(p, p_c, D_eff)` where `D_eff` is the effective diffusivity on the cluster (computable from per-bond flux at a calibration p ≥ p_c).
- Falsifiability: measured activation energy curve as a function of p must match the prediction within ensemble noise. Disagreement reveals that the framework's percolation extension (per-bond flux + connectivity-dependent κ) is incomplete.

### 04 Absorbing Barrier and 06 Coupled SOC

Abbreviated; same instrumentation set as 01.04. Coupled SOC (06) requires additional instrumentation: per-coupling-bond flux between systems A and B, treated as the same primary observable as intra-system per-bond flux.

---

## 13. Summary of falsifiability tests

Consolidated list of every claim and the test that could refute it:

| Claim | Test | Refuted if |
|-------|------|-----------|
| Energy is additive (instrumentation only) | Re-run 01.02 with new instrumentation | α∞, β_high, b(x), other statistics shift outside ensemble noise |
| C-DP RD applies to Manna | Sethna shape-collapse on existing wave_profile | Curves don't collapse across L and duration bins |
| Mean-field shape correct | Same; fit `u^a (1−u)^b` | Asymmetry direction wrong (a ≥ b instead of a < b); specific (a, b) thresholds TBD pending source verification |
| Heat is non-causal in natural SOC | α_drop sweep on 01.02 | Avalanche statistics change with α_drop |
| Per-bond flux symmetric at NESS | Cumulative net flux on 01.02 | Significant non-zero net flux at interior bonds |
| σ-damage is small perturbation | Cumulative-KE vs Model C damage map | Correlation r < 0.3 at small α |
| Self-damping via −μn² | Wavefront velocity binned by peak amplitude (mean velocity given n_peak) | No deceleration as peak amplitude grows |
| NESS for all 3 reservoirs in 01.04 | Burn-in trace extended to σ, H | Reservoirs don't stabilize at fitted κ, α_H |
| Toppling-order independence (optional) | Re-run with sequential-random | Order-independent statistics differ by >0.5σ |
| Activation energy on percolation | E_activation(p) measurement | Disagrees with `f(p, p_c, D_eff)` prediction |
| Heat-coupled recovery in 01.04 | σ-trajectory vs local H correlation | Zero or positive correlation |

Each row is a test we either can run on existing data (top three) or queue for the next instrumentation pass.

---

## 14. Open questions documented for ongoing iteration

Items to revisit as the framework is exercised:

- **Heat as separate reservoir vs derived from height variance**: framework commits to "separate reservoir" with own continuity equation. Open question whether this is necessary or whether a derived form (heat ∝ post-event height variance) gives equivalent predictions. Test: do the two formulations differ on any observable? If not, prefer the simpler.
- **σ-diffusion: real mechanism or modeling choice?** Argument for: similar to fault healing; adds richness. Argument against: not all materials show it. Stay agnostic; document as configurable; sweep over D_σ ∈ {0, small, large} when 01.04 Model C runs.
- **Heat-σ coupling strength**: free parameter. Default to "off" until evidence demands it.
- **Toppling-order sensitivity test**: optional future check (not required validation). Documented protocol available.
- **Flux-divergence vs local-KE heat rule**: comparison test in 01.04 once flux instrumentation is in place.

---

## 15. Status of cross-experiment doc updates

The following experiment docs reference earlier versions of this energy framework and will need consistency updates after the rewrite is settled:

- `../validation/01_03_negatives.md` — pull in the operationalized rejection thresholds from §12
- `../validation/01_04_manna_overtopping.md` — Model C now references heat reservoir and cumulative-KE prediction
- `../validation/01_05_manna_liquefaction.md` — π = H connection made explicit; reverse heat → KE coupling activated
- `../validation/02_percolation.md` — connectivity-dependent κ hooks
- `../validation/03_activation_threshold.md` — activation energy operationalized as `f(p, p_c, D_eff)`
- `../validation/06_coupled_soc.md` — coupling = per-bond flux interface

These updates are deferred to a separate documentation pass after this framework is reviewed and accepted.

---

## Related documents

- `overtopping.md` — defines σ field, damage rule, recovery rule (this doc operationalizes their energy meaning)
- `liquefaction.md` — defines π = H connection (this doc unifies under heat reservoir)
- `distorted_soc_signatures.md` — detection categories (CSOC-like, ISOC-like) that this framework's mechanisms produce
- `architecture_mapping.md` — connection to the SOC Model Architecture's C_d framework
- `../validation/01_02_manna_sandpile.md` — natural-SOC baseline that re-instrumentation must reproduce
- `../validation/01_04_manna_overtopping.md` — the experiment that operationalizes this framework's σ + heat dynamics

## References

- **Lübeck, S.** (2004). "Universal scaling behavior of non-equilibrium phase transitions." *Int. J. Mod. Phys. B* 18, 3977. C-DP universality and reaction-diffusion form.
- **Vespignani, A., Zapperi, S., Pietronero, L.** (2000). Continuum field theory for sandpile models.
- **Bonachela, J. A., Muñoz, M. A.** (2009). "Self-organization without conservation: True or just apparent scale-invariance?" *J. Stat. Mech.* P09009. Self-organized quasi-criticality.
- **Muñoz, M. A., Dickman, R., Vespignani, A., Zapperi, S.** (1998). Manna abelian-in-distribution.
- **Tebaldi, C., De Menech, M., Stella, A. L.** (1999). "Multifractality, microcanonical distributions and universality of branching processes." *Phys. Rev. Lett.* 83, 3952. BTW multiscaling — why this framework doesn't apply quantitatively to BTW.
- **Kuntz, M. C., Sethna, J. P.** (2000). "Noise in disordered systems: The power spectrum and dynamic exponents in avalanche models." *Phys. Rev. B* 62, 11699. Avalanche shape; mean-field parabolic profile.
- **Papanikolaou, S., Bohn, F., Sommer, R. L., Durin, G., Zapperi, S., Sethna, J. P.** (2011). "Universality beyond power laws and the average avalanche shape." *Nature Physics* 7, 316. 2D avalanche shape corrections.
- **Sethna, J. P.** (2018). *Statistical Mechanics: Entropy, Order Parameters, and Complexity* (2nd ed.). Crackling-noise framework.
