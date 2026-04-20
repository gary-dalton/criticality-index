# Criticality Index

A research project applying Self-Organized Criticality (SOC) theory to Quality of Government (QoG) data to identify empirical signatures of criticality in governance systems. Built in Julia, run in JupyterLab via Docker.

## Project Structure

```
criticality-index/
├── document/
│   ├── publication/                    # Reader-facing cross-phase docs
│   │   ├── soc_model_architecture.md   # SOC model definition
│   │   ├── soc_companion_guide.md      # Glossary, primers, physics analogs
│   │   ├── soc_empirical_signatures.md # Five signatures of criticality
│   │   ├── grounding.md                # Criticality validation signatures
│   │   └── order.md                    # Order/damping component
│   └── internal/                       # AI-agent & developer continuity
│       ├── ai-instructions.md          # Collaboration rules
│       └── new-chat-summary.md         # Project onboarding
├── work/
│   ├── p00_*.ipynb / p00b_*.ipynb      # Phase 0 / 0b notebooks
│   ├── p01_*.ipynb / p01b_*.ipynb      # Phase 1 / 1b notebooks
│   ├── p02_*.ipynb                     # Phase 2 notebooks
│   ├── exp*_*.ipynb                    # Validation experiment notebooks
│   ├── data/                           # Data files (gitignored)
│   ├── phase0/                         # Phase 0: Preprocessing
│   ├── phase00b/                       # Phase 0b: Extended preprocessing (EM-DAT, DOSE, SHDI, CEPII)
│   ├── phase1/                         # Phase 1: Slug Classification
│   ├── phase01b/                       # Phase 1b: Structural Integration
│   ├── phase2/                         # Phase 2: Variable Mapping
│   ├── experiments/                    # Synthetic SOC validation experiments
│   │   ├── ideas/                      # CSOC/ISOC frameworks, feasibility, mapping
│   │   └── validation/                 # Simulator, diagnostics, runners, WORKFLOW.md
│   └── test/                           # Test suite
├── .claude/phases/                     # Phase-specific context files
├── CLAUDE.md                           # AI collaboration context
├── docker-compose.yml                  # JupyterLab container
├── docker-compose.julia.yml            # Headless Julia container for batch compute
└── README.md
```

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 0 | Preprocessing | Complete |
| 0b | Extended Preprocessing (EM-DAT, DOSE, SHDI, CEPII, Laeven & Valencia) | Complete |
| 1 | Slug Classification | Complete — missingness scoring, reclassification, 9 labeled clusters |
| 1b | Structural Integration (master country ref, coverage matrix) | In progress |
| 2 | Variable Mapping (Slug Selection) | In progress |
| 3 | Locked Analysis | Not started |
| 4 | Synthesis & Writing | Not started |

Parallel to the main phases, the `work/experiments/` directory contains synthetic SOC validation experiments (BTW sandpile, Manna, percolation, etc.) that test the diagnostic machinery on systems where the answer is known before applying to governance data. See [work/experiments/validation/WORKFLOW.md](work/experiments/validation/WORKFLOW.md).

## Notebook Convention

Notebooks are named `pNN_SS_name.ipynb` where `NN` is the two-digit phase number (optional `b` suffix for sub-phases) and `SS` is the sequence order. Validation experiment notebooks use `expNN_SS_name.ipynb`. Special prefixes: `ref` for reference/utility, `xx` for exploratory.

### Phase 0 / 0b — Preprocessing

| Notebook | Role |
|----------|------|
| `p00_00_julia_setup` | Package installation & environment setup |
| `p00_01_std_dataset` | Load & standardize QoG data |
| `p00_02_pdf_work` | PDF codebook extraction |
| `p00_03_metadata` | 3-way metadata unification |
| `p00_04_enrich_meta` | Temporal & geographic enrichment |
| `p00_05_geo_region` | UN geographic region assignment |
| `p00_06_clustering` | Legacy variable clustering (superseded by Phase 1) |
| `p00_ref_reference` | Function reference & diagnostics |
| `p00_xx_early_explore` | Initial data exploration |
| `p00_xx_maps` | UN region/subregion/continent choropleth maps |
| `p00b_emdat` | EM-DAT disaster database (Phase 0b) |
| `p00b_dose` | DOSE subnational GDP (Phase 0b) |
| `p00b_shdi` | SHDI subnational HDI (Phase 0b) |
| `p00b_cepii_geodist` | CEPII geographic distances (Phase 0b) |
| `p00b_cepii_gravity` | CEPII bilateral trade flows (Phase 0b) |
| `p00b_laeven_valencia` | Systemic crisis database (Phase 0b) |

