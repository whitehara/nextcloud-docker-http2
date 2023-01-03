# ADD CRON and SMBCLIENT
# see https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles
FROM local-nextcloud:25-apache-zts

RUN apt-get update && apt-get install -y \
    supervisor procps smbclient imagemagick \
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

# enable FastCGI
RUN a2enmod proxy proxy_fcgi && a2dismod php
RUN sed -i -e "s!SetHandler .*!SetHandler 'proxy:unix:/var/run/php-fpm/php-fpm.sock|fcgi://localhost'!g" /etc/apache2/conf-enabled/docker-php.conf

RUN cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
RUN sed -i -e "s/include=NONE\//include=/g" /usr/local/etc/php-fpm.conf

RUN mkdir -p /var/run/php-fpm
RUN cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf
RUN sed -i -e "s!^\(listen =\).*!\1 /var/run/php-fpm/php-fpm.sock!g" \
           -e "s/^;\(listen.\(owner\|group\) = www-data\)/\1/g" \
/usr/local/etc/php-fpm.d/www.conf

# Tune APCu
RUN echo "apc.shm_size = 128M" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

# Enable HTTP/2
RUN a2dismod mpm_prefork && a2enmod mpm_event
RUN a2enmod http2

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
