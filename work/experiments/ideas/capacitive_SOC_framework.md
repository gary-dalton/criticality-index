# Capacitive SOC: A Theoretical Framework

## Preamble

This document lays out the theoretical framework of **Capacitive SOC** — a proposed dynamic regime in which a Self-Organized Critical system is subject to suppression of small events, producing a characteristic cycle of deficit accumulation and disproportionate large-scale release. The framework is developed from established SOC and criticality theory, with two components — the percolation threshold as termination condition and the maximum energy boundary — treated as speculative and flagged accordingly.

### Terminology Note

This document uses **"suppression"** to describe the mechanism that blocks small avalanches — distinct from strong **"ordering" (O)** as used in the SOC Model Architecture. The paired counterpart (Inductive SOC) uses **"amplification"** to describe energy injected during cascade propagation — distinct from **"excitation" (E)** in the architecture, which is the slow driving force between events. CSOC suppression and ISOC amplification are mechanisms that *distort* an SOC substrate; architecture O and E *determine* the phase state. Whether these describe the same phenomenon or genuinely different dynamics is an open question addressed by the experimental program.

---

## Part I: Grounding Concepts

### 1.1 Self-Organized Criticality (SOC)

SOC describes a class of dynamical systems that spontaneously evolve toward a critical state without external parameter tuning. The canonical properties are:

- **Slow driving** — energy or stress is added continuously at a slow rate
- **Fast dissipation** — release events occur on a timescale much faster than accumulation
- **Self-tuning** — the system drives itself toward the critical point through its own dynamics
- **Power law distributed events** — avalanche sizes and durations follow power laws with no characteristic scale
- **Fat-tailed distributions** — large events are rare but not negligible; a small trigger can produce a system-spanning release

SOC is a **mechanism**, not merely a set of signatures. It is the process by which a system arrives at and maintains a critical state through internal dynamics.

### 1.2 The Critical Point

The critical point sits between two qualitatively distinct regimes:

**Subcritical** — activity dies out. Perturbations do not propagate far. Correlations are short-range. The system is stable but sluggish. The branching ratio sigma < 1.

**Critical** — avalanches of all sizes occur. Correlations are long-range but flexible. The system is maximally sensitive. Dynamic range is maximized. The branching ratio sigma = 1.

**Supercritical** — activity self-amplifies. Large system-spanning events dominate. Correlations are long-range but rigid. The system loses discrimination between inputs. The branching ratio sigma > 1.

The critical point is the knife's edge between order and disorder, and is the state at which a SOC system self-organizes.

### 1.3 The Hypothesis of Criticality

The Hypothesis of Criticality proposes that certain biological and physical systems operate near the critical point — and that this confers functional advantages including:

- Maximum dynamic range
- Maximum information transmission
- Maximum sensitivity to inputs
- Optimal balance of integration and segregation

The hypothesis does not require SOC as the mechanism — the system may arrive at criticality through external tuning, evolutionary selection, or homeostatic regulation. SOC is one possible mechanism among several.

### 1.4 Signatures of Criticality

Criticality produces observable signatures across multiple domains. These signatures are **necessary but not sufficient** — each can arise from non-critical mechanisms. Confirmation of criticality requires **multiple independent signatures being simultaneously consistent**.

**Statistical / Scaling:**
- Power law distributions of event sizes and durations
- Exponent relations satisfied — the exponents of different observables are internally consistent via known scaling relations
- Avalanche shape collapse — temporal profiles rescale onto a single universal function
- Finite size scaling — behavior follows predictable scaling laws with system size

**Spectral / Fractal:**
- 1/f noise — power spectral density scales as 1/f^beta with beta near 1
- Long-range temporal correlations
- Self-similarity across scales
- Hurst exponent near appropriate critical value

**Network / Graph Theoretic:**
- Scale-free degree distribution
- Small world topology — high clustering with short path lengths
- Balanced modularity and integration
- Edge weight distribution following power law

**Information Theoretic:**
- Maximum entropy — broadest exploration of state space
- Peak mutual information between subsystems
- Maximum dynamic range
- Peak transfer entropy
- Peak Fisher information — maximum sensitivity to parameter changes

**Dynamical:**
- Branching ratio sigma near 1
- Diverging susceptibility — response to perturbation is maximal and scales with system size
- Universality class membership — exponents consistent with a known universality class such as directed percolation

