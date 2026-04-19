# syntax=docker/dockerfile:1.7
#
# Multi-stage build for the React frontend.
#
# Three stages:
#   1. "deps"    — install node_modules (cached when package.json unchanged)
#   2. "builder" — run `vite build` to produce static assets
#   3. "runtime" — nginx serving the static assets
#
# For local dev, compose overrides this entirely and runs `vite dev` with a
# bind mount. The image defined here is what we'll deploy later.

# ---------- deps ----------
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
# `npm ci` is stricter than `npm install` — requires a lockfile, won't modify it.
# Falls back to `npm install` if no lockfile exists yet (first run).
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi


# ---------- builder ----------
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# VITE_API_URL must be baked in at build time (Vite inlines env vars).
# Override via: docker build --build-arg VITE_API_URL=https://api.example.com ...
ARG VITE_API_URL=http://localhost:8000
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build


# ---------- runtime ----------
FROM nginx:1.27-alpine AS runtime

# Custom nginx config: SPA fallback (all routes -> index.html) + health endpoint.
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/health || exit 1
