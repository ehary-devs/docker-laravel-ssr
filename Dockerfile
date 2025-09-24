# ===========================================
# STAGE 1: Node.js Dependencies
# ===========================================
FROM node:20-alpine AS node-deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --frozen-lockfile

# ===========================================
# STAGE 2: PHP Base (FrankenPHP + Node)
# ===========================================
FROM dunglas/frankenphp:1.1-php8.3 AS php-base
WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl unzip zip libpq-dev libicu-dev libzip-dev libmagickwand-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN install-php-extensions gd zip intl pdo_mysql imagick

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs=20.* \
    && npm install -g pm2@5.3.0

# ===========================================
# STAGE 3: PHP Dependencies
# ===========================================
FROM php-base AS php-deps
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress --no-scripts

# ===========================================
# STAGE 4: Node Build (Vite + SSR)
# ===========================================
FROM node:20-alpine AS node-build
WORKDIR /app
COPY . .
COPY --from=node-deps /app/node_modules ./node_modules
COPY --from=php-deps /app/vendor ./vendor
RUN npm run build:ssr

# ===========================================
# STAGE 5: Production
# ===========================================
FROM php-base AS production
WORKDIR /app

# Runtime ENV defaults (override di Dokploy/compose)
ENV APP_ENV=production \
    APP_PORT=80 \
    PHP_WORKERS=4 \
    APP_CWD=/app \
    SSR_ENTRY=/app/bootstrap/ssr/ssr.js \
    SSR_INSTANCES=max \
    RUN_MIGRATION=false \
    ENABLE_QUEUE=false \
    ENABLE_SCHEDULER=false \
    PM2_LOG_DIR=/app/pm2-logs

# User non-root
RUN groupadd -r app && useradd -r -g app -s /bin/bash app
RUN mkdir -p $PM2_LOG_DIR && chown -R app:app $PM2_LOG_DIR

# Copy deps & source
COPY --from=php-deps /app/vendor ./vendor
COPY --from=node-deps /app/node_modules ./node_modules
COPY . .
COPY --from=node-build /app/public/build ./public/build
COPY --from=node-build /app/bootstrap/ssr ./bootstrap/ssr

RUN composer dump-autoload --optimize --no-dev

# Copy config
COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY docker/start-container.sh /start-container.sh
COPY docker/ecosystem.config.cjs /etc/app-config/ecosystem.config.cjs
RUN chmod +x /start-container.sh

# Permissions
RUN chown -R app:app /app \
    && chmod -R 750 /app \
    && chmod -R 755 /app/public \
    && chmod -R 775 /app/storage /app/bootstrap/cache \
    && mkdir -p /config/caddy /data/caddy \
    && chown -R app:app /config /data

USER app
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost/health || exit 1

ENTRYPOINT ["/start-container.sh"]
