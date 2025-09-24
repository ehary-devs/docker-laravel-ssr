# 🚀 Dokploy Laravel SSR (Reusable Docker Image)

Base image reusable untuk **Laravel + Inertia + SSR** menggunakan:
- [FrankenPHP](https://frankenphp.dev/) sebagai web server (Caddy).
- [PM2](https://pm2.keymetrics.io/) untuk mengelola proses SSR, Queue, Scheduler.
- Multi-stage Docker build (Node + PHP).
- ENV-driven configuration untuk fleksibilitas di [Dokploy](https://dokploy.com/) atau Docker Compose.

---

## ✨ Fitur
- ✅ Multi-stage build → ringan & cepat.
- ✅ SSR dengan PM2 (auto cluster).
- ✅ Queue & Scheduler bisa ON/OFF via ENV.
- ✅ Caddy/FrankenPHP sudah built-in.
- ✅ Healthcheck bawaan (`/health`).
- ✅ Bisa tambah PHP extensions via `ARG` atau extend.

---

## 📂 Struktur Repo
```
docker-laravel-ssr/
├── docker/
│   ├── Caddyfile
│   ├── ecosystem.config.cjs
│   └── start-container.sh
├── Dockerfile
├── .dockerignore
├── .github/
│   └── workflows/
│       └── docker-publish.yml
└── README.md
```

---

## 🛠️ Cara Build & Push Base Image

### Build default (extension standar)
```bash
docker build -t ghcr.io/ehary-devs/docker-laravel-ssr:latest .
docker push ghcr.io/ehary-devs/docker-laravel-ssr:latest
```

### Build dengan extension tambahan
```bash
docker build   --build-arg PHP_EXTENSIONS="gd zip intl pdo_mysql imagick bcmath redis"   -t ghcr.io/ehary-devs/docker-laravel-ssr:custom .
```

---

## ⚡ Penggunaan di Project Laravel

### 1. Dockerfile Project
```dockerfile
FROM ghcr.io/ehary-devs/docker-laravel-ssr:latest

USER root
# (Opsional) Tambah extension khusus project ini
RUN install-php-extensions bcmath redis

WORKDIR /app
COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress
RUN npm ci --omit=dev --frozen-lockfile && npm run build

USER app
```

### 2. ENV Variables (Dokploy UI / `.env`)
```env
APP_ENV=production
APP_PORT=80
PHP_WORKERS=4
APP_CWD=/app

# Laravel migration
RUN_MIGRATION=false

# Queue
ENABLE_QUEUE=true
QUEUE_LIST=default,high
QUEUE_TRIES=3
QUEUE_TIMEOUT=60

# Scheduler
ENABLE_SCHEDULER=true

# SSR
SSR_ENTRY=/app/bootstrap/ssr/ssr.js
SSR_INSTANCES=max

# Logs
PM2_LOG_DIR=/app/pm2-logs
```

### 3. Healthcheck
Container otomatis expose endpoint:
```
GET http://localhost/health
→ OK
```

---

## ⚙️ Menambah Extension PHP

### Opsi 1: Tambah di base image (permanent untuk semua project)
```dockerfile
ARG PHP_EXTENSIONS="gd zip intl pdo_mysql imagick bcmath redis"
RUN install-php-extensions $PHP_EXTENSIONS
```

### Opsi 2: Extend di project Laravel (khusus project itu saja)
```dockerfile
FROM ghcr.io/ehary-devs/docker-laravel-ssr:latest
USER root
RUN install-php-extensions redis amqp
```

---

## 📜 License
MIT © 2025 — [ehary-devs](https://github.com/ehary-devs)
