# Liquefaction — ISOC-Side Mechanism (Corollary)

## Status

**Theoretical skeleton, not simulation-ready.** This document specifies the intended formalism for the ISOC-side counterpart to overtopping. It is deferred as a corollary to the primary overtopping experimental program. Parameters, dynamics, and predictions below are hypothesis, not fact.

## Preamble

Liquefaction is the primary mechanistic formalism for SOC systems exposed to cyclic external driving that amplifies cascades mid-propagation, producing system-spanning events and history-dependent response. The name comes from the canonical physical example — soil liquefaction under seismic loading — but the formalism generalizes to any SOC system coupled to an external driver that can destroy local damping mechanisms during events. The soil image is mnemonic; it does not constrain the formalism.

The central insight is that a system's **transmission medium** can be destabilized by cyclic loading. In standard (natural) SOC, local force chains or damping mechanisms terminate cascades by absorbing propagating energy. In a liquefiable state, those local damping mechanisms are destroyed during the event itself — pore pressure rises to equal confining pressure, grain contacts are lost, and the system loses its ability to absorb and terminate propagation. The result is a system-spanning amplified cascade whose magnitude depends more on external driving than on local stored potential.

This document should be read alongside `overtopping.md` (the CSOC-side primary mechanism) and `distorted_soc_signatures.md` (the ISOC-like signature bundle liquefaction is expected to produce).

---

## Part I: Motivation — Soil Liquefaction as Physical Analogy

### The failure dynamic

When saturated loose granular soil is subjected to cyclic loading (earthquake, machine vibration, wave action):

- Each cycle of stress increases pore-water pressure by a small increment.
- Effective stress (total stress minus pore pressure) decreases toward zero.
- As effective stress drops, grain-contact force chains — which normally carry stress between grains and provide local damping — are progressively destroyed.
- When effective stress approaches zero, the soil transitions from solid-like to liquid-like behavior. Buildings sink, flat ground spreads laterally, sand boils vent.
- The failure is not proportional to the triggering stress; it is proportional to the accumulated pore-pressure buildup from prior cycles, which depends on preconditions (saturation, density, grain size) independent of the current cycle.

After shaking stops, pore pressure dissipates, effective stress recovers, and grain contacts reform — but the post-event soil is denser than the pre-event soil, and its response to future cyclic loading is altered.

### Why this is ISOC and not natural SOC

Four features distinguish liquefaction dynamics from natural SOC:

1. **External driving injects energy into ongoing cascades.** Unlike slow SOC driving (grain drops between events), cyclic loading continues *during* the event and sustains it. This is amplification during propagation, the defining feature of ISOC-like dynamics.
2. **Local damping is destroyed during the event.** The grain contacts that would terminate a natural SOC cascade are precisely what cyclic loading dismantles. Termination is delayed until the external driving stops.
3. **History dependence.** Response to a given stress depends on the current pore-pressure state, which depends on prior loading history. A system that has just experienced strong shaking is more liquefiable than a fresh one.
4. **Preconditions matter.** Dense well-drained soil does not liquefy regardless of shaking. The phenomenon requires a combination of saturation, density, and grain-size distribution that permits pore-pressure buildup. ISOC-like dynamics emerge only when preconditions are satisfied.

### Why complete liquefaction rather than partial

Three mechanisms combine:

1. Each cycle of cascading motion produces more pore-pressure buildup, which lowers effective stress, which permits more motion. Positive feedback during the event.
2. Lost grain contacts cannot reform during the event because pore pressure prevents grain-grain contact pressure.
3. The external driver (shaking) continues to pump energy in regardless of the soil's state. There is no natural feedback that reduces driving as damage accumulates.

The failure propagates to the boundary of the driven region.

---

## Part II: The Central Insight

### Transmission medium and damping may coincide

In a naive amplification model, the mechanism sustaining cascades is external to the system: some amplifier boosts propagation, events run further, but the system's local damping mechanisms remain intact. Once external amplification is removed, the system returns to natural SOC immediately.

In the liquefaction case, the external driver (cyclic loading) destroys the local damping mechanism (grain contacts carrying force chains) during the event. The transmission medium (the granular skeleton) is the same material that provides damping. Destroying damping and destroying transmission capacity are the same operation.

The formalism treats this as the **general case** for amplification-driven dynamics. Any system where cyclic external driving destroys local damping structure during events will exhibit liquefaction-like dynamics. Pure external amplification without damping-structure destruction is a degenerate special case.

### Implications

1. **Post-event state is not the pre-event state.** Even after driving stops and pore pressure dissipates, the soil skeleton is denser and its future response is altered.
2. **The boundary of cascade propagation is the boundary of the driven region**, not the boundary of stored local potential. Cascades can recruit essentially all of the driven region regardless of pre-event stress distribution.
3. **Preconditions introduce a new timescale** — the time required to build the preconditions (saturate the soil, accumulate legitimacy deficit, reach susceptible population density). This is distinct from the event timescale and the recovery timescale.
4. **Structural consequences accumulate across events.** Repeated liquefaction densifies the soil. After enough cycles, the soil may no longer satisfy the liquefaction preconditions — the system "grows out of" the susceptible regime. The opposite of overtopping's progressive structural decay.

