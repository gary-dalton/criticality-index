# Falsifiability Requirements for Modified-SOC Mechanism Frameworks

## Preamble

The modified-SOC mechanism frameworks — **overtopping** (suppressed-release SOC with structural fragility) and **liquefaction** (amplified-cascade SOC with cyclic external driving) — must meet falsifiability standards before any empirical claim based on them can be considered scientific rather than speculative. This document defines those standards: the specific conditions, predictions, and research designs that allow a mechanism claim to be confirmed or refuted.

The standard is explicit and non-negotiable:

> **A theory that cannot be falsified is not a scientific theory. A mechanism framework must make specific predictions that could be wrong.**

This document is mechanism-agnostic: its methodology applies equally to overtopping, liquefaction, and future modified-SOC mechanism proposals. For the specific predictions each mechanism makes, see `overtopping.md` Part VII and `liquefaction.md` Part VI. For the observable signatures these mechanisms should produce (separate from mechanism identification), see `distorted_soc_signatures.md`.

---

## Part I: The Core Requirements

### 1.1 Specific Quantitative Predictions

Qualitative predictions — suppression distorts the distribution, amplification inflates large events — are insufficient. The framework must generate quantitative predictions of the form:

- Given a measurable suppression threshold T and a measurable driving rate D, the large event distribution should take a specific mathematical form
- The ratio of large events to small events should change in a predictable and calculable way as suppression intensity changes
- The inter-event interval for large events should scale with suppression intensity according to a specific relationship
- The degree of distributional distortion should scale with intervention intensity in a specific and testable way

These predictions must follow **necessarily** from the framework — not be retrofitted to data after the fact.

### 1.2 Predictions That Could Be Wrong

A modified-SOC framework has serious absorptive capacity if any observation can be retrofitted to it:

- Quiet system → suppressed-release accumulation phase
- Large events → suppressed-release event
- Continuous high activity → amplified-cascade dynamics
- Looks subcritical → suppressed-release in disguise
- Looks supercritical → amplified-cascade in disguise

This is a fatal weakness. The falsifying observations must be stated explicitly and in advance.

**Falsifying observations for overtopping (suppressed-release with structural damage):**
- Systems with documented strong suppression mechanisms show no excess of large events relative to weakly suppressed systems
- Distributional distortion does not scale with suppression intensity
- Large event timing is no more regular than natural SOC or simple subcritical systems would predict
- Removing a documented suppression mechanism does not shift the event distribution toward natural SOC
- The post-large-event quiescence duration does not correlate with pre-event suppression duration
- **Overtopping-specific:** no phase transition in (T, α) at fixed recovery_rate; σ degradation does not scale with event size; runaway onset is gradual rather than sudden; recovery_rate does not rescue high-damage regimes. See `overtopping.md` Part VII for the full list.
- **Trickle-specific:** the trickle sufficiency boundary is gradual rather than sharp; adding controlled release does not lengthen inter-event intervals.

**Falsifying observations for liquefaction (amplified-cascade with cyclic driving):**
- Systems with documented amplification mechanisms show no excess of large events relative to non-amplified systems
- Event size does not scale with cyclic-driving amplitude
- History dependence — post-large-event depletion — is absent
- Removing the cyclic driver does not shift signatures toward natural SOC
- **Liquefaction-specific:** preconditions (saturation, density analogs) do not form a sharp activation boundary; pore-pressure analog does not accumulate with cumulative driving; densification does not shift the precondition boundary. See `liquefaction.md` Part VI for the full list.

**Falsifying the underlying SOC substrate claim:**
- The system does not exhibit the four SOC preconditions — slow driving, threshold dynamics, redistribution, dissipation
- The structural argument for SOC cannot be made independently of the distributional signatures

**Falsifying the detection category claim (separate from any mechanism):**
- See `distorted_soc_signatures.md` Parts IV and VI for the signature-bundle falsification conditions.

### 1.3 Measurements That Are Actually Obtainable

The framework is only useful if its predictions can be tested with data that exists or can be collected. Required measurable quantities include:

**For event distributions:**
- Discrete, unambiguous events with measurable magnitudes
- Sufficient historical record to estimate distribution tails
- Data predating intervention mechanisms where possible

