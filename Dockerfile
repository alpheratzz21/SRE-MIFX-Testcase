#Using the official PHP image with FPM and Alpine Linux
FROM php:8.2-fpm-alpine

# Install nginx
RUN apk add --no-cache nginx nginx-mod-http-headers-more

# Create non-root user for security hardening
RUN adduser -D -g 'www' www

# Change user PHP-FPM from default to 'www'
RUN sed -i 's/user = www-data/user = www/' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/group = www-data/group = www/' /usr/local/etc/php-fpm.d/www.conf

# Unable PHP function  for security hardening
RUN echo "disable_functions = exec,passthru,shell_exec,system" > /usr/local/etc/php/conf.d/security.ini

# Create nginx run directory
RUN mkdir -p /run/nginx

# Copy application
COPY ./app/index.php /var/www/html/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set permissions for the www user
RUN chown -R www:www /var/www/html

# Expose port 80 for the web server
EXPOSE 80

# Start both PHP-FPM and nginx when the container starts
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]