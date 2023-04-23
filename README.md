# nextcloud-docker-http2
HTTP/2, PHP-FPM, Redis cache and Samba client enabled Nextcloud docker image
## What's this?
This docker image is Nextcloud image which is enabled HTTP/2, PHP-FPM, Redis cache and Samba client with small memory tweaks.

This image is used to learn how it works. If you want to get the production ready one, I recommend to use https://github.com/nextcloud/all-in-one
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
The 2nd part is nextcloud. It is originaly from https://github.com/nextcloud/docker/tree/master/26/apache

There is no extra customize. Just use the 1st php image.

### 3.nextcloud-custom
The last part is customized nextcloud. It is based on the 2nd image. The additional customizes are below. (See also Dockerfile)

- Install supervisor (for cron and php-fpm)
- Install smbclient (Samba client)
- Enable php-fpm (ondemand)
  - You can change parameters by environments below.
    - pm.max_children: PHP_FPM_MAX_CHILDREN (default value:5)
    - pm.process_idle_timeout: PHP_FPM_PROCESS_IDLE_TIMEOUT (default value:10s)
    - pm.max_requests: PHP_FPM_MAX_REQUESTS (default value:400)
- Change php max upload count
  - You can change it by an environment below.
    - PHP_UPLOAD_COUNT (default value:20)

- Tune APCu shared memory size (original=32M)  
  - You can change it by an environment below.
    - PHP_APC_SHM_SIZE (default value:128M)

- Make local cache dir .You can use the fllolwing settings in the config/config.php
  ```
    'cache_path' => '/var/www/nxc_cache',
  ```
- Install Redis Server
  - You can use it to write the following settings in the config/config.php
  ```
    'memcache.distributed' => '\OC\Memcache\Redis',
  'redis' => [
	'host'     => '/var/run/redis/redis-server.sock',
	'port'     => 0,
	'dbindex'  => 0,
	'timeout'  => 1.5,
  ],
  ```
- Enable / Disable Apache2 modules.
  - Disabled mods
    - access_compat
    - reqtimeout
    - status
    - mpm_prefork
    - deflate
  - Enabled modes (This list contains some default enabled ones.)
    - mpm_event
    - proxy_fcgi
    - proxy
    - http2
    - rewrite
    - headers
    - setenvif
    - env
    - mime 
    - dir
    - alias
    - remoteip
    - filter
    - brotli
