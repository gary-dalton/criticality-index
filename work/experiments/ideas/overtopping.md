# Overtopping — A CSOC Extension

## Preamble

This document extends the Capacitive SOC (CSOC) framework with a structural-fragility mechanism we call **overtopping**. The name comes from the canonical physical example (water overtopping a dam), but the mechanism generalizes beyond hydrology to any system where the suppression structure and the system structure share material or function.

The extension formalizes what was previously speculative in CSOC Parts VII and VIII (percolation-threshold termination and maximum energy boundary) and gives a concrete, simulation-ready mathematical form. It establishes a three-way naming parallel to the existing CSOC / ISOC framework:

- **CSOC** — suppression of small events
- **ISOC** — amplification of events
- **Overtopping** — CSOC where the release damages the suppression

The central insight is that in CSOC, **the suppression structure and the system structure may be the same thing**. When the system fails by release, the release destroys the structure that was providing containment. This means post-failure dynamics can be qualitatively different from pre-failure dynamics, and the upper energy boundary is not merely about propagation capacity but about structural survivability.

This document should be read alongside `capacitive_SOC_framework.md` (which establishes CSOC proper) and `../validation/01_03_manna_overtopping.md` (the corresponding experiment design).

---

## Part I: Motivation — Dam Overtopping as Physical Analogy

### The failure cascade

When water overtops a dam it does not flow over harmlessly:

- Water flowing over the crest hits the downstream face at high velocity.
- The downstream face is typically not designed to handle flowing water — it is designed to *hold* water, not *convey* it.
- The flowing water erodes the downstream face — in earthen dams this is rapid, in concrete dams it undermines the foundation.
- Erosion creates a notch, which concentrates flow, which accelerates erosion. Positive feedback.
- The notch deepens faster than the reservoir level drops.
- Structural integrity fails faster than the energy driving the failure dissipates.
- Complete failure follows rapidly from what began as a small overflow.

The structure was never designed to handle the energy of its own release. It was designed to contain. The moment containment fails, the structure encounters a regime it has no capacity to survive.

### Why complete failure rather than partial

Four mechanisms combine:

1. The erosion positive feedback accelerates faster than any natural damping can arrest it.
2. The structural elements that would need to resist failure are the same elements being destroyed by the failure.
3. There is no stable intermediate state — partial overtopping leads to more overtopping leads to more erosion.
4. The energy driving the failure — the head of water — does not diminish fast enough to arrest the process once started.

The failure is not proportional to the trigger. It is proportional to the accumulated deficit behind the structure.

---

## Part II: The Central Insight

### Suppression and system may coincide

In CSOC as previously specified, the suppression mechanism was an external modifier of the system: small avalanches are suppressed, deficit accumulates, eventually a trigger causes a disproportionate release. The mechanism was exogenous.

In the dam case, the suppression mechanism (the dam) and the pathway structure (the downstream channel) share physical material. Releasing the accumulated deficit requires propagating through the same walls that held it back. The release damages those walls. Once damaged, they cannot rebuild containment during the release, and may not fully recover after it.

The extension says: treat this as the general case for CSOC, not the special case. Any system where suppression is implemented via structural features — and where those features are also part of the stress-transmission pathway — will exhibit dam-like dynamics at failure.

### Implications for the framework

1. **Post-release suppression may be absent or weakened.** The cycle that follows failure is not simply a repeat of the cycle that preceded it. Deficit accumulation may not resume at the same rate, or at all, if the mechanism is gone.

2. **The upper energy boundary is not about propagation capacity in a static sense.** It is about whether the release energy exceeds what the system can survive structurally intact. This is a refinement of the speculative "maximum energy boundary" in CSOC framework Part VIII.

3. **Positive feedback introduces a third timescale.** Natural SOC has one timescale (driving). CSOC adds deficit accumulation. This extension adds structural damage and repair. The ratio of damage to repair rates determines whether failures compound or recover.

4. **The absorbing barrier is locatable in parameter space.** The architecture (§5.5) asserts the absorbing barrier exists but does not specify where. In this extension, the barrier is the boundary in (T, α, recovery_rate) space between regimes where failures recover and regimes where structural damage compounds to total collapse.

---

## Part III: Formal Framework

### The σ field

Introduce a structural integrity variable per site:

```
σ_i ∈ [0, 1]    σ_i(t=0) = 1.0
```

σ = 1 means fully intact structural integrity. σ = 0 means the suppression mechanism at that site is destroyed.

### Modified toppling condition

For the Manna model, natural toppling occurs at `z_i ≥ z_c` (typically z_c = 2). The CSOC modification elevates the threshold via a suppression parameter T:

```
effective_threshold_i = z_c + T · σ_i
topple site i when z_i ≥ effective_threshold_i
```

