# ------------------------------------------------
# STAGE 1 — FRONTEND BUILD (Vite/Node)
# ------------------------------------------------
FROM node:20-bullseye AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build


# ------------------------------------------------
# STAGE 2 — PHP-FPM + NGINX + COMPOSER
# ------------------------------------------------
FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html

# ✅ Pastikan kita punya akses root dulu
USER root

# Install PHP extensions & dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        unzip \
        libicu-dev \
        libpng-dev \
        libzip-dev \
        zip && \
    docker-php-ext-install intl pdo_pgsql gd zip && \
    rm -rf /var/lib/apt/lists/*

# Copy composer dari official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy source code dari repository
COPY . .

# Copy hasil build frontend (Vite)
COPY --from=build /app/public/build /var/www/html/public/build

# Install Laravel dependencies (tanpa dev)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Laravel optimization & permission setup
RUN php artisan storage:link || true && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Ganti user kembali ke www-data
USER www-data

EXPOSE 8000
CMD ["php-fpm"]