### 1.5 The Evidentiary Standard

> **The confirmation threshold for criticality is multiple independent tests being simultaneously consistent.**

No single signature confirms criticality. No single test is sufficient. The strength of the claim scales with the convergence of independent lines of evidence. This standard applies throughout this framework and to all claims made within it.

---

## Part II: Capacitive SOC — The Framework

### 2.1 Definition

**Capacitive SOC** describes a dynamical regime in which an underlying SOC system is subject to suppression of small events — through any mechanism — producing:

- Sustained accumulation of unreleased energy (the **energy deficit**)
- Distortion of the natural SOC event distribution
- Periodic or quasi-periodic large-scale release events that are disproportionate to their triggers
- A characteristic temporal structure of accumulation followed by discharge

The term **capacitive** is chosen because the system stores potential under continuous input and releases it when a threshold is overcome — directly analogous to a capacitor in an electrical circuit. The suppression mechanism is deliberately unspecified; the framework applies regardless of how small events are damped.

### 2.2 The Energy Deficit

In natural SOC, energy input and release are statistically balanced. Small events continuously bleed off accumulated local stress, maintaining the system near the critical point. When small events are suppressed:

- A gap opens between the energy that should have been released and the energy actually released
- This gap — the **energy deficit** — grows continuously under sustained driving
- The deficit grows non-linearly: each suppressed small event would have redistributed stress, potentially preventing other small events, so suppression has cascading consequences
- The deficit accumulates unevenly across the system, concentrating along pathways that would normally carry small event traffic and pooling at nodes that would normally be frequent release sites

The energy deficit is not uniformly distributed. It has **spatial structure** that reflects the topology of the system and the pattern of suppression.

### 2.3 The Two Timescales

Natural SOC has one governing timescale — the driving rate. Capacitive SOC acquires a second:

- **Timescale 1** — the driving rate (intrinsic to SOC)
- **Timescale 2** — the deficit accumulation timescale, governing when and how large release events occur

The second timescale is imposed by the suppression mechanism, not intrinsic to the SOC dynamics. Its presence is itself a diagnostic marker of Capacitive SOC.

### 2.4 The Accumulation-Release Cycle

Capacitive SOC produces a characteristic cycle:

**Phase 1 — Accumulation:**
- Driving continues at the natural rate
- Small events are suppressed
- Energy deficit grows continuously
- The system appears quiet — resembling a subcritical system to an observer (see Section III)
- Hidden spatial structure develops in the deficit distribution

**Phase 2 — Threshold Breach:**
- At some point accumulated deficit, combined with a triggering event, overcomes the suppression threshold
- The trigger itself may be unremarkable — a normal-scale input
- The trigger and the scale of release are decoupled by the deficit

**Phase 3 — Release:**
- The cascade propagates through a system pre-loaded far beyond its natural SOC state
- Propagation encounters pre-loaded neighbors — the wavefront finds prepared ground
- The spatial pattern of release reflects the topology of accumulated deficit, not current connectivity alone
- The event carries energy from both the triggering input and the accumulated deficit
- Release may be faster, broader, and more spatially correlated than natural SOC large events

**Phase 4 — Post-Release:**
- The system may be driven below its natural critical state — temporarily over-released
- A period of quiescence follows as the system rebuilds toward criticality
- If suppression persists, deficit accumulation resumes immediately
- The cycle repeats with a characteristic period governed by the deficit accumulation rate and the suppression threshold

### 2.5 The Inductive Counterpart

Capacitive SOC has a natural opposite: **Inductive SOC**, in which excitation is artificially added rather than suppressed. In Inductive SOC:

- Small events are enhanced and amplified
- The branching ratio is pushed above 1
- Cascades propagate further than natural SOC produces
- The natural absorptive boundaries that terminate avalanches are overcome
- Signatures resemble supercriticality

The pairing of **Capacitive** and **Inductive** provides a symmetric framework around the natural SOC critical point — one damped, one driven.

---

## Part III: Similarities and Differences with Subcritical Systems

### 3.1 The Diagnostic Problem

During the accumulation phase, Capacitive SOC is observationally difficult to distinguish from a genuinely subcritical system. This is a significant diagnostic challenge.