---

## Part III: Formal Framework (Draft)

### The π field

Introduce a per-site **pore-pressure-analog** variable:

```
π_i ∈ [0, π_max]    π_i(t=0) = π_0
```

π represents local latent amplification potential. π = 0 means no amplification; π → π_max means local damping is completely destroyed and the site transmits without dissipation.

### Preconditions

Liquefaction dynamics activate only when preconditions are met. At minimum:

- **Saturation-analog** `s_i ∈ [0, 1]` — fraction of local "pore space" filled with the liquefiable medium.
- **Density-analog** `d_i ∈ [0, d_max]` — local structural density that resists amplification (denser = more resistant).
- **Activation threshold** — liquefaction dynamics engage when `s_i > s_crit` AND `d_i < d_crit` AND external cyclic driver present.

Below activation, the system behaves as natural SOC.

### Cyclic external driver

Unlike overtopping (and natural SOC), liquefaction requires an external cyclic driver:

- Driving has amplitude `A` and frequency `ω`.
- Each cycle increments π at each activated site:
  ```
  if site_activated(i):
      π_i ← min(π_max, π_i + Δπ · A)
  ```
- Δπ may scale with proximity to currently-active sites (cascades increase local π beyond the baseline cyclic contribution).

### Modified toppling (amplification)

When π_i is high, the site's effective threshold is reduced:

```
effective_threshold_i = z_c − T_a · (π_i / π_max)
topple site i when z_i ≥ effective_threshold_i
```

where T_a is an amplification parameter (analogous to T in overtopping but with opposite sign — T_a lowers the threshold, T raises it).

### Post-event relaxation

After driving ceases:

- π dissipates: `π_i ← π_i − decay_rate` (pore pressure equilibrates over time).
- d recovers (densification if repeated events): `d_i ← min(d_max, d_i + consolidation_rate · events_experienced)`.

### Structural consequences

Repeated liquefaction events modify `d_i` upward (densification), gradually moving the site out of the liquefiable regime. This is the opposite of overtopping's structural decay — liquefaction self-stabilizes after enough cycles, at the cost of permanent structural alteration.

---

## Part IV: Multi-Timescale Structure

| Timescale | Setter | Dimensional form |
|-----------|--------|------------------|
| Driving (natural SOC) | Baseline event rate | Relevant only when cyclic driver absent |
| Cyclic driver | ω | 2π / ω per cycle |
| Pore-pressure buildup | Δπ · A · ω | π_max / (Δπ · A · ω) cycles to full liquefaction |
| Depletion recovery | decay_rate | 1 / decay_rate timesteps for π to return to baseline |
| Densification | consolidation_rate · event_frequency | Many events required to move out of liquefiable regime |
| Precondition establishment | System-specific | Time to build saturation + loose density before liquefaction possible |

The precondition-establishment timescale is the key new timescale distinguishing liquefaction from simpler amplification models.

---

## Part V: Phase Space (Draft)

Control parameters: (T_a, A, ω, decay_rate, consolidation_rate, s_i, d_i initial conditions, precondition thresholds).

Primary experimental sweep: fix most and vary (A, ω) against the preconditions plane.

| Region | Characterization |
|---|---|
| Low A, any ω | No liquefaction; natural SOC dominates. |
| High A, low ω (rare strong events) | Episodic liquefaction; full recovery between events. |
| High A, high ω (continuous driving) | Sustained liquefaction; system spends significant time in liquefied state; densification slow. |
| High A, any ω, pre-dense | Preconditions not met; no liquefaction regardless of driving. |
| High A, any ω, fully saturated + loose | Preconditions met; liquefaction triggered easily; densification gradually moves system out of regime. |

The **precondition activation boundary** (s, d combination at which liquefaction becomes possible) is the primary experimental target. The **sustained-liquefaction boundary** (A, ω at which the system spends >X% of time liquefied) is the secondary target.

---

## Part VI: Falsifiability Implications (Draft)

Specific quantitative predictions:

1. **Preconditions are discrete, not gradual.** There should exist a sharp (s_crit, d_crit) boundary at which liquefaction-like dynamics activate. Below the boundary, events are natural SOC. Above, events show ISOC-like signatures. If the transition is gradual, the precondition framework needs refinement.

2. **π scales with cumulative driving.** Post-event π should correlate with total cyclic-loading-cycles-accumulated, not just current driving amplitude. If π is memoryless, the pore-pressure-analog model is wrong.

