# Overtopping — Primary Formalism for Suppressed-Release SOC Dynamics

## Preamble

This document specifies **overtopping**, the primary mechanistic formalism for SOC systems in which small events are suppressed and accumulated deficit is released through a structure that is itself damaged by the release. The name comes from the canonical physical example (water overtopping a dam), but the σ + damage + recovery formalism generalizes to any distributed suppression mechanism — institutional, normative, ecological, material — where the suppression structure is also part of the stress-transmission pathway. The dam image is mnemonic; it does not constrain the formalism.

The central insight is that **the suppression structure and the system structure may be the same thing**. When the system fails by release, the release destroys the structure that was providing containment. Post-failure dynamics can therefore be qualitatively different from pre-failure dynamics, and the upper energy boundary is not merely about propagation capacity but about structural survivability.

Overtopping gives a concrete, simulation-ready mathematical form for three previously-informal propositions:

1. The percolation-threshold termination mechanism (cascades end when propagation depletes connected energy below p_c).
2. The maximum-energy boundary (events that exceed what the structure can transmit damage the structure).
3. The **absorbing barrier** (architecture §5.5) as a locatable boundary in parameter space rather than an assertion.

Overtopping is paired with **liquefaction** (see `liquefaction.md`), which provides the symmetric mechanism on the amplification side. The signature patterns these mechanisms produce — mechanism-agnostic detection categories — are cataloged in `distorted_soc_signatures.md`. Historically, these patterns were called "CSOC-like" (suppressed-release) and "ISOC-like" (amplified-cascade) signatures; those terms survive in the signatures catalog as rigorously-defined adjective-form detection categories.

Read alongside:
- `liquefaction.md` — the ISOC-side counterpart (deferred corollary)
- `distorted_soc_signatures.md` — empirical detection categories
- `architecture_mapping.md` — connection to the SOC Model Architecture's C_d framework
- `../validation/01_03_manna_overtopping.md` — the corresponding experiment design

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

A naive exogenous-suppression model treats the mechanism that blocks small events as an external modifier of the system: small avalanches are suppressed, deficit accumulates, eventually a trigger causes a disproportionate release. The suppression is independent of the system it suppresses.

In the dam case, the suppression mechanism (the dam) and the pathway structure (the downstream channel) share physical material. Releasing the accumulated deficit requires propagating through the same walls that held it back. The release damages those walls. Once damaged, they cannot rebuild containment during the release, and may not fully recover after it.

The overtopping formalism treats this as the **general case** for suppressed-release dynamics. Any system where suppression is implemented via structural features — and where those features are also part of the stress-transmission pathway — will exhibit dam-like dynamics at failure. Uncoupled suppression (where the suppression mechanism is not damaged by what it suppresses) is a degenerate special case; see Part V's corner-case discussion.

### Implications

1. **Post-release suppression may be absent or weakened.** The cycle that follows failure is not simply a repeat of the cycle that preceded it. Deficit accumulation may not resume at the same rate, or at all, if the mechanism is gone.

2. **The upper energy boundary is not about propagation capacity in a static sense.** It is about whether the release energy exceeds what the system can survive structurally intact.

3. **Positive feedback introduces additional timescales.** Natural SOC has one timescale (driving). Suppressed-release adds deficit accumulation. Overtopping adds structural damage and repair. The trickle mechanism adds a controlled discharge rate. The ratios among these determine the regime (see Part IV).

4. **The absorbing barrier is locatable in parameter space.** The architecture (§5.5) asserts the absorbing barrier exists but does not specify where. In overtopping, the barrier is the boundary in (T, α, recovery_rate) space between regimes where failures recover and regimes where structural damage compounds to total collapse.

---

## Part III: Formal Framework

### The σ field

Introduce a structural integrity variable per site:

```
σ_i ∈ [0, 1]    σ_i(t=0) = 1.0
```

σ = 1 means fully intact structural integrity. σ = 0 means the suppression mechanism at that site is destroyed.

### Modified toppling condition

