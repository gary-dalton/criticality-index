# Experiment 04: Overloading the Joined System — The Absorbing Barrier

> **See also:** [`01_03_manna_overtopping.md`](01_03_manna_overtopping.md) is a concrete Manna-based implementation of the absorbing-barrier concept via the overtopping mechanism (structural integrity field σ). Where this doc abstractly describes "lattice degradation" rules, 01_03 gives specific mathematical dynamics, specific parameter sweeps (T, α, recovery_rate), and specific falsifiability predictions. Consider 01_03 the operational version of what this doc lays out conceptually.

## Purpose

Push the sandpile-on-percolation-lattice system past criticality to determine whether an irreversible dissolution boundary (absorbing barrier) exists and can be measured. The model architecture (§5.5) claims that a super-critical excursion can destroy not just the current configuration but the system's capacity to reconstitute. This experiment tests that claim computationally.

---

## Conceptual Framework

Experiment 03 established the activation threshold (floor): below p*, SOC cannot emerge. This experiment looks for the ceiling: conditions under which the system breaks irreversibly.

The architecture defines three relevant concepts:

1. **Super-criticality** — E > O, system heating up, but recoverable
2. **Absorbing barrier** — point of no return, entropy collapses, system cannot reconstitute
3. **Fracture vs. ruin** — system breaks into viable pieces (fracture, recoverable) vs. pieces that cannot function (ruin, irreversible)

The sandpile analogy: if you drive the system hard enough, does the lattice itself degrade? Does the system reach a state from which it cannot return to criticality?

---

## The Model: Overloaded Sandpile with Lattice Degradation

### Approach 1: Increased Driving Rate

Break the separation of timescales. Instead of one grain per timestep (infinitely slow driving), add multiple grains before allowing topplings to complete.

| Parameter | Range | Effect |
|-----------|-------|--------|
| grains_per_step | 1, 2, 5, 10, 50 | Ratio of driving rate to relaxation rate |

**At grains_per_step = 1:** Standard BTW, SOC expected.
**At high grains_per_step:** System cannot relax between inputs. Energy accumulates without bound. Does the system enter a qualitatively different regime?

**Measure:** All SOC signatures as a function of grains_per_step. Is there a threshold where signatures collapse?

### Approach 2: Reduced Dissipation

Reduce the rate at which energy leaves the system. In the standard BTW, energy exits only at boundaries. Modifications:

| Variant | Mechanism | Effect |
|---------|-----------|--------|
| Reflecting boundaries | Grains at edge topple back inward | No energy exit at all |
| Partial reflection | Fraction r of boundary grains reflect | Tunable dissipation |
| Bulk dissipation removal | Remove random dissipation sites | Fewer energy exit points |

**Expected:** As dissipation decreases, the system overloads. Energy density increases without bound. At some point, the dynamics change qualitatively.

### Approach 3: Lattice Degradation (The Key Innovation)

Introduce a mechanism where extreme overloading damages the lattice itself. This is the computational analogue of the absorbing barrier — the system loses structural capacity.

**Degradation rule:** When a site topples more than k_damage times in a single avalanche (or accumulates more than z_damage total height), it becomes permanently inactive. This removes a node from the lattice, reducing connectivity.

| Parameter | Default | Interpretation |
|-----------|---------|----------------|
| k_damage | 10, 20, 50 | Toppling count threshold for degradation |
| z_damage | 20, 50, 100 | Height threshold for degradation |
| repair_rate | 0, 0.001, 0.01 | Probability per timestep that a degraded site recovers |

**This creates a feedback loop:**
1. Overloading causes large avalanches
2. Large avalanches damage sites (degrade lattice)
3. Degraded lattice changes dynamics
4. Changed dynamics may cause more overloading (positive feedback → ruin) or less (negative feedback → fracture and recovery)

**The absorbing barrier exists if:** There is a driving intensity above which lattice degradation cascades — each damaged site increases stress on neighbors, causing more damage, until the lattice collapses below the activation threshold p*. At that point, SOC is no longer possible and the system cannot self-repair.

