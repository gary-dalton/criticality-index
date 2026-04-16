---
title: "The Five Empirical Signatures of Self-Organized Criticality"
linkTitle: "Empirical Signatures"
description: "Detailed exposition of the five measurable signatures — power-law distributions, diverging correlation length, scale invariance, fractal structure, and fat-tailed changes — that distinguish systems at criticality from merely complex ones"
author: "Gary Dalton"
date: 2026-04-05T10:00:00-05:00
include_toc: true
show_comments: false
draft: true
weight: 25
keywords: "self-organized criticality, power law, correlation length, scale invariance, fractal structure, fat tails, leptokurtosis, empirical signatures, governance"
---

# The Five Empirical Signatures of Self-Organized Criticality

Systems at criticality produce five measurable signatures that distinguish them from merely complex or merely random systems. These signatures are not metaphors — they are quantifiable properties with established mathematical frameworks and empirical testing methods. This document explains what each signature means, why it arises, how to test for it, and what it implies for systems that exhibit it. The companion *Grounding the Criticality Hypothesis* document specifies how these signatures are operationalized as validation diagnostics in the model.

---

## 1. Power-Law Event Distribution

### The Statistical Shift: Beyond the Bell Curve

In traditional statistics, we are taught to view the world through the lens of the **Normal Distribution**, or the Bell Curve. In this framework, most observations cluster around a central mean, and extreme deviations—what we call "outliers"—are so rare that they are effectively ignored in risk models.

However, in systems functioning at **Self-Organized Criticality (SOC)**, the Bell Curve is fundamentally broken. Instead, these systems are defined by **Power-Law Distributions**.

A power law indicates that the frequency of an event is inversely proportional to its size. This means that while small events are common, large events are not "outliers" in the traditional sense; they are a statistically inevitable consequence of the same rules that govern the small ones.

In an SOC system, there is no "typical" event size. If you ask what the "average" earthquake or "average" market crash looks like, the answer is mathematically meaningless because the variance of the system is often infinite.

---

### The Mathematical Framework

The core of this signature is the probability density function of an event's magnitude ($s$):

$$
P(s) = C s^{-\tau}
$$

- $C$ is a constant
- $\tau$ (tau) is the **scaling exponent**

This exponent is effectively the fingerprint of the system's criticality. For most SOC systems in nature and society, $\tau$ typically falls between **1.0 and 3.0**.

#### Key Property: Scale Invariance

If you multiply the size of an event by a factor of $k$, the probability changes only by a proportional constant $k^{-\tau}$.

This is why power laws are often described as **scale-free**: the same dynamics apply regardless of magnitude—from tiny perturbations to system-wide cascades.

---

### The Mechanism: Slow Drive and Rapid Relaxation

SOC emerges from an interplay between two distinct timescales:

**1. The Slow Drive.** Energy, information, or stress is added gradually:

- Sandpile → grain-by-grain addition
- Tectonics → millimetric crust movement
- Social systems → accumulation of tension or inequality

**2. The Threshold.** Each component has a **local stability threshold**. When exceeded, it topples and redistributes stress to neighbors.

**3. The Avalanche.** This redistribution may trigger cascading failures:

- Stops immediately (small event)
- Propagates widely (large event)

Because the system sits at a **critical point**, neighboring states vary across all scales. This produces a **power-law distribution of avalanche sizes**.

---

### Empirical Testing and Backtesting

**Log-Log Linearity.** Plot frequency vs. magnitude on a **log-log scale**:

- Power law → straight line
- Non-power law → curvature or exponential cutoff

**Maximum Likelihood Estimation (MLE).** Used to estimate $\tau$ and test fit rigorously. Typical workflow:

- Fit exponent via MLE
- Validate using **Kolmogorov–Smirnov tests**
- Compare against alternatives: log-normal, Weibull

**The Lindy Effect.** A temporal manifestation of power laws:

> The expected future lifetime of a non-perishable entity is proportional to its current age.

---

### Real-World Examples

**Seismology — Gutenberg–Richter Law:** ~10× more magnitude 3 earthquakes than magnitude 4. Linear in log space → classic SOC signature.

**Neuroscience — Neuronal avalanches:** Cascades of neural activity follow power-law distributions, enabling optimal information flow while avoiding pathological synchronization (e.g., seizures).

