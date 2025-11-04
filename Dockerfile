# ============================================
# Stage 1: Build front-end assets (Vite)
# ============================================
FROM node:20-bullseye-slim AS assets
WORKDIR /app

ENV npm_config_fund=false \
    npm_config_audit=false \
    npm_config_optional=true \
    npm_config_platform=linux \
    npm_config_arch=x64 \
    ROLLUP_USE_NODE_JS=1 \
    NODE_ENV=production

COPY package*.json ./
ARG CACHE_BUSTER=1

RUN npm ci --no-fund --no-audit --include=optional \
  || (rm -rf node_modules package-lock.json && npm install --no-fund --no-audit --include=optional)

RUN npm i -D @rollup/rollup-linux-x64-gnu lightningcss-linux-x64-gnu

COPY . .

RUN npm run build


# ============================================
# Stage 2: PHP + Nginx (serversideup/php)
# ============================================
FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html
USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libicu-dev \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl zip \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=2000 \
    COMPOSER_MAX_PARALLEL_HTTP=12

COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

COPY --chown=www-data:www-data . .

COPY --from=assets /app/public/build /var/www/html/public/build

RUN composer dump-autoload -o

RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

ENV PHP_OPCACHE_ENABLE=1

EXPOSE 80
