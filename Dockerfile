FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html
USER root
ENV DEBIAN_FRONTEND=noninteractive

# Tools + ekstensi yang dibutuhkan
RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libicu-dev \
 && docker-php-ext-install zip intl \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer env
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=2000 \
    COMPOSER_MAX_PARALLEL_HTTP=12

# Cache layer vendor
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN php -m | grep -i intl \
 && composer install --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

# Copy source
COPY --chown=www-data:www-data . .

# Final composer (autoload optimized)
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader

# Build asset jika ada Node di image (opsional)
RUN if [ -f package.json ] && command -v npm >/dev/null 2>&1; then \
      npm install && npm run build; \
    fi

# Permission
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

USER www-data
EXPOSE 80
CMD ["start-container"]