For the Manna model, natural toppling occurs at `z_i ≥ z_c` (typically z_c = 2). The overtopping formalism elevates the threshold via a suppression parameter T coupled to the local integrity σ_i:

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
- `recovery_rate >> α`: repair dominates → cyclical suppressed-release without compounding damage
- `recovery_rate ≈ α`: marginal stability, noisy alternation

### Trickle release (spillway)

Real containment structures often have controlled partial-release mechanisms — spillways on dams are the canonical case. A spillway bleeds off excess energy above a threshold lower than the failure threshold, preventing overtopping by providing a managed escape path. The analogous mechanism in governance: bankruptcy laws, scheduled elections, regulated market corrections, controlled protests, safety-valve institutions. These are deliberate small-event release mechanisms that discharge accumulated deficit without requiring full containment failure.

Add a fourth parameter `r` (trickle rate) and an auxiliary threshold `z_leak` (the spillway crest):

```
between grain drops, after recovery:
    for each site i with z_i > z_leak:
        discharge: z_i ← z_i − δ   at rate r · (z_i − z_leak) per timestep
        (or: discrete discharge of δ grains per timestep with probability r · (z_i − z_leak))
```

The trickle rate `r` governs how fast accumulated high-z sites bleed off to neighbors or out of the system. In the canonical form we treat trickle as out-of-system dissipation (the grain leaves the lattice, mimicking a spillway discharging to the downstream channel); an alternative form redistributes to neighbors. Both are worth testing.

Dynamical regimes from trickle:
- `r = 0` — no spillway. Classic overtopping dynamics as specified above.
- `r · spillway capacity ≫ input rate` — spillway has adequate capacity. Deficit cannot accumulate; the system behaves as natural SOC at a shifted operating point.
- `r · spillway capacity ≈ input rate` — marginal spillway. Deficit accumulates slowly; rare overtopping events when spillway is saturated.
- `r · spillway capacity ≪ input rate` — spillway is nominal but inadequate. Behaves much like no spillway; full overtopping dynamics dominate.

The trickle mechanism adds a third timescale (see Part IV) and a fourth phase-space dimension (see Part V). It changes the central question from "does this system overtop?" to "does its spillway suffice for its input?" — a first-order distinction the original three-parameter formalism cannot express.

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
4. Apply trickle: for each site with `z_i > z_leak`, discharge δ grains with probability `r · (z_i − z_leak)` (or equivalent deterministic rate).

---

## Part IV: Multi-Timescale Structure

Natural SOC has one governing timescale: the driving rate. Overtopping adds three more, for a four-timescale structure:

| Timescale | Setter | Dimensional form |
|-----------|--------|------------------|
| Driving | Grain-addition rate | 1 grain per timestep |
| Deficit accumulation | Natural SOC + T, net of trickle | O(L² · T) grains between release events when `r=0`; extended by trickle |
| Structural repair | recovery_rate | 1 / recovery_rate timesteps to fully heal |
| Trickle discharge | r, z_leak | 1 / r timesteps to bleed off one unit of excess above z_leak per site |

Ratios between these define regime:

- **recovery_rate >> damage rate per event × large event frequency**: suppression regrows between failures, cyclic CSOC-like dynamics.
- **recovery_rate ≈ damage rate per event × large event frequency**: marginal stability, alternating recovery and degradation.
- **recovery_rate << damage rate per event × large event frequency**: damage compounds faster than repair, σ trends downward, runaway failure.
- **r · excess > input rate**: spillway dominates, overtopping dynamics suppressed.
- **r · excess < input rate**: spillway inadequate, overtopping dynamics persist.

The damage-repair ratio determines whether a system stays CSOC-like or crosses the absorbing barrier. The trickle-input ratio determines whether the system enters the suppressed-release regime at all.

---

## Part V: Phase Space

Four control parameters: (T, α, recovery_rate, r). For tractable exploration, fix recovery_rate and r at representative values and map the (T, α) plane first:

