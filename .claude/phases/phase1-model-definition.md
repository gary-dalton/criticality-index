# Phase 1: Model Definition (Conceptual & Mathematical)

**Objective:** Define the topology, node properties (mass/density), and edge dynamics (information flow/entropy).

**Constraint:** Open exploration. Cite theoretical principles (e.g., "Percolation Thresholds," "Shannon Entropy") or QoG variable definitions.

**Data Handling:** Cite Variable Definitions/Codebooks. Do not modify source data.

**Status:** Not started. Grounding functions prototyped in `work/phase0/functions/grounding.jl`.

## Theoretical Foundation
Five empirical signatures of criticality (see `work/phase0/document/grounding.md`):
1. Power-law distribution of events
2. Diverging correlation length across sectors
3. Scale invariance (local vs national governance)
4. Fractal structure (future — spatial data)
5. No characteristic event size (fat-tailed distributions)

## Prototyped Validation Functions
In `work/phase0/functions/grounding.jl`:
- `validate_power_law()` — α near 1.0 (scale-free)
- `validate_correlation_divergence()` — ρ > 0.70 (coupling)
- `validate_scale_invariance()` — Similarity > 0.85
- `validate_event_scaling()` — Kurtosis > 1.5

## Dependencies
- Requires Phase 0 metadata and clustering to be finalized
- Variable selection feeds into Phase 2

## Key Reference
- `work/phase0/document/grounding.md` — Full theoretical grounding
- `work/phase0/document/order.md` — Order/damping subsystem (safety sensors, lattice failure multiplier)