### 3.2 Shared Apparent Signatures

During the accumulation phase, Capacitive SOC and subcritical systems share:

| Observable | Subcritical | Capacitive SOC (Accumulation Phase) |
|---|---|---|
| Small event frequency | Low | Low (suppressed) |
| Branching ratio | sigma < 1 | Appears < 1 |
| Power law | Absent or exponential | Truncated at low end |
| Correlation length | Short | Appears short |
| System activity | Sparse | Sparse |
| Overall appearance | Stable, quiet | Stable, quiet |

### 3.3 Critical Differences

Despite surface similarity, the two systems are fundamentally different:

| Property | Subcritical | Capacitive SOC |
|---|---|---|
| Underlying state | True equilibrium below critical point | Underlying SOC dynamics present but masked |
| Stored energy | Not anomalously accumulating | Continuously growing deficit |
| System stability | Genuinely stable | Metastable — coiled |
| Large event distribution | Exponentially suppressed | Excess large events above suppression threshold |
| Temporal structure | Stationary | Non-stationary — slow drift in baseline |
| Post-large-event behavior | Returns to same subcritical state | Deep quiescence then resumption of cycle |
| Inter-event intervals | Stationary distribution | Quasi-periodic for large events |
| Baseline measures | Stable | Slow systematic drift between large events |

### 3.4 The Key Diagnostic Distinction

The critical test that separates Capacitive SOC from genuine subcriticality is **temporal observation across the full cycle**:

- A subcritical system remains quiet indefinitely
- A Capacitive SOC system eventually produces large release events that are excessive relative to what a subcritical system would predict
- The post-release quiescence and resumption of the cycle reveals the underlying dynamic

Single-timepoint observation during the accumulation phase cannot reliably distinguish the two. **Longitudinal observation is required.**

---

## Part IV: Distorted Signatures of Capacitive SOC

### 4.1 Statistical / Scaling Signatures

- **Power law truncated at the low end** — small event tail is suppressed
- **Excess large events** — above the suppression threshold, more large events than natural SOC predicts
- **Characteristic scale appears** — at the suppression threshold, introducing a scale that true SOC should not have
- **Exponent relations fail** — scaling relations between exponents are violated because the distribution is distorted
- **Avalanche shape collapse fails** — small and large event populations are generated by qualitatively different dynamics

### 4.2 Spectral / Fractal Signatures

- **1/f spectrum develops a knee** — flat or white-noise-like at low frequencies, transitioning to 1/f at higher frequencies
- **Self-similarity breaks at fine scales** — fractal dimension inconsistent across scales
- **Characteristic frequency appears** — corresponding to the suppression threshold
- **Long-range temporal correlations distorted** — small events that maintain them are removed
- **Hurst exponent altered**

### 4.3 Network / Graph Theoretic Signatures

- **Weak edges functionally removed** — small events often represent weak-connection activations
- **Degree distribution truncated** — low-degree nodes become functionally invisible
- **Small world property degrades** — short path lengths depend on weak long-range connections that suppression preferentially removes
- **Network fragments toward modularity** — without weak inter-module connections, the graph breaks into more isolated clusters
- **Global efficiency drops** — locally efficient but globally poor
- **Hub dependence increases** — the system becomes over-reliant on strong high-degree connections

### 4.4 Information Theoretic Signatures

- **Entropy reduced** — accessible state space is truncated
- **Mutual information degraded** — particularly at fine scales
- **Dynamic range compressed** — lower end of discriminable inputs is lost
- **Transfer entropy distorted** — dominated by large events, fine-grained continuous transfer is lost
- **Fisher information peak shifts or broadens** — system no longer at maximum sensitivity

### 4.5 The Cross-Domain Pattern

Across all domains, suppression of small events consistently produces the same fundamental distortion:

> **A characteristic scale is introduced where there should be none, and the system loses its capacity to operate across the full range of scales simultaneously.**

Each domain reveals this differently — a knee in the spectrum, a truncated degree distribution, a compressed dynamic range — but all point to the same underlying distortion.

---

## Part V: Testing for Capacitive SOC

### 5.1 The Evidentiary Requirement

Per the established standard — multiple independent tests being simultaneously consistent — no single test confirms Capacitive SOC. The convergence of the following tests across domains constitutes the evidence base.

