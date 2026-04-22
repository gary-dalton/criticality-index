> **ARCHIVED — SUPERSEDED.** This document is retained for historical reference. Operational content has moved to:
> - `work/experiments/ideas/liquefaction.md` — primary mechanism framework for amplified-cascade SOC dynamics (subsumes Parts II, VI–VIII of this document). Currently a skeleton; full development deferred as a corollary to the overtopping experimental program.
> - `work/experiments/ideas/distorted_soc_signatures.md` — empirical detection categories including the "ISOC-like signature bundle" and the three-regime comparison table (subsumes Parts III, IV, V, and Part IX appendix of this document).
> - `work/experiments/ideas/falsifiability_requirements.md` — generalized falsifiability methodology.
> - `work/experiments/ideas/architecture_mapping.md` — mapping to the SOC Model Architecture.
>
> The standalone ISOC framework has been superseded by mechanism-specific formalisms. "ISOC-like" survives as an adjective-form detection category name in the signatures catalog, with rigorous referents.

---

# Inductive SOC: A Theoretical Framework

## Preamble

This document lays out the theoretical framework of **Inductive SOC** — a proposed dynamic regime in which a Self-Organized Critical system is subject to artificial excitation of events, producing amplified cascades, elevated branching, and signatures that superficially resemble supercriticality. Inductive SOC is the paired counterpart to Capacitive SOC, forming a symmetric framework around the natural SOC critical point. The framework is developed from established SOC and criticality theory, with two components — the percolation threshold as an artificially maintained condition and the maximum energy boundary — treated as speculative and flagged accordingly.

This document should be read alongside the Capacitive SOC framework document. Where that document concerns suppression and deficit, this one concerns amplification and excess. The grounding concepts — SOC, criticality, signatures, and the evidentiary standard — are established in the Capacitive SOC document and assumed here.

### Terminology Note

This document uses **"amplification"** to describe the mechanism that sustains and extends cascades beyond their natural SOC boundaries — energy injected *during* propagation. This is distinct from **"excitation" (E)** as used in the SOC Model Architecture, which refers to the slow driving force that adds energy to the system between events (grains added to the sandpile). The distinction matters: architecture-E is the pressure that accumulates; ISOC amplification is the boost that extends cascades once they begin. Where "excitation" appears below, it refers to the ISOC amplification mechanism, not the architecture's E component.

---

## Part I: Definition and Core Mechanism

### 1.1 Definition

**Inductive SOC** describes a dynamical regime in which an underlying SOC system is subject to artificial amplification or excitation of events — through any mechanism — producing:

- Enhanced propagation of cascades beyond natural SOC boundaries
- Elevated branching ratio, pushed toward and potentially beyond sigma = 1
- A shift in the event distribution toward larger events
- Signatures that superficially resemble a supercritical system
- Potential structural consequences from repeated large-scale cascade propagation

The term **inductive** is chosen as the natural electrical counterpart to capacitive. Where a capacitor stores and releases potential, an inductor amplifies and drives current — it adds energy to propagation. The excitation mechanism is deliberately unspecified; the framework applies regardless of how events are amplified.

### 1.2 What Excitation Does to a SOC System

In natural SOC, cascades are self-limiting. Propagation depends on local stored potential, which is continuously redistributed and partially dissipated as the cascade moves through the system. Events terminate naturally when they encounter insufficient local energy to sustain further propagation.

When excitation is applied:

- **Activation thresholds are effectively lowered** — nodes that would not normally participate in a cascade are drawn in
- **Propagation is sustained beyond natural boundaries** — regions that would normally absorb and terminate cascades instead propagate them
- **The branching ratio is elevated** — each event produces more downstream events than natural SOC would predict
- **The natural termination mechanism is delayed or overcome** — cascades run further and recruit more of the system
- **Events are larger, more frequent, and more system-spanning** than natural SOC produces

### 1.3 The Energy Picture

Inductive SOC has a fundamentally different energy accounting from Capacitive SOC:

**Capacitive SOC:** Energy is deferred. Deficit accumulates. Large events carry historical stored energy.

**Inductive SOC:** Energy is added during propagation. No deficit accumulates between events. Instead, the system is continuously over-discharged relative to its natural SOC state.

The consequences:

