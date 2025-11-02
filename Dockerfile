# Stage 1 - Frontend build
FROM node:20-bookworm AS build

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=optional

COPY . .
RUN npm run build

# Stage 2 - Laravel (Backend)
FROM php:8.3-fpm-bookworm

WORKDIR /app

# Install PHP dependencies (minimal & cepat)
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libzip-dev libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql gd zip \
    && rm -rf /var/lib/apt/lists/*

# Copy composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy source & build hasil dari vite
COPY . .
COPY --from=build /app/public/build /app/public/build

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Set permission folder penting
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
