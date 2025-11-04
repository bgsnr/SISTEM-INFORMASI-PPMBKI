# ---- Stage 1: Build Vite assets ----
FROM node:20-bullseye-slim AS assets
WORKDIR /app

# Env untuk mencegah error rollup native & lightningcss
ENV ROLLUP_USE_NODE_JS=1 \
    npm_config_fund=false \
    npm_config_audit=false \
    npm_config_optional=true

# Copy package files and install dependencies (use lockfile if present)
COPY package*.json ./
# Upgrade npm to v11 to avoid npm v10 optional dependency bug for rollup native binaries
RUN npm install -g npm@11 --silent
# Try `npm ci` for reproducible install; if it fails (lockfile mismatch) fall back to `npm install`
RUN npm ci --no-fund --no-audit || npm install --no-fund --no-audit

# Copy project files into assets stage (rely on .dockerignore to exclude node_modules/vendor)
COPY . .

# Rebuild native deps if needed and run build
RUN npm rebuild rollup --build-from-source || true
RUN npm run build


# ---- Stage 2: PHP Runtime ----
FROM php:8.3-fpm AS runtime

# Install system packages & php extensions
RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libicu-dev libpq-dev libpng-dev libonig-dev libxml2-dev curl \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl zip pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copy application files into the image
COPY . .

# Install composer and PHP deps AFTER full copy, skip scripts then run them explicitly
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
 && composer install --no-dev --no-interaction --optimize-autoloader --prefer-dist --no-scripts \
 && composer dump-autoload --optimize

# Run composer post scripts that require artisan/bootstrap (safe now that files are present)
RUN php artisan package:discover --ansi || true

# Copy built assets from node stage
COPY --from=assets /app/public/build /var/www/html/public/build

# Fix permissions
RUN chown -R www-data:www-data storage bootstrap/cache public/build \
    && chmod -R 775 storage bootstrap/cache public/build

EXPOSE 9000
CMD ["php-fpm"]
