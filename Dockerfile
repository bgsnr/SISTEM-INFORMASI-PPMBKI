# ============================
# Laravel + Filament Dockerfile
# ============================
FROM serversideup/php:8.3-fpm-nginx

# Ganti ke root user supaya bisa install paket tambahan
USER root

WORKDIR /var/www/html

# Install PHP extension intl
RUN apk add --no-cache icu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && apk del icu-dev

# Balik lagi ke www-data user (best practice)
USER www-data

# Copy semua file project
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Build assets jika pakai Vite
RUN if [ -f package.json ]; then \
      npm install && npm run build; \
    fi

# Set permissions
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 80
CMD ["start-container"]
