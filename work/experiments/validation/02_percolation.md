# Experiment 02: Synthetic Percolation — Threshold Detection and Phase Transition

## Purpose

Validate that we can correctly identify the percolation threshold p_c and measure the phase transition around it. This establishes the tools needed for Experiment 03 (sandpile on a percolation lattice) and grounds the activation threshold hypothesis — the claim that SOC requires a minimum lattice connectivity before system-spanning cascades become structurally possible.

---

## The Model: Site Percolation on a Square Lattice

### Definition

An L x L square lattice where each site is independently **occupied** with probability p and **empty** with probability (1 - p).

Two occupied sites are connected if they share a lattice edge (4-connectivity). A **cluster** is a maximal connected component of occupied sites.

**Percolation threshold p_c:** The critical occupation probability at which a spanning cluster (connecting opposite edges of the lattice) first appears with probability 1 in the thermodynamic limit (L → infinity).

For 2D site percolation on a square lattice: **p_c ≈ 0.5927** (known to high precision).

### Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| L | 64, 128, 256, 512 | Lattice side length |
| p_range | [0.3, 0.8] in steps of 0.01 | Occupation probability sweep |
| p_fine | [0.55, 0.63] in steps of 0.002 | Fine sweep near p_c |
| N_realizations | 1000 | Independent random lattices per (L, p) pair |

### Why Site Percolation

Bond percolation (edges occupied/empty, sites always present) is equally valid and has a different p_c (0.5 exactly for 2D square lattice). We use site percolation because the governance analogy is clearer: sites are institutions/nodes that may or may not be functional, and connectivity depends on which sites are active. Bond percolation can be added as a comparison.

---

## What We Measure

### Per Realization

| Quantity | Symbol | Definition |
|----------|--------|------------|
| Spanning | P_span | Does a cluster connect top to bottom? (boolean) |
| Largest cluster size | S_max | Number of sites in the largest cluster |
| Largest cluster fraction | S_max / N_occ | Fraction of occupied sites in the largest cluster |
| Cluster size distribution | n(s) | Number of clusters of size s |
| Number of clusters | N_c | Total number of distinct clusters |
| Correlation length | xi | Characteristic cluster linear extent (excluding spanning cluster) |

### Phase Transition Diagnostics

#### 2a. Spanning Probability

**Method:** For each (L, p), compute the fraction of realizations that produce a spanning cluster.

**Expected result:**
- Sigmoid curve transitioning from ~0 to ~1 around p_c
- Transition sharpens with increasing L
- Crossing point of curves for different L values converges to p_c ≈ 0.5927

**Acceptance criteria:**
- Crossing point within 0.01 of known p_c = 0.5927
- Transition width narrows proportionally to L^(-1/nu) where nu = 4/3

#### 2b. Order Parameter: Percolation Strength

**Method:** Compute P_infinity(p) = <S_max> / (L^2 * p), the fraction of occupied sites belonging to the spanning cluster, averaged over realizations.

**Expected result:**
- P_infinity = 0 for p < p_c
- P_infinity > 0 for p > p_c
- Near p_c: P_infinity ~ (p - p_c)^beta with beta = 5/36 ≈ 0.139

**Acceptance criteria:**
- Fitted beta within 20% of 5/36

#### 2c. Cluster Size Distribution at p_c

**Method:** At p = p_c (and a narrow band around it), collect the full cluster size distribution across all realizations.

**Expected result:**
- n(s) ~ s^(-tau_p) with tau_p = 187/91 ≈ 2.055
- Power law over multiple decades
- Away from p_c: exponential cutoff appears

**Acceptance criteria:**
- tau_p via MLE in [1.8, 2.3]
- KS test does not reject power law at p_c
- Power law clearly rejected at p = 0.4 and p = 0.8

#### 2d. Correlation Length Divergence

**Method:** Compute the correlation length xi(p) from the second moment of the cluster size distribution (excluding the spanning cluster):

```
xi^2 = (sum over finite clusters: s * R_s^2) / (sum over finite clusters: s)
```

where R_s is the radius of gyration of cluster s.

**Expected result:**
- xi diverges as |p - p_c|^(-nu) with nu = 4/3
- xi is bounded by system size L (finite-size effect)

**Acceptance criteria:**
- Log-log plot of xi vs |p - p_c| is linear
- Fitted nu within 20% of 4/3

#### 2e. Susceptibility (Mean Cluster Size)

**Method:** Compute chi(p) = <s^2> / <s> averaged over finite clusters (excluding spanning cluster).

**Expected result:**
- chi diverges at p_c as |p - p_c|^(-gamma) with gamma = 43/18 ≈ 2.389
- Peak in chi occurs near p_c, sharpening with L

**Acceptance criteria:**
- Peak location within 0.01 of p_c
- Fitted gamma within 20% of 43/18

#### 2f. Fractal Dimension of the Spanning Cluster

**Method:** At p_c, measure the mass of the spanning cluster as a function of box size.

**Expected result:**
- M(r) ~ r^(D_f) with D_f = 91/48 ≈ 1.896
- The spanning cluster at p_c is fractal, not space-filling

**Acceptance criteria:**
- Fitted D_f within 10% of 91/48

---

## Finite-Size Scaling

