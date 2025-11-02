# Stage 1 - Laravel PHP runtime
FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html

# Install missing intl extension
RUN apt-get update && apt-get install -y libicu-dev \
    && docker-php-ext-install intl \
    && rm -rf /var/lib/apt/lists/*

# Copy composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy all files
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Laravel setup
RUN php artisan storage:link && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

EXPOSE 8000

CMD ["php-fpm"]


# Stage 2 - Laravel (Backend)
# Stage 2 - Laravel (Backend)
FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

RUN php artisan storage:link && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

EXPOSE 8000

CMD ["php-fpm"]

