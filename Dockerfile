# ==============================
# 1️⃣ Build Frontend (Vite)
# ==============================
FROM node:20-alpine AS frontend
WORKDIR /app

COPY package*.json vite.config.* ./
RUN npm ci
COPY . .
RUN npm run build


# ==============================
# 2️⃣ Install Backend (Composer)
# ==============================
FROM composer:2 AS backend
WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction
COPY . .


# ==============================
# 3️⃣ Runtime — PHP + Nginx (Production)
# ==============================
FROM php:8.3-fpm-alpine

# Install dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    git \
    libpng-dev libjpeg-turbo-dev libzip-dev libxml2-dev oniguruma-dev zip curl \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip opcache

WORKDIR /var/www/html

# Copy built app
COPY --from=backend /app ./
COPY --from=frontend /app/public/build ./public/build

# Config
COPY ./docker/php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./nginx/default.conf /etc/nginx/http.d/default.conf
COPY ./docker/supervisord.conf /etc/supervisord.conf

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

EXPOSE 8000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
