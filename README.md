# DevOps Learning Project

A full-stack task manager — the vehicle for learning Docker, Kubernetes, GCP,
CI/CD, and observability. This repo is the **Phase 1** scaffold: local dev
with Docker Compose.

## Stack

- **Frontend**: React 18 + Vite
- **Backend**: FastAPI (async) + SQLAlchemy 2.0 + Alembic
- **Database**: PostgreSQL 16
- **Local orchestration**: Docker Compose

## Prerequisites

- Docker Desktop (or Docker Engine + Compose v2)
- `make` (optional but convenient)

That's it. No local Python, Node, or Postgres needed.

## Quick start

```bash
make up          # build & start everything
make migrate     # apply DB migrations
```

Then open:
- Frontend — http://localhost:5173
- API — http://localhost:8000
- API docs (Swagger) — http://localhost:8000/docs
- Health — http://localhost:8000/health
- Readiness — http://localhost:8000/ready

## Common commands

```bash
make help             # list all targets
make logs             # tail logs
make ps               # see running containers
make shell-backend    # bash inside the backend container
make shell-db         # psql into the db
make migration name="add something"   # create a new migration
make down             # stop everything
make clean            # stop + wipe DB volume (destructive)
```

## Project structure

```
devops-learning/
├── app/
│   ├── backend/             # FastAPI app
│   │   ├── src/app/         # source: main, config, db, routers
│   │   ├── migrations/      # Alembic migrations
│   │   ├── Dockerfile       # multi-stage: builder + runtime
│   │   ├── requirements.txt
│   │   └── alembic.ini
│   └── frontend/            # React + Vite app
│       ├── src/             # App.jsx, main.jsx, index.css
│       ├── Dockerfile       # multi-stage: deps + builder + nginx
│       ├── nginx.conf       # SPA fallback + /health
│       └── package.json
├── docker-compose.yml       # local dev orchestration
├── .env.example             # sample env vars (commit this)
├── .env                     # actual env vars (gitignored)
├── Makefile                 # convenience commands
└── README.md
```

## What this phase teaches

- **Multi-stage Dockerfiles** — separate build-time deps from runtime. Smaller,
  more secure images. Look at both Dockerfiles and compare builder vs runtime
  stages.
- **Docker layer caching** — why `COPY requirements.txt` comes before
  `COPY src/`. Change source, pip install is still cached.
- **Container networking** — three services on a compose-created bridge
  network, finding each other by service name (`db`, `backend`). Same DNS
  pattern as Kubernetes services.
- **Volumes vs bind mounts** — named volume (`db_data`) for Postgres
  persistence; bind mounts for source code hot reload.
- **12-factor config** — no secrets in code, all config via env vars. Same
  image, different env → different environment.
- **Healthchecks** — `/health` (liveness) and `/ready` (readiness) endpoints
  exist now so they're battle-tested before you wire them to K8s probes.
- **Non-root containers** — backend image runs as user `app`, not root.
  Habit you want before clusters with PodSecurity enforcement refuse to run
  root containers.
- **DB migrations** — Alembic. Never let the app create its own schema in
  production; migrations are separate, reviewable artifacts.

## Verify everything works

```bash
# 1. Backend up
curl -s http://localhost:8000/health
# → {"status":"ok"}

# 2. DB reachable
curl -s http://localhost:8000/ready
# → {"status":"ready","db":"ok"}

# 3. Create a task
curl -s -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn Docker"}'

# 4. List tasks
curl -s http://localhost:8000/api/tasks

# 5. Open the frontend and try the UI
open http://localhost:5173
```

## Troubleshooting

**`make migrate` fails with "connection refused"**
DB isn't ready yet. Wait ~10s after `make up` and try again. You can also
`make logs` and watch for `database system is ready to accept connections`.

**Frontend shows "API error: Failed to fetch"**
Check that backend is up (`curl http://localhost:8000/health`). CORS misconfig
is also possible — check the `CORS_ORIGINS_RAW` env var in `docker-compose.yml`.

**Port already in use**
Something else is on 5173, 8000, or 5432. Either stop it, or change the
port mapping in `docker-compose.yml` (e.g., `"8001:8000"`).

**Hot reload isn't working**
Vite needs filesystem polling in Docker. Already set in `vite.config.js`. For
the backend, `--reload` is in the compose command override.

## Next: Phase 2

Deploy this to GKE Autopilot on GCP. You'll:
- Push images to Artifact Registry
- Provision a GKE Autopilot cluster and Cloud SQL instance (manually first!)
- Write Kubernetes manifests by hand
- Connect it all together and feel why we need Helm and Terraform
