FROM wenbin1989/php-nginx:5.5
MAINTAINER Wenbin Wang <wenbin1989@gmail.com>

# install persistent / runtime deps
RUN apt-get update && apt-get install -y \
        imagemagick \
        libfreetype6 \
        libgif4 \
        libicu52 \
        libjpeg62-turbo \
        libmcrypt4 \
        libpng12-0 \
        libpq5 \
    --no-install-recommends && rm -r /var/lib/apt/lists/*

# install PHP extensions
RUN set -xe \
    && buildDeps=" \
        libbz2-dev \
        libfreetype6-dev \
        libgif-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libmagickwand-dev \
        libmcrypt-dev \
        libpng12-dev \
        libpq-dev \
    " \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        --with-png-dir=/usr/include --enable-gd-native-ttf \
    && docker-php-ext-install -j$(nproc) bz2 gd intl mbstring mcrypt mysql mysqli opcache pdo_mysql pcntl zip \
    && echo '' | pecl install imagick \
    && pecl install rar \
    && pecl install redis \
    && pecl install xdebug \
    # Note that we only need xdebug in development environment, so we did not enable it here.
    && docker-php-ext-enable imagick rar redis \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps

# install infosec extensions for ICBC
COPY lib /usr/lib
RUN mv /usr/lib/infosec.so "$(php -r 'echo ini_get("extension_dir");')"

# copy configurations
COPY etc/nginx-default.conf /etc/nginx/conf.d/default.conf
COPY etc/php.ini-Production /usr/local/etc/php/php.ini