- When σ_i = 1: full suppression, site topples at `z_c + T`.
- When σ_i → 0: suppression absent, site topples at natural threshold `z_c`.
- Intermediate σ_i: partial suppression, partially damaged site.

### Damage mechanism

When a toppling occurs at site i, compute the local energy flux. If the flux exceeds a critical value E_crit, the structural integrity at that site degrades:

```
if flux_i > E_crit:
    σ_i ← σ_i · (1 − α)
```

where α ∈ (0, 1) is the damage rate per damaging event.

The flux definition is an important modeling choice (see Open Questions). For the canonical form we use **cumulative topplings at site i during the current avalanche**: this captures the "repeated stress damages" intuition and matches the dam analogy in which prolonged flow erodes more than a single surge.

### Recovery mechanism

Between grain drops (or at a slower rate during avalanches), σ slowly recovers toward 1:

```
σ_i ← min(1, σ_i + recovery_rate)
```

where `recovery_rate` is the fractional recovery per timestep. Typical regimes:

- `recovery_rate << α`: damage compounds faster than repair → runaway failures possible
- `recovery_rate >> α`: repair dominates → CSOC cycles without compounding damage
- `recovery_rate ≈ α`: marginal stability, noisy alternation

### Complete dynamics

Per timestep:

1. Add one grain to a random site (slow driving).
2. If any site is unstable, run avalanche to completion:
   a. Identify unstable sites (`z_i ≥ z_c + T · σ_i`).
   b. For each, topple: subtract 2 from z_i, add 1 each to two randomly chosen neighbors.
   c. Track cumulative topplings per site during this avalanche.
   d. If any site's cumulative toppling count crosses above the flux threshold E_crit, apply damage: `σ_i ← σ_i · (1 − α)`.
   e. Recompute unstable set and repeat until all sites stable.
3. Apply recovery: `σ_i ← min(1, σ_i + recovery_rate)` for all sites.

---

## Part IV: Three-Timescale Structure

Natural SOC has one governing timescale: the driving rate. CSOC introduced a second: the deficit accumulation timescale (how long between release events). This extension introduces a third: the structural repair timescale.

| Timescale | Setter | Dimensional form |
|-----------|--------|------------------|
| Driving | Grain-addition rate | 1 grain per timestep |
| Deficit accumulation | Natural SOC + T | O(L² · T) grains between release events |
| Structural repair | recovery_rate | 1 / recovery_rate timesteps to fully heal |

Ratios between these define regime:

- **recovery_rate >> damage rate per event × large event frequency**: suppression regrows between failures, CSOC proceeds cyclically.
- **recovery_rate ≈ damage rate per event × large event frequency**: marginal stability, alternating recovery and degradation.
- **recovery_rate << damage rate per event × large event frequency**: damage compounds faster than repair, σ trends downward, eventual runaway failure.

The third ratio is the one that determines whether a system stays in CSOC or crosses the absorbing barrier. It is the parameter to sweep most carefully.

---

## Part V: Phase Space

Three control parameters: (T, α, recovery_rate). For initial exploration, fix recovery_rate at a representative value and map the (T, α) plane:

| Region | Characterization | Architecture analog |
|--------|------------------|---------------------|
| Low T, low α | Close to natural SOC, σ mostly intact, avalanche distribution near natural SOC. | c_d ≈ 0, robust |
| High T, low α | Strong CSOC: large deficit-driven events, but σ survives the event. Cyclical accumulation–release. | Sub-critical (architecture §3) — over-ordered, dangerous, but recoverable |
| High T, high α | Runaway: large events damage σ enough that next event finds a weaker structure. Damage compounds. σ trends to 0. Structural failure. | **Crossed absorbing barrier** (architecture §5.5) |
| Low T, high α | Weak suppression with fragile structure. Small events may damage σ without producing large releases. Anomalous. | Super-critical with structural fragility — unusual hybrid regime |

**The boundary between high-T/low-α and high-T/high-α is the primary experimental target.** Finding this boundary quantitatively locates the absorbing barrier in parameter space.

---

## Part VI: Connection to Existing Framework

### Refinement of CSOC Parts VII and VIII

**Part VII (Percolation Threshold as Termination Condition)** proposed that cascades self-terminate when activity depletes below a connectivity threshold. This extension is compatible: as σ degrades, effective connectivity degrades, and structural failure can prevent the system from returning to the recurrent class even if activity drops. The σ field is the explicit mechanism by which effective percolation can be lost.

