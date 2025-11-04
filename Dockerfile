# =============================================
# Laravel + Filament + intl Extension (Debian)
# =============================================
FROM serversideup/php:8.3-fpm-nginx

# Ganti ke root user supaya bisa install dependencies
USER root

WORKDIR /var/www/html

# Install PHP extension intl (pakai apt karena base image Debian)
RUN apt-get update && apt-get install -y \
    libicu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Kembali ke user www-data untuk keamanan
USER www-data

# Copy semua file project
COPY . .

# Install dependencies PHP
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Build asset jika pakai Vite
RUN if [ -f package.json ]; then \
      npm install && npm run build; \
    fi

# Set permission Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 80
CMD ["start-container"]
