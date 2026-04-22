# Architecture ↔ Mechanism Mapping

## Purpose

This document makes explicit the relationship between the SOC Model Architecture (`document/publication/soc_model_architecture.md`) and the modified-SOC mechanism frameworks (`overtopping.md`, `liquefaction.md`). The architecture specifies what is measured and how the model's phase is determined. The mechanism frameworks specify what physical dynamics produce those measurements and what signatures appear in data. Where they agree strengthens both. Where they diverge defines what the experimental program must resolve.

This document replaces an earlier CSOC/ISOC ↔ architecture mapping written when CSOC and ISOC were standalone theoretical frameworks. Those frameworks have been superseded by overtopping (primary CSOC-side mechanism) and liquefaction (primary ISOC-side mechanism); CSOC-like / ISOC-like survive only as adjective-form detection category names (see `distorted_soc_signatures.md`).

---

## The Two Framings

### The architecture

The SOC Model Architecture assumes that O (order) and E (excitation) are measurable forces whose balance determines the phase state:

- C_d = E − O
- C_d < 0 → sub-critical (O dominates)
- C_d = 0 → at criticality
- C_d > 0 → super-critical (E dominates)

The system's state *is* what the components measure. If C_d < 0, the system is sub-critical.

### The mechanism frameworks

Overtopping and liquefaction start from an SOC substrate and specify what happens when that substrate is distorted by coupling to external dynamics:

- **Overtopping** — coupling to a fragile suppression structure (σ field + damage + recovery + optional trickle release). Produces suppressed-release dynamics that mimic sub-criticality but have a different underlying state.
- **Liquefaction** — coupling to a cyclic external driver that destroys local damping during events (π field + preconditions + cyclic forcing). Produces amplified-cascade dynamics that mimic super-criticality but have a different underlying state.

In both mechanisms, the system's apparent state may not be its true state. A system measured as C_d < 0 might actually be an overtopping system in its accumulation phase — distorted critical dynamics, not genuinely sub-critical. A system measured as C_d > 0 might be a liquefaction system under cyclic loading — distorted critical dynamics, not genuinely super-critical.

**These are different claims.** They cannot both be right in all cases. They could both be right in different cases — some sub-critical-measured systems are genuinely sub-critical, others are overtopping in accumulation phase. The experimental program is designed to determine whether the distinction is empirically detectable.

---

## Terminology Mapping

| Architecture term | Overtopping term | Liquefaction term | Relationship |
|---|---|---|---|
| Excitation (E) | Slow driving | Cyclic driving (distinct concept) | For overtopping, architecture E maps to the slow SOC driving; for liquefaction, the architecture's E does not capture the cyclic-driving dimension |
| Ordering (O) | Suppression strength T · σ | Damping (inverse of π) | Architecture O is a measured aggregate force. Overtopping's T · σ decomposes this into a static part (T) and a damageable part (σ). Liquefaction's damping is inverse of π, with preconditions gating activation |
| C_d < 0 (sub-critical) | Recovering suppressed-release regime | (not applicable) | Architecture says state *is* sub-critical. Overtopping says state is distorted-critical with suppressed small events |
| C_d > 0 (super-critical) | (not applicable) | Active liquefaction regime | Architecture says state *is* super-critical. Liquefaction says state is distorted-critical with amplified propagation |
| C_d = 0 (critical) | Natural SOC (α = 0, σ = 1 + T = 0 corner, or trickle-sufficient regime) | Natural SOC (preconditions unsatisfied OR driver absent) | Both mechanisms reduce to natural SOC at specific parameter corners |
| Absorbing barrier (§5.5) | (T, α, recovery_rate) phase-space boundary between recovering and runaway | Densification stabilization threshold | Architecture defines the governance concept; overtopping locates it in parameter space; liquefaction offers a different (stabilizing) form |
| Activation threshold (mass threshold) | No direct analog | Precondition activation (s, d plane) | Architecture defines governance mass threshold; liquefaction has an analogous precondition boundary |
| Lattice failure (Φ function) | σ → 0 globally | (not addressed) | Architecture-specific concept; overtopping provides an explicit ruin mechanism |
| Entropy (S) → 0 | System dissolution (σ → 0 + pathway damage) | Progressive densification to solid state | Both mechanisms agree: irreversible loss of configuration space, via different routes |
| Detection signatures | CSOC-like signature bundle | ISOC-like signature bundle | See `distorted_soc_signatures.md` for the empirical co-occurrence specifications |

---

## Where They Agree

1. **Criticality is the functional optimum.** Architecture and both mechanisms hold that the critical state is where the system is most capable. Maximum power delivery (architecture), maximum dynamic range and information transmission (mechanism frameworks).

2. **Sub-critical-measured is dangerous.** Architecture §3: "sub-critical is NOT safe — accumulates stress." Overtopping: accumulated deficit releases disproportionately. Same conclusion, overtopping provides the mechanism.

3. **Super-critical-measured is dissolution.** Architecture §3: "liquefied, lacks cohesion." Liquefaction: continuous over-propagation destroys local damping and, in the extreme, the transmission medium. Same conclusion, liquefaction adds the specific physical route.

