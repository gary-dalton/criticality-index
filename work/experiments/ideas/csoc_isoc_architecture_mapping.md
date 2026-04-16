# CSOC/ISOC ↔ Architecture Mapping

## Purpose

This document makes explicit the relationship between the Capacitive/Inductive SOC framework and the SOC Model Architecture. They describe overlapping phenomena from different starting assumptions. Where they agree strengthens both. Where they diverge defines what the experimental program must resolve.

---

## Different Starting Assumptions

**The Architecture** (soc_model_architecture.md) assumes that O and E are measurable forces whose balance determines the phase state:

- C_d = E - O
- C_d < 0 → sub-critical (O dominates)
- C_d = 0 → at criticality
- C_d > 0 → super-critical (E dominates)

The system's state IS what the components measure. If C_d < 0, the system is sub-critical.

**The CSOC/ISOC Framework** assumes an underlying SOC substrate that can be distorted by suppression (CSOC) or amplification (ISOC):

- The system "wants" to be at criticality (SOC is the attractor)
- Suppression masks the SOC substrate → system appears sub-critical but is accumulating deficit
- Amplification extends cascades → system appears super-critical but retains SOC dynamics beneath

The system's apparent state may not be its true state. A system measured as C_d < 0 might actually be CSOC — a distorted critical system, not a genuinely sub-critical one.

**These are different claims.** They cannot both be right in all cases. They could both be right in different cases — some sub-critical systems are genuinely sub-critical, others are CSOC. The experimental program (Experiments 01-06) is designed to determine whether the CSOC/ISOC distinction is empirically detectable.

---

## Terminology Mapping

| Architecture Term | CSOC/ISOC Term | Relationship |
|-------------------|---------------|--------------|
| Excitation (E) | Slow driving | Same concept: energy entering the system between events |
| Ordering (O) | (no direct equivalent) | Architecture O is a measured force. CSOC suppression is a mechanism that blocks small avalanches — related but not identical |
| C_d < 0 (sub-critical) | CSOC accumulation phase | Architecture says the state IS sub-critical. CSOC says it LOOKS sub-critical but may be storing deficit |
| C_d > 0 (super-critical) | ISOC continuous activity | Architecture says the state IS super-critical. ISOC says it LOOKS super-critical but may retain SOC substrate |
| C_d = 0 (critical) | Natural SOC | Same concept |
| Absorbing barrier | Maximum energy boundary / absorbing state | Architecture defines the governance concept. CSOC/ISOC connect it to physics (directed percolation absorbing state). See architecture §5.5 |
| Activation threshold (mass threshold) | Percolation threshold p_c | Architecture defines the governance concept. CSOC/ISOC use the formal physics construct. Same phenomenon |
| Lattice failure (Φ function) | (not addressed) | Architecture-specific. CSOC/ISOC don't model transmission failure separately |
| Entropy (S) → 0 | System dissolution | Both frameworks agree: irreversible loss of configuration space |
| (not addressed) | Energy deficit | CSOC-specific: cumulative unreleased energy from suppressed events. The architecture measures U (internal energy) as a snapshot, not a cumulative deficit |
| (not addressed) | Amplification during propagation | ISOC-specific: energy injected during cascades. The architecture's E is slow driving, not mid-cascade injection |
| (not addressed) | Depletion recovery timescale | ISOC-specific: time to rebuild after amplified events deplete stored energy |

---

## Where They Agree

1. **Criticality is the functional optimum.** Both frameworks hold that the critical state is where the system is most capable. Maximum power delivery (architecture), maximum dynamic range and information transmission (CSOC/ISOC).

2. **Sub-critical is dangerous.** Architecture §3: "sub-critical is NOT safe — accumulates stress." CSOC: sub-critical appearance hides deficit accumulation leading to catastrophic release. Same conclusion, CSOC provides the mechanism.

3. **Super-critical is dissolution.** Architecture §3: "liquefied, lacks cohesion." ISOC: continuous over-propagation depletes and potentially damages the lattice. Same conclusion, ISOC adds structural consequence detail.

4. **The absorbing barrier exists.** Architecture §5.5: irreversible dissolution where S → 0. CSOC/ISOC: connect this to the physics absorbing state (directed percolation) and maximum energy boundary. The architecture defines what it means for governance; CSOC/ISOC provide the physics formalism.

