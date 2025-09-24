# Dokploy Laravel SSR Package

Reusable Docker + PM2 + FrankenPHP setup for Laravel + Inertia + SSR.

## Features
- Multi-stage Docker build (Node + PHP + FrankenPHP).
- Caddy/FrankenPHP web server.
- PM2 process manager (SSR, Queue, Scheduler).
- ENV-driven customization.
- Healthcheck endpoint `/health`.

## Usage

### 1. Build & Push Image
```bash
docker build -t ghcr.io/yourname/dokploy-laravel-ssr:latest .
docker push ghcr.io/yourname/dokploy-laravel-ssr:latest