### 5.2 Distribution Analysis

**Test:** Examine the full event size and duration distribution.

**Expected finding in Capacitive SOC:**
- Truncation at the low end below the suppression scale
- Excess events above the suppression scale
- A bump or characteristic scale at the suppression threshold
- Power law behavior in the large-event tail that may appear locally SOC-like

**Distinguishes from:**
- Natural SOC — no truncation, clean power law across all scales
- Subcritical — exponential decay, no excess large events
- Supercritical — excess at all large scales, no truncation at small scales

### 5.3 Exponent Consistency Testing

**Test:** Extract exponents for event size distribution (tau), duration distribution (alpha), and the size-duration scaling relation. Check internal consistency via:

(alpha - 1) / (tau - 1) = expected scaling exponent

**Expected finding in Capacitive SOC:**
- Exponent relations fail — the distorted distribution breaks the scaling consistency that holds at true criticality

### 5.4 Avalanche Shape Analysis

**Test:** Extract temporal profiles of events at different sizes. Rescale and attempt shape collapse.

**Expected finding in Capacitive SOC:**
- Shape collapse fails — particularly the large events, which reflect deficit-driven dynamics rather than natural SOC propagation

### 5.5 Spectral Analysis

**Test:** Compute power spectral density of system activity. Fit to 1/f^beta and examine for deviations.

**Expected finding in Capacitive SOC:**
- A knee in the spectrum at a characteristic frequency corresponding to the suppression threshold
- Beta inconsistent across frequency ranges

### 5.6 Branching Ratio Estimation

**Test:** Estimate the branching ratio sigma from event propagation statistics.

**Expected finding in Capacitive SOC:**
- Sigma appears subcritical during accumulation phase
- Sigma appears supercritical during and immediately following large release events
- Sigma is non-stationary across the full cycle

### 5.7 Susceptibility Measurement

**Test:** Apply small perturbations to the system and measure response magnitude as a function of system state and time.

**Expected finding in Capacitive SOC:**
- Susceptibility is suppressed during accumulation phase relative to natural SOC
- Susceptibility spikes dramatically immediately preceding large release events as deficit-loaded system is poised for cascade
- Non-stationary susceptibility profile across the cycle

### 5.8 Temporal Structure Analysis

**Test:** Examine inter-event intervals for large events and the temporal distribution of small events.

**Expected finding in Capacitive SOC:**
- Quasi-periodicity in large event timing — a characteristic period absent in natural SOC
- Systematic decrease in small event frequency during accumulation phase
- Deep quiescence immediately post-release followed by gradual resumption of small events
- Slow drift in baseline activity measures between large events

### 5.9 Network Analysis

**Test:** Examine functional connectivity and graph-theoretic properties across the cycle.

**Expected finding in Capacitive SOC:**
- Progressive loss of weak edges during accumulation phase
- Fragmentation toward modularity
- Spike in global efficiency immediately during large release
- Post-release network state different from pre-accumulation state

### 5.10 Cross-Domain Convergence

**Test:** Apply tests across statistical, spectral, network, and information-theoretic domains simultaneously.

**Confirmation criterion:** If truncated distribution, failed shape collapse, failed exponent relations, spectral knee, non-stationary branching ratio, and quasi-periodic temporal structure are all observed simultaneously and consistently, this convergence constitutes the primary evidence for Capacitive SOC rather than natural SOC, subcriticality, or noise.

---

## Part VI: Percolation Threshold as Termination Condition (Speculative)

> **Note: This section is speculative. The components are grounded in established theory but their synthesis as stated here has not been confirmed in the literature and requires investigation. See the companion research pathways document.**

### 6.1 The Proposition

In a SOC system, cascade events self-terminate not merely because they reach the system boundary, but because:

> The cascade consumes stored potential as it propagates. The act of propagation depletes the energy available for further propagation. When remaining system energy drops below the percolation threshold p_c, the connected spanning cluster cannot be maintained and the cascade self-extinguishes.

### 6.2 Grounding in Established Theory

Several established frameworks contain components of this proposition:

**Percolation theory** formally defines p_c as the minimum connectivity condition for a spanning cluster. Below p_c, only finite isolated clusters exist.