- Between events, the system has **less stored potential** than natural SOC because events are larger and more frequent
- During events, **excess energy is present** — more than the accumulated input alone would provide
- The system may exist in a state of **continuous partial depletion** punctuated by amplified events
- There is no accumulation phase and no characteristic accumulation timescale — excitation is continuously expressed

### 1.4 Absence of the Two-Timescale Structure

A defining feature of Capacitive SOC is the acquisition of a second timescale — the deficit accumulation rate — superimposed on the natural SOC driving rate. Inductive SOC does **not** acquire this second timescale in the same way.

Inductive SOC is governed by:
- **The natural driving rate** (intrinsic to SOC)
- **The excitation rate and magnitude** — which modulate event propagation continuously rather than creating a slow accumulation cycle

The temporal structure of Inductive SOC is therefore **not quasi-periodic** in the way Capacitive SOC is. Instead it is characterized by continuously elevated activity with events that are persistently larger and more frequent than natural SOC produces.

This is a fundamental structural difference from Capacitive SOC and has direct implications for how the two systems are distinguished in observation.

---

## Part II: The Inductive Cycle

### 2.1 Event Dynamics

In natural SOC, an event initiates locally and propagates according to local stored potential. The fat-tailed distribution means a small trigger can produce a large event — but this is because accumulated potential is recruited, not because energy is added during propagation.

In Inductive SOC, propagation is actively sustained:

**Phase 1 — Initiation:**
- Initiation may occur at lower thresholds than natural SOC — the excitation lowers the bar for cascade onset
- Events initiate more frequently than natural SOC predicts
- Small triggering inputs are more likely to produce propagating events

**Phase 2 — Propagation:**
- The cascade propagates through the system with excitation sustaining it beyond natural boundaries
- Regions that would naturally absorb the cascade are instead drawn into it
- The cascade recruits more nodes and pathways than stored potential alone would support
- Propagation speed may be elevated — the cascade does not slow as it depletes local potential because excitation compensates

**Phase 3 — Termination:**
- Termination still occurs — the system is finite and excitation is not infinite
- But termination is delayed relative to natural SOC
- Events are more likely to be system-spanning before they terminate
- The post-event state reflects deeper depletion than natural SOC large events produce

**Phase 4 — Recovery:**
- Post-event recovery involves rebuilding from a more depleted state than natural SOC
- If excitation persists, the next event initiates before full recovery
- The system operates in a state of **chronic partial depletion** with continuously amplified events
- Unlike Capacitive SOC, there is no deep quiescence and slow rebuild — the system is continuously active

### 2.2 The Depletion Paradox

Inductive SOC creates an apparent paradox:

- Excitation amplifies events, making them larger
- Larger events deplete the system more thoroughly
- More thorough depletion means less stored potential for subsequent events
- But excitation compensates, sustaining the next event despite reduced stored potential

This creates a **chronic tension** between amplification and depletion that is distinct from both natural SOC and Capacitive SOC. The system is simultaneously over-driven and under-resourced.

If excitation is strong enough to overcome this depletion continuously, the system may approach a runaway condition. If excitation is insufficient to fully compensate for depletion, the system oscillates between amplified events and brief recovery periods — a dynamic that may superficially resemble Capacitive SOC but with a different generative mechanism and much shorter cycle time.

---

## Part III: Similarities and Differences with Supercritical Systems

### 3.1 The Diagnostic Problem

Inductive SOC produces signatures that resemble a supercritical system. This creates a diagnostic challenge parallel to the one Capacitive SOC presents with subcriticality.

### 3.2 Shared Apparent Signatures

| Observable | Supercritical | Inductive SOC |
|---|---|---|
| Branching ratio | sigma > 1 | Appears > 1 |
| Event size | Excess of large events | Excess of large events |
| System-spanning events | Frequent | More frequent than natural SOC |
| Power law | Truncated at high end or absent | Distorted toward large events |
| Correlation length | Long but rigid | Appears long |
| Small event frequency | Suppressed relative to large | May be elevated in absolute terms but diminished relative to large |
| Overall appearance | Highly active, large events dominant | Highly active, large events elevated |

### 3.3 Critical Differences

Despite surface similarity, the two systems are fundamentally different:

| Property | Supercritical | Inductive SOC |
|---|---|---|
| Underlying state | True system state — parameters above critical point | Underlying SOC dynamics present; excitation is external |
| Reversibility | Removing excitation does not restore criticality — system is supercritical by parameter | Removing excitation allows system to return toward natural SOC critical point |
| Small event distribution | Small events suppressed by dominance of large | Small events elevated in absolute frequency but overshadowed |
| Energy source of large events | Internal — natural consequence of supercritical parameters | Mixed — stored potential plus externally added excitation |
| Temporal stationarity | Stationary in its supercritical state | Non-stationary — depends on ongoing excitation |
| Post-large-event state | Remains supercritical | Transiently more depleted; recovers toward critical under continued excitation |
| Response to perturbation | Uniformly amplified | Amplified but modulated by local depletion state |
| Structural consequences | None implied by parameter state | Potential structural alteration from repeated over-propagation |

### 3.4 The Key Diagnostic Distinction

The critical test separating Inductive SOC from genuine supercriticality is **perturbation and response**:

- A supercritical system responds consistently regardless of recent event history — it is in a stable supercritical state
- An Inductive SOC system shows **history dependence** — response is modulated by local depletion from recent events, reflecting the underlying SOC dynamics beneath the excitation

Additionally:
- **Removing the excitation** from a supercritical system does not restore criticality
- **Removing the excitation** from an Inductive SOC system should allow relaxation toward the natural critical point

If the excitation source can be identified and experimentally manipulated, this provides the clearest distinction. Where this is not possible, temporal analysis of response variability relative to event history provides the most accessible test.

---

## Part IV: Distorted Signatures of Inductive SOC

### 4.1 Statistical / Scaling Signatures

- **Power law distorted at the large end** — excess of large events beyond natural SOC prediction
- **Small event frequency elevated in absolute terms** but **reduced relative to large events** — the distribution is skewed upward
- **Characteristic scale may appear** at the excitation threshold — events that reach the amplification condition show systematically elevated sizes
- **Exponent relations fail** — the distorted distribution breaks scaling consistency
- **Avalanche shape collapse fails** — amplified propagation produces event profiles that do not collapse cleanly with natural SOC events
- **Mean event size elevated** relative to natural SOC or supercritical baseline

### 4.2 Spectral / Fractal Signatures

- **1/f spectrum steepened or distorted** — excess power at low frequencies corresponding to large events
- **Spectral knee at the excitation scale** — below the excitation threshold the spectrum may appear different from above it
- **Self-similarity breaks at coarse scales** — large events dominate and distort the fractal structure
- **Long-range temporal correlations altered** — the pattern of correlations reflects excitation dynamics rather than natural SOC
- **Hurst exponent elevated** — persistent long-range correlations but from amplified large events rather than natural SOC dynamics

### 4.3 Network / Graph Theoretic Signatures

- **Weak edges persistently activated** — excitation recruits low-weight connections that natural SOC would not consistently activate
- **Degree distribution distorted toward high connectivity** — apparent connectivity is elevated by excitation
- **Small world property altered** — high clustering maintained or elevated, but path lengths shortened by forced long-range activation
- **Modularity reduced** — module boundaries are more frequently breached by amplified cascades
- **Global efficiency elevated** — but artificially, reflecting excitation rather than natural connectivity
- **Hub nodes over-recruited** — large high-degree nodes are activated in more events than natural SOC predicts, potentially accumulating structural load

### 4.4 Information Theoretic Signatures

- **Entropy altered** — the state space is explored in a biased way, with large coordinated states over-represented
- **Mutual information elevated between subsystems** — but reflecting forced correlation rather than natural critical-state information sharing
- **Dynamic range compressed at the upper end** — the system loses discrimination between large inputs because it responds maximally to many of them
- **Transfer entropy elevated but less specific** — more information flows between subsystems but its directional and conditional structure is distorted
- **Fisher information reduced** — despite apparently high sensitivity, the system's ability to discriminate fine differences near the critical point is degraded

### 4.5 The Cross-Domain Pattern

Across all domains, amplification of events in Inductive SOC consistently produces the same fundamental distortion — the mirror image of Capacitive SOC:

> **A characteristic scale is introduced where there should be none, and the system loses its capacity to operate across the full range of scales simultaneously — but in the opposite direction from Capacitive SOC, with coarse scales over-represented rather than suppressed.**

