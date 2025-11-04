FROM serversideup/php:8.3-fpm-nginx

WORKDIR /var/www/html

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
