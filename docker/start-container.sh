#!/bin/bash
set -euo pipefail

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

check_user() {
    if [ "${EUID:-0}" -eq 0 ]; then
        log "❌ WARNING: Running as root is not recommended"
    fi
}

validate_environment() {
    log "🔍 Validating environment..."
    [ -f "/app/artisan" ] || { log "❌ artisan not found"; exit 1; }
    [ -f "/etc/caddy/Caddyfile" ] || { log "❌ Caddyfile not found"; exit 1; }
    for dir in /app/storage /app/bootstrap/cache; do
        [ -d "$dir" ] || { log "❌ Dir $dir not found"; exit 1; }
        [ -w "$dir" ] || { log "❌ Dir $dir not writable"; exit 1; }
    done
    log "✅ Env validation passed"
}

bootstrap_laravel() {
    log "🚀 Bootstrapping Laravel..."
    php artisan storage:link || true
    for cmd in config:clear cache:clear route:clear view:clear optimize:clear; do
        php artisan "$cmd" || true
    done
    for cmd in config:cache route:cache view:cache; do
        php artisan "$cmd" || true
    done
    php artisan optimize || true
    [ "${RUN_MIGRATION:-false}" = "true" ] && php artisan migrate --force
    log "✅ Laravel ready"
}

cleanup() {
    log "🛑 Shutdown signal received"
    pm2 delete all || true
    exit 0
}
trap cleanup SIGTERM SIGINT

main() {
    log "🌟 Init container..."
    check_user
    validate_environment
    bootstrap_laravel

    export PM2_HOME="${PM2_LOG_DIR}/.pm2"
    mkdir -p "$PM2_HOME"

    log "🟢 Starting PM2 apps..."
    pm2-runtime /etc/app-config/ecosystem.config.cjs &

    log "🌍 Starting FrankenPHP..."
    exec docker-php-entrypoint frankenphp run --config /etc/caddy/Caddyfile --adapter caddyfile
}

main "$@"
