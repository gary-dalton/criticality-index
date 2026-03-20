# Phase 2: Variable Mapping (Slug Selection)

**Objective:** Map concepts to specific data slugs (QoG Primary, External Secondary).

**Constraint:** If QoG is insufficient, you *must* recommend high-fidelity external sources.

**Data Handling:** Cite Variable Definitions/Codebooks. Do not modify source data.

**Status:** Not started.

## Dependencies
- Requires Phase 1 model definition to be locked
- Uses enriched metadata from Phase 0 (temporal/geographic profiles, clustering)

## Key Constraints
- Slug independence: grounding validations must use slugs NOT in the main index (circularity prevention)
- If QoG coverage is insufficient for a concept, must identify and recommend external sources

## Outputs
- Locked variable-to-concept mapping
- Gap analysis identifying where external data is needed