**Directed percolation** — the universality class of most SOC systems — treats the absorbing state as the condition from which activity cannot spread. Activity depletion drives the system toward the absorbing state.

**Forest fire model** — fire self-terminates when connected fuel clusters are consumed. The remaining forest falls below the connectivity condition for further fire spread. This is mathematically close to the proposition.

**SIR epidemic models** — epidemic termination when the susceptible population is depleted below the herd immunity threshold is formally equivalent to crossing below a percolation threshold. Epidemic final size theory explicitly connects outbreak size to the initial distance above p_c.

### 6.3 What the Proposition Adds

The proposition formalizes p_c as serving a **dual role**:

- **Activation condition** — minimum energy/connectivity for criticality and cascade initiation (established)
- **Termination condition** — the threshold below which cascade propagation cannot be sustained, reached dynamically during the cascade through energy consumption (proposed)

This dual role does not appear to be explicitly stated in the SOC literature, though it may be implicit in existing models.

### 6.4 Implications for Natural SOC

If the proposition holds:

- Event size in SOC is limited not merely by system size but by the total energy available above p_c at cascade initiation
- The energy budget of any event is: total system energy minus the energy at p_c
- A small trigger can recruit all energy above p_c across the connected system — consistent with the fat-tailed distribution and the principle that trigger energy and release energy are decoupled
- The system self-terminates naturally when it reaches p_c — providing a dynamic energy-based explanation for cascade arrest

### 6.5 Implications for Capacitive SOC

In Capacitive SOC, the proposition has significant consequences:

- Deficit accumulation loads the system **far above p_c**
- The gap between the loaded system energy and p_c is much larger than in natural SOC
- Release events therefore have more energy to consume before reaching the termination condition
- Large events are larger precisely because **the termination condition is harder to reach from a higher starting point**
- The spatial extent of large release events is governed by how far the system was loaded above p_c

This provides a potentially quantitative relationship between deficit accumulation and large event magnitude.

### 6.6 Research Required

To confirm or refute:
- Whether existing SOC models implicitly satisfy this proposition
- Whether event size scales with initial distance above p_c in existing models
- Whether the absorbing state in directed percolation formally corresponds to falling below p_c
- Whether the forest fire model explicitly frames termination in these terms
- Formal derivation of cascade termination condition in terms of p_c

---

## Part VII: Maximum Energy and System Capacity (Speculative)

> **Note: This section is speculative. It connects to established concepts but does not map cleanly onto a single established construct. It may be a synthesis unique to this framework.**

### 7.1 The Concept

A system subject to Capacitive SOC accumulates a deficit that may grow very large. At some point, the energy concentration in particular regions or pathways may exceed what the system's connectivity and node structure can propagate normally. This represents an upper boundary on the system's capacity to handle energy release — distinct from the percolation threshold lower bound.

### 7.2 Connection to Susceptibility

**Susceptibility** — the established concept most relevant here — describes how much of the system can be recruited into a response to a perturbation. It is formally related to the integral of correlations across the system and peaks at the critical point.

In energetic terms, susceptibility captures:
- The total stored potential that can be recruited by a cascade
- The connected volume that can participate in an event
- The upper range of what is energetically possible in a single event

At the critical point, susceptibility is maximized — consistent with the power law distribution extending to system-size events.

### 7.3 The Proposed Upper Boundary

The proposed maximum energy concept differs from susceptibility in a specific way:

Where susceptibility describes the **maximum recruitable energy under natural SOC conditions**, the proposed boundary describes the **maximum energy the pathway structure can transmit** when energy concentration is anomalous.

In Capacitive SOC:
- Deficit accumulates unevenly, creating regions of anomalously high local concentration
- When release occurs, local energy concentration may exceed what connected pathways can normally propagate
- The pathway structure — determined by connectivity, edge strength, and node capacity — imposes an upper limit on propagation
- Beyond this limit, the event may damage the pathway structure itself, altering the system's future dynamics

### 7.4 Relationship Between the Two Boundaries

Together, the percolation threshold and the proposed maximum energy boundary define an **operational envelope** for the system:

- **Lower bound — Percolation threshold p_c:** Minimum energy/connectivity for criticality to be expressed and cascade termination condition
- **Upper bound — Maximum energy / system capacity:** Maximum energy the connected structure can handle without structural alteration