Both Capacitive and Inductive SOC destroy the scale-free character of natural SOC. They do so symmetrically — one by truncating the small-event tail, the other by inflating the large-event tail.

---

## Part V: Testing for Inductive SOC

### 5.1 The Evidentiary Requirement

Per the established standard — multiple independent tests being simultaneously consistent — no single test confirms Inductive SOC. The convergence of the following tests across domains constitutes the evidence base.

### 5.2 Distribution Analysis

**Test:** Examine the full event size and duration distribution.

**Expected finding in Inductive SOC:**
- Inflation at the large end — more large events than natural SOC predicts
- Possible elevation of small event absolute frequency but diminished relative to large events
- Distortion toward a characteristic scale at or above the excitation threshold
- Power law exponent shallower than natural SOC — fatter upper tail

**Distinguishes from:**
- Natural SOC — clean power law, no systematic excess at any scale
- Subcritical — exponential decay, no large events
- Capacitive SOC — truncated at the small end; Inductive SOC is inflated at the large end
- Supercritical — excess at all large scales but no history-dependent modulation

### 5.3 Exponent Consistency Testing

**Test:** Extract exponents for event size (tau) and duration (alpha) distributions and check internal consistency.

**Expected finding in Inductive SOC:**
- Exponent relations fail — the inflated distribution breaks the scaling consistency of true criticality
- Apparent tau shallower than the natural SOC value for the system's universality class

### 5.4 Avalanche Shape Analysis

**Test:** Extract temporal profiles of events at different sizes. Rescale and attempt shape collapse.

**Expected finding in Inductive SOC:**
- Shape collapse fails — particularly for large events, which reflect excitation-sustained dynamics rather than natural SOC propagation
- Large event profiles may show elevated plateaus or extended durations reflecting sustained excitation during propagation

### 5.5 Spectral Analysis

**Test:** Compute power spectral density of system activity.

**Expected finding in Inductive SOC:**
- Excess power at low frequencies relative to natural SOC
- Possible steepening of the 1/f slope — beta greater than 1
- Distortion that is directionally opposite to Capacitive SOC's high-frequency knee

### 5.6 Branching Ratio Estimation

**Test:** Estimate sigma from event propagation statistics.

**Expected finding in Inductive SOC:**
- Sigma consistently above 1 across the observation period
- Unlike Capacitive SOC, sigma is relatively stationary — there is no accumulation-release cycle modulating it
- History-dependent modulation of sigma — sigma may be transiently lower immediately after large events as depletion temporarily reduces propagation, then recovering as the system rebuilds

### 5.7 Susceptibility Measurement

**Test:** Apply small perturbations and measure response magnitude as a function of system state and recent event history.

**Expected finding in Inductive SOC:**
- Susceptibility persistently elevated relative to natural SOC
- But **history-dependent** — transiently reduced immediately after large events due to depletion
- This history dependence distinguishes Inductive SOC from true supercriticality, which does not show the same post-event susceptibility reduction

### 5.8 Temporal Structure Analysis

**Test:** Examine inter-event intervals and temporal clustering of events.

**Expected finding in Inductive SOC:**
- Events more frequent than natural SOC
- No quasi-periodicity in the Capacitive SOC sense — continuous activity rather than accumulation-release cycle
- Possible short-timescale clustering — elevated event rate immediately following large events if excitation drives rapid reinitiation
- Reduced inter-event intervals for large events compared to natural SOC

### 5.9 History Dependence Testing

**Test:** Examine whether event characteristics are modulated by the history of recent events — specifically whether large events are followed by a transient reduction in subsequent event size or frequency before recovery.

**Expected finding in Inductive SOC:**
- Yes — transient post-large-event reduction in activity reflecting depletion
- Recovery timescale determined by combination of natural SOC driving rate and excitation strength
- This history dependence is the clearest behavioral signature distinguishing Inductive SOC from true supercriticality

**Expected finding in true supercriticality:**
- No — or minimal — history dependence. The system remains in its supercritical parameter state regardless of recent events.

### 5.10 Excitation Removal Test

**Test:** If the excitation mechanism can be identified and experimentally reduced or removed, observe subsequent system behavior.

