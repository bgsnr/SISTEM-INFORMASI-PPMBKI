# ============================================
# Stage 1: Build front-end assets (Vite)
# - Gunakan Debian (glibc) agar Rollup optional deps beres
# ============================================
FROM node:20-bullseye-slim AS assets
WORKDIR /app

# Salin minimal yang dibutuhkan agar cache npm bagus
COPY package*.json ./

# Install deps. Sertakan optional (workaround bug npm + rollup prebuilt)
RUN npm ci --no-audit --no-fund --include=optional \
 || (rm -rf node_modules package-lock.json && npm install --no-audit --no-fund --include=optional)

# Salin sisa source supaya Vite bisa build
# (Aman meski tidak semua file ada; kalau tidak pakai Tailwind/PostCSS, biarkan saja)
COPY . .

# Build Vite (hasil ke /app/public/build + manifest.json)
RUN npm run build


# ============================================
# Stage 2: PHP + Nginx (Server Side Up image)
# ============================================
FROM serversideup/php:8.3-fpm-nginx

# Kerja di root proyek Laravel
WORKDIR /var/www/html
USER root
ENV DEBIAN_FRONTEND=noninteractive

# System deps + ekstensi PHP yang dibutuhkan (intl & zip)
RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libicu-dev \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl zip \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer env
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=2000 \
    COMPOSER_MAX_PARALLEL_HTTP=12

# --- Optimalkan layer composer ---
# Salin composer files dulu biar cache vendor nge-lock
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install \
    --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

# Salin seluruh source code
COPY --chown=www-data:www-data . .

# Salin hasil build Vite dari stage assets → wajib ada manifest.json
COPY --from=assets /app/public/build /var/www/html/public/build

# Optimalkan autoload (tanpa rerun semua scripts)
RUN composer dump-autoload -o

# Permission untuk Laravel (storage, cache)
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

# Aktifkan OPCache (sangat disarankan untuk production)
ENV PHP_OPCACHE_ENABLE=1

# Image ini sudah men-serve Nginx+PHP-FPM dengan default vhost root: /var/www/html/public
# Tidak perlu CMD/ENTRYPOINT custom. Port 80 sudah dibuka di image base.

# (Optional, eksplisitkan saja)
EXPOSE 80