In natural SOC, the system operates within this envelope by definition — small events bleed off potential continuously, preventing approach to either boundary. In Capacitive SOC, the lower bound governs termination of large events while the upper bound may be approached or exceeded during severe deficit accumulation.

### 7.5 Connections to Established Theory

Several established concepts partially capture this upper boundary:

- **Dynamic range saturation** — the upper limit of the input range a critical system can discriminate
- **Maximum flow in network theory** — topological upper limit on throughput through a network
- **Spinodal point** — upper limit of metastability in phase transition theory, beyond which the system cannot remain in a metastable state
- **Tipping points / bifurcations** — where qualitative system behavior changes under increasing load

None of these are identical to the proposed concept. The maximum energy boundary as a property of anomalous energy concentration meeting pathway structure constraints may be a synthesis not yet formally named.

### 7.6 Research Required

To confirm or refute:
- Whether any existing SOC framework includes an upper energy bound distinct from system size
- Whether network maximum flow theory has been applied to cascade propagation limits
- Whether spinodal points have been connected to cascade arrest in SOC systems
- Whether the concept of structural damage during cascades has been formalized in SOC theory
- Numerical simulation of Capacitive SOC systems to detect whether an upper propagation limit emerges

---

## Part VIII: Overtopping Dynamics (Refinement of Parts VI and VII)

> **Status:** This section refines the speculative Parts VI and VII with a concrete, simulation-ready mechanism named **overtopping** (after the canonical dam-overtopping example). Full theoretical development is in `overtopping.md`. The experimental test is specified in `../validation/01_03_manna_overtopping.md`.

### 8.1 The Central Insight

Parts VI and VII treat the percolation threshold (below which cascades terminate) and the maximum energy boundary (above which pathway capacity is exceeded) as fixed properties of the underlying system. The overtopping analysis reveals a stronger claim:

> **The suppression structure and the system structure may be the same thing.**

When a CSOC release occurs, the release propagates through the same physical or institutional medium that was providing suppression. If that medium is damaged by the release, post-event suppression is weakened or absent. This is not an academic refinement — it is the general case for physical dams, for institutional frameworks, for ecological regulatory mechanisms. The exogenous-suppression model in Part II is the special case.

### 8.2 Formal Mechanism

A per-site structural integrity field σ_i ∈ [0,1] couples suppression strength to release energy. The modified CSOC dynamics (on a Manna substrate) are:

```
effective_threshold_i = z_c + T · σ_i
topple site i when z_i ≥ effective_threshold_i

during toppling:
    track cumulative topplings n_i at this site during this avalanche
    if n_i > E_crit:
        σ_i ← σ_i · (1 − α)    [damage]

between grain drops:
    σ_i ← min(1, σ_i + recovery_rate)    [repair]
```

Parameters: T (suppression intensity), E_crit (damage threshold), α (damage rate per damaging event), recovery_rate (repair rate between events).

See `overtopping.md` for the full exposition.

### 8.3 Refinement of Parts VI and VII

**Part VI (percolation termination):** as σ degrades, the effective connectivity of the suppressed lattice degrades with it. A site with σ=0 topples at the natural threshold (no suppression) and transmits to its neighbors normally, but the suppressed system as a whole has lost coverage. Structural failure is a mechanism by which effective p_c can be lost independent of activity level.

**Part VII (maximum energy boundary):** the upper bound is not just about propagation capacity in a static sense. It is about whether the release energy exceeds what the structure can survive structurally intact. The positive feedback — release damages structure, weakened structure allows more release, more release damages more structure — is what makes the boundary sharp rather than gradual.

### 8.4 Qualitatively Different Pre- and Post-Failure Dynamics

A CSOC cycle with intact σ:
- Quiet accumulation phase
- Trigger + large release
- σ mostly recovers via recovery_rate
- Next cycle resembles the previous one

A CSOC cycle that crosses the absorbing barrier:
- σ degrades faster than it recovers
- Suppression erodes across consecutive events
- Eventually σ_mean ≈ 0 system-wide
- Post-failure: no suppression mechanism remains, system cannot enter another CSOC accumulation phase
- What follows may be closer to natural SOC (if the pathway structure is otherwise intact) or to dissolution (if the pathway structure itself has been compromised)