The core validation that our measurements reflect the true phase transition, not finite-size artifacts.

**Data collapse:** For each observable X(p, L), attempt collapse using:
```
X(p, L) = L^(a/nu) * f((p - p_c) * L^(1/nu))
```

where a is the critical exponent for X and f is a universal scaling function.

**Expected result:**
- Data from all L values collapse onto a single curve when plotted with rescaled axes
- This simultaneously validates p_c, nu, and the exponent a

**Apply to:**
- Spanning probability: a = 0 (dimensionless)
- Order parameter: a = beta
- Susceptibility: a = -gamma
- Correlation length: a = -nu (trivial but confirms)

---

## Negative Controls

### Control 1: p Well Below p_c (p = 0.3)

**Expected:** No spanning cluster. Exponential cluster size distribution. Short correlation length. All "at criticality" diagnostics fail.

### Control 2: p Well Above p_c (p = 0.8)

**Expected:** Single dominant cluster containing most sites. No power-law cluster distribution. Correlation length meaningless (system is one cluster). This is the "fully connected" regime.

### Control 3: Random Graph (Erdos-Renyi)

Same diagnostics on a random graph with N = L^2 nodes and edge probability tuned to match mean degree. Percolation transition exists but at a different threshold and with different exponents (mean-field: tau = 5/2, nu = 3, etc.). Verifies that our tools detect the *right* universality class, not just any transition.

---

## Connection to the Activation Threshold Hypothesis

The activation threshold hypothesis claims that governance SOC requires a minimum lattice connectivity — analogous to p > p_c. This experiment establishes:

1. **p_c detection works** — we can identify the threshold from observables
2. **Below p_c is qualitatively different** — no spanning cluster, no long-range correlations, no power-law distributions. This maps to "pre-SOC" in the phase diagram.
3. **The transition is sharp** — there is a well-defined boundary, not a gradual fade. This supports the claim that the activation threshold is a genuine phase transition, not a soft gradient.
4. **Finite-size effects are understood** — small systems (microstates) blur the transition. This connects to the mass threshold in the architecture.

---

## Experimental Outputs

| Output | Format | Purpose |
|--------|--------|---------|
| Spanning probability curves | DataFrame + plot | P_span(p) for each L |
| Order parameter | DataFrame + plot | P_infinity(p) for each L |
| Cluster size distributions | Arrow file | Full n(s) at selected p values |
| Critical exponents | Named tuple | tau_p, beta, nu, gamma, D_f with uncertainties |
| Correlation length | DataFrame + plot | xi(p) for each L |
| Data collapse | Plots | Finite-size scaling validation |
| Negative control results | DataFrame | Diagnostics on sub/super-critical and random graph |

---

## Implementation Plan

1. **Build the percolation simulator** — `work/experiments/validation/percolation.jl`
   - `site_percolation(L, p; seed)` → lattice, clusters, spanning flag
   - Cluster labeling via union-find (Hoshen-Kopelman algorithm) — efficient for large lattices
   - `sweep_percolation(L, p_range, N_realizations)` → full diagnostic dataset

2. **Build percolation diagnostics** — extend `work/experiments/validation/diagnostics.jl`
   - `spanning_probability(results, p_range)` → P_span(p) curve
   - `percolation_strength(results, p_range)` → P_infinity(p) curve
   - `cluster_size_distribution(clusters)` → n(s)
   - `correlation_length_percolation(clusters)` → xi
   - `susceptibility_percolation(clusters)` → chi
   - `fractal_dimension_cluster(cluster)` → D_f
   - `finite_size_collapse(data, L_values, p_c, nu, exponent)` → collapsed data

3. **Run experiments** — `work/experiments/validation/02_run_percolation.jl` or notebook
   - Coarse sweep: p in [0.3, 0.8] for L = 64, 128, 256, 512
   - Fine sweep near p_c for exponent extraction
   - Negative controls
   - Finite-size scaling collapse
   - Generate plots and exponent table

4. **Verify against known results:**
   - p_c = 0.5927 (2D site percolation, square lattice)
   - tau_p = 187/91 ≈ 2.055
   - beta = 5/36 ≈ 0.139
   - nu = 4/3 ≈ 1.333
   - gamma = 43/18 ≈ 2.389
   - D_f = 91/48 ≈ 1.896

---

## Success Criteria

The experiment succeeds if:

1. p_c is identified within 1% of the known value
2. All critical exponents are within 20% of known values
3. Power-law cluster distribution is detected at p_c and correctly rejected away from p_c
4. Finite-size scaling collapse works across L values
5. Negative controls are correctly classified

The experiment fails if we cannot distinguish the percolation transition from noise, or if exponents are systematically wrong. Failure indicates a bug in the measurement tools.

---

## Dependencies

- Julia packages: `Distributions.jl`, `StatsBase.jl`, `DataStructures.jl` (for union-find), `Arrow.jl`, `DataFrames.jl`
- Experiment 01 diagnostics (power-law fitting, fractal dimension) are reused here
- No external data required

## Next Experiment

**Experiment 03: Sandpile on a Percolation Lattice** — place the BTW sandpile on a lattice whose connectivity is controlled by the percolation parameter p. Test whether a clear activation energy emerges at p_c where SOC signatures appear.
