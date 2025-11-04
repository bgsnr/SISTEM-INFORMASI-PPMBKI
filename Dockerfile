# =============================================
# Laravel + Filament (serversideup/php:8.3-fpm-nginx)
# =============================================
FROM serversideup/php:8.3-fpm-nginx

# Workdir
WORKDIR /var/www/html

# Root untuk install tools
USER root

# Tools untuk Composer & zip (dan git untuk fallback sumber)
RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev \
 && docker-php-ext-install zip \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- Composer tuning (hindari timeout) ----
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=2000 \
    COMPOSER_MAX_PARALLEL_HTTP=12

# (opsional) pasang token agar terhindar rate-limit
# ARG GITHUB_TOKEN
# RUN if [ -n "$GITHUB_TOKEN" ]; then composer config -g github-oauth.github.com $GITHUB_TOKEN; fi

# ---- 1) Copy hanya file composer untuk cache layer ----
COPY --chown=www-data:www-data composer.json composer.lock ./

# Install vendor (tanpa scripts dulu biar cepat & cacheable)
RUN composer install \
    --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

# ---- 2) Baru copy source code full ----
COPY --chown=www-data:www-data . .

# Jalankan composer install final (autoload optimized + scripts)
RUN composer install \
    --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader

# ---- 3) Build asset Vite kalau ada npm & package.json ----
# (serversideup image biasanya sudah ada Node; kalau tidak, step ini akan dilewati)
RUN if [ -f package.json ] && command -v npm >/dev/null 2>&1; then \
      npm install && npm run build; \
    fi

# Permission Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

# Turun ke user non-root
USER www-data

EXPOSE 80
CMD ["start-container"]
