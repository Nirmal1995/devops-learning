# syntax=docker/dockerfile:1.7
#
# Multi-stage build for the FastAPI backend.
#
# Why multi-stage?
#   - "builder" has compilers and build deps.
#   - "runtime" has ONLY what's needed to run. No pip, no gcc, no source cruft.
#   - Result: smaller, more secure final image.
#
# Why python:3.12-slim (not alpine)?
#   - Alpine uses musl libc. Many Python wheels (asyncpg, psycopg2) ship glibc
#     wheels, so pip falls back to source builds on Alpine — slower, more fragile.
#   - slim is Debian-based, still small, and wheels "just work".

# ---------- builder ----------
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy requirements FIRST, then install, then copy source. This way the pip
# install layer is cached as long as requirements.txt doesn't change.
# Docker layer caching 101.
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt


# ---------- runtime ----------
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/usr/local/bin:$PATH"

# libpq5 = runtime library for postgres clients. We do NOT install libpq-dev
# or build-essential here.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5 \
      curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root user. Running as root inside containers is a bad habit that WILL
# bite you in Kubernetes, where many clusters enforce non-root via policy.
RUN groupadd --system app && useradd --system --gid app --create-home app

WORKDIR /app

COPY --from=builder /install /usr/local

COPY --chown=app:app src ./src
COPY --chown=app:app migrations ./migrations
COPY --chown=app:app alembic.ini .

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--app-dir", "src"]
