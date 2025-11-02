FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git unzip libicu-dev libpng-dev libzip-dev libpq-dev zip && \
    docker-php-ext-install intl pdo_pgsql gd zip && \
    rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress && \
    php artisan storage:link || true && \
    php artisan config:cache || true && \
    php artisan route:cache || true && \
    php artisan view:cache || true && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Root folder untuk Nginx bawaan ServerSideUp
ENV WEBROOT=/var/www/html/public
EXPOSE 80

CMD ["start-container"]
