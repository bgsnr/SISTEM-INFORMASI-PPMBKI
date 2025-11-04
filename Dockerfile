# Use a base PHP-FPM image for Laravel
FROM php:8.3-fpm-alpine

# Set the working directory inside the container
WORKDIR /var/www/html

# Install system dependencies and PHP extensions required by Laravel
RUN apk update && apk add --no-cache \
    git \
    curl \
    libzip-dev \
    libpng-dev \
    jpeg-dev \
    freetype-dev \
    icu-dev \
    postgresql-dev \
    && docker-php-ext-install pdo_mysql pdo_pgsql zip gd intl opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Copy the Laravel application code into the container
COPY . .

# Install Laravel application dependencies
RUN composer install --no-dev --optimize-autoloader

# Generate application key and optimize configuration (for production)
# For development, these steps might be handled differently or omitted
RUN php artisan key:generate
RUN php artisan config:cache

# Expose the port where PHP-FPM will be listening
EXPOSE 8000

# Start PHP-FPM
CMD ["php-fpm"]