---

## What We Measure

### Phase Diagram: Driving Rate x Dissipation x Degradation Threshold

The primary output is a phase diagram in the space of (driving_intensity, dissipation_rate, degradation_threshold) showing:

| Region | Behavior |
|--------|----------|
| **SOC** | Standard SOC signatures, stable lattice |
| **Stressed SOC** | SOC signatures present but degraded, occasional site loss, recovery possible |
| **Fracture** | Lattice breaks into disconnected components, each may exhibit local SOC |
| **Ruin** | Lattice degrades below p*, cascading site loss, no recovery → absorbing state |

### Specific Diagnostics

#### 4a. Lattice Health Time Series

Track the fraction of active sites over time: p_eff(t) = N_active(t) / L^2.

**Expected in SOC region:** p_eff stable at initial value.
**Expected in fracture region:** p_eff drops then stabilizes above p*.
**Expected in ruin region:** p_eff drops below p* and continues declining → absorbing state.

**Key plot:** p_eff(t) trajectories for different driving intensities. The absorbing barrier is the driving intensity where p_eff crosses p* irreversibly.

#### 4b. Recovery Test

After the system reaches steady state (or ruin), remove the excess driving (return to standard BTW conditions). Can the system recover SOC?

**Recoverable (fracture):** SOC signatures return on the remaining lattice.
**Irrecoverable (ruin):** Lattice is below p*. No spanning cluster. SOC cannot return even with normal driving. The system has crossed the absorbing barrier.

#### 4c. Entropy Proxy

Track the number of distinct height values across the lattice and the spatial distribution of heights.

**SOC:** Broad distribution, many height values, spatially heterogeneous.
**Approaching ruin:** Distribution narrows, heights concentrate at extremes (very high on remaining sites), spatial diversity collapses.
**Post-ruin:** Few active sites, trivial dynamics. Entropy → 0.

This maps directly to the architecture's claim that the absorbing barrier is where S → 0.

#### 4d. Cascade Morphology

Track how avalanche shapes change as the system is overloaded.

**SOC:** Power-law distributed sizes, fractal spatial footprints.
**Stressed SOC:** Larger average events, spatial footprints start to be constrained by damaged regions.
**Near ruin:** Avalanches forced through narrow corridors between damaged zones. Spatial structure becomes elongated/channelized rather than fractal.

#### 4e. Fragmentation Analysis

When the lattice breaks apart, characterize the fragments.

**Fracture with viable fragments:** Multiple components above local p_c, each showing SOC-like dynamics at reduced scale. System has broken but pieces work.
**Ruin:** All components below local p_c. No fragment can sustain SOC.

**Measure:** Component size distribution after damage. Compare to percolation cluster distribution from Experiment 02. Does the post-damage lattice look like a sub-critical percolation lattice?

---

## The Absorbing Barrier as a Phase Transition

If the absorbing barrier exists, it should exhibit signatures of a phase transition in its own right:

- **Order parameter:** Fraction of lattice surviving (p_eff), or presence/absence of SOC signatures
- **Critical slowing down:** Near the barrier, recovery from perturbations takes longer
- **Hysteresis:** The driving intensity required to cross the barrier (ruin) is higher than the intensity required to recover from it (because recovery requires rebuilding lattice above p*)
- **Universality:** The barrier transition may belong to a known universality class (directed percolation of the lattice itself?)

Testing for these would establish the absorbing barrier as a genuine phase transition rather than a gradual degradation.

---

## Connection to the Model Architecture

| Architecture Concept | Experiment Analogue |
|---------------------|---------------------|
| Absorbing barrier (§5.5) | Driving intensity where p_eff crosses p* irreversibly |
| Fracture vs. ruin (§5.5) | Lattice breaks into viable pieces vs. collapses below p* |
| S → 0 at dissolution | Entropy proxy collapses as lattice degrades |
| Distributed vs. concentrated entropy | Fragments above/below local p_c |
| Lindy-weighted mass | Sites that survive degradation have demonstrated structural fitness |
| Trajectory (d1, d2) | dp_eff/dt and d²p_eff/dt² as early warning of barrier approach |
| Non-ergodicity | Ensemble of realizations shows path-dependent ruin — same average p_eff can correspond to recoverable or irrecoverable states |

