# Experiment 06: Coupled SOC Systems — Energy Leakage Between Lattices

## Purpose

Test what happens when two (or more) SOC systems are coupled — where avalanche energy from one system leaks into another. This goes beyond slow driving (one grain at a time) to model the reality that perturbations arriving from a neighbor are not single grains but cascades of varying size. A financial crisis, a war, a refugee flow — these are not point inputs. They are another system's avalanche landing on your lattice.

This experiment tests whether coupled SOC systems exhibit emergent behaviors not present in isolated systems, and whether the coupling itself can push a system into CSOC-like or ISOC-like regimes (detection categories per [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md)). The framework prediction is that *coupling itself* is a candidate mechanism for the amplified-cascade regime described in [`../ideas/liquefaction.md`](../ideas/liquefaction.md) — neighbor avalanches landing on System B act as bursty amplification from outside.

---

## Motivation

The architecture models between-country coupling through the network diffusion term in E and the density component (rho). But the current formulation treats neighbor influence as a continuous, smooth signal — a term added to E. Real inter-system coupling is bursty: nothing for years, then a neighbor's avalanche dumps a large perturbation onto your lattice all at once.

This experiment asks:
- Does coupling change the SOC signatures of the individual systems?
- Does it create system-spanning avalanches across the coupled pair?
- Can coupling push a system off criticality even when its internal O-E balance is fine?
- Does the coupling strength determine whether energy transfer looks like slow driving or like amplification?

---

## The Model: Two Sandpiles with Boundary Coupling

### Basic Configuration

Two L x L BTW sandpiles (System A and System B) on separate lattices. Each runs standard BTW dynamics internally. The coupling is at the boundary: when an avalanche in System A reaches System A's boundary, instead of grains falling off (dissipating), a fraction of them are deposited onto System B's boundary sites (and vice versa).

```
 System A          System B
┌──────────┐      ┌──────────┐
│          │      │          │
│  BTW     │─────▶│  BTW     │
│  sandpile│◀─────│  sandpile│
│          │      │          │
└──────────┘      └──────────┘
   boundary        boundary
   coupling        coupling
```

### Coupling Parameters

| Parameter | Range | Interpretation |
|-----------|-------|----------------|
| coupling_fraction (c) | 0, 0.1, 0.25, 0.5, 0.75, 1.0 | Fraction of boundary-exiting grains sent to neighbor vs. dissipated |
| coupling_symmetry | symmetric, asymmetric | Same c both directions, or c_AB ≠ c_BA |
| coupling_delay | 0, 1, 5, 10 | Timesteps delay before leaked grains arrive (instantaneous vs. lagged) |
| coupling_topology | boundary, random, hub | Where leaked grains land on the receiving system |

**c = 0:** No coupling. Two independent sandpiles. Recovers Experiment 01 on each.
**c = 1:** Full coupling. No energy dissipates at the shared boundary — all boundary grains transfer to the neighbor. The two systems effectively become one larger system with altered boundary conditions.

### Coupling Topology Variants

**Boundary coupling:** Grains exit System A's right edge and enter System B's left edge at the corresponding row. Geographically adjacent — stress transfers to the nearest sites.

**Random coupling:** Grains exit System A's boundary and land on random sites in System B. Models long-range connections (financial flows, trade shocks) where the receiving point is not geographically predictable.

**Hub coupling:** Grains exit System A and concentrate on a small number of high-centrality sites in System B. Models the reality that international shocks often enter through capital cities, major ports, or financial centers — not uniformly.

### Extended Configurations

**Multiple systems:** Chain of N sandpiles (A → B → C → ...) or ring topology (A → B → C → A). Does cascade energy propagate across multiple systems? Does it amplify or attenuate?

**Heterogeneous systems:** Systems of different sizes (L_A ≠ L_B), different thresholds, or different internal dynamics. A large system coupled to a small one. A system at criticality coupled to one below the activation threshold (from Experiment 03).

**Asymmetric coupling:** c_AB >> c_BA. One system dumps energy into the other but doesn't receive much back. Models unequal power relationships — a major economy's crisis affecting a dependent neighbor more than the reverse.

