FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html

USER root

# Install dependensi dasar PHP
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        unzip \
        libicu-dev \
        libpng-dev \
        libzip-dev \
        libpq-dev \
        zip && \
    docker-php-ext-install intl pdo_pgsql gd zip && \
    rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy seluruh project Laravel
COPY . .

# Install dependency Laravel
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress && \
    php artisan storage:link || true && \
    php artisan config:cache || true && \
    php artisan route:cache || true && \
    php artisan view:cache || true && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Aktifkan Nginx bawaan
ENV WEBROOT=/var/www/html/public
ENV PHP_FPM_LISTEN=9000

EXPOSE 80
CMD ["supervisord"]
