# 1. Base image with PHP and required extensions
FROM php:8.2-fpm

# 2. Install dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 4. Set working directory
WORKDIR /var/www

# 5. Copy composer files first (for better caching)
COPY composer.json composer.lock ./

# 6. Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts

# 7. Copy Laravel files
COPY . .

# 8. Run post-install scripts
RUN composer run-script post-install-cmd --no-interaction || true

# 9. Set correct permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 storage bootstrap/cache

# 10. Create storage directories if they don't exist
RUN mkdir -p storage/logs storage/framework/{cache,sessions,views} \
    && chown -R www-data:www-data storage \
    && chmod -R 775 storage

# 11. Expose port
EXPOSE 9000

# 12. Use www-data for PHP-FPM
USER www-data

CMD ["php-fpm"]
