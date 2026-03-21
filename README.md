# Criticality Index

A research project applying Self-Organized Criticality (SOC) theory to Quality of Government (QoG) data to identify empirical signatures of criticality in governance systems. Built in Julia, run in JupyterLab via Docker.

## Project Structure

```
criticality-index/
├── document/
│   └── ai-instructions.md           # Cross-phase collaboration rules
├── work/
│   ├── *.ipynb                       # Jupyter notebooks
│   ├── data/                         # Data files (gitignored)
│   └── phase0/                       # Phase 0: Preprocessing
│       ├── document/                 # Phase 0 documentation
│       └── functions/                # Phase 0 Julia modules
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

## Prerequisites
- Docker + Docker Compose installed

## Start JupyterLab

```sh
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
