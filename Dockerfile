########################################
# STAGE 1 — FRONTEND BUILD (Vite)
########################################
FROM node:20-alpine AS frontend

WORKDIR /app

# Install dependencies
COPY package*.json vite.config.* ./
RUN npm ci

# Copy project files and build Vite
COPY . .
RUN npm run build


########################################
# STAGE 2 — BACKEND BUILD (Composer)
########################################
FROM composer:2 AS backend

WORKDIR /app

# Copy composer files and install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy all app files
COPY . .


########################################
# STAGE 3 — PRODUCTION RUNTIME (Nginx + PHP-FPM)
########################################
FROM php:8.3-fpm-alpine

# Install system & PHP dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    git \
    icu-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    libxml2-dev \
    oniguruma-dev \
    zip \
    curl \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        opcache \
        intl

# Set working directory
WORKDIR /var/www/html

# Copy backend (Laravel app)
COPY --from=backend /app ./

# Copy built frontend (Vite)
COPY --from=frontend /app/public/build ./public/build

# Copy configs
COPY ./docker/php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./nginx/default.conf /etc/nginx/http.d/default.conf
COPY ./docker/supervisord.conf /etc/supervisord.conf

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

# Expose port 8000 for Nginx
EXPOSE 8000

# Run Nginx and PHP-FPM together
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