| Region | Characterization | Architecture analog |
|--------|------------------|---------------------|
| Low T, low α | Close to natural SOC, σ mostly intact, avalanche distribution near natural SOC. | C_d ≈ 0, robust |
| High T, low α | Strong suppressed-release regime: large deficit-driven events, but σ survives the event. Cyclical accumulation–release. | Sub-critical (architecture §3) — over-ordered, dangerous, but recoverable |
| High T, high α | Runaway: large events damage σ enough that the next event finds a weaker structure. Damage compounds. σ trends to 0. Structural failure. | **Crossed absorbing barrier** (architecture §5.5) |
| Low T, high α | Weak suppression with fragile structure. Small events may damage σ without producing large releases. Anomalous. | Super-critical with structural fragility — unusual hybrid regime |

**The boundary between high-T/low-α and high-T/high-α is the primary experimental target.** Finding this boundary quantitatively locates the absorbing barrier in parameter space.

### The trickle dimension

With `r` added, each (T, α) regime gains a trickle-dependence:

| (T, α) regime | r = 0 | r · capacity ≈ input | r · capacity ≫ input |
|---|---|---|---|
| Low T | Natural SOC | Natural SOC (marginal effect) | Natural SOC |
| High T, low α | Cyclical suppressed-release | Occasional rare overtopping | Overtopping prevented; behaves as natural SOC at shifted operating point |
| High T, high α | Runaway | Delayed runaway | Runaway prevented as long as spillway holds; new failure mode if spillway itself degrades |

Two experimentally interesting boundaries emerge:
1. The (T, α) absorbing-barrier boundary at fixed (recovery_rate, r) — the primary target.
2. The **trickle sufficiency boundary** — the critical `r` at which overtopping dynamics disappear into natural-SOC behavior for given (T, α, recovery_rate). This is a governance-relevant quantity: it answers "how large must a controlled release mechanism be to prevent catastrophic events?"

### Corner cases (free baselines in the simulator)

- **T = 0** — no suppression. Recovers natural Manna SOC; sanity check against baseline Manna simulations (exp01_02).
- **α = 0, σ₀ = 1** — elevated threshold without structural dynamics. σ pins at 1; effective threshold is a constant `z_c + T`. Tests whether uncoupled suppression (the "abstract CSOC" case) actually produces the distinctive suppressed-release signatures or reduces to natural SOC at a rescaled operating point. Framework prediction: the latter — uncoupled suppression is approximately a renormalization.
- **r = 0** — no spillway. Recovers the original three-parameter overtopping dynamics.
- **α = 0, σ₀ = 1, r > 0** — pure spillway regime without structural damage. Tests trickle sufficiency in isolation.

---

## Part VI: Connection to Other Components

### The percolation-threshold termination mechanism

A long-standing (and informally-stated) proposition holds that SOC cascades self-terminate when activity depletes below a connectivity threshold p_c (see `energy_depletion_percolation_research_paths.md` for the research pathways). Overtopping makes this mechanism explicit: as σ degrades, effective connectivity of the suppressed lattice degrades with it. A site with σ = 0 topples at the natural threshold (no suppression) and transmits to its neighbors normally, but the suppressed system as a whole has lost coverage. **Structural failure is the explicit mechanism by which effective p_c can be lost independent of activity level.**

### The maximum-energy boundary

The same literature proposes that anomalous energy concentration may exceed what the pathway structure can transmit. Overtopping formalizes what happens at that boundary: excess energy damages σ, reducing effective capacity further, creating positive feedback. The maximum-energy boundary is not just where propagation exceeds capacity in a static sense — it is where the structure carrying the propagation is damaged by it. The positive feedback is what makes the boundary sharp rather than gradual.

### Connection to architecture §5.5 (Absorbing barrier)

Architecture §5.5 defines:

- **Fracture** — system breaks into pieces that remain individually viable.
- **Ruin** — system breaks and the pieces cannot function.
- **Absorbing barrier** — the state boundary beyond which ruin is inevitable.

In overtopping:

