# Criticality Index (Jupyter via Docker)

This project runs JupyterLab in Docker using [docker-compose.yml](docker-compose.yml). Notebooks and files are persisted in the local `work/` directory (mounted into the container).

## Prerequisites
- Docker + Docker Compose installed

## Start JupyterLab
From the repository root (where [docker-compose.yml](docker-compose.yml) is):

```sh
docker compose up -d
```

Then open JupyterLab in your browser:

- http://localhost:8888

When prompted for a token/password, use the token configured in [docker-compose.yml](docker-compose.yml):

- `my-prosperity-token`

## Using notebooks
- Create/open notebooks in the `work/` folder.
- Anything saved under `work/` is saved on your machine and will still be there after restarting the container.

## Stop / remove the container
Stop:

```sh
docker compose down
```

If you want to stop and also remove any associated volumes created by Compose:

```sh
docker compose down -v
```

## View logs
```sh
docker compose logs -f
```