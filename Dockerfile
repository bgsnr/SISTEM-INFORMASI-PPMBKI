# ----------------------------------------------
# STAGE 1 — PHP-FPM + COMPOSER (No Node)
# ----------------------------------------------
FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html

# Gunakan root untuk install dependencies
USER root

# Install dependensi dasar PHP
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

# Tambahkan composer dari official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy source project Laravel
COPY . .

# Install dependency Laravel tanpa dev
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Cache konfigurasi Laravel
RUN php artisan config:cache || true && \
    php artisan route:cache || true && \
    php artisan view:cache || true && \
    php artisan storage:link || true && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Kembali ke user web server
USER www-data

# Expose port PHP-FPM
EXPOSE 8000

# Jalankan PHP-FPM
CMD ["php-fpm"]