---

## Negative Controls

### Control 1: No Degradation

Standard BTW with increased driving but no lattice damage. The system should overload but never reach an absorbing state — it can always recover when driving is reduced.

**Purpose:** Confirms that the absorbing barrier requires structural damage, not just high energy.

### Control 2: Instant Repair

Degradation occurs but repair_rate = 1.0 (immediate recovery). The system should never reach ruin because damaged sites recover before cascading damage can accumulate.

**Purpose:** Confirms that the absorbing barrier requires damage accumulation, not just damage.

### Control 3: Uniform Degradation

Instead of damage-driven degradation, randomly remove sites at a fixed rate independent of dynamics. Compare the trajectory to damage-driven degradation.

**Purpose:** Distinguishes dynamically-driven ruin (positive feedback between overload and damage) from externally-imposed degradation. The absorbing barrier is only interesting if the system drives itself across it.

---

## Experimental Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| Phase diagram | DataFrame + heatmap | SOC/fracture/ruin regions in parameter space |
| p_eff trajectories | DataFrame + plot | Lattice health over time at each driving intensity |
| Recovery test results | DataFrame | Can the system recover from each state? |
| Entropy time series | DataFrame + plot | Configurational diversity as system degrades |
| Fragment analysis | DataFrame | Post-damage component sizes and SOC capability |
| Barrier location | Named tuple | Driving intensity at barrier for each parameter set |
| Early warning diagnostics | DataFrame | d1, d2, critical slowing down near barrier |

---

## Implementation Plan

1. **Build the overloaded sandpile** — `work/experiments/validation/overloaded_sandpile.jl`
   - `btw_overloaded(L, p, driving_rate, dissipation, damage_threshold, repair_rate; seed)`
   - Track lattice state evolution: which sites are active, when they degrade
   - Record avalanche catalogs and lattice health at each step

2. **Build barrier detection** — extend `work/experiments/validation/diagnostics.jl`
   - `lattice_health(active_sites_history)` → p_eff(t), dp_eff/dt, d²p_eff/dt²
   - `entropy_proxy(height_field)` → configurational diversity measure
   - `fragment_viability(components, p_c)` → per-fragment SOC capability
   - `recovery_test(system_state)` → can SOC resume?
   - `find_absorbing_barrier(sweep_results)` → barrier location in parameter space

3. **Run experiments** — `work/experiments/validation/04_run_barrier.jl` or notebook
   - Sweep driving intensity with and without degradation
   - Recovery tests at each parameter point
   - Entropy and fragment analysis
   - Phase diagram construction
   - Negative controls

---

## Success Criteria

The experiment succeeds if:

1. An absorbing barrier is identifiable: a driving intensity above which the lattice degrades irreversibly below p*
2. The distinction between fracture (recoverable) and ruin (irrecoverable) is measurable
3. Entropy proxy collapses correlate with irreversibility
4. Negative controls confirm that the barrier requires both structural damage and positive feedback
5. Early warning diagnostics (trajectory, critical slowing down) provide lead time before barrier crossing

The experiment is inconclusive if no clear barrier exists (gradual degradation without a threshold) or if all damage is always recoverable. Either outcome is informative — it would mean the absorbing barrier concept needs refinement.

---

## Dependencies

- Experiments 01-03 validated (sandpile, percolation, activation threshold)
- Activation threshold p* from Experiment 03 (defines the floor below which SOC is impossible)
- Julia packages: same as Experiments 01-03

## Next Experiment

**Experiment 05: CSOC and ISOC Signatures** — apply suppression (capacitive) and amplification (inductive) to the validated sandpile system. Test whether the distorted signatures predicted by the CSOC and ISOC frameworks are detectable and distinguishable from natural SOC and from each other.