**Conflict and War:** War sizes (fatalities) follow power laws. Small conflicts and world wars arise from the same mechanism. Outcome depends on system state at ignition.

---

### What Power-Law Distributions Enable

**Capability — Response at every scale:** The system processes inputs of any magnitude using the same mechanism. A small policy adjustment and a major institutional reorganization are produced by the same dynamics, just at different scales. This is what makes the system maximally capable — there is no input size for which the system has no response pathway.

**Cost of the alternative:** A Gaussian system can engineer for a "worst case" but cannot respond to anything outside its design envelope. It trades capability across scales for predictability at one scale. SOC systems trade that predictability for the ability to deliver power across the full range of demands.

> The presence of a power-law distribution indicates that the system has access to its full configuration space — every scale of response is available to it. Large reorganizations are not anomalies; they are the system using its full range. This is the signature of a system operating at maximum capability rather than one optimized for a narrow operating point.

---

## 2. Diverging Correlation Length

### The Mechanics of Connectivity: From Local to Global

In the study of classical physics and stable engineering, systems are typically designed to be **modular**. This means that the components of the system are relatively independent; what happens in one part of the system has a limited, local effect that diminishes quickly over distance.

However, as a system organizes itself toward **Self-Organized Criticality (SOC)**, these internal boundaries begin to dissolve. The defining relational signature of this transition is the **Diverging Correlation Length**.

The correlation length, denoted by the Greek letter $\xi$ (xi), is a mathematical measure of the distance over which one part of a system influences or "synchronizes" with another.

- In a stable system → $\xi$ is small
- In an SOC system → $\xi$ diverges (approaches system size)

At the critical point, every part of the system is functionally connected to every other part.

---

### The Mathematical Framework: Exponential vs. Power-Law Decay

**Sub-Critical State (Exponential Decay):**

$$
G(r) \approx e^{-r/\xi}
$$

- Rapid decay
- Local containment
- Finite correlation length

**Critical State (Power-Law Decay):**

$$
G(r) \approx r^{-(d-2+\eta)}
$$

- Heavy-tailed decay
- Long-range dependence
- Effectively infinite correlation length

---

### The Mechanism: The Loss of Modularity

Systems tend toward SOC due to efficiency pressures: removal of buffers, increased connectivity, faster communication.

**Benefit:** Global coordination, rapid signal propagation.

**Cost:** System brittleness, cascading failures.

---

### The Graph-Theoretic View

Correlation length has a natural expression in **graph theory**, which provides the operational framework for measuring it in real systems. When a system is modeled as a network — nodes connected by weighted edges — diverging $\xi$ manifests as measurable changes in network structure:

**Spectral gap narrowing.** The spectral gap is the difference between the two largest eigenvalues of the network's adjacency or Laplacian matrix. In a modular system, this gap is wide — distinct communities are weakly coupled. As the system approaches criticality, the gap narrows toward zero, signaling that the network is losing its modular decomposition and behaving as a single connected component.

**Centrality homogenization.** In a sub-critical network, centrality measures (degree, betweenness, eigenvector) vary widely — some nodes are hubs, others are peripheral. As $\xi$ diverges, centrality distributions flatten. Every node approaches equal importance because perturbations at any node can reach any other. The network transitions from hub-and-spoke to fully meshed influence.

**Community dissolution.** Community detection algorithms (modularity maximization, spectral clustering) find fewer, larger communities as the system approaches criticality. The number of detected communities decreases and modularity scores drop — the boundaries between groups dissolve.

**Path length compression.** Average shortest path length decreases as new connections form under efficiency pressure. Information and stress propagate in fewer hops, amplifying the effective range of local perturbations.

These graph-theoretic diagnostics are directly computable from empirical data — trade networks, institutional linkages, communication flows — making them a practical bridge between the abstract concept of correlation length and observable governance structure.

**Edge-type separation.** The network diagnostics above should be run on each edge type separately (trade layer, geographic layer, colonial/linguistic/institutional lineage layer) rather than on an aggregated network. Different edge types carry different types of stress: a financial contagion propagates via trade and interbank exposure, not via geographic proximity; a political shock may propagate via colonial-era institutional ties that do not appear in trade data. Running diagnostics per layer and checking whether they agree has two benefits: (1) disagreement between layers reveals which channels actually carry governance stress — itself an empirical finding; (2) agreement across layers strengthens the correlation-length finding considerably, as the signal is robust to the choice of connectivity measure. Aggregating before testing risks a false negative — concluding that correlation length does not diverge when in fact it diverges on one layer but is masked by noise on others.

