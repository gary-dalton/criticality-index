# Criticality Index

A research project applying Self-Organized Criticality (SOC) theory to Quality of Government (QoG) data to identify empirical signatures of criticality in governance systems. Built in Julia, run in JupyterLab via Docker.

## Project Structure

```
criticality-index/
├── document/
│   └── ai-instructions.md           # Cross-phase collaboration rules
├── work/
│   ├── p00_*.ipynb                   # Phase 0 notebooks (see below)
│   ├── data/                         # Data files (gitignored)
│   └── phase0/                       # Phase 0: Preprocessing
│       ├── document/                 # Phase 0 documentation
│       └── functions/                # Phase 0 Julia modules
├── test/                              # Test suite (all phases)
│   ├── runtests.jl                   # Entry point
│   └── phase0/                       # Phase 0 unit & integration tests
├── .claude/phases/                   # Phase-specific context files
├── CLAUDE.md                         # AI collaboration context
├── docker-compose.yml                # JupyterLab container config
└── README.md
```

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 0 | Preprocessing | **Active** — data loading, metadata, geographic mapping complete; clustering in development |
| 1 | Model Definition (Conceptual & Mathematical) | Not started |
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

```sh
cd ~/projects/criticality-index
julia test/runtests.jl
```

Unit tests run without data files. Integration tests (marked with `has_data()`) require the QoG data in `work/data/` and are skipped when absent.

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
