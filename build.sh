#!/bin/sh

# This script is not used on GitHub Actions.
# It is used to build the image locally.

### Envionment ###

NEXTCLOUD_VER=`awk -F'.' '{print $1}' nextcloud/latest.txt`
NEXTCLOUD_TAG=local-nextcloud:$NEXTCLOUD_VER-apache-zts
NEXTCLOUD_DIR=./nextcloud/$NEXTCLOUD_VER/apache/
PHP_VER=`sed -e "s/FROM php:\([0-9\.]*\)-apache-\(.*\)/\1/p" -e d $NEXTCLOUD_DIR/Dockerfile`
PHP_DEBIAN=`sed -e "s/FROM php:\([0-9\.]*\)-apache-\(.*\)/\2/p" -e d $NEXTCLOUD_DIR/Dockerfile`
PHP_TAG=local-php:$PHP_VER-apache-zts-$PHP_DEBIAN
PHP_DIR=./php/$PHP_VER/$PHP_DEBIAN/apache

### 1st stage: php ###

function build_php () {
	# Update the repository
	(cd php; git reset --hard; git pull https://github.com/docker-library/php/ master)
	# Modify Dockerfile
	sed -i -e "s/\(--with-apxs2\)/\1 --enable-zts --disable-zend-signals --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --with-bz2 /g" \
		-e "s/\(zlib1g-dev\)/\1 libbz2-dev/g" \
		-e "s/\(gnupg\)/\1 aria2/g" \
		-e "s/curl -fsSL/aria2c -x8/g" \
		$PHP_DIR/Dockerfile
	# Build
	docker build -t $PHP_TAG --pull --no-cache $PHP_DIR
}

### 2nd stage: nextcloud ###

function build_nextcloud () {
	# Update the repository
	(cd nextcloud; git reset --hard; git pull https://github.com/nextcloud/docker/ master)
	# Modify Dockerfile for faster download
	sed -i -e "s!FROM .*!FROM $PHP_TAG!g" \
		-e "s/\(rsync\)/\1 aria2/" \
		-e "s/curl -fsSL/aria2c -x8/g" \
		$NEXTCLOUD_DIR/Dockerfile
	# Build
	docker build -t $NEXTCLOUD_TAG $NEXTCLOUD_DIR
}

### 3rd stage: nextcloud-custom ###
CUSTOM_TAG=nextcloud-custom
function build_custom () {

	# Modify Dockerfile
	sed -i -e "s!FROM .*!FROM $NEXTCLOUD_TAG!g" ./Dockerfile
	# Build
	docker build -t $CUSTOM_TAG .
}

### MAIN ###
build_php
build_nextcloud
build_custom
