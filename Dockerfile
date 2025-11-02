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

# Tambahkan konfigurasi pool FPM agar tidak error "user has not been defined"
RUN echo "\
[www]\n\
user = www-data\n\
group = www-data\n\
listen = /var/run/php/php-fpm.sock\n\
listen.owner = www-data\n\
listen.group = www-data\n\
listen.mode = 0660\n\
pm = dynamic\n\
pm.max_children = 5\n\
pm.start_servers = 2\n\
pm.min_spare_servers = 1\n\
pm.max_spare_servers = 3\n\
chdir = /\n\
" > /usr/local/etc/php-fpm.d/www.conf

# Pastikan folder socket PHP tersedia
RUN mkdir -p /var/run/php && chown -R www-data:www-data /var/run/php

ENV WEBROOT=/var/www/html/public
ENV PHP_OPCACHE_ENABLE=1

EXPOSE 80