**Expected finding if system is Inductive SOC:**
- Gradual relaxation toward natural SOC signatures as excitation is removed
- Power law distribution recovering across all scales
- Branching ratio returning toward 1
- Event size distribution returning toward natural SOC form

**Expected finding if system is truly supercritical:**
- System remains supercritical — removal of putative excitation does not restore criticality because the supercritical state is intrinsic to system parameters, not externally driven

This is the most definitive test but requires the ability to manipulate the excitation mechanism.

### 5.11 Cross-Domain Convergence

**Confirmation criterion:** If inflated large-event distribution, failed shape collapse, failed exponent relations, steepened or distorted spectrum, persistently elevated but history-dependent susceptibility, and continuous elevated activity without quasi-periodicity are all observed simultaneously and consistently, this convergence constitutes the primary evidence for Inductive SOC rather than natural SOC, supercriticality, or noise.

---

## Part VI: The Symmetric Framework with Capacitive SOC

### 6.1 Mirror Structure

Capacitive SOC and Inductive SOC are symmetric deviations from the natural SOC critical point:

| Property | Capacitive SOC | Natural SOC | Inductive SOC |
|---|---|---|---|
| Small events | Suppressed | Natural power law | Elevated / amplified |
| Large events | Excess | Natural power law | Excess |
| Branching ratio | Appears < 1 | sigma = 1 | Appears > 1 |
| Resembles | Subcritical | Critical | Supercritical |
| Temporal structure | Quasi-periodic (accumulation-release) | Scale-free, no characteristic timescale | Continuous, no accumulation phase |
| Energy deficit | Accumulates between events | Balanced | Does not accumulate |
| Post-large-event state | Deep quiescence | Returns near critical | Transiently depleted, recovers rapidly |
| Spectral distortion | Knee at high frequency | Clean 1/f | Steepened, excess low frequency |
| Distribution truncation | Low end | None | High end inflated |
| Second timescale | Yes — accumulation timescale | No | No — but depletion recovery timescale |

### 6.2 The Depletion Recovery Timescale

Although Inductive SOC does not acquire a deficit accumulation timescale, it does acquire a **depletion recovery timescale** — the time required for the system to rebuild from the post-large-event depleted state under continued excitation.

This is distinct from the Capacitive SOC accumulation timescale:

- **Capacitive accumulation timescale** — slow, governing the long interval between large events
- **Inductive depletion recovery timescale** — faster, governing the short interval between large events during which the system rebuilds enough to sustain the next amplified cascade

Both represent departures from natural SOC's lack of characteristic timescale, but in opposite temporal directions — Capacitive SOC introduces a longer timescale, Inductive SOC introduces a shorter one.

### 6.3 Combined Capacitive-Inductive Conditions

It is conceivable that a system experiences both suppression of some events and amplification of others simultaneously — for example, suppression of small events below one threshold while amplification of events above another. This would produce a more complex signature profile combining elements of both frameworks and is left as a direction for future development.

---

## Part VII: Percolation Threshold as an Artificially Maintained Condition (Speculative)

> **Note: This section is speculative. The components are grounded in established theory but their synthesis as stated here has not been confirmed in the literature and requires investigation. See the companion research pathways document.**

### 7.1 Recap of the Percolation Threshold Proposition

From the Capacitive SOC framework: the percolation threshold p_c serves a dual role — as an activation condition for cascades and as a natural termination condition. When cascade propagation depletes system energy below p_c, the connected spanning cluster cannot be maintained and the cascade self-extinguishes.

### 7.2 The Inductive SOC Implication

In natural SOC, cascades terminate when propagation drives the system below p_c. In Inductive SOC, excitation actively works against this termination mechanism:

- As the cascade propagates and depletes local energy, excitation replenishes or supplements it
- The system is **maintained above p_c** by the excitation even as propagation would naturally drive it below
- The cascade continues beyond its natural termination point
- Termination is delayed until excitation is insufficient to maintain the system above p_c

This is a direct inversion of the Capacitive SOC picture. Where Capacitive SOC loads the system far above p_c (extending the distance to the termination condition), Inductive SOC artificially maintains the system above p_c (preventing the termination condition from being reached).

### 7.3 The Termination Condition in Inductive SOC