**For intervention mechanisms:**
- Independent and documentable measure of suppression or amplification intensity
- Clear start date or intensity gradient for natural experiments
- Measure that does not depend on the event distribution itself — independence is critical

**For temporal structure:**
- Sufficient temporal resolution to detect quasi-periodicity
- Long enough record to observe multiple accumulation-release cycles
- Stationarity assessment — the record must be long enough relative to the cycle period

**For system structure:**
- Network connectivity measures
- Evidence of threshold dynamics
- Evidence of redistribution following threshold crossing
- Evidence of dissipation

### 1.4 Comparison Cases

The forest fire geographical comparison is the template. Its strength comes from:
- Multiple instances of the same system type with different intervention intensities
- Intervention intensity documented independently of event data
- Sufficient events in each comparison case to estimate distributions

For human systems the equivalent requires:
- Multiple instances of comparable systems — jurisdictions, institutions, markets, periods — with different intervention regimes
- Independent documentation of those regimes
- Comparable event data across instances
- Control for confounding differences between instances

---

## Part II: The Falsifiability Problem in Human Systems Specifically

### 2.1 Why Human Systems Are Harder Than Forest Fires

The forest fire case succeeds because:
- Events are discrete and unambiguous — a fire either occurs or it does not
- The intervention policy is written, dated, and independent of the fire data
- Geographic comparison cases exist with minimal confounding
- The system is not reflexive — trees do not observe suppression policy

Human systems fail on multiple conditions:
- Events are often definitionally contested — what counts as a financial crisis, a political collapse, a religious schism
- Intervention mechanisms are entangled with system dynamics — impossible to measure independently
- Comparison cases differ in many confounding ways simultaneously
- Reflexivity — human agents observe the system and change behavior in response

### 2.2 The Minimum Viable Human System

The theory should first be tested on the human system that most closely approximates forest fire conditions:

- Events are discrete and measurable with minimal definitional ambiguity
- Intervention mechanism is documentable and dated with clear intensity variation
- Comparison cases exist with minimal confounding
- Reflexivity is minimized — agent behavior is relatively constrained by structure

Identifying this minimum viable system is itself a research task. It should be completed before extending to more complex domains.

### 2.3 The Entanglement Problem

In most human systems the intervention mechanism and the system dynamics are entangled — you cannot measure one independently of the other. This is the central methodological challenge.

Possible approaches:
- Find cases where intervention was imposed externally — by law, treaty, or exogenous shock — rather than emerging endogenously from the system
- Find cases where intervention intensity varies for reasons unrelated to the system state — instrumental variable approach
- Use structural modeling to separate intervention effects from underlying dynamics

None of these fully solve the entanglement problem. Acknowledging this limitation explicitly is part of intellectual honesty about the framework's current state.

---

## Part III: The Mathematical Development Requirement

### 3.1 Why a Formal Model Is Essential

Without a formal mathematical model the framework remains verbal and therefore unfalsifiable in practice. A formal model is required to:

- Generate specific quantitative predictions from stated parameters
- Allow predictions to be made before data is examined
- Allow the framework to be fit to data and tested against alternative models
- Define precisely what the framework claims and therefore what would refute it

### 3.2 The Starting Point

The existing SOC mathematics provides the foundation:
- Branching process theory — provides the mathematical structure for cascade propagation
- Directed percolation — provides the universality class framework
- Sandpile models — provide the accumulation and release mechanics
- Percolation theory — provides the connectivity threshold framework

The required development is a formal modification of these frameworks that incorporates:
- A suppression parameter — threshold below which events are damped
- An amplification parameter — factor by which propagation is enhanced
- Quantitative predictions about how the event distribution changes as functions of these parameters
- Quantitative predictions about temporal structure as functions of these parameters

### 3.3 The Predictions The Model Must Generate

At minimum the formal model must produce:

- The expected event size distribution as a function of suppression threshold and driving rate
- The expected large event inter-event interval as a function of the same parameters
- The expected ratio of large to small events as a function of suppression intensity
- The expected post-large-event quiescence duration
- The expected signatures in each observational domain — spectral, network, information theoretic

These predictions must be derivable from the model parameters, not fitted to data.