---

### Empirical Testing

**Mutual Information ($I$).** Measures shared information between variables. Rising $I$ across distant nodes → increasing correlation length.

**Susceptibility ($\chi$):**

$$
\chi \propto \xi^{2-\eta}
$$

- Large $\xi$ → massive system response
- Small perturbations → large-scale reactions

**Network diagnostics.** Track spectral gap, modularity score, and average path length over time. Converging trajectories (narrowing gap, falling modularity, shrinking paths) indicate diverging correlation length in the underlying system.

---

### Real-World Manifestations

**Financial Systems:** Market sectors become highly correlated. The system behaves as a single unit. Network analysis of interbank lending reveals spectral gap collapse preceding crises.

**Social Media:** Information cascades across global networks. Loss of local containment. Community structure dissolves as viral content overrides topic boundaries.

**Power Grids:** Interconnected infrastructure where local failure triggers cascading blackouts. Graph centrality measures predict which failures will propagate.

---

### What Diverging Correlation Length Enables

**Capability:** System-wide power delivery. A perturbation in one sector reaches every other sector through the lattice. Coordinated response, rapid reorganization, maximum information processing.

**Cost of the alternative:** A modular system with short correlation length cannot deliver power at scale. Local responses stay local. The system processes demands one sector at a time rather than mobilizing the whole lattice.

> Diverging correlation length is the mechanism by which a system at criticality delivers power across all scales. The transition from modular independence to fully integrated interdependence is what makes maximum capability possible. A small perturbation can produce a system-wide reorganization because the lattice is structurally capable of transmitting it — that capability is the point, not a side-effect to be minimized. Graph theory provides the tools to measure this transition empirically.

---

## 3. Scale Invariance (Dynamics)

### The Functional Proof: A System Without a Ruler

If the first signature is about the *size* of events and the second is about the *connectivity* of the system, the third signature—**Scale Invariance**—is about the **behavior** of the system across time and space.

In traditional systems, there is a characteristic scale (e.g., heart rate, resonant frequency). In SOC systems, this "ruler" disappears. Whether observed over seconds or decades, at local or global levels, the statistical behavior remains identical.

---

### The Mathematical Framework: Self-Similarity

$$
f(kx) = k^n f(x)
$$

- Scaling input by factor $k$ scales output proportionally
- Only power-law functions satisfy this condition

This creates a direct link to Signature 1: power-law distributions ⇒ scale-invariant dynamics.

**Self-Similarity.** Time series appear statistically identical across scales. Micro fluctuations resemble macro trends. There is no distinguishable "zoom level."

---

### The Temporal Signature: 1/f Noise (Flicker Noise)

$$
S(f) \propto \frac{1}{f^\beta}
$$

- Typically $\beta \approx 1$
- Also called **Pink Noise**

**Interpretation:** Between white noise (random) and brown noise (over-correlated). Indicates long-range temporal correlation — the system retains "memory" across time.

---

### Empirical Testing

**Hurst Exponent ($H$):**

- $H = 0.5$ → random walk
- $H < 0.5$ → mean-reverting
- $H > 0.5$ → **persistent, scale-invariant (SOC)**

**Detrended Fluctuation Analysis (DFA):** Measures scaling behavior across time windows. A constant scaling exponent confirms scale invariance.

---

### Real-World Manifestations

**Internet Traffic:** Bursty, clustered arrivals. Scale-invariant across milliseconds to hours.

**Biological Systems:** Heart rate variability follows 1/f patterns. Loss of variability indicates a pathological state.

**Financial Markets:** Volatility exhibits scale invariance. Short-term crashes resemble long-term cycles.

---

### What Scale Invariance Enables

**Capability:** The same dynamics operate at every temporal scale, so the system delivers governance from the daily-decision scale to the multi-decade institutional scale through one set of mechanisms rather than separate machinery for each timeframe. This is maximum throughput per unit of institutional complexity.

**Implication for control:** Fixed-scale controls — regulations designed for a particular event size or frequency — cannot work in a scale-invariant system. Suppressing small fluctuations does not stabilize the system; it strips away the small avalanches through which capability is delivered, redirecting energy into larger events. Effective governance respects the scale-invariant structure rather than imposing a preferred scale on it.

