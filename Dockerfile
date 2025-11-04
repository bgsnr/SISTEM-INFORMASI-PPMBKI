# =========================
# Stage 1: Build Frontend
# =========================
FROM node:20-alpine AS assets
WORKDIR /app

# Environment agar Rollup pakai JS fallback
ENV ROLLUP_USE_NODE_JS=1 \
    npm_config_fund=false \
    npm_config_audit=false \
    npm_config_optional=true \
    NODE_OPTIONS=--no-experimental-fetch

COPY package*.json ./
RUN npm install --no-fund --no-audit --include=optional || npm install

COPY . .

# 🔧 Clean possible musl rollup binary
RUN rm -rf node_modules/@rollup \
 && npm install rollup vite --no-optional --force \
 && echo "=== Running vite build (JS fallback)===" \
 && node -e "console.log('Rollup version:', require('rollup').version)" \
 && node node_modules/vite/bin/vite.js build --debug || (echo '❌ BUILD FAILED' && cat /app/node_modules/rollup/dist/native.js && exit 1)


# =========================
# Stage 2: Laravel Runtime
# =========================
FROM php:8.3-fpm-alpine
WORKDIR /var/www/html

RUN apk add --no-cache \
    git curl zip unzip icu-dev oniguruma-dev libzip-dev \
    libpng-dev libjpeg-turbo-dev freetype-dev postgresql-dev bash shadow \
 && docker-php-ext-configure gd --with-jpeg --with-freetype \
 && docker-php-ext-install pdo_mysql pdo_pgsql mbstring exif bcmath gd intl zip opcache \
 && adduser -D -u 1000 www-data \
 && chown -R www-data:www-data /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY . .
COPY --from=assets /app/public/build /var/www/html/public/build

RUN mkdir -p \
    bootstrap/cache \
    storage/framework/{sessions,views,cache} \
    storage/logs \
 && chmod -R 775 storage bootstrap/cache \
 && chown -R www-data:www-data storage bootstrap/cache

RUN COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --optimize-autoloader --no-interaction

USER www-data
EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
