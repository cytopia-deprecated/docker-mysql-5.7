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
	build-date="2017-04-20"


###
### Envs
###

# User/Group
ENV MY_USER="mysql"
ENV MY_GROUP="mysql"
ENV MY_UID="48"
ENV MY_GID="48"

# Files
ENV MYSQL_INCL="/etc/mysql/conf.d"
ENV MYSQL_CUST_INCL="/etc/mysql/docker-default.d"
ENV MYSQL_DEF_DAT="/var/lib/mysql"
ENV MYSQL_DEF_LOG="/var/log/mysql"
ENV MYSQL_DEF_PID="/var/run/mysqld"
ENV MYSQL_DEF_SCK="/var/sock/mysqld"


###
### Install
###
RUN groupadd -g ${MY_GID} -r ${MY_GROUP} && \
	adduser ${MY_USER} -u ${MY_UID} -M -s /sbin/nologin -g ${MY_GROUP}

RUN \
	yum -y install epel-release && \
	rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm && \
	yum-config-manager --disable mysql55-community && \
	yum-config-manager --disable mysql56-community && \
	yum-config-manager --enable mysql57-community && \
	yum clean all

RUN yum -y update && yum -y install \
	mysql-community-server

RUN \
	yum -y autoremove && \
	yum clean metadata && \
	yum clean all && \
	yum -y install hostname && \
	yum clean all


##
## Configure
##
RUN \
	mkdir -p ${MYSQL_INCL} && \
	mkdir -p ${MYSQL_CUST_INCL} && \
	mkdir -p ${MYSQL_DEF_DAT} && \
	mkdir -p ${MYSQL_DEF_SCK} && \
	mkdir -p ${MYSQL_DEF_PID} && \
	mkdir -p ${MYSQL_DEF_LOG} && \
	\
	chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_INCL} && \
	chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_CUST_INCL} && \
	chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_DAT} && \
	chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_SCK} && \
	chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_PID} && \
	chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_LOG} && \
	\
	chmod 0775 ${MYSQL_INCL} && \
	chmod 0775 ${MYSQL_CUST_INCL} && \
	chmod 0775 ${MYSQL_DEF_DAT} && \
	chmod 0775 ${MYSQL_DEF_SCK} && \
	chmod 0775 ${MYSQL_DEF_PID} && \
	chmod 0775 ${MYSQL_DEF_LOG}

RUN \
	echo "[client]"                                         > /etc/my.cnf && \
	echo "socket = ${MYSQL_DEF_SCK}/mysqld.sock"           >> /etc/my.cnf && \
	\
	echo "[mysql]"                                         >> /etc/my.cnf && \
	echo "socket = ${MYSQL_DEF_SCK}/mysqld.sock"           >> /etc/my.cnf && \
	\
	echo "[mysqld]"                                        >> /etc/my.cnf && \
	echo "skip-host-cache"                                 >> /etc/my.cnf && \
	echo "skip-name-resolve"                               >> /etc/my.cnf && \
	echo "datadir = ${MYSQL_DEF_DAT}"                      >> /etc/my.cnf && \
	echo "user = ${MY_USER}"                               >> /etc/my.cnf && \
	echo "port = 3306"                                     >> /etc/my.cnf && \
	echo "bind-address = 0.0.0.0"                          >> /etc/my.cnf && \
	echo "socket = ${MYSQL_DEF_SCK}/mysqld.sock"           >> /etc/my.cnf && \
	echo "pid-file = ${MYSQL_DEF_PID}/mysqld.pid"          >> /etc/my.cnf && \
	echo "general_log_file = ${MYSQL_DEF_LOG}/mysql.log"   >> /etc/my.cnf && \
	echo "slow_query_log_file = ${MYSQL_DEF_LOG}/slow.log" >> /etc/my.cnf && \
	echo "log-error = ${MYSQL_DEF_LOG}/error.log"          >> /etc/my.cnf && \
	echo "!includedir ${MYSQL_INCL}/"                      >> /etc/my.cnf && \
	echo "!includedir ${MYSQL_CUST_INCL}/"                 >> /etc/my.cnf


##
## Bootstrap Scipts
##
COPY ./scripts/docker-entrypoint.sh /


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
