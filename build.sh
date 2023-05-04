#!/bin/sh

### 1st stage: php ###
PHP_VER=8.1
PHP_TAG=local-php:$PHP_VER-apache-zts-bullseye
PHP_DIR=./php/$PHP_VER/bullseye/apache/

# Update the repository
(cd php; git reset --hard; git pull)
# Modify Dockerfile
sed -i -e "s/\(--with-apxs2\)/\1 --enable-zts --disable-zend-signals --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data /g" $PHP_DIR/Dockerfile
# Build
docker build -t $PHP_TAG --pull --no-cache $PHP_DIR

### 2nd stage: nextcloud ###
NEXTCLOUD_VER=`awk -F'.' '{print $1}' nextcloud/latest.txt`
NEXTCLOUD_TAG=local-nextcloud:$NEXTCLOUD_VER-apache-zts
NEXTCLOUD_DIR=./nextcloud/$NEXTCLOUD_VER/apache/

# Update the repository
(cd nextcloud; git reset --hard; git pull)
# Modify Dockerfile
sed -i -e "s!FROM .*!FROM $PHP_TAG!g" $NEXTCLOUD_DIR/Dockerfile
# Build
docker build -t $NEXTCLOUD_TAG $NEXTCLOUD_DIR

### 3rd stage: nextcloud-custom ###
CUSTOM_TAG=nextcloud-custom

# Modify Dockerfile
sed -i -e "s!FROM .*!FROM $NEXTCLOUD_TAG!g" ./Dockerfile
# Build
docker build -t $CUSTOM_TAG .