This is the concrete mechanism for the architecture's **fracture vs. ruin** distinction (§5.5): whether the post-failure system retains enough structure to reconstitute, or whether it is irretrievably damaged.

### 8.5 Connection to the Absorbing Barrier

The architecture (§5.5) asserts the absorbing barrier exists but does not specify where. In the overtopping extension, the barrier is the boundary in (T, α, recovery_rate) parameter space between regimes where:

- damage is recovered between events (CSOC cycles persist), vs.
- damage compounds faster than recovery (σ trends to 0, structural failure)

This makes the absorbing barrier empirically locatable via simulation, not just a theoretical assertion. The experiment design in `../validation/01_03_manna_overtopping.md` specifies how to find it.

### 8.6 Status

The extension is a theoretical proposal, not a validated result. Its quantitative predictions (Part VII of `overtopping.md`) are simulation-testable on the Manna substrate. Confirmation or refutation depends on that experiment. If confirmed, the extension becomes part of CSOC proper rather than a speculative refinement.

---

## Part IX: Summary of the Framework

### The Core Architecture

Capacitive SOC describes a SOC system with suppressed small events. The suppression mechanism is irrelevant to the observable signatures — what matters is the effect on the event distribution.

The system undergoes a characteristic accumulation-release cycle governed by two timescales. During the accumulation phase it superficially resembles a subcritical system. During the release phase it produces events that are disproportionate in size, spatially structured by the deficit topology, and distinct from natural SOC large events in their temporal profile and post-event behavior.

### The Signature Profile

Capacitive SOC produces a distinctive and convergent signature profile across all domains:
- Truncated distribution at the low end
- Excess large events above the suppression scale
- Characteristic scale introduced at the suppression threshold
- Failed exponent relations and shape collapse
- Spectral knee at the suppression frequency
- Non-stationary branching ratio and susceptibility
- Quasi-periodic large event timing
- Progressive network fragmentation during accumulation

These signatures are **mechanism agnostic** — they detect the effect of suppression regardless of how suppression is occurring.

### The Speculative Extensions

Two speculative propositions extend the framework into territory that requires literature investigation and formal derivation:

1. **Percolation threshold as termination condition** — cascade events self-terminate when propagation depletes system energy below p_c, with implications for event size scaling with initial distance above p_c

2. **Maximum energy boundary** — anomalous energy concentration from deficit accumulation may approach or exceed the maximum energy the connected pathway structure can propagate, defining an upper bound on the operational envelope

### The Paired Framework

Capacitive SOC is paired with **Inductive SOC** — its excitatory counterpart — providing a symmetric framework around the natural SOC critical point. Together they describe the full range of deviation from natural SOC:

- **Inductive SOC** — artificially driven toward and beyond criticality
- **Natural SOC** — self-organized critical state
- **Capacitive SOC** — artificially damped below natural release rate

---

## Appendix: Established Terms and Their Roles in This Framework

| Term | Origin | Role in Framework |
|---|---|---|
| Self-Organized Criticality | Bak, Tang, Wiesenfeld (1987) | Foundational mechanism |
| Critical point | Statistical physics | The target state of SOC |
| Power law | Mathematics / statistics | Primary signature of criticality |
| Branching ratio (sigma) | Branching process theory | Dynamical measure of critical state |
| Percolation threshold (p_c) | Percolation theory | Lower operational bound (speculative dual role) |
| Susceptibility | Statistical physics | Recruitable energy; peaks at criticality |
| Directed percolation | Statistical physics | Universality class of SOC; absorbing states |
| Finite size scaling | Statistical physics | Connects system size to event size distribution |
| Dynamic range | Neuroscience / physics | Information-theoretic advantage of criticality |
| 1/f noise | Signal processing | Spectral signature of criticality |
| Absorbing state | Non-equilibrium physics | State from which activity cannot spread |
| Stick-slip | Tribology / seismology | Phenomenological analogue to Capacitive SOC cycle |
| Capacitive SOC | This framework | SOC with suppressed small events |
| Inductive SOC | This framework | SOC with amplified events |
| Energy deficit | This framework | Accumulated unreleased potential |

---

*This document represents a working theoretical framework. Speculative components are clearly flagged and require literature investigation and formal derivation before they can be treated as established.*