> Scale invariance indicates that the system delivers power identically across all levels of observation. Local mirrors global because both are produced by the same generating dynamics. Controls that target one scale interfere with capability delivery at every other scale.

---

## 4. Fractal Structure (Topology)

### The Architecture of Criticality: The Physical Map

If **Scale Invariance** (Signature 3) describes the behavior of a system across time, **Fractal Structure** describes its physical or network topology.

In systems exhibiting **Self-Organized Criticality (SOC)**, structure is not smooth or Euclidean. Instead, it is **fractal**—self-similar across scales. This structure is the accumulated result of cascades (avalanches) occurring across all magnitudes.

---

### The Mathematical Framework: Fractional Dimensions

$$
N \propto r^{-D}
$$

- $D$ = fractal (Hausdorff) dimension
- Non-integer dimensionality

Examples: Coastline ~1.25. Lung surface ~2.9.

**Interpretation:** Clusters within clusters. Hierarchical organization. Structural scale invariance.

---

### The Mechanism: Emergence and Renormalization

Fractal structures arise via bottom-up processes:

1. Local interaction
2. Cascading reconfiguration
3. System pruning and reinforcement

Driven by infinite correlation length (Signature 2) and repeated avalanche dynamics (Signature 1).

---

### Empirical Testing

**Box-Counting Method:** Count occupied boxes at scale $\epsilon$. A power-law relationship confirms fractality.

**Coarse-Graining:** Aggregate nodes into super-nodes. Re-measure system properties. Invariance confirms fractal structure.

**Network Spectral Analysis:** Eigenvalue distribution reveals topology type.

---

### Real-World Manifestations

**River Networks:** Branching patterns identical across scales.

**Urban Systems:** Clusters and transport-driven expansion.

**Biological Systems:** Circulatory and respiratory branching networks.

**Governance Systems:** Administrative hierarchies exhibit fractal nesting — national ministries contain regional offices, which contain district offices, which contain local service points. If governance is at criticality, the statistical properties of service delivery, resource allocation, and institutional performance should be self-similar across these levels. A country's subnational development pattern (measurable via indices like the Subnational Human Development Index) reveals whether governance structure is fractal: does the distribution of development across districts within a region mirror the distribution across regions within the country? If so, the topology encodes the same cascade dynamics at every administrative scale — the hallmark of fractal structure in a governance lattice.

---

### What Fractal Structure Enables

**Capability:** Optimal distribution efficiency at every scale simultaneously. Minimal resource expenditure for maximum reach. Governance hierarchies that deliver service from national ministry down to local office through self-similar structure rather than redundant parallel systems.

**Cost of the alternative:** A system without fractal structure must build separate mechanisms for each scale of operation — national policy, regional implementation, local delivery — each with its own overhead. Capability per unit of resource drops sharply.

> Fractal structure indicates that the system's topology is a direct imprint of its cascade dynamics. Structure encodes history, local mirrors global, and the same organizational principle delivers governance at every administrative scale. This is how a system at criticality achieves maximum throughput per unit of institutional mass — by reusing the same structural pattern across scales rather than building parallel mechanisms.

---

## 5. Fat-Tailed Changes (Leptokurtosis)

### The Volatility of the Poised State: The Nature of the "Jump"

Signature 5 examines incremental fluctuations in systems exhibiting **Self-Organized Criticality (SOC)**.

In stable systems, changes follow a **Gaussian distribution** where small deviations dominate. In SOC systems, changes follow **fat-tailed (leptokurtic) distributions** where large jumps occur frequently and volatility is dominated by extremes.

---

### Mathematical Framework: Kurtosis

- Gaussian baseline: $K = 3$
- SOC systems: $K \gg 3$

High kurtosis implies concentration near the mean combined with heavy tails producing extreme events.

**Lévy Stability:** Fat tails persist across aggregation. Step changes are scale-free.

---

### Magnitude vs. Change

- Signature 1 → total event size
- Signature 5 → step-by-step volatility

SOC systems exhibit both: large events and sudden jumps in progression.

---

### Mechanism: Loss of Damping

