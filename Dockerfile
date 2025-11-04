# ============================================
# Stage 1: Build front-end assets (Vite)
# ============================================
FROM node:20-bullseye-slim AS assets
WORKDIR /app

# --- Workaround bug optional deps Rollup ---
# Paksa Rollup pakai implementasi JS, bukan native binary
ENV ROLLUP_USE_NODE_JS=1
# (opsional) kecilkan noise npm
RUN npm config set fund false && npm config set audit false

# Salin berkas untuk cache layer npm
COPY package*.json ./

# Install deps (ikutkan optional agar deps terkait platform ikut terpasang)
RUN npm ci --no-fund --no-audit --include=optional \
  || (rm -rf node_modules package-lock.json && npm install --no-fund --no-audit --include=optional)

# Salin seluruh source yang dibutuhkan Vite
COPY . .

# Build assets -> hasilkan public/build + manifest.json
RUN npm i -D @rollup/rollup-linux-x64-gnu
RUN npm run build


# ============================================
# Stage 2: PHP + Nginx (serversideup/php)
# ============================================
FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html
USER root
ENV DEBIAN_FRONTEND=noninteractive

# System deps + ekstensi PHP (intl & zip) untuk Laravel/Filament
RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libicu-dev \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl zip \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer env
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=2000 \
    COMPOSER_MAX_PARALLEL_HTTP=12

# --- Optimalkan layer vendor ---
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

# Salin seluruh source Laravel
COPY --chown=www-data:www-data . .

# Salin hasil build Vite dari stage assets
COPY --from=assets /app/public/build /var/www/html/public/build

# Optimalkan autoload
RUN composer dump-autoload -o

# Permission Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

# OPCache on untuk produksi
ENV PHP_OPCACHE_ENABLE=1

# Image base sudah expose 80 & jalankan nginx+php-fpm
EXPOSE 80
