FROM alpine:3.10

WORKDIR /srv

RUN apk update && apk upgrade && apk add htop php7 php7-fpm php7-pdo_pgsql php7-pdo \
php7-json php7-phalcon nginx postgresql neovim git && \
cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
mkdir -p /run/postgresql && chown -R postgres:postgres /run/postgresql && \
mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql/data


USER postgres
RUN initdb -D /var/lib/postgresql/data -E 'UTF-8' --lc-collate='en_US.UTF-8' --lc-ctype='en_US.UTF-8' --auth-local=trust --auth-host=trust
VOLUME /var/lib/postgresql/data
COPY ./postgresql/postgresql.conf /var/lib/postgresql/data/postgresql.conf
COPY ./postgresql/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
COPY ./postgresql/pg_ident.conf /var/lib/postgresql/data/pg_ident.conf


USER root
RUN git clone git://github.com/phalcon/phalcon-devtools.git /srv/phalcon-webtools
RUN ln -s /srv/phalcon-webtools/phalcon /usr/sbin/phalcon
RUN /srv/phalcon-webtools/phalcon create-project app
RUN mv /srv/app /srv/app-tmp
RUN mkdir -p /srv/app && chown -R nginx:nginx /srv/app
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./php/php-fpm.d/www.conf /etc/php7/php-fpm.d/www.conf
COPY ./src /srv/app
RUN chown -R nginx:nginx /srv/app


USER root
RUN sed -i 's/display_errors = Off/display_errors = On/g' /etc/php7/php.ini
RUN echo "#!/bin/sh -e" >> /usr/sbin/start.sh && \
echo "/bin/su - postgres -c \"/usr/bin/pg_ctl -D /var/lib/postgresql/data start\"" >> /usr/sbin/start.sh && \
echo "mkdir -p /run/nginx && /usr/sbin/nginx -g \"daemon on;\"" >> /usr/sbin/start.sh && \
echo "/usr/sbin/php-fpm7 -D" >> /usr/sbin/start.sh && \
echo "/bin/sh" >> /usr/sbin/start.sh && \
chmod +x /usr/sbin/start.sh


CMD ["/usr/sbin/start.sh"]
