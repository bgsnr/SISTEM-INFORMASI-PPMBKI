# -------------------------------------
# STAGE 1: FRONTEND BUILD (optional, jika pakai vite)
# -------------------------------------
FROM node:20-bullseye AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build


# -------------------------------------
# STAGE 2: PHP + NGINX + COMPOSER
# -------------------------------------
FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html

# Install intl extension
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libpng-dev \
    libzip-dev \
    zip \
    && docker-php-ext-install intl pdo_pgsql gd zip \
    && rm -rf /var/lib/apt/lists/*

# Copy composer binary
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy app files
COPY . .

# Copy built assets from previous stage (optional)
COPY --from=build /app/public/build /var/www/html/public/build

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Laravel setup
RUN php artisan storage:link || true && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

EXPOSE 8000
CMD ["php-fpm"]
