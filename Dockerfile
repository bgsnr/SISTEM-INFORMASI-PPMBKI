# ================================
# Stage 1: Build Frontend (Vite)
# ================================
FROM node:20-alpine AS frontend

WORKDIR /app

# Salin config dan dependencies untuk Vite
COPY package*.json vite.config.js ./
RUN npm install

# Salin resource Vite
COPY resources ./resources

# Jalankan build untuk production
RUN npm run build


# ================================
# Stage 2: Laravel + PHP
# ================================
FROM php:8.3-fpm-alpine

WORKDIR /var/www/html

# Install dependencies sistem dan ekstensi PHP
RUN apk add --no-cache \
    git \
    curl \
    zip \
    unzip \
    nodejs \
    npm \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    postgresql-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        mbstring \
        exif \
        bcmath \
        gd \
        intl \
        zip \
        opcache

# Copy Composer dari image resmi
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Salin seluruh project Laravel
COPY . .

# Copy hasil build frontend dari Stage 1
COPY --from=frontend /app/public/build ./public/build

# Buat folder storage dan cache yang aman
RUN mkdir -p bootstrap/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache \
    storage/logs \
    && chmod -R 775 storage bootstrap/cache

# Install dependency Laravel
RUN COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --optimize-autoloader --no-interaction

# Optimisasi konfigurasi Laravel (opsional tapi disarankan)
RUN php artisan config:cache && php artisan route:cache && php artisan view:cache

# Ganti permission
RUN chown -R www-data:www-data /var/www/html

EXPOSE 8000

# Jalankan Laravel di port 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
