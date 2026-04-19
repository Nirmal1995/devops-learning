"""
FastAPI entrypoint.

Health endpoints:
  /health - liveness (is the process up?)
  /ready  - readiness (can we serve traffic? DB reachable?)

These exist now — before Kubernetes — because running them locally is how
you verify they work. In Phase 3 we'll wire them into K8s probes.
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.config import settings
from app.db.session import engine
from app.routers import tasks


@asynccontextmanager
async def lifespan(_: FastAPI):
    yield
    await engine.dispose()


app = FastAPI(title="DevOps Learning API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tasks.router, prefix="/api/tasks", tags=["tasks"])


@app.get("/health")
async def health():
    """Liveness: the process is up. Nothing more."""
    return {"status": "ok"}


@app.get("/ready")
async def ready():
    """Readiness: we can actually serve traffic (DB reachable)."""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return {"status": "ready", "db": "ok"}
    except Exception as e:
        return {"status": "not_ready", "db": f"error: {type(e).__name__}"}
