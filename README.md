# Criticality Index

A research project applying Self-Organized Criticality (SOC) theory to Quality of Government (QoG) data to identify empirical signatures of criticality in governance systems. Built in Julia, run in JupyterLab via Docker.

## Project Structure

```
criticality-index/
├── document/
│   └── ai-instructions.md           # Cross-phase collaboration rules
├── work/
│   ├── p00_*.ipynb                   # Phase 0 notebooks (see below)
│   ├── p01_*.ipynb                   # Phase 1 notebooks
│   ├── data/                         # Data files (gitignored)
│   ├── phase0/                       # Phase 0: Preprocessing
│   │   ├── document/                 # Phase 0 documentation
│   │   └── functions/                # Phase 0 Julia modules
│   ├── phase1/                       # Phase 1: Model Definition
│   │   └── functions/                # Phase 1 Julia modules
│   └── test/                         # Test suite (all phases)
│       ├── runtests.jl               # Entry point
│       ├── phase0/                   # Phase 0 tests
│       └── phase1/                   # Phase 1 tests
├── .claude/phases/                   # Phase-specific context files
├── CLAUDE.md                         # AI collaboration context
├── docker-compose.yml                # JupyterLab container config
└── README.md
```

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 0 | Preprocessing | Complete — data loading, metadata, geographic mapping, output integrity verified |
| 1 | Model Definition (Conceptual & Mathematical) | **Active** — slug clustering by country coverage |
| 2 | Variable Mapping (Slug Selection) | Not started |
| 3 | Locked Analysis | Not started |
| 4 | Synthesis & Writing | Not started |

## Notebook Convention

Notebooks are named `pNN_SS_name.ipynb` where `NN` is the two-digit phase number and `SS` is the sequence order. Special prefixes: `ref` for reference/utility, `xx` for exploratory.

| Notebook | Role |
|----------|------|
| `p00_00_julia_setup` | Package installation & environment setup |
| `p00_01_std_dataset` | Load & standardize QoG data |
| `p00_02_pdf_work` | PDF codebook extraction |
| `p00_03_metadata` | 3-way metadata unification |
| `p00_04_enrich_meta` | Temporal & geographic enrichment |
| `p00_05_geo_region` | UN geographic region assignment |
| `p00_06_clustering` | Variable clustering (in development) |
| `p00_ref_reference` | Function reference & diagnostics |
| `p00_xx_early_explore` | Initial data exploration (exploratory) |

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