### Phase 1 / 1b — Classification & Structural Integration

| Notebook | Role |
|----------|------|
| `p01_01_country_missingness` | Country missingness scoring & status classification |
| `p01_02_slug_reclassification` | Revised penetration, UN vectors, clustering pool filter |
| `p01_03_slug_clustering` | Slug clustering by country coverage |
| `p01b_structural_integration` | Master country reference + coverage matrix |

### Phase 2 — Variable Mapping

| Notebook | Role |
|----------|------|
| `p02_network_data` | Network layer construction (trade, geographic, lineage edges) |

### Validation experiments

| Notebook | Role |
|----------|------|
| `exp01_01_btw_sandpile` | BTW sandpile simulation and SOC signature validation |

See [work/experiments/validation/WORKFLOW.md](work/experiments/validation/WORKFLOW.md) for the three-phase (explore → ensemble → analyze) workflow used by experiment notebooks.

### Shared

| Notebook | Role |
|----------|------|
| `pALL_test` | Test runner notebook |

## Running Tests

From the command line:

```sh
cd ~/projects/criticality-index
docker compose exec -w /home/jovyan/work jupyter julia test/runtests.jl
```

From a Jupyter notebook (or use `pALL_test.ipynb`):

```julia
using Test
include("test/runtests.jl")
```

### Test tiers

| Tier | Requires data? | What it tests |
|------|---------------|---------------|
| **Load** | No | Constants defined, correct values, key mappings exist |
| **Unit** | No | Pure functions with synthetic inputs (classification, normalization, parsing, sensors) |
| **Integration** | Yes | Full pipeline output (row counts, column presence, uniqueness, no missing regions) |

Integration tests are gated behind `has_data()` and skipped when QoG data files aren't present in `work/data/`.

### Test files

| File | Module | Assertions |
|------|--------|------------|
| `test_augmented_standard.jl` | qog_augmented_standard | Constants, HISTORICAL_CCODE_MAP values, COLLISION_PRIORITY_ALPHAS, RESCUED_ENTITY_REGIONS, full pipeline integration |
| `test_pdf_extract.jl` | qog_pdf_extract | parse_year_value (OCR, missing indicators, range), extract_first_paragraph, classify_provenance cascade |
| `test_metadata_join.jl` | qog_metadata_join | normalize_ligatures (all 5 Unicode ligatures), has_proper_temporal_data |
| `test_grounding.jl` | grounding | All 4 SOC validators: power law, correlation divergence, scale invariance, event scaling (insufficient data + sufficient data) |
| `test_order.jl` | order | sensor_pts normalization, sensor_peasfrel min-max, sensor_homicide with penalty logic |
| `test_enrich_metadata.jl` | enrich_metadata | classify_temporal_profile (all 6 profiles), classify_geographic_profile (global/regional/other) |

### Adding new tests

1. Create `work/test/phase0/test_<module>.jl` (or `work/test/phase1/` for future phases)
2. Use `@testset verbose=true "name"` for visibility in output
3. Add `include(...)` line in `work/test/runtests.jl`
4. For data-dependent tests, wrap in `if has_data() ... end`

## Prerequisites
- Docker + Docker Compose installed

## Start JupyterLab

From the repository root:

```sh
cd ~/projects/criticality-index
docker compose up -d
```

Then open http://localhost:8888 with token: `my-prosperity-token`

## Headless Julia container (for batch compute)

For long-running simulations (validation experiments) that shouldn't hold data in a Jupyter kernel, a separate headless Julia container is available via `docker-compose.julia.yml`. It shares the Julia depot with the Jupyter container so packages installed in either are visible to both.

```sh
# Start
docker compose -f docker-compose.julia.yml up -d

# Shell in
docker compose -f docker-compose.julia.yml exec julia bash

# Inside container, run a validation experiment
julia --project experiments/validation/run_btw_ensemble.jl

# Stop
docker compose -f docker-compose.julia.yml down
```

See [work/experiments/validation/WORKFLOW.md](work/experiments/validation/WORKFLOW.md) for the full workflow.

## Stop

```sh
docker compose down
```

To also remove volumes:

```sh
docker compose down -v
```

## View logs

```sh
docker compose logs -f
```