- Fracture corresponds to suppressed-release with σ recovering after each event. The system produces a large event, σ degrades locally, but recovery_rate restores it before the next event.
- Ruin corresponds to σ → 0 globally. The suppression mechanism is destroyed.
- The absorbing barrier is the set of parameter values where the damage-recovery balance tips from net recovery to net degradation.

This makes the architecture's absorbing barrier empirically locatable via simulation, not just a theoretical assertion. The experiment design in `../validation/01_03_manna_overtopping.md` specifies how to find it.

### Connection to detection categories

Overtopping is a mechanism proposal. The signatures it produces — truncated distributions, quasi-periodic large events, spectral knees, non-stationary branching ratio — are the CSOC-like signature bundle cataloged in `distorted_soc_signatures.md`. Detecting CSOC-like signatures in data does not prove the mechanism is overtopping (other mechanisms could produce the same pattern), but overtopping's quantitative predictions (Part VII below) discriminate it from alternative mechanism hypotheses.

---

## Part VII: Falsifiability Implications

The extension makes specific quantitative predictions that could be wrong:

1. **Phase transition in (T, α) space.** At fixed recovery_rate, there exists a well-defined boundary between "recovering" and "runaway" regimes. If the transition is gradual rather than sharp (a crossover instead of a phase transition), the framework's "absorbing barrier" concept needs refinement.

2. **σ degradation scales with event size above E_crit.** Specifically, post-event mean σ should drop by an amount proportional to (mean_flux − E_crit) in the damaged sites. If no such correlation exists — events don't damage σ, or damage is size-independent — the flux-triggered damage mechanism is wrong.

3. **Inter-event interval lengthens after partial damage.** A system with degraded σ_mean should have longer intervals between large events (because thresholds are lower, so more frequent small releases bleed off deficit). If intervals don't lengthen with damage, the σ-threshold coupling is wrong.

4. **Runaway onset is sudden, not gradual.** Once σ drops below a critical value (specific to the parameter combination), degradation should accelerate rather than stabilize. If σ decay is exponential everywhere in parameter space (no critical onset), the framework's "absorbing barrier" is not a sharp boundary.

5. **Recovery_rate rescues high-damage regimes.** Increasing recovery_rate at fixed (T, α) should move the system from runaway to recovering. If the regime is determined solely by damage rate without recovery mattering, the framework's timescale-ratio interpretation is wrong.

6. **Trickle sufficiency boundary is sharp.** Increasing `r` at fixed (T, α, recovery_rate) should move the system from suppressed-release dynamics toward natural-SOC-like behavior with a well-defined critical `r*` above which CSOC-like signatures disappear. If the transition is gradual or the signatures persist at arbitrary `r`, the spillway formalism needs refinement.

7. **Trickle lengthens inter-event intervals monotonically.** At fixed (T, α, recovery_rate), increasing `r` should increase the mean time between overtopping events (more deficit bled off continuously → longer accumulation times before crossing the failure threshold). If intervals do not lengthen with `r`, the trickle-as-deficit-relief model is wrong.

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

What's different in overtopping: the DS model modifies binary lattice occupancy (site present / absent); overtopping modulates a continuous σ field that changes a **suppression threshold**. DS has no "suppressed" regime; the whole model lives at its natural critical state. Overtopping starts from a suppressed-release substrate (threshold elevation T) and asks what happens when that elevation is fragile.

### Rate-and-state friction in earthquake models (Dieterich 1979, Ruina 1983; OFC variants)

Fault surfaces have a state variable that decays with slip (slip weakens the fault) and heals during quiescent periods. Slip-weakening drives slip instability (positive feedback); healing restores state between events. Mapped onto overtopping: state variable is σ-like, slip is toppling, healing is recovery_rate.

The dynamics are formally similar. What's different: friction models typically aim to reproduce the Gutenberg-Richter law (natural SOC distribution); overtopping explicitly asks about the suppressed-release regime (threshold elevated) and the failure of that suppression. Different motivating question, similar mathematics.

