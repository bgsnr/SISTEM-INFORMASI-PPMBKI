# --- Stage 1: Build assets ---
FROM node:20-alpine AS assets
WORKDIR /app

COPY package*.json ./
# Jika file2 ini ADA di repo kamu (biasanya ada di stack Vite+Tailwind)
COPY vite.config.* ./
COPY postcss.config.* ./
COPY tailwind.config.* ./

RUN npm ci --no-audit --no-fund

COPY resources ./resources
COPY public ./public

RUN npm run build


# =========================
# Stage 2: PHP + Nginx
# =========================
# --- Stage 2: PHP + Nginx ---
FROM serversideup/php:8.3-fpm-nginx
USER root
WORKDIR /var/www/html

# System deps + intl + zip
RUN apt-get update && apt-get install -y \
      git unzip zip libzip-dev libicu-dev \
  && docker-php-ext-configure intl \
  && docker-php-ext-install intl zip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=2000 \
    COMPOSER_MAX_PARALLEL_HTTP=12

# Vendor cache layer
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

# App source
COPY --chown=www-data:www-data . .

# Hasil build Vite (manifest.json) dari stage assets
COPY --from=assets /app/public/build /var/www/html/public/build

# Optimize autoload
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Permissions
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

# Produksi: aktifkan OPCache
ENV PHP_OPCACHE_ENABLE=1

EXPOSE 80
# Pakai entrypoint default image (nginx+php-fpm)


# Jalankan entrypoint default image (nginx+php-fpm)
# (Tidak perlu CMD custom; image sudah meng-handle)