3. **History-dependent susceptibility is the key discriminator.** Liquefaction-like regimes should show post-event reduction in subsequent event size before recovery. Natural supercriticality should not.

4. **Removing driving returns the system to natural SOC.** Stopping the external driver and waiting for π to dissipate should restore natural SOC signatures. A genuinely supercritical system should not.

5. **Densification shifts the precondition boundary.** Repeated events should move the system out of the liquefiable regime. If densification has no effect on subsequent liquefaction susceptibility, the consolidation mechanism is wrong.

---

## Part VII: Open Questions

1. **What is the cleanest way to couple the cyclic driver to the Manna substrate?** Manna uses stochastic grain drops as slow driving. A cyclic driver might take the form of periodic bulk grain injection, periodic threshold modulation, or explicit per-site stress increments. Each choice has different consequences for detectability.

2. **Is π best formalized as a per-site variable or a bulk field?** Real pore pressure is spatially distributed but diffuses. A site-local π may miss diffusion; a bulk π may miss heterogeneity.

3. **Should decay_rate depend on local density?** In real soil, dense areas dissipate pore pressure faster (more drainage paths). Modeling this couples π dynamics to d dynamics in a non-trivial way.

4. **What are the minimum preconditions to simulate?** Saturation + density may be sufficient in a first implementation; grain-size distribution and prior-loading history may be deferred.

5. **How should the natural-SOC baseline be recovered as a limit?** Setting T_a = 0 makes amplification zero — the site never has lowered threshold. Setting preconditions unsatisfied forces natural SOC. Either corner should reproduce the Manna baseline.

---

## Part VIII: Relationship to Overtopping

Overtopping and liquefaction are symmetric around natural SOC:

| Property | Overtopping (CSOC-side) | Liquefaction (ISOC-side) |
|---|---|---|
| Deviation from SOC | Small events suppressed | Cascades amplified |
| Core mechanism | Elevated threshold (T·σ) | Lowered threshold (T_a·π/π_max) |
| Damageable structure | σ (suppression) | d (density, but in opposite direction — densification stabilizes, not destabilizes) |
| Driver | Slow SOC driving | Cyclic external loading |
| Preconditions | None; overtopping can activate any suppressed system | Required: saturation + low density + active driver |
| Structural consequence trajectory | σ degrades → ruin | d densifies → stabilization |
| Controlled release | Trickle (spillway) prevents overtopping | Drainage / densification prevents liquefaction |
| Timescales | 4 (driving, deficit, damage-repair, trickle) | 6 (driving, cyclic, π-buildup, π-decay, densification, precondition) |

Both mechanisms share the feature that release destroys a local structure — but one destroys **suppression** (overtopping — makes future releases more likely) while the other destroys **damping** (liquefaction — makes cascades larger during events, but cumulative events eventually stabilize via densification).

### Water-as-agent framing

- Overtopping: water was contained by a wall; escape destroys the wall.
- Liquefaction: water was in the pores between grains; cyclic shaking amplifies its pressure until grain contacts are destroyed.

Different modes of water-driven destabilization — one is containment failure, the other is transmission-medium failure. The symmetry is the scaffold for the complete mechanism catalog.

---

## Part IX: Related Work

*(To be developed. Preliminary citations to investigate:)*

- **Rate-and-state friction** (Dieterich 1979, Ruina 1983) — state variable decays with slip, heals in quiescence. Partial analog for π dynamics.
- **Soil liquefaction under cyclic loading** (Seed & Lee 1966; Castro 1975; Ishihara 1993) — the physical phenomenon. Review for formal parameter definitions and precondition criteria.
- **Granular SOC and shear banding** (Dahmen et al., various) — slow-shear avalanche statistics in granular materials. Relevant to establishing granular materials as an SOC substrate before adding amplification.
- **Self-organized quasi-criticality** (Bonachela & Muñoz 2010) — systems dynamically driven near criticality. Liquefaction fits this family on the amplified side.
- **Neural ISOC precedents** — sustained driving of neural networks via stimulation, producing ISOC-like signatures in dish cortex preparations. Check for applicability.
- **Epidemic amplification / superspreading** — external forcing (holiday gatherings, super-events) acts as a cyclic driver raising effective R0 above 1. Check for parallel formal structure.

See `soc_study_guide.md` for the broader SOC literature; liquefaction-specific citations are to be integrated there as this document develops.

---

## Summary

Liquefaction is the primary mechanistic formalism for SOC systems coupled to cyclic external driving that destroys local damping during events. It produces ISOC-like signatures (see `distorted_soc_signatures.md`) with specific preconditions (saturation, density, grain-size analogs) that must be met before amplification dynamics activate. It is paired with overtopping on the suppression side, and the two mechanisms together span the symmetric distortions of natural SOC around its critical point.

This is a skeleton. The formalism needs further development before simulation. Deferred as a corollary to the primary overtopping experimental program.
