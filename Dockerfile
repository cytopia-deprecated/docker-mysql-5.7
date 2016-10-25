##
## MySQL 5.7
##
FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>


##
## Labels
##
LABEL \
	name="cytopia's MySQL 5.7 Image" \
	image="mysql-5.7" \
	vendor="cytopia" \
	license="MIT" \
	build-date="2016-10-25"


##
## Bootstrap Scipts
##
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /


##
## Install
##
RUN /docker-install.sh


##
## Ports
##
EXPOSE 3306


##
## Volumes
##
VOLUME /var/lib/mysql
VOLUME /var/log/mysql
VOLUME /var/sock/mysqld
VOLUME /etc/mysql/conf.d


##
## Entrypoint
##
ENTRYPOINT ["/docker-entrypoint.sh"]
