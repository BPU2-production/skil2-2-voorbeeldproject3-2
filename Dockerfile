# Multi-stage Dockerfile for Laravel with Nginx

# Stage 1: PHP-FPM
FROM php:8.2-fpm as laravel-app

# Install dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy composer files first (for better caching)
COPY composer.json composer.lock ./

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy Laravel files
COPY . .

# Run post-install scripts
RUN composer run-script post-install-cmd --no-interaction || true

# Create storage directories if they don't exist
RUN mkdir -p storage/logs storage/framework/{cache,sessions,views} \
    && chown -R www-data:www-data /var/www \
    && chmod -R 775 storage bootstrap/cache

# Stage 2: Nginx + PHP-FPM
FROM nginx:alpine

# Install PHP-FPM
RUN apk add --no-cache php82-fpm php82-pdo_mysql php82-mbstring \
    php82-xml php82-gd php82-curl php82-zip php82-bcmath \
    php82-tokenizer php82-fileinfo php82-json php82-session \
    supervisor

# Copy Laravel app from previous stage
COPY --from=laravel-app /var/www /var/www

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create PHP-FPM configuration
RUN echo '[global]' > /etc/php82/php-fpm.d/docker.conf \
    && echo 'error_log = /proc/self/fd/2' >> /etc/php82/php-fpm.d/docker.conf \
    && echo '[www]' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'user = nginx' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'group = nginx' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'listen = 127.0.0.1:9000' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'pm = dynamic' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'pm.max_children = 5' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'pm.start_servers = 2' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'pm.min_spare_servers = 1' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'pm.max_spare_servers = 3' >> /etc/php82/php-fpm.d/docker.conf \
    && echo 'access.log = /proc/self/fd/2' >> /etc/php82/php-fpm.d/docker.conf

# Create supervisor configuration
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf \
    && echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'user=root' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '[program:nginx]' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'command=nginx -g "daemon off;"' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stderr_logfile=/var/log/nginx.err.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stdout_logfile=/var/log/nginx.out.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '[program:php-fpm]' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'command=php-fpm82 -F' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stderr_logfile=/var/log/php-fpm.err.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stdout_logfile=/var/log/php-fpm.out.log' >> /etc/supervisor/conf.d/supervisord.conf

# Set correct permissions
RUN chown -R nginx:nginx /var/www \
    && chmod -R 755 /var/www/storage /var/www/bootstrap/cache

# Expose port
EXPOSE 80

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