### Neural SOC with synaptic plasticity (Levina, Herrmann, Geisel 2007; Hernández-Urbina & Herrmann 2017)

Neural avalanche models where synapse strengths adapt based on activity. Activity strengthens some synapses (LTP), sustained activity causes long-term depression (LTD). Analog to overtopping's σ dynamics but richer — synapses can increase or decrease, not just damage and recover.

### Self-organized quasi-criticality (Bonachela & Muñoz 2010)

Broader framing: systems where the control parameter is dynamically driven by activity in a way that keeps the system near (but not exactly at) the critical point. Overtopping fits this family — σ is dynamically modified by activity, and in the "recovering suppressed-release" regime the system sits near a quasi-critical state defined by the damage-recovery balance.

### Adaptive network SOC (Gross & Blasius 2008 review)

Networks where edges form or break based on node activity. Topology-responds-to-dynamics is the general frame. Overtopping is a node-local version (σ per site) rather than an edge version, but fits the same conceptual family.

### What's novel in overtopping

Given these precedents, what's distinctive about overtopping:

1. **The combination of threshold elevation (T) with substrate damage (σ degradation) on an SOC substrate.** None of the above precedents combine all three: forest fire has no threshold elevation (it lives at its natural critical state), RAS friction has no explicit elevation parameter distinct from the state variable, neural plasticity models lack the suppression framing. Overtopping asks what happens specifically when a system in a suppressed-release regime fails, with the suppression mechanism itself being the fragile structure.

2. **Explicit link to the absorbing barrier concept.** Overtopping provides the mechanism by which the architecture's absorbing barrier (§5.5) becomes empirically locatable in parameter space. Forest fire and RAS-friction models aren't typically framed this way.

3. **Four-timescale structure with recovery_rate AND trickle-release as specific phase-space dimensions.** The parameter (T, α, recovery_rate, r) phase space is a novel formulation; earlier models have subsets but not all four simultaneously. The trickle-release dimension is particularly novel — it distinguishes systems with adequate controlled-release mechanisms from those without, a first-order governance-relevant distinction.

4. **Release-damages-containment framing.** The overtopping mechanism has a specific physical intuition (release energy damages the pathway that's carrying it) that's distinct from fire-consumes-fuel or slip-weakens-fault.

When results are published, the Related Work discussion should explicitly cite the precedents above and state overtopping's contribution as the combination, not as inventing the feedback dynamic in isolation.

---

## Summary

Overtopping is the primary mechanistic formalism for suppressed-release SOC dynamics. It gives a concrete, simulation-ready account of the maximum-energy boundary, the percolation-threshold termination condition, and the architecture's absorbing barrier. The σ field couples suppression strength to release energy via a positive-feedback damage-recovery loop; the trickle mechanism adds a controlled-release valve that distinguishes "no safety valve" systems from "adequate safety valve" systems at the governance level.

Four parameters (T, α, recovery_rate, r) generate a phase space with two primary boundaries:
1. The **absorbing barrier** — the (T, α) boundary at fixed (recovery_rate, r) between recovering and runaway regimes.
2. The **trickle sufficiency boundary** — the critical `r` above which suppressed-release dynamics disappear at fixed (T, α, recovery_rate).

Both are testable via simulation on the Manna substrate (see `../validation/01_03_manna_overtopping.md`). The formalism subsumes abstract suppression (α = 0, σ = 1 corner) and natural SOC (T = 0 corner) as free baselines.

Related Work (Part IX) situates overtopping within existing literature on activity-substrate feedback in SOC; the mechanism draws on precedents (Drossel-Schwabl forest-fire regrowth, rate-and-state friction, synaptic plasticity models, self-organized quasi-criticality, adaptive-network SOC) but is distinctive in its three-timescale structure with explicit trickle-release and its tie to the absorbing-barrier concept.

Status: **theoretical framework, not yet implemented or tested.** All numerical values, parameter choices, and expected regime boundaries are hypothesis, not fact.
