# Stage 1 - Build frontend
FROM node:20-bullseye AS build

WORKDIR /app

# salin package.json dan lockfile
COPY package*.json ./

# install dependency (tanpa optional supaya rollup nggak error)
RUN npm install --omit=optional

# salin seluruh kode
COPY . .

# build asset vite
RUN npm run build

# Stage 2 - Laravel + PHP-FPM
FROM php:8.3-fpm

WORKDIR /app

# install dependensi php yang diperlukan
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libpng-dev \
    libzip-dev \
    zip \
    && docker-php-ext-install pdo pdo_pgsql gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# salin composer dari image resmi
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# salin source code Laravel
COPY . .

# salin hasil build frontend
COPY --from=build /app/public/build /app/public/build

# install dependensi Laravel
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# izin akses
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# generate key jika belum ada
RUN php artisan key:generate --force || true

# expose port untuk serve
EXPOSE 8000

# jalankan Laravel server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