---

## What We Measure

### Per-System Diagnostics

Run the full Experiment 01 diagnostic battery on each system independently:
- Power-law exponent tau
- Branching ratio sigma
- Hurst exponent H
- Excess kurtosis
- PSD / 1/f noise

**Question:** Does coupling change the SOC signatures of the individual systems?

### Cross-System Diagnostics

#### 6a. Cross-System Avalanche Propagation

Track whether an avalanche in System A triggers an avalanche in System B.

**Define:** A cross-system event occurs when grains leaked from A's avalanche trigger topplings in B within a coupling_delay window.

**Measure:**
- Frequency of cross-system events as a function of c
- Size of the resulting avalanche in B as a function of the triggering avalanche size in A
- Whether cross-system cascades can "bounce" — A triggers B triggers A

**Expected:** At low c, cross-system events are rare and small. At high c, A and B effectively cascade together.

#### 6b. Combined System Statistics

Treat the coupled pair as a single system. Measure avalanche sizes as the sum of topplings across both systems for correlated events.

**Question:** Does the combined system exhibit SOC? At what coupling strength?

**Expected:** 
- At c = 0: two independent SOC systems
- At intermediate c: signatures may degrade — the coupling is neither slow driving nor instantaneous
- At c = 1: the combined system may recover SOC at a larger effective system size

#### 6c. Correlation Between Systems

Measure the cross-correlation of avalanche activity between A and B.

**Expected:** Correlation increases with c. At high c, the systems synchronize — their avalanche activity becomes coupled, analogous to diverging correlation length (Signature 2) but between systems rather than within one.

#### 6d. Coupling as Amplification Mechanism

**Key question:** At intermediate coupling, does System B experience the leaked energy as amplification (producing an ISOC-like signature) rather than slow driving?

If A has a large avalanche and dumps many grains onto B simultaneously, this is not a single grain addition — it's a burst that could trigger and sustain cascades in B beyond what B's internal stored energy would support. This is structurally similar to the amplified-cascade mechanism formalized in [`../ideas/liquefaction.md`](../ideas/liquefaction.md).

**Test:** Compare B's signature profile under coupling to:
- Experiment 01 (natural SOC, no coupling)
- Experiment 05 Model C (amplification without coupling; see [`05_suppression_amplification.md`](05_suppression_amplification.md))

If B's signatures match the ISOC-like bundle (inflated large events, history-dependent σ, steepened PSD) per [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md) Part III, coupling can produce ISOC-like dynamics without any explicit amplification mechanism — a significant claim: amplification need not be added by fiat, it can emerge from coupling topology alone.

#### 6e. Coupling-Induced Sub-criticality

**Key question:** Can coupling push a system below criticality?

If System A is much larger than B, A's avalanches may overwhelm B — flooding it with energy it cannot process. Conversely, if coupling drains energy from A (grains leave to B instead of dissipating), A may lose the dissipation needed to maintain criticality.

**Test:** Run with asymmetric sizes (L_A = 256, L_B = 64) and measure SOC signatures on each as a function of c.

#### 6f. Cascade Chain Length

In the multi-system chain (A → B → C → ...), how far does a cascade propagate?

**Measure:** Given an avalanche originating in A, how many downstream systems experience cross-system events?

**Expected:**
- At low c: cascades die out quickly (attenuate)
- At critical c: cascades propagate indefinitely through the chain (this would itself be a percolation transition in the inter-system network)
- At high c: cascades propagate and potentially amplify

**This is a higher-order activation threshold:** not just "does a single lattice support cascades?" but "does a network of lattices support cross-system cascades?"

---

## Connection to Governance

This experiment models the reality that countries don't exist in isolation. The architecture's network layer (CEPII trade/geographic) provides the coupling topology. The coupling fraction c is related to rho (density/coupling). But the experiment tests something the architecture doesn't currently capture: the *bursty* nature of inter-system coupling.

