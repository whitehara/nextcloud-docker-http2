# ADD CRON and SMBCLIENT
# see https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles
FROM local-nextcloud:25-apache-zts

RUN apt-get update && apt-get install -y \
    supervisor procps smbclient redis-server imagemagick \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord

RUN echo "[supervisord]\n\
nodaemon=true\n\
logfile=/var/log/supervisord/supervisord.log\n\
pidfile=/var/run/supervisord/supervisord.pid\n\
childlogdir=/var/log/supervisord/\n\
logfile_maxbytes=50MB                           ; maximum size of logfile before rotation\n\
logfile_backups=10                              ; number of backed up logfiles\n\
loglevel=error\n\
\n\
[program:redis-server]\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
user=redis\n\
command=redis-server /etc/redis/redis.conf\n\
\n\
[program:php-fpm]\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
command=php-fpm -F -O\n\
\n\
[program:apache2]\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
command=apache2-foreground\n\
\n\
[program:cron]\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
command=/cron.sh" > /supervisord.conf

# disable unused Apache2 module & enable used modules
RUN a2dismod access_compat reqtimeout status mpm_prefork
RUN a2dismod -f deflate
RUN a2enmod mpm_event proxy_fcgi proxy http2 rewrite headers setenvif env mime dir alias remoteip filter brotli

# enable FastCGI
RUN sed -i -e "s!SetHandler .*!SetHandler 'proxy:unix:/var/run/php-fpm/php-fpm.sock|fcgi://localhost'!g" /etc/apache2/conf-enabled/docker-php.conf
RUN echo "SetEnv proxy-sendcl 1" >> /etc/apache2/conf-enabled/docker-php.conf
RUN echo "AddOutputFilterByType BROTLI_COMPRESS text/html text/plain text/xml text/css text/javascript application/javascript application/json image/svg+xml" >> /etc/apache2/conf-enabled/docker-php.conf

RUN cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
RUN sed -i -e "s/include=NONE\//include=/g" /usr/local/etc/php-fpm.conf

RUN mkdir -p /var/run/php-fpm
RUN cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf
RUN sed -i -e "s!^\(listen =\).*!\1 /var/run/php-fpm/php-fpm.sock!g" \
           -e "s/^;\(listen.\(owner\|group\) = www-data\)/\1/g" \
           -e "s/^\(pm =\).*/\1 ondemand/g" \
           -e "s/^\(pm.max_children =\).*/\1 \${PHP_FPM_MAX_CHILDREN}/g" \
           -e "s/^;\(pm.process_idle_timeout =\).*/\1 \${PHP_FPM_PROCESS_IDLE_TIMEOUT}/g" \
           -e "s/^;\(pm.max_requests =\).*/\1 \${PHP_FPM_MAX_REQUESTS}/g" \
           -e "s/^;\(catch_workers_output =\).*/\1 yes/g" \
           -e "s/^;\(php_admin_value\[error_log\] =\).*/\1 \/dev\/stderr/g" \
           -e "s/^;\(php_admin_flag\[log_errors\] =\).*/\1 on/g" \
/usr/local/etc/php-fpm.d/www.conf

ENV PHP_FPM_MAX_CHILDREN=5
ENV PHP_FPM_PROCESS_IDLE_TIMEOUT=10s
ENV PHP_FPM_MAX_REQUESTS=400

# Tune APCu
RUN echo "apc.shm_size = ${PHP_APC_SHM_SIZE}" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

ENV PHP_APC_SHM_SIZE=128M

# Make local cache dir
# You can use it in config.php > config_path
RUN mkdir -p /var/www/nxc_cache && chown www-data /var/www/nxc_cache

# Install redis using with unixsocket
RUN mkdir -p /var/run/redis && chown redis:redis /var/run/redis
RUN sed -i -e "s/^\(port\) .*/\1 0/g" \
          -e "s/^\(daemonize\) .*/\1 no/g" \
          -e "s!^\(logfile\) .*!\1 ''!g" \
          -e "s/^\(always-show-logo\) .*/\1 no/g" \
          -e "s/^# \(unixsocket \)/\1/g" \
          -e "s/^# \(unixsocketperm\) .*/\1 770/g" \
          -e "s/^\(save .*\)/# \1/g" \
          /etc/redis/redis.conf
RUN usermod -a -G redis www-data

# Enable PDF preview
# You can use it with modifying config.php
RUN sed -i -e "s/\(domain=\"coder\" rights=\"\)none\(\" pattern=\"PDF\)/\1read\|write\2/g" /etc/ImageMagick-6/policy.xml

# Enable max upload files count
RUN echo "max_file_uploads=\${PHP_UPLOAD_COUNT}" >> /usr/local/etc/php/conf.d/nextcloud.ini

ENV PHP_UPLOAD_COUNT=20

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
