# Phase 3: Locked Analysis

**Objective:** Execute analysis and simulation.

**Constraint:** Strict adherence to mapped slugs. If a variable is not in the approved map, it does not exist.

**Data Handling:** Cite specific Variable Slugs (e.g., `vdem_libdem`). Do not modify source data.

**Status:** Not started.

## Key Constraints
- No variable substitution once the mapping is locked
- All analysis must use the exact slugs specified in Phase 2
- Variables outside the approved map are treated as nonexistent

## Dependencies
- Requires Phase 2 variable mapping to be finalized and locked

## Planned Signature 2 methodology (from Exp 01.01 findings)

Signature 2 (diverging correlation length) on governance data will use **effective resistance** as the graph distance measure rather than shortest path. Rationale:

- SOC cascades don't follow shortest paths — they branch across multiple parallel channels simultaneously. Effective resistance integrates over all parallel paths, correctly weighting the actual coupling strength between two nodes.
- The BTW lattice G(r) experiment (Exp 01.01 §4) showed a characteristic 1/L plateau in the correlation function — the finite-size fingerprint of ξ ≥ L. On an arbitrary graph this translates to the 1/N finite-size fingerprint of effective-resistance-based correlations.
- Computational cost: 202×202 Laplacian pseudoinverse per (year × edge layer). Under a second each; ~30s total for the full time-layer grid. Trivial.

Per-layer analysis with three edge types already in hand:
1. **Trade conductance** ∝ CEPII BACI trade flows (time-varying, annual)
2. **Geographic conductance** ∝ 1/distance from CEPII GeoDist (static)
3. **Lineage conductance** via `ggis_shared_lineage` (static, binary)

For each layer, compute `mutual_information(X_i, X_j)` between grounding slugs across all country pairs, then plot ⟨MI⟩ as a function of effective resistance R_ij. A plateau at large R is Signature 2 (diverging correlation length). Exponential decay is sub-critical (modular governance). Agreement across layers strengthens the finding; disagreement reveals which channel carries governance stress.

**Not available / deferred:**
- Cascade-traced effective conductance (requires event-level causal data — ACLED or similar)
- Financial flow layer (BIS Locational Banking data — flagged as deferred in architecture §10)
- Sanction-edge layer (deferred)
- Alliance layer (ATOP — in architecture but not yet integrated)

Running with trade + geographic + lineage is sufficient for a first test. Additional layers can be added later without changing the methodology.

See Exp 01.01 validation (`work/experiments/validation/01_01_btw_sandpile.md`) for the lattice-case proof-of-concept.