If the proposition holds, cascade termination in Inductive SOC occurs when:

- The combined effect of natural depletion and the spatial extent of excitation finally brings the system below p_c
- Excitation is finite and spatially bounded — there are limits to how much of the system it can maintain above p_c simultaneously
- When the cascade propagates beyond the reach of excitation, it enters regions where natural depletion can bring the system below p_c, and termination occurs there

This predicts that cascade termination in Inductive SOC should occur at the **boundary of the excitation's spatial reach** — producing a characteristic spatial scale for cascade termination that natural SOC does not have.

### 7.4 Implications for Event Size

If event size in natural SOC is bounded by the total energy above p_c at cascade initiation, then in Inductive SOC:

- The effective energy above p_c is greater than stored potential alone — it includes the excitation contribution
- Events can therefore be larger than any stored potential alone would support
- The upper bound on event size is extended by the magnitude and spatial reach of excitation
- Very strong excitation could in principle produce system-spanning events repeatedly, approaching a runaway condition

### 7.5 Research Required

To confirm or refute:
- Whether cascade termination in existing SOC models can be formally described as falling below p_c
- Whether adding excitation to existing SOC models produces the predicted delay in termination
- Whether cascade spatial extent in Inductive SOC correlates with excitation spatial reach
- Whether event size scales with excitation magnitude in a manner consistent with extending the effective energy above p_c

---

## Part VIII: Maximum Energy and Structural Consequences (Speculative)

> **Note: This section is speculative. It connects to established concepts but does not map cleanly onto a single established construct and may be a synthesis unique to this framework.**

### 8.1 Recap of the Maximum Energy Concept

From the Capacitive SOC framework: when energy concentration is anomalously high, cascade energy may exceed what the connected pathway structure can propagate normally. This represents an upper bound on the operational envelope.

### 8.2 The Inductive SOC Situation

In Capacitive SOC, the maximum energy boundary is approached from below — deficit accumulation loads the system upward toward this limit. In Inductive SOC, the boundary is approached differently:

- Excitation adds energy during propagation — not through slow accumulation but through active amplification
- The cascade therefore carries more energy through pathways than natural SOC would route through them
- Pathways that are structurally sized for natural SOC event traffic are now carrying amplified loads
- Repeated over-loading of pathways may exceed their transmission capacity

### 8.3 Structural Consequences

Unlike Capacitive SOC, where the energy concentration is a transient release of stored deficit, Inductive SOC continuously routes excess energy through the system's pathway structure. This sustained over-loading may produce **structural consequences**:

- **Pathway remodeling** — structures that carry excess energy loads may be altered by that experience
- **Threshold lowering** — repeated over-activation may lower local activation thresholds, making future amplification easier (a positive feedback on Inductive SOC dynamics)
- **Pathway strengthening or weakening** — depending on system type, repeated over-loading may strengthen high-traffic pathways or degrade them
- **Altered future dynamics** — structural changes alter the system's response to future excitation, creating a history-dependent system whose Inductive SOC dynamics evolve over time

This introduces a **slow structural timescale** distinct from the event timescale — a slow drift in system architecture driven by the sustained over-loading of Inductive SOC.

### 8.4 The Asymmetry with Capacitive SOC

This structural consequence asymmetry is notable:

- **Capacitive SOC** — the suppression mechanism prevents events; structural consequences are primarily from the large release events (which are transient and infrequent)
- **Inductive SOC** — the excitation mechanism sustains continuous over-propagation; structural consequences accumulate continuously from every amplified event

Inductive SOC may therefore produce more sustained and progressive structural alteration than Capacitive SOC, particularly if excitation is chronic rather than acute.

### 8.5 The Two Boundaries in Inductive SOC

Returning to the operational envelope established in the Capacitive SOC framework:

- **Lower bound — Percolation threshold p_c:** In Inductive SOC, excitation works to maintain the system above this bound, delaying natural termination
- **Upper bound — Maximum energy / structural capacity:** In Inductive SOC, excitation continuously pushes cascade energy toward or beyond this bound, potentially producing structural alteration

In natural SOC, the system operates comfortably within the envelope — neither approaching p_c severely during events nor approaching the structural capacity limit. Inductive SOC simultaneously lifts the effective lower bound (by maintaining above p_c) and presses against the upper bound (by routing excess energy through the pathway structure).