---

## Part IV: Research Design Templates

### 4.1 Natural Experiment Design

**Requirement:** A system with a documentable change in intervention intensity at a known time, with event data available before and after.

**Structure:**
- Pre-intervention period: estimate event size distribution, temporal structure, network signatures
- Post-intervention period: estimate same quantities
- Prediction: specific directional and quantitative changes in each quantity consistent with the hypothesized mechanism (overtopping, liquefaction, etc.)
- Falsification: changes are absent, opposite in direction, or inconsistent in magnitude with predictions

### 4.2 Cross-Sectional Comparison Design

**Requirement:** Multiple comparable system instances with different intervention intensities, measured simultaneously or in comparable periods.

**Structure:**
- Rank instances by independently measured intervention intensity
- Estimate event distributions for each
- Test whether distributional distortion scales monotonically with intervention intensity in the predicted direction and magnitude
- Falsification: no monotonic relationship, wrong direction, wrong magnitude

### 4.3 Intervention Removal Design

**Requirement:** A case where an intervention mechanism was removed or substantially reduced, with event data before, during, and after.

**Structure:**
- Characterize distribution under intervention
- Characterize distribution after removal
- Prediction: distribution shifts toward natural SOC signatures as intervention is removed
- Falsification: distribution does not shift, or shifts in wrong direction

### 4.4 Intensity Gradient Design

**Requirement:** Continuous variation in intervention intensity across cases or time, with independent measurement of that intensity.

**Structure:**
- Measure intervention intensity independently
- Measure event distribution characteristics
- Test the specific predicted relationship between intensity and distributional distortion
- Falsification: relationship is absent or inconsistent with framework predictions

---

## Part V: Stating Falsifying Conditions Before Looking at Data

This is a methodological requirement, not a suggestion. The falsifying conditions must be stated explicitly and publicly before examining any dataset. This prevents retrofitting and ensures the theory is genuinely at risk.

For any investigation the following must be pre-registered:

1. The specific system being investigated and why it qualifies as a candidate SOC substrate
2. The specific intervention mechanism and how its intensity is measured independently
3. The specific quantitative predictions the framework makes for this system
4. The specific observations that would falsify the framework in this case
5. The statistical thresholds that distinguish confirmation from falsification

Without pre-registration the investigation is hypothesis generation, not hypothesis testing. Both are valuable but they must not be confused.

---

## Part VI: The Logical Sequence of Work

Given everything above, the work proceeds in this order:

**Step 1 — Mathematical development**
Develop the formal model that generates quantitative predictions. This is the prerequisite for everything else.

**Step 2 — Identify the minimum viable human system**
Find the human system that most closely approximates forest fire conditions. Establish that it meets the SOC substrate requirements independently of the event data.

**Step 3 — Pre-register predictions**
State the specific quantitative predictions and falsifying conditions before examining the data.

**Step 4 — Test against the clean case**
Apply the research design to the minimum viable system. Report honestly whether predictions are confirmed or falsified.

**Step 5 — Extend or revise**
If the clean case confirms the framework, extend to more complex systems. If it falsifies, revise the framework before proceeding. Do not extend a falsified framework to new domains.

**Step 6 — Accumulate comparison cases**
Build the case across multiple systems with different intervention types and intensities. Convergence across independent cases is the strongest form of evidence.

---

## Summary

A modified-SOC mechanism framework becomes a falsifiable scientific theory when it has:

- A formal mathematical model generating specific quantitative predictions (overtopping and liquefaction both meet this minimum; see their respective Part VI/VII)
- Identification of the minimum viable test system for initial investigation (simulation: Manna substrate; empirical: TBD per domain)
- Pre-registered falsifying conditions stated before data examination
- Natural experiment, cross-sectional, intervention-removal, or intensity-gradient research designs
- Honest reporting of falsifying as well as confirming observations
- Extension to complex human systems only after the clean case is established

The work is substantial. The standard is demanding. That is appropriate — the claims being made are significant and deserve rigorous treatment.

---

*This document should be read alongside `overtopping.md`, `liquefaction.md`, `distorted_soc_signatures.md`, `soc_study_guide.md`, and `energy_depletion_percolation_research_paths.md`.*