5. **Connectivity has a threshold.** Architecture §5.1: mass threshold / minimum system size. Activation threshold hypothesis: percolation threshold for lattice connectivity. CSOC/ISOC: p_c as both activation and termination condition.

---

## Where They Diverge

### 1. Is Sub-Critical Genuine or Masked?

**Architecture:** C_d < 0 means O > E. The system is sub-critical. Full stop.

**CSOC:** The system may be at SOC internally but with suppressed small avalanches. It *appears* sub-critical because the suppression mechanism blocks the events that would produce SOC signatures. The deficit accumulates invisibly.

**Resolution required:** Can the two be distinguished empirically? CSOC predicts quasi-periodic large release events. Genuine sub-criticality predicts indefinite quiet. Experiment 05 tests this on synthetic systems. Whether it's detectable in governance data is the feasibility question.

### 2. Is Super-Critical Genuine or Amplified?

**Architecture:** C_d > 0 means E > O. The system is super-critical.

**ISOC:** The system may be at SOC internally but with amplified cascades. It *appears* super-critical because amplification inflates event sizes. The underlying SOC dynamics persist beneath.

**Resolution required:** ISOC predicts history-dependent response (post-large-event depletion dips). Genuine super-criticality predicts no history dependence. Experiment 05 tests this. Removing the amplification mechanism should restore SOC signatures (ISOC) or not (genuine super-critical).

### 3. Energy Accounting

**Architecture:** U (internal energy) is a snapshot: kinetic + potential + thermal energy at time t. Measured from slugs.

**CSOC:** The energy deficit is cumulative — the integral of suppressed-event energy over time. It depends on history, not just the current state. This quantity is not directly measurable from a single time point.

**ISOC:** Amplification injects energy during propagation — a quantity not captured by between-event measurements. U(t) before an event does not predict event size because amplification adds energy during the cascade.

**Implication:** The architecture's snapshot measurement of U may not capture the dynamics CSOC/ISOC describe. Trajectory analysis (d1, d2) partially addresses this — sustained C_d < 0 with rising U *might* indicate CSOC accumulation — but it's indirect.

### 4. The O Lever

**Architecture §8.2:** States control O. Increasing O moves toward sub-criticality. The state should tune O to match E.

**CSOC:** Increasing O excessively doesn't just make the system sluggish — it suppresses small avalanches, creating a deficit accumulation cycle that ends in disproportionate catastrophic release. Over-ordering is actively dangerous, not merely suboptimal.

**ISOC:** Decreasing O excessively doesn't just make the system chaotic — it amplifies cascades, depleting stored energy and potentially damaging the lattice. Under-ordering causes structural harm, not just instability.

**Implication:** CSOC/ISOC provide a stronger practical warning than the architecture currently delivers. This is where the frameworks are most complementary — the architecture provides the measurement, CSOC/ISOC provide the mechanistic warning about what the measurement means.

---

## What the Experimental Program Resolves

| Question | Experiment | Outcome If Confirmed | Outcome If Refuted |
|----------|-----------|---------------------|-------------------|
| Can SOC signatures be detected in a known SOC system? | 01 (sandpile) | Diagnostic tools are valid | Tools need fixing |
| Can a connectivity threshold be detected? | 02-03 (percolation + activation) | Activation threshold is real | Threshold is gradual or absent |
| Does an absorbing barrier exist? | 04 (overload) | Irreversible dissolution is measurable | Damage is always recoverable |
| Can CSOC be distinguished from genuine sub-criticality? | 05 (CSOC/ISOC) | CSOC is empirically testable | CSOC is unfalsifiable |
| Can ISOC be distinguished from genuine super-criticality? | 05 (CSOC/ISOC) | ISOC is empirically testable | ISOC is unfalsifiable |
| Does inter-system coupling produce ISOC-like signatures? | 06 (coupled SOC) | Coupling is an amplification mechanism | Coupling is just slow driving |

---

## Status

This mapping is a working document. The CSOC/ISOC framework is not part of the main architecture — it is a separate theoretical extension with its own experimental validation path. The architecture stands on its own: QoG data, five empirical signatures, backtesting, C_d. CSOC/ISOC extend the interpretation of what C_d values mean and are tested through synthetic experiments and (potentially) domain-specific high-frequency data.

If the experimental program confirms that CSOC/ISOC dynamics are empirically detectable and distinguishable, the architecture may be updated to incorporate the distinction. If not, CSOC/ISOC remain structured speculation — useful for thinking but not operationalized in the model.
