FROM php:8.3-fpm

# Arguments for user/group IDs
ARG USER_ID=1000
ARG GROUP_ID=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    libcurl4-openssl-dev \
    pkg-config \
    libssl-dev \
    libicu-dev \
    libxslt1-dev \
    libmemcached-dev \
    zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure GD with all image formats
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

# Install core PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mysqli \
    mbstring \
    zip \
    exif \
    pcntl \
    bcmath \
    gd \
    opcache \
    intl \
    xml \
    soap \
    xsl \
    curl \
    sockets \
    gettext \
    iconv

# Install PECL extensions
RUN pecl install redis-6.0.2 \
    && pecl install apcu-5.1.23 \
    && pecl install igbinary-3.2.15 \
    && pecl install msgpack-2.2.0 \
    && pecl install memcached-3.2.0 \
    && docker-php-ext-enable \
        redis \
        apcu \
        igbinary \
        msgpack \
        memcached

# Configure OPcache for JIT (PHP 8.3)
RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.enable_cli=1'; \
        echo 'opcache.memory_consumption=2048'; \
        echo 'opcache.interned_strings_buffer=64'; \
        echo 'opcache.max_accelerated_files=100000'; \
        echo 'opcache.max_wasted_percentage=5'; \
        echo 'opcache.use_cwd=1'; \
        echo 'opcache.validate_timestamps=0'; \
        echo 'opcache.revalidate_freq=0'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.enable_file_override=1'; \
        echo 'opcache.max_file_size=2048'; \
        echo 'opcache.file_cache=/tmp/opcache'; \
        echo 'opcache.huge_code_pages=1'; \
        echo 'opcache.jit=tracing'; \
        echo 'opcache.jit_buffer_size=256M'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# Configure APCu
RUN { \
        echo 'apc.enabled=1'; \
        echo 'apc.shm_size=512M'; \
        echo 'apc.ttl=7200'; \
        echo 'apc.enable_cli=1'; \
        echo 'apc.serializer=igbinary'; \
    } > /usr/local/etc/php/conf.d/apcu.ini

# Configure Redis with igbinary serializer
RUN { \
        echo 'redis.serializer=igbinary'; \
        echo 'redis.compression=lz4'; \
        echo 'redis.compression_level=3'; \
    } > /usr/local/etc/php/conf.d/redis.ini

# Create OPcache file cache directory
RUN mkdir -p /tmp/opcache && chmod 777 /tmp/opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN groupadd -g ${GROUP_ID} www && \
    useradd -u ${USER_ID} -ms /bin/bash -g www www

# Create log directory
RUN mkdir -p /var/log/php && \
    chown -R www:www /var/log/php

# Set working directory
WORKDIR /var/www

# Copy existing application directory
COPY --chown=www:www . /var/www

# Change ownership of the application directory
RUN chown -R www:www /var/www

# Configure PHP-FPM to run as www user with optimized settings
RUN { \
        echo '[global]'; \
        echo 'daemonize = no'; \
        echo 'error_log = /var/log/php/fpm-error.log'; \
        echo 'log_level = warning'; \
        echo ''; \
        echo '[www]'; \
        echo 'user = www'; \
        echo 'group = www'; \
        echo 'listen = 9000'; \
        echo 'listen.owner = www'; \
        echo 'listen.group = www'; \
        echo 'listen.mode = 0660'; \
        echo 'pm = dynamic'; \
        echo 'pm.max_children = 100'; \
        echo 'pm.start_servers = 20'; \
        echo 'pm.min_spare_servers = 10'; \
        echo 'pm.max_spare_servers = 30'; \
        echo 'pm.max_requests = 1000'; \
        echo 'pm.process_idle_timeout = 10s'; \
        echo 'pm.status_path = /status'; \
        echo 'ping.path = /ping'; \
        echo 'ping.response = pong'; \
        echo 'access.log = /var/log/php/fpm-access.log'; \
        echo 'access.format = "%R - %u %t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"'; \
        echo 'slowlog = /var/log/php/fpm-slow.log'; \
        echo 'request_slowlog_timeout = 5s'; \
        echo 'request_terminate_timeout = 30s'; \
        echo 'catch_workers_output = yes'; \
        echo 'decorate_workers_output = no'; \
        echo 'clear_env = no'; \
        echo 'security.limit_extensions = .php'; \
        echo ''; \
        echo '; Dynamic process management tuning'; \
        echo 'rlimit_files = 65536'; \
        echo 'rlimit_core = unlimited'; \
        echo ''; \
        echo '; PHP flags'; \
        echo 'php_admin_value[memory_limit] = 512M'; \
        echo 'php_admin_value[error_log] = /var/log/php/fpm-php-error.log'; \
        echo 'php_admin_flag[log_errors] = on'; \
        echo 'php_admin_flag[display_errors] = off'; \
        echo 'php_admin_value[error_reporting] = E_ALL & ~E_DEPRECATED & ~E_STRICT'; \
        echo 'php_admin_value[post_max_size] = 64M'; \
        echo 'php_admin_value[upload_max_filesize] = 64M'; \
        echo 'php_admin_value[max_execution_time] = 30'; \
        echo 'php_admin_value[max_input_time] = 60'; \
        echo 'php_admin_value[max_input_vars] = 10000'; \
        echo 'php_admin_value[realpath_cache_size] = 16384K'; \
        echo 'php_admin_value[realpath_cache_ttl] = 600'; \
        echo 'php_admin_value[session.save_handler] = redis'; \
        echo 'php_admin_value[session.save_path] = "tcp://redis:6379?auth=yourpassword"'; \
    } > /usr/local/etc/php-fpm.d/www.conf

# Create health check script
RUN { \
        echo '#!/bin/sh'; \
        echo 'SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 | grep "pong" > /dev/null 2>&1'; \
    } > /usr/local/bin/health-check && chmod +x /usr/local/bin/health-check

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/bin/health-check || exit 1

# Switch to www user
USER www

# Expose port 9000
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]