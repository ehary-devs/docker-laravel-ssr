# ===========================================
# STAGE 1: PHP + Node Base
# ===========================================
FROM dunglas/frankenphp:1.1-php8.3 AS base
WORKDIR /app

# Default arg, bisa di-override saat build
ARG PHP_EXTENSIONS="gd zip intl pdo_mysql imagick"

RUN apt-get update && apt-get install -y \
    curl unzip zip libpq-dev libicu-dev libzip-dev libmagickwand-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP extensions (default / custom via build-arg)
RUN install-php-extensions $PHP_EXTENSIONS

# Node + PM2
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs=20.* \
    && npm install -g pm2@5.3.0

# ===========================================
# STAGE 2: Production
# ===========================================
FROM base AS production
WORKDIR /app

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

RUN groupadd -r app && useradd -r -g app -s /bin/bash app
RUN mkdir -p $PM2_LOG_DIR && chown -R app:app $PM2_LOG_DIR

# Copy config dari repo ini
COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY docker/start-container.sh /start-container.sh
COPY docker/ecosystem.config.cjs /etc/app-config/ecosystem.config.cjs
RUN chmod +x /start-container.sh

RUN mkdir -p /config/caddy /data/caddy \
    && chown -R app:app /config /data

USER app
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost/health || exit 1

ENTRYPOINT ["/start-container.sh"]
