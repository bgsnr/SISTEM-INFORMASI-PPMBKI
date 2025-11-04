# =======================
# Stage 1: Build frontend
# =======================
FROM node:20-bullseye-slim AS assets
WORKDIR /app

ENV ROLLUP_USE_NODE_JS=1 \
    npm_config_fund=false \
    npm_config_audit=false \
    npm_config_optional=true \
    npm_config_omit=dev

# Salin dan install dependensi
COPY package*.json ./
RUN npm install --no-fund --no-audit --include=optional

# Copy source & config
COPY resources ./resources
COPY vite.config.* postcss.config.* tailwind.config.* ./
COPY public ./public

# Rebuild rollup manual biar gak error di Debian
RUN npm rebuild rollup --build-from-source || true

# Build assets Vite
RUN npm run build


# =======================
# Stage 2: Laravel runtime
# =======================
FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libicu-dev libpq-dev \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl zip pdo pdo_mysql pdo_pgsql \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY . .
COPY --from=assets /app/public/build /var/www/html/public/build

# Composer install
COPY composer.json composer.lock ./
RUN curl -sS https://getcomposer.org/installer | php && \
    php composer.phar install --no-dev --optimize-autoloader --no-interaction

# Permission Laravel
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

USER www-data
EXPOSE 80
CMD ["php", "-S", "0.0.0.0:80", "-t", "public"]