Fat-tailed changes arise when a system's **ordering forces** — the mechanisms that absorb stress, enforce norms, and dissipate energy — weaken relative to the excitatory pressures driving the system. In the SOC sandpile, damping is what causes grains to topple and exit at the boundary rather than accumulating without limit. When damping is adequate, perturbations are absorbed locally and changes are small. When damping erodes, perturbations propagate through the system's now-extended correlation length (Signature 2) and produce sudden, large transitions.

This is directly observable in governance systems. Functioning institutions — rule of law, regulatory enforcement, judicial independence — act as damping forces. They absorb social and economic stress locally: a contract dispute is resolved in court, a bank failure is contained by deposit insurance, a protest is channeled through political representation. When these ordering mechanisms degrade, the same perturbations propagate unchecked. A contract dispute becomes a property rights crisis. A bank failure triggers a financial contagion. A protest escalates into regime change. The step-by-step volatility of governance indicators shifts from Gaussian to fat-tailed — not because the perturbations themselves changed, but because the system lost its capacity to damp them.

The critical distinction: fat tails are not caused by larger shocks. They are caused by the same shocks propagating through a system that can no longer contain them.

---

### Empirical Testing

**Kurtosis Tracking:** Monitor rolling kurtosis. Rising values indicate instability.

**Power Spectral Density:** Confirms fat-tail structure via burst aggregation. (Note: Signature 3 also uses PSD, but to measure temporal memory via the $\beta$ exponent. Same instrument, different quantity — Sig 3 reads the *slope* as a memory diagnostic; Sig 5 reads the *shape* as a tail-structure diagnostic.)

**Wild Randomness Test:** Extreme events dominate variance. Non-Gaussian behavior confirmed.

---

### Real-World Manifestations

**Power Grids:** Voltage spikes under stress.

**Hydrology:** River levels exhibit extreme jumps.

**Financial Markets:** Flash crashes and rapid recoveries.

---

### What Fat-Tailed Changes Enable

**Capability:** The system reorganizes through jumps of any size — small adjustments when small adjustments suffice, major reorganizations when conditions demand them. This is how capability is delivered across the full range of operating conditions. A system limited to incremental change cannot respond to demands that require structural reorganization.

**Implication for measurement:** Average behavior is not the operating point — it is a statistical artifact of integrating across many different reorganization events. Models that fit the average and treat the tails as noise are fitting the wrong quantity. The tails *are* the capability delivery mechanism.

> Fat-tailed changes indicate that the system delivers power through reorganizations of every size, with no preferred jump scale. Extremes do not break the system — they are how the system handles inputs that exceed local processing capacity. Building risk models around average behavior misses where the work is actually done.

---

## Summary

The five signatures form a coherent diagnostic set:

| # | Signature | What It Measures | Key Diagnostic |
|---|-----------|-----------------|----------------|
| 1 | Power-Law Distribution | Event size distribution | Log-log linearity, MLE exponent |
| 2 | Diverging Correlation Length | System-wide connectivity | Mutual information, susceptibility, network diagnostics per edge layer |
| 3 | Scale Invariance | Behavioral self-similarity across scales | Hurst exponent, DFA |
| 4 | Fractal Structure | Topological self-similarity | Box-counting, coarse-graining |
| 5 | Fat-Tailed Changes | Incremental volatility | Kurtosis, power spectral density |
| — | Branching Ratio (σ) | Cascade propagation dynamics | σ = 1 at criticality (exact value); data-constrained |
| — | Inter-Event Times | Temporal clustering of events | Power-law or stretched exponential waiting times |

Each signature is independently testable, but they are not independent phenomena. Power-law event sizes (1) arise because correlation length diverges (2). Scale invariance in dynamics (3) and structure (4) are the temporal and spatial consequences. Fat-tailed changes (5) are the volatility fingerprint of a system poised at the critical point. Finding all five in a system is strong evidence of Self-Organized Criticality.

---

## Complementary Diagnostics

The five signatures characterize the *shape* of event distributions (Sig 1, 5), the *spatial reach* of coupling (Sig 2), and the *self-similarity* of structure and dynamics across scales (Sig 3, 4). Two additional diagnostics complement these by measuring aspects of criticality that the five do not directly capture: the *mechanics* of perturbation propagation and the *temporal structure* of event sequences.

### Branching Ratio (σ)

The branching ratio measures the average number of subsequent events triggered by a single event. It captures the *propagation dynamics* of cascades — whether a perturbation decays, sustains, or amplifies as it moves through the system step by step.

