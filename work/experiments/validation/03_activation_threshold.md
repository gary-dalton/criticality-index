# Experiment 03: Sandpile on a Percolation Lattice — Activation Threshold

## Purpose

Test whether a clear activation energy / activation threshold emerges when SOC dynamics (sandpile) are placed on a lattice whose connectivity is controlled by a percolation parameter. This is the computational test of the activation threshold hypothesis: does SOC require a minimum lattice connectivity, and is that threshold identifiable as a phase transition?

This experiment joins the validated tools from Experiments 01 (sandpile) and 02 (percolation).

---

## The Model: BTW Sandpile on a Diluted Lattice

### Definition

Start with an L x L square lattice. Each site is **active** with probability p and **inactive** (permanently empty, cannot hold grains or topple) with probability (1 - p). The BTW sandpile runs only on the active sites.

**Toppling rule (modified):** When an active site topples, grains are distributed only to active neighbors. Grains that would go to inactive neighbors are lost (dissipated). Boundary dissipation still applies at lattice edges.

**Key difference from pure percolation:** The lattice is not just a static structure — it is the substrate on which a dynamical process (the sandpile) operates. The question is: at what connectivity does the dynamical process exhibit SOC?

### Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| L | 128 | Fixed lattice size (large enough for SOC, small enough for sweeps) |
| p_range | [0.3, 1.0] in steps of 0.02 | Occupation probability sweep |
| p_fine | [0.50, 0.70] in steps of 0.005 | Fine sweep around expected transition |
| N_transient | 5 * 10^4 | Grains before recording (per p value) |
| N_record | 5 * 10^5 | Avalanches recorded (per p value) |
| N_realizations | 10 | Independent lattice realizations per p |

### Why This Model

The pure BTW sandpile (Experiment 01) runs on a fully connected lattice (p = 1). Pure percolation (Experiment 02) is a static structure with no dynamics. This model sits at the intersection: a dynamical process on a partially connected substrate.

The activation threshold hypothesis predicts that there exists a critical connectivity p* at or near the percolation threshold p_c ≈ 0.5927 where:
- Below p*: the lattice cannot support system-spanning cascades → no SOC signatures
- Above p*: SOC signatures emerge and strengthen as connectivity increases
- At p = 1: full BTW sandpile (Experiment 01 results recovered)

---

## What We Measure

For each (p, realization), run the sandpile to steady state and compute all diagnostics from Experiment 01.

### Primary Observable: SOC Signature Strength vs. p

For each p value, measure:

| Diagnostic | Below p* | At/Above p* |
|------------|----------|-------------|
| Power-law exponent tau | Undefined or poor fit | Converges to BTW value |
| KS p-value for power law | Low (reject) | High (accept) |
| Branching ratio sigma | < 1 | Approaches 1 |
| Correlation length xi | Short, bounded | Scales with system size |
| Hurst exponent H | Near 0.5 (random) | > 0.5 (persistent) |
| Excess kurtosis | Low | High |
| Maximum avalanche size | Small, bounded | Scales with L |

### The Central Question: Is There a Sharp Transition?

**Hypothesis A (sharp threshold):** SOC signatures turn on abruptly at p* ≈ p_c. Below p*, all signatures are absent. Above p*, all signatures are present. The transition is a phase transition in the dynamical process, coinciding with the structural percolation transition.

**Hypothesis B (gradual emergence):** SOC signatures fade in gradually as p increases. There is no sharp p*. The system becomes "more SOC-like" continuously. This would weaken the activation threshold hypothesis.

**Hypothesis C (offset threshold):** SOC signatures emerge at p* > p_c. The structural spanning cluster is necessary but not sufficient — additional connectivity beyond p_c is needed for the dynamical process to achieve criticality. This would refine the hypothesis.

The experiment discriminates between these by plotting each signature diagnostic as a function of p and looking for the transition shape.

### Detailed Measurements

#### 3a. Avalanche Size Distribution vs. p

At each p, fit P(s) to power law and record tau, xmin, KS p-value.

**Plot:** tau(p) with error bars. Mark p_c on the x-axis.

**Expected if Hypothesis A:** Step function — tau jumps from undefined to ~1.2 at p_c.

**Expected if Hypothesis C:** tau becomes well-defined at some p* > p_c.

#### 3b. Branching Ratio vs. p

At each p, compute sigma from wave-by-wave toppling counts.

**Plot:** sigma(p) with error bars. Mark sigma = 1 and p_c.

**Expected:** sigma < 1 for p < p*, sigma → 1 for p > p*. The crossing point sigma = 1 identifies p*.

#### 3c. Maximum Avalanche Size vs. p

Track the largest avalanche observed at each p.

**Plot:** log(s_max) vs. p.

**Expected:** s_max bounded for p < p*, then grows rapidly at p*, eventually scaling as L^D for p → 1.

#### 3d. Dissipation Fraction vs. p

At each p, measure the fraction of toppled grains lost to inactive neighbors (vs. lost at boundaries vs. transferred to active neighbors).

**Plot:** dissipation_inactive(p), dissipation_boundary(p), transfer(p).

**Expected:** As p decreases, dissipation to inactive sites increases, draining energy from cascades and preventing SOC. This is the mechanistic explanation for why low p kills SOC.

#### 3e. Effective Lattice Properties vs. p

For each lattice realization, compute:
- Spanning cluster size (from Experiment 02)
- Mean cluster size
- Coordination number distribution (how many active neighbors per active site)

**Purpose:** Connects the structural percolation diagnostics (Experiment 02) to the dynamical SOC diagnostics. If p* = p_c, the spanning cluster is necessary for SOC. If p* > p_c, something more than spanning is needed.