4. **The absorbing barrier exists.** Architecture §5.5: irreversible dissolution where S → 0. Overtopping: parameter-space boundary where damage-recovery balance tips. Liquefaction: precondition trajectory reaching full liquefaction (in the extreme). Architecture defines what it means for governance; mechanisms locate it.

5. **Connectivity has a threshold.** Architecture §5.1 mass threshold. Overtopping effective p_c via σ degradation. Liquefaction precondition threshold (s, d). All three converge on the idea that the system must meet structural conditions to be critical.

---

## Where They Diverge

### 1. Is sub-critical measurement the state or a mask?

**Architecture:** C_d < 0 means O > E. The system is sub-critical. Full stop.

**Overtopping:** The system may be at SOC internally but with suppressed small avalanches. It *appears* sub-critical because the suppression mechanism blocks the events that would produce SOC signatures. The deficit accumulates invisibly until release.

**Resolution required:** Can the two be distinguished empirically? Overtopping predicts quasi-periodic large release events (see `overtopping.md` Part VII). Genuine sub-criticality predicts indefinite quiet. Experiment 01_03 tests this on synthetic systems. Whether detectable in governance data is the feasibility question.

### 2. Is super-critical measurement the state or a mask?

**Architecture:** C_d > 0 means E > O. The system is super-critical.

**Liquefaction:** The system may be at SOC internally but with cyclic driving amplifying cascades. It *appears* super-critical because amplification inflates event sizes. Removing the driver should restore SOC dynamics.

**Resolution required:** Liquefaction predicts history-dependent response (post-large-event depletion dips) and reversibility on driver removal. Genuine super-criticality predicts neither. Experiment for liquefaction is deferred as a corollary.

### 3. Energy accounting

**Architecture:** U (internal energy) is a snapshot: kinetic + potential + thermal energy at time t. Measured from slugs.

**Overtopping:** σ (accumulated fragility) is history-dependent — the integral of damaging-event flux over time, net of repair. Not directly measurable from a single time point.

**Liquefaction:** π (accumulated amplification potential) is history-dependent — the integral of cyclic-driving cycles at activated sites, net of dissipation. Also not directly measurable from a single time point.

**Implication:** The architecture's snapshot measurement of U may not capture the dynamics the mechanisms describe. Trajectory analysis (d1, d2) partially addresses this — sustained C_d < 0 with rising U *might* indicate overtopping accumulation — but it's indirect. Direct mechanism identification probably requires multi-timepoint observation, as specified in `falsifiability_requirements.md` Part IV.

### 4. The O lever

**Architecture §8.2:** States control O. Increasing O moves toward sub-criticality.

**Overtopping:** Increasing T (threshold elevation) does *not* just make the system sluggish — it creates a deficit accumulation cycle that ends in disproportionate catastrophic release, with possible σ destruction. Over-ordering via overtopping is actively dangerous. Adding adequate trickle release (r above the sufficiency boundary) prevents the dangerous regime without requiring reduced T.

**Liquefaction:** Decreasing O excessively (i.e., losing damping capacity) without active cyclic driving is just natural SOC. But with cyclic driving, low damping + preconditions + driver triggers liquefaction dynamics with cascades that can damage the transmission medium through sustained over-loading.

**Implication:** The mechanisms provide stronger practical warnings than the architecture alone delivers. This is where the framings are most complementary — the architecture provides the measurement, the mechanisms provide the mechanistic warning about what the measurement means and what governance levers (e.g., trickle release mechanisms) can mitigate the risk.

---

## What the Experimental Program Resolves

| Question | Experiment | Outcome if confirmed | Outcome if refuted |
|---|---|---|---|
| Can SOC signatures be detected in a known SOC system? | 01 (sandpile) | Diagnostic tools are valid | Tools need fixing |
| Can a connectivity / mass threshold be detected? | 02–03 (percolation + activation) | Activation threshold is real | Threshold is gradual or absent |
| Does an absorbing barrier exist? | 04 (overload) | Irreversible dissolution is measurable | Damage is always recoverable |
| Does overtopping produce distinguishable signatures and predicted phase transitions? | 01_03 (Manna + overtopping) | Overtopping is empirically testable; absorbing barrier located | Suppression + damage does not produce the predicted dynamics |
| Does adding trickle release suppress overtopping dynamics above a sharp `r*`? | 01_03 extension | Trickle sufficiency boundary is real | Trickle only gradually modulates overtopping |
| Does liquefaction produce ISOC-like signatures with predicted preconditions? | TBD — deferred corollary | Liquefaction is empirically testable | Cyclic driving does not produce predicted dynamics |
| Are CSOC-like and ISOC-like signatures empirically distinguishable from natural SOC, sub-critical, and super-critical? | Signatures catalog Part VI | Detection categories are valid | Detection collapses into mechanism identification question |

---

## Status

Overtopping is specified and scheduled (experiment 01_03). Liquefaction is skeletal and deferred. The signatures catalog is specified and awaits measurement-procedure calibration. The architecture stands independently of these mechanisms; if experimental results confirm that overtopping and liquefaction dynamics are empirically detectable and distinguishable from naive sub/super-criticality, the architecture's interpretation may be refined accordingly.

If experiments falsify these mechanisms, the signatures catalog still stands as a detection-category specification independent of mechanism — an observation of CSOC-like or ISOC-like signatures would then require a different mechanism proposal.
