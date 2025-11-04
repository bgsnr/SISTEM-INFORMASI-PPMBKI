FROM php:8.3-fpm-alpine

WORKDIR /var/www/html
RUN apk update && apk add --no-cache \
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
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY . .

RUN mkdir -p bootstrap/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache \
    storage/logs \
    && chmod -R 775 storage bootstrap/cache

RUN COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --optimize-autoloader --no-interaction --no-scripts
RUN npm install && npm run build


RUN chown -R www-data:www-data /var/www/html

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