| Experiment Concept | Governance Analogue |
|-------------------|---------------------|
| Boundary coupling | Geographic neighbors (shared border, refugee flows) |
| Random coupling | Financial contagion (crisis hits unexpected sectors) |
| Hub coupling | Capital city / major port receives the shock |
| Coupling fraction c | Trade openness, financial integration, rho |
| Asymmetric coupling | Dependency relationships (small economy coupled to large) |
| Chain propagation | Contagion across a trade network |
| Cross-system avalanche | A crisis in one country triggering a crisis in another |
| Higher-order activation threshold | Globalization threshold — when is the world system connected enough for system-spanning crises? |

---

## Experimental Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| Per-system SOC diagnostics vs. c | DataFrame | How coupling changes individual system signatures |
| Cross-system event catalog | Arrow file | Which avalanches propagated across systems |
| Size correlation | Plot | Triggering avalanche size vs. resulting avalanche size |
| Combined system signatures | DataFrame | SOC diagnostics for the coupled pair as one system |
| ISOC-like comparison | Table | Does coupling produce ISOC-like signatures (per distorted_soc_signatures.md Part III)? |
| Chain propagation | DataFrame + plot | How far cascades travel in multi-system chain |
| Higher-order threshold | Plot | Cross-system cascade statistics vs. c |

---

## Implementation Plan

1. **Build coupled sandpile** — `work/experiments/validation/coupled_sandpile.jl`
   - `btw_coupled(L_A, L_B, c, coupling_topology; delay, seed)`
   - Track which avalanches are "native" vs. "triggered by coupling"
   - Support chain and ring topologies for multi-system runs

2. **Build cross-system diagnostics** — extend `work/experiments/validation/diagnostics.jl`
   - `cross_system_events(catalog_A, catalog_B, coupling_log)` → correlated event pairs
   - `cascade_chain_length(multi_system_catalogs)` → propagation distance
   - `coupling_signature_comparison(catalog, isoc_like_reference)` → similarity to ISOC-like bundle

3. **Run experiments** — `work/experiments/validation/06_run_coupled.jl` or notebook
   - Sweep c from 0 to 1 for symmetric coupling
   - Asymmetric coupling with heterogeneous system sizes
   - Multi-system chain at selected c values
   - Full diagnostic battery on each configuration
   - Compare to ISOC-like signatures from Experiment 05 (Model C)

---

## Success Criteria

The experiment succeeds if:

1. c = 0 recovers independent SOC (Experiment 01) on each system
2. Coupling produces measurable changes in individual system signatures
3. Cross-system cascades are detectable and their statistics are characterizable
4. The relationship between coupling strength and signature distortion is systematic
5. The comparison to the ISOC-like signature bundle has a clear answer (match or mismatch)
6. In multi-system chains, a higher-order activation threshold is identifiable (or shown not to exist)

---

## Dependencies

- Experiment 01 (sandpile) validated
- Experiment 05 (suppression, amplification, and distinguishability) completed — needed for the ISOC-like signature reference profile
- Experiment 03 (activation threshold) — for testing coupling to sub-threshold systems

## Related Documents

- [`../ideas/liquefaction.md`](../ideas/liquefaction.md) — the primary mechanism formalism for amplified-cascade dynamics; coupling is a candidate mechanism for producing it
- [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md) — Part III specifies the ISOC-like signature bundle to test for in System B
- [`../ideas/architecture_mapping.md`](../ideas/architecture_mapping.md) — connects coupling-induced ISOC-like dynamics to the SOC Model Architecture's E_network term and ρ (coupling density)
- [`../ideas/energy_accounting.md`](../ideas/energy_accounting.md) — coupled-SOC experiments require per-site-of-origin dissipation (an upgrade from the current scalar `n_dissipated`); section "What to instrument and when" specifies the minimum change
- [`05_suppression_amplification.md`](05_suppression_amplification.md) — Model C there is the uncoupled amplification control this experiment compares against

## Future Directions

- **Coupling with lattice degradation** (Experiment 04) — can a neighbor's avalanche damage your lattice?
- **Adaptive coupling** — coupling strength changes based on system state (trade increases during stability, decreases during crisis)
- **Coupling as a mechanism for intentional tuning** — a system deliberately managing its coupling to neighbors to maintain criticality
- **Network of many coupled systems** — moving from pairs to the full multi-layer network topology