### 8.6 Research Required

To confirm or refute:
- Whether sustained over-propagation in SOC models produces measurable structural changes
- Whether structural threshold lowering in Inductive-like conditions creates positive feedback dynamics
- Whether the structural consequences of Inductive SOC are formally distinct from general activity-dependent remodeling in complex systems
- Whether a maximum energy boundary can be formally derived for cascade propagation in network models

---

## Part IX: Summary of the Framework

### The Core Architecture

Inductive SOC describes a SOC system with amplified events. The amplification mechanism is irrelevant to the observable signatures — what matters is the effect on event propagation and the resulting distribution.

The system exhibits continuously elevated activity with events that are persistently larger and more frequent than natural SOC produces. Unlike Capacitive SOC, there is no quasi-periodic accumulation-release cycle. Instead the system operates in a state of chronic partial depletion under continuous excitation, with a depletion recovery timescale shorter than natural SOC's event interval timescale.

### The Signature Profile

Inductive SOC produces a distinctive and convergent signature profile across all domains:
- Inflated large-event distribution
- Excess events above natural SOC predictions
- Characteristic scale introduced at the excitation threshold
- Failed exponent relations and shape collapse
- Steepened or distorted spectrum with excess low-frequency power
- Persistently elevated but history-dependent branching ratio and susceptibility
- Continuous activity without quasi-periodicity
- Post-large-event depletion recovery visible in temporal analysis

These signatures are **mechanism agnostic** — they detect the effect of amplification regardless of how excitation is occurring.

### The Speculative Extensions

Two speculative propositions extend the framework:

1. **Percolation threshold maintained artificially** — excitation prevents cascade termination by maintaining the system above p_c beyond its natural termination point, with cascade size extending to the spatial boundary of the excitation's reach

2. **Maximum energy boundary and structural consequences** — sustained over-loading of pathways by Inductive SOC may produce progressive structural alteration, including threshold lowering and pathway remodeling, creating a slow structural timescale and potentially a positive feedback on Inductive SOC dynamics

### The Complete Symmetric Framework

The three regimes together:

> **Capacitive SOC — Natural SOC — Inductive SOC**

represent a continuous spectrum of deviation from the critical point, with Natural SOC at the center. Capacitive SOC introduces a slow accumulation timescale and produces quasi-periodic large events. Inductive SOC introduces a fast depletion recovery timescale and produces continuous amplified activity. Both destroy the scale-free character of natural SOC in opposite and potentially distinguishable ways.

---

## Appendix: Comparison of Key Properties Across All Three Regimes

| Property | Capacitive SOC | Natural SOC | Inductive SOC |
|---|---|---|---|
| Small events | Suppressed | Power law | Amplified |
| Large events | Excess, deficit-driven | Power law | Excess, excitation-driven |
| Branching ratio | < 1 apparent | = 1 | > 1 apparent |
| Resembles | Subcritical | Critical | Supercritical |
| Superficial misclassification | Subcritical | — | Supercritical |
| Temporal structure | Quasi-periodic | Scale-free | Continuous, no accumulation |
| Second timescale | Slow (accumulation) | None | Fast (depletion recovery) |
| Energy deficit | Accumulates | Balanced | Does not accumulate |
| Post-large-event | Deep quiescence | Near-critical return | Rapid recovery |
| Spectral distortion | High-frequency knee | Clean 1/f | Low-frequency excess |
| Distribution distortion | Low-end truncated | None | High-end inflated |
| Exponent relations | Fail | Satisfied | Fail |
| Shape collapse | Fails | Succeeds | Fails |
| Susceptibility | Suppressed, non-stationary | Maximized, stationary | Elevated, history-dependent |
| Structural consequences | From infrequent large releases | Natural | From continuous over-loading |
| p_c role (speculative) | Termination when deficit depletes to p_c | Natural termination | Excitation maintains above p_c |
| Max energy (speculative) | Approached from below by deficit | Operates within envelope | Pressed against from within by excitation |

---

*This document represents a working theoretical framework and should be read alongside the Capacitive SOC framework document and the Energy Depletion — Percolation Threshold research pathways document. Speculative components are clearly flagged and require literature investigation and formal derivation before they can be treated as established.*