$$
\sigma = \frac{\text{number of events at generation } t+1}{\text{number of events at generation } t}
$$

At criticality, $\sigma = 1$ exactly — each event triggers, on average, exactly one subsequent event. This is the only SOC diagnostic with an exact theoretically predicted critical value, not a range or threshold:

- $\sigma < 1$ — sub-critical. Perturbations decay. Cascades die out. The system damps faster than it propagates.
- $\sigma = 1$ — critical. Cascades are sustained indefinitely. The system is poised between decay and amplification.
- $\sigma > 1$ — super-critical. Perturbations amplify. Cascades grow exponentially until the system's capacity is exhausted.

**Relationship to the five signatures:** The branching ratio is the *mechanism* that produces Signatures 1 and 5. When $\sigma = 1$, cascades at all scales are possible — generating power-law event distributions (Sig 1) and fat-tailed changes (Sig 5). When $\sigma \neq 1$, cascades are either truncated (sub-critical) or explosive (super-critical), distorting those signatures.

**Relationship to the activation threshold:** The branching ratio is arguably the most direct diagnostic for the lattice activation threshold (see *Activation Threshold* working document). In a pre-SOC system — one whose lattice connectivity is insufficient for system-spanning cascades — $\sigma < 1$ always, regardless of O-E balance. The activation threshold is the point where $\sigma = 1$ becomes structurally achievable for the first time.

**Data requirement:** Computing σ cleanly requires high-frequency, event-level data with sequential structure — identifying which events triggered which subsequent events. ACLED (daily conflict events) would be ideal but is deferred. EM-DAT (disaster sequences) and Laeven & Valencia (financial crisis cascades) can provide rough approximations for disaster and financial domains respectively, but neither has the temporal resolution or causal linkage for a reliable σ estimate. This is a named gap: the diagnostic is theoretically precise but data-constrained.

### Inter-Event Time Distribution

Signature 1 tests the distribution of event *magnitudes*. The complementary question is the distribution of event *timing* — the waiting times between successive events. Together, magnitude and timing fully characterize the point process.

At criticality, inter-event times follow a **power-law or stretched exponential distribution**:

$$
P(\Delta t) \propto \Delta t^{-\gamma} \quad \text{or} \quad P(\Delta t) \propto e^{-(\Delta t / \tau_0)^\beta}
$$

This means events cluster in time — bursts of activity separated by long quiescent periods. There is no characteristic waiting time, just as there is no characteristic event size (Sig 1) or characteristic correlation length (Sig 2).

**Below the activation threshold:** Inter-event times should be approximately exponential (Poisson process) — events occur randomly and independently because the lattice cannot sustain correlated cascading. The shift from exponential to power-law waiting times is a potential marker of threshold crossing.

**Sub-critical systems:** Events are rare and temporally uncorrelated (strong ordering suppresses cascading). Waiting times are long and approximately exponential.

**Super-critical systems:** Events are frequent and clustered but without the power-law structure — more like continuous noise than structured bursts.

**Data availability:** Unlike the branching ratio, inter-event times are computable with currently available data. EM-DAT provides disaster event dates, and Laeven & Valencia provides crisis onset years. Inter-crisis intervals for banking, currency, and sovereign debt crises are directly computable from existing Phase 0b data. This diagnostic can be tested during backtesting without additional data acquisition.

---

## From Theory to Governance Testing

These five signatures are general properties of any system at criticality — they arise in sandpiles, earthquakes, neural networks, and financial markets. The question this project asks is whether governance systems exhibit them too.

The *SOC Model Architecture* defines six measurable components of governance (Order, Excitation, Mass, Internal Energy, Entropy, Density) and derives a criticality distance ($C_d$) from their interaction. But before that index can be trusted, the underlying claim — that governance systems operate at or near criticality — must be tested empirically. That is the role of the *Grounding the Criticality Hypothesis* document, which specifies a diagnostic function for each signature, with acceptance criteria and testing protocols applied to Quality of Government time-series data.

The grounding layer is deliberately independent from the index components. The signatures are tested using variables that do not feed into $C_d$, preventing circular validation. If the signatures are present, the model's theoretical foundation is supported. If they are absent, no amount of index construction can rescue the claim. The signatures come first.
