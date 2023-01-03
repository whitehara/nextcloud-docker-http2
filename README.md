# nextcloud-docker-http2
HTTP/2, PHP-FPM and Samba client enabled Nextcloud docker image
## What's this?
This docker image is Nextcloud image which is enabled HTTP/2, PHP-FPM and Samba client with small memory tweaks.
## How to build docker image?
```
git clone https://github.com/whitehara/nextcloud-docker-http2 .
cd nextcloud-docker-http2
./build.sh
```
You get "nextcloud-custom" image.

## How to run the docker image
You can run this image like the normal nextcloud image.
Please see: https://github.com/nextcloud/docker

## Details
This docker image is based on three parts.

### 1. php
The 1st part is customized php. It is originaly from https://github.com/docker-library/php/tree/master/8.1/bullseye/apache

And add these compile options.

- for zts(Threadsafe worker)
  - --enable-zts
  - --disable-zend-signals
- for fpm
  - --enable-fpm
  - --with-fpm-user=www-data
  - --with-fpm-group=www-data

### 2.nextcloud
The 2nd part is nextcloud. It is originaly from https://github.com/nextcloud/docker/tree/master/25/apache

There is no extra customize. Just use the 1st php image.

### 3.nextcloud-custom
The last part is customized nextcloud. It is based on the 2nd image. The additional customizes are below. (See also Dockerfile)

- Install supervisor (for cron and php-fpm)
- Install smbclient (Samba client)
- Enable php-fpm
- Tune APCu shared memory size to 128M (default=32M)  
- Disable mpm_prefork &Enable mpm_event
- Enable HTTP/s
