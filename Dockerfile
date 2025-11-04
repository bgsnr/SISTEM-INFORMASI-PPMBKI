########################################
# STAGE 1 — FRONTEND (Vite build)
########################################
FROM node:20-alpine AS frontend

WORKDIR /app

# Install dependencies
COPY package*.json vite.config.* ./
RUN npm ci

# Copy project files & build Vite
COPY . .
RUN npm run build


########################################
# STAGE 2 — BACKEND (Composer install)
########################################
FROM php:8.3-fpm-alpine AS backend

# Install system deps + intl agar composer tidak error
RUN apk add --no-cache icu-dev libzip-dev oniguruma-dev git bash zip curl \
    && docker-php-ext-install intl zip opcache pdo_mysql bcmath

WORKDIR /app

# Install composer manually (karena image ini base-nya php)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy composer files & install deps
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy seluruh app
COPY . .


########################################
# STAGE 3 — RUNTIME (Nginx + Supervisor)
########################################
FROM php:8.3-fpm-alpine

# Install Nginx, Supervisor, PHP extensions, intl
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

WORKDIR /var/www/html

# Copy hasil build backend dan frontend
COPY --from=backend /app ./
COPY --from=frontend /app/public/build ./public/build

# Copy konfigurasi
COPY ./docker/php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./nginx/default.conf /etc/nginx/http.d/default.conf
COPY ./docker/supervisord.conf /etc/supervisord.conf

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

EXPOSE 8000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