**Part VIII (Maximum Energy and System Capacity)** proposed an upper boundary where anomalous energy concentration exceeds what the pathway structure can transmit. This extension formalizes what happens *at* that boundary: the excess energy damages σ, which reduces the effective capacity further, creating the positive feedback. The maximum-energy boundary is not just where propagation exceeds capacity — it is where the structure carrying the propagation is damaged by it.

### Connection to architecture §5.5 (Absorbing barrier)

Architecture §5.5 defines:

- **Fracture** — system breaks into pieces that remain individually viable.
- **Ruin** — system breaks and the pieces cannot function.
- **Absorbing barrier** — the state boundary beyond which ruin is inevitable.

In this extension:

- Fracture corresponds to CSOC with σ recovering after each release. The system produces a large event, σ degrades locally, but recovery_rate restores it before the next event.
- Ruin corresponds to σ → 0 globally. The suppression mechanism is destroyed.
- The absorbing barrier is the set of parameter values where the damage-recovery balance tips from net recovery to net degradation.

This makes the architecture's absorbing barrier empirically locatable via simulation, not just a theoretical assertion.

---

## Part VII: Falsifiability Implications

The extension makes specific quantitative predictions that could be wrong:

1. **Phase transition in (T, α) space.** At fixed recovery_rate, there exists a well-defined boundary between "recovering" and "runaway" regimes. If the transition is gradual rather than sharp (a crossover instead of a phase transition), the framework's "absorbing barrier" concept needs refinement.

2. **σ degradation scales with event size above E_crit.** Specifically, post-event mean σ should drop by an amount proportional to (mean_flux − E_crit) in the damaged sites. If no such correlation exists — events don't damage σ, or damage is size-independent — the flux-triggered damage mechanism is wrong.

3. **Inter-event interval lengthens after partial damage.** A system with degraded σ_mean should have longer intervals between large events (because thresholds are lower, so more frequent small releases bleed off deficit). If intervals don't lengthen with damage, the σ-threshold coupling is wrong.

4. **Runaway onset is sudden, not gradual.** Once σ drops below a critical value (specific to the parameter combination), degradation should accelerate rather than stabilize. If σ decay is exponential everywhere in parameter space (no critical onset), the framework's "absorbing barrier" is not a sharp boundary.

5. **Recovery_rate rescues high-damage regimes.** Increasing recovery_rate at fixed (T, α) should move the system from runaway to recovering. If the regime is determined solely by damage rate without recovery mattering, the framework's timescale-ratio interpretation is wrong.

Each of these is testable in the Manna + overtopping simulation (see `../validation/01_03_manna_overtopping.md`).

---

## Part VIII: Open Questions

### 1. Flux definition

Three candidates for the "flux at site i":

- **Instantaneous z_i at toppling.** Simplest. Captures peak energy at the moment of release.
- **Cumulative topplings at site i during this avalanche.** Captures repeated stress and matches the dam-flow analogy.
- **Total energy passing through the site over a time window.** Captures sustained flow.

Initial implementation uses option 2 (cumulative topplings during avalanche). If results are sensitive to this choice, all three should be tested.

### 2. σ update timing

- **Mid-cascade:** σ updates during the avalanche as each site crosses the flux threshold. Most physically accurate, matches dam erosion happening during flow. Introduces in-cascade nonstationarity.
- **End-of-avalanche:** σ updates computed once per avalanche. Simpler, avoids nonstationarity, but misses the positive feedback within single events.

Initial implementation uses mid-cascade. End-of-avalanche should be tested as a comparison.

### 3. Recovery timing

- **Per grain drop:** Apply recovery between avalanches, not during. Physically motivated: repair is slow compared to avalanche dynamics.
- **Continuous:** Apply a small recovery at every toppling step. Less physical but mathematically simpler.

Initial implementation uses per-grain-drop recovery.

### 4. Endogenous vs. exogenous suppression rebuilding

The framework above models endogenous recovery via `recovery_rate`. Real systems (governance, infrastructure) also have exogenous suppression rebuilding — external actors deliberately restore a damaged mechanism (constitutional conventions, treaty renegotiation, infrastructure repair following a disaster). This would be modeled as a discrete event that resets σ → 1 at random (or externally-triggered) times. Not included in the initial framework; worth noting as a natural extension.

### 5. Parameter scaling with L

All three parameters (T, E_crit, recovery_rate) may need to scale with system size:

- T scales as a density? Or absolute value?
- E_crit scales as L^β for some β?
- recovery_rate independent of L?

Initial implementation uses L-independent parameter values. If results don't collapse with L, parameter scaling needs to be found empirically — the scaling itself would be a physics result.

### 6. Relationship to bulk dissipation

Standard Manna has no bulk dissipation (grains only leave at boundaries). Adding σ-dependent toppling could be viewed as a form of state-dependent bulk dissipation — when σ is low, the site dissipates less efficiently. Whether to add explicit bulk dissipation on top of σ dynamics, or treat σ itself as the dissipation modulator, is a design choice worth documenting.

