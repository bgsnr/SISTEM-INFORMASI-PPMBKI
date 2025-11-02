# Stage 1 - Frontend build
FROM node:20-bookworm AS build

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=optional

COPY . .
RUN npm run build

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

