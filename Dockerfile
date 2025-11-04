FROM node:20-bullseye-slim AS assets
WORKDIR /app
COPY package*.json ./
RUN npm ci --no-fund --no-audit || npm install --no-fund --no-audit
COPY resources ./resources
COPY vite.config.* postcss.config.* tailwind.config.* ./
RUN npm run build


FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libicu-dev libpq-dev \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl zip pdo pdo_mysql pdo_pgsql \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY . .

COPY --from=assets /app/public/build /var/www/html/public/build

COPY composer.json composer.lock ./
RUN curl -sS https://getcomposer.org/installer | php && \
    php composer.phar install --no-dev --no-interaction --optimize-autoloader

RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

USER www-data
EXPOSE 80

CMD ["php", "-S", "0.0.0.0:80", "-t", "public"]