---

## Part IX: Related Work

Overtopping is not the first SOC extension with activity-damages-substrate feedback. Several published SOC models contain closely related mechanisms, and overtopping should be understood as a specific novel combination rather than an entirely novel mechanism.

### Forest fire model with regrowth (Drossel & Schwabl 1992)

The Drossel-Schwabl forest fire model has trees that regrow at rate p and fires that consume connected tree clusters at rate f. The consumed-tree / regrowth cycle is the closest published precedent for the overtopping damage-recovery loop:

- Fire (release event) → tree consumed (substrate damaged)
- Slow regrowth (analog of recovery_rate)
- Runaway if p << consumption rate × fire frequency

What's different in overtopping: the DS model modifies binary lattice occupancy (site present / absent); overtopping modulates a continuous σ field that changes a **suppression threshold**. DS has no "suppressed" regime; the whole model lives at its natural critical state. Overtopping sits on top of CSOC (threshold elevation) and asks what happens when that elevation is fragile.

### Rate-and-state friction in earthquake models (Dieterich 1979, Ruina 1983; OFC variants)

Fault surfaces have a state variable that decays with slip (slip weakens the fault) and heals during quiescent periods. Slip-weakening drives slip instability (positive feedback); healing restores state between events. Mapped onto overtopping: state variable is σ-like, slip is toppling, healing is recovery_rate.

The dynamics are formally similar. What's different: friction models typically aim to reproduce the Gutenberg-Richter law (natural SOC distribution); overtopping explicitly asks about the CSOC regime (suppression elevated) and the failure of that suppression. Different motivating question, similar mathematics.

### Neural SOC with synaptic plasticity (Levina, Herrmann, Geisel 2007; Hernández-Urbina & Herrmann 2017)

Neural avalanche models where synapse strengths adapt based on activity. Activity strengthens some synapses (LTP), sustained activity causes long-term depression (LTD). Analog to overtopping's σ dynamics but richer — synapses can increase or decrease, not just damage and recover.

### Self-organized quasi-criticality (Bonachela & Muñoz 2010)

Broader framing: systems where the control parameter is dynamically driven by activity in a way that keeps the system near (but not exactly at) the critical point. Overtopping fits this family — σ is dynamically modified by activity, and in the "recovering CSOC" regime the system sits near a quasi-critical state defined by the damage-recovery balance.

### Adaptive network SOC (Gross & Blasius 2008 review)

Networks where edges form or break based on node activity. Topology-responds-to-dynamics is the general frame. Overtopping is a node-local version (σ per site) rather than an edge version, but fits the same conceptual family.

### What's novel in overtopping

Given these precedents, what's distinctive about overtopping:

1. **The combination of CSOC (threshold elevation T) with substrate damage (σ degradation).** None of the above precedents are specifically CSOC — they operate on natural SOC substrates. Overtopping asks what happens when a suppressed system fails, with the suppression mechanism itself being the fragile structure.

2. **Explicit link to the absorbing barrier concept.** Overtopping provides the mechanism by which the architecture's absorbing barrier (§5.5) becomes empirically locatable in parameter space. Forest fire and RAS-friction models aren't typically framed this way.

3. **Three-timescale structure with recovery_rate as a specific phase-space dimension.** The parameter (T, α, recovery_rate) phase space is a novel formulation; earlier models have two of these three but not all three simultaneously.

4. **Release-damages-containment framing.** The overtopping mechanism has a specific physical intuition (release energy damages the pathway that's carrying it) that's distinct from fire-consumes-fuel or slip-weakens-fault.

When results are published, the Related Work discussion should explicitly cite the precedents above and state overtopping's contribution as the combination, not as inventing the feedback dynamic in isolation.

---

## Summary

The overtopping extension gives CSOC a concrete, simulation-ready mechanism for the previously-speculative "maximum energy boundary" and for the architecture's "absorbing barrier." The σ field couples suppression strength to release energy via a positive-feedback damage-recovery loop. Three parameters (T, α, recovery_rate) generate a phase space whose "recovering ↔ runaway" boundary is the absorbing barrier in parameter space.

The extension is testable via simulation on the Manna model (see `../validation/01_03_manna_overtopping.md`) and generates quantitative predictions that could falsify it. Related work (Part IX) situates overtopping within the existing literature on activity-substrate feedback in SOC; the mechanism draws on precedents but is distinctive in its CSOC framing and its explicit tie to the absorbing-barrier concept.

Status: **theoretical framework, not yet implemented or tested.** All numerical values, parameter choices, and expected regime boundaries are hypothesis, not fact.