---

## Identifying the Activation Threshold

### Method 1: Sigma Crossing

Plot sigma(p). Find the p value where sigma crosses 1.0. This is the most direct estimate of p*.

### Method 2: Power-Law Onset

Plot the KS p-value for the power-law fit as a function of p. Find the p value where the power law first becomes acceptable (p-value > 0.05).

### Method 3: Susceptibility Peak

By analogy with the percolation susceptibility (Experiment 02), compute the variance of avalanche sizes as a function of p. A divergence or peak identifies the transition.

### Method 4: Binder Cumulant

Compute the Binder cumulant U = 1 - <s^4> / (3 <s^2>^2) for the avalanche size distribution. Crossing points for different L values identify p* precisely. (Requires running at multiple L values.)

### Comparison

If all four methods give consistent p* estimates, the activation threshold is well-defined. If they disagree, the transition is not sharp and the hypothesis needs refinement.

---

## The Pre-SOC Regime (p < p*)

Characterize what the system looks like below the activation threshold:

- **Avalanche statistics:** Exponential or truncated distributions? What determines the cutoff?
- **Spatial extent:** Avalanches confined to isolated clusters? Size bounded by cluster size?
- **Temporal structure:** Inter-event times exponential (Poisson)? This is a specific prediction from the empirical signatures document.
- **Branching ratio:** How far below 1? Constant or varying?

This characterizes the "pre-SOC" phase in your phase diagram: (Pre-SOC → Sub-critical / Critical / Super-critical → Dissolution).

---

## Negative Controls

### Control 1: Sandpile on Random Graph

Same experiment but on an Erdos-Renyi random graph with N = L^2 nodes and mean degree matched to the square lattice at each p. SOC on random graphs has different properties (mean-field exponents). Verifies that the threshold we detect is lattice-specific, not an artifact of node count.

### Control 2: Sandpile with Annealed Disorder

Instead of a fixed (quenched) lattice, randomly re-draw active/inactive sites at each toppling step. This destroys spatial correlations while maintaining the same average connectivity. If SOC signatures disappear, spatial structure matters — connectivity alone is insufficient.

---

## Experimental Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| Signature diagnostics vs. p | DataFrame | All signature values at each p |
| p* estimates | Named tuple | From each identification method |
| Avalanche catalogs | Arrow files | At selected p values (below, at, above p*) |
| Dissipation analysis | DataFrame + plot | Energy flow vs. connectivity |
| Pre-SOC characterization | DataFrame + plot | Avalanche stats below threshold |
| Lattice-dynamics joint analysis | DataFrame | Structural percolation diagnostics alongside SOC diagnostics |

---

## Implementation Plan

1. **Build the diluted sandpile** — `work/experiments/validation/diluted_sandpile.jl`
   - `btw_diluted(L, p, N_transient, N_record; seed)` → avalanche catalog + dissipation stats
   - Reuse cluster labeling from Experiment 02 for lattice analysis
   - Track per-toppling grain destinations (active neighbor, inactive neighbor, boundary)

2. **Build threshold detection** — extend `work/experiments/validation/diagnostics.jl`
   - `sweep_diluted_sandpile(L, p_range, N_realizations)` → full diagnostic dataset
   - `find_activation_threshold(sweep_results)` → p* estimates from multiple methods
   - `characterize_pre_soc(catalog)` → pre-SOC regime description

3. **Run experiments** — `work/experiments/validation/03_run_activation.jl` or notebook
   - Coarse sweep: p in [0.3, 1.0]
   - Fine sweep around transition
   - All diagnostics at each p
   - Negative controls
   - Generate plots and summary

4. **Validate:**
   - p = 1.0 results match Experiment 01 (sanity check)
   - p = 0.3 results show no SOC signatures (expected)
   - p* is consistent across identification methods
   - Compare p* to p_c from Experiment 02

---

## Success Criteria

The experiment succeeds if:

1. SOC signatures are present at p = 1.0 (recovers Experiment 01)
2. SOC signatures are absent at p = 0.3
3. A transition region is identified where signatures emerge
4. Multiple methods for estimating p* give consistent results (within statistical uncertainty)
5. The relationship between p* and p_c is clearly characterized (equal, offset, or gradual)

The experiment is inconclusive if the transition is too gradual to identify p* or if different signatures give wildly different transition points. This would not falsify the activation threshold hypothesis but would require reframing it as a crossover rather than a phase transition.

---

## Dependencies

- Experiment 01 sandpile simulator and diagnostics (validated)
- Experiment 02 percolation simulator and diagnostics (validated)
- Julia packages: same as Experiments 01 and 02

## Related Documents

- [`../ideas/distorted_soc_signatures.md`](../ideas/distorted_soc_signatures.md) — signature catalog. Use this to interpret which signatures appear at each p. Below p*, SOC signatures should be absent; at p_c they should emerge; between p* and p_c the signature profile may resemble CSOC-like (suppressed-release) as the spanning cluster is marginal.
- [`../ideas/energy_accounting.md`](../ideas/energy_accounting.md) — gives a quantitative definition of "activation energy": the minimum PE required for a spanning cascade on the current cluster structure. Percolation extension section specifies which measurements (per-bond flux, spanning-cluster mass) make this operational.
- [`../ideas/energy_depletion_percolation_research_paths.md`](../ideas/energy_depletion_percolation_research_paths.md) — literature map for the "p_c as termination condition" proposition this experiment tests from below.

## Next Experiment

**Experiment 04: Overloading the Joined System** — push the sandpile-on-lattice past criticality to find the absorbing barrier. Increase driving rate, reduce dissipation, or flood the system to determine if an irreversible dissolution boundary exists and can be measured.
