#!/bin/sh -eu


###
### Variables
###
MY_USER="mysql"
MY_GROUP="mysql"
MY_UID="27"
MY_GID="27"

MYSQL_DEF_INCL="/etc/mysql/docker-default.d"
MYSQL_INCL="/etc/mysql/conf.d"

###
### Can be overwritten in docker-entrypoint.sh
### via user-supplied variables
###
MYSQL_DEF_DAT="/var/lib/mysql"		# Data directory
MYSQL_DEF_LOG="/var/log/mysql"		# Log directory
MYSQL_DEF_PID="/var/run/mysqld"		# Pid directory
MYSQL_DEF_SCK="/var/sock/mysqld"	# Socket directory



###
### Functions
###
print_headline() {
	_txt="${1}"
	_blue="\033[0;34m"
	_reset="\033[0m"

	printf "${_blue}\n%s\n${_reset}" "--------------------------------------------------------------------------------"
	printf "${_blue}- %s\n${_reset}" "${_txt}"
	printf "${_blue}%s\n\n${_reset}" "--------------------------------------------------------------------------------"
}

run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


################################################################################
# MAIN ENTRY POINT
################################################################################


###
### Adding User/Group
###
print_headline "1. Adding Users"
run "groupadd -g ${MY_GID} -r ${MY_GROUP}"
run "adduser ${MY_USER} -u ${MY_UID} -M -s /sbin/nologin -g ${MY_GROUP}"



###
### Adding Repositories
###
print_headline "2. Adding Repository"
run "rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm"
run "yum-config-manager --disable mysql55-community"
run "yum-config-manager --disable mysql56-community"
run "yum-config-manager --enable mysql57-community"


###
### Updating Packages
###
print_headline "3. Updating Packages Manager"
run "yum clean all"
run "yum -y check"
run "yum -y update"



###
### Installing Packages
###
print_headline "4. Installing Packages"
run "yum -y install \
	mysql-community-server
	"



###
### Configure MySQL
###
print_headline "5. Configure MySQL"

# Add default directories and permission
if [ ! -d "${MYSQL_DEF_INCL}" ]; then run "mkdir -p ${MYSQL_DEF_INCL}"; fi
if [ ! -d "${MYSQL_INCL}" ];     then run "mkdir -p ${MYSQL_INCL}";     fi


if [ ! -d "${MYSQL_DEF_DAT}"  ]; then run "mkdir -p ${MYSQL_DEF_DAT}" ; fi
if [ ! -d "${MYSQL_DEF_SCK}"  ]; then run "mkdir -p ${MYSQL_DEF_SCK}" ; fi
if [ ! -d "${MYSQL_DEF_PID}"  ]; then run "mkdir -p ${MYSQL_DEF_PID}" ; fi
if [ ! -d "${MYSQL_DEF_LOG}"  ]; then run "mkdir -p ${MYSQL_DEF_LOG}" ; fi

run "chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_DAT}"
run "chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_SCK}"
run "chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_PID}"
run "chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_LOG}"

run "chmod 777 ${MYSQL_DEF_DAT}"
run "chmod 777 ${MYSQL_DEF_SCK}"
run "chmod 777 ${MYSQL_DEF_PID}"
run "chmod 777 ${MYSQL_DEF_LOG}"


# Add default config
run "echo '[client]'										> /etc/mysql/my.cnf"
run "echo 'socket = ${MYSQL_DEF_SCK}/mysqld.sock'			>> /etc/mysql/my.cnf"

run "echo '[mysql]'											>> /etc/mysql/my.cnf"
run "echo 'socket = ${MYSQL_DEF_SCK}/mysqld.sock'			>> /etc/mysql/my.cnf"

run "echo '[mysqld]'										>> /etc/mysql/my.cnf"
run "echo 'skip-host-cache'									>> /etc/mysql/my.cnf"
run "echo 'skip-name-resolve'								>> /etc/mysql/my.cnf"
run "echo 'datadir = ${MYSQL_DEF_DAT}'						>> /etc/mysql/my.cnf"
run "echo 'user = ${MY_USER}'								>> /etc/mysql/my.cnf"
run "echo 'port = 3306'										>> /etc/mysql/my.cnf"
run "echo 'bind-address = 0.0.0.0'							>> /etc/mysql/my.cnf"
run "echo 'socket = ${MYSQL_DEF_SCK}/mysqld.sock'			>> /etc/mysql/my.cnf"
run "echo 'pid-file = ${MYSQL_DEF_PID}/mysqld.pid'			>> /etc/mysql/my.cnf"
run "echo 'general_log_file = ${MYSQL_DEF_LOG}/mysql.log'	>> /etc/mysql/my.cnf"
run "echo 'slow_query_log_file = ${MYSQL_DEF_LOG}/slow.log'	>> /etc/mysql/my.cnf"
run "echo 'log-error = ${MYSQL_DEF_LOG}/error.log'			>> /etc/mysql/my.cnf"
run "echo '!includedir ${MYSQL_DEF_INCL}/'					>> /etc/mysql/my.cnf"
run "echo '!includedir ${MYSQL_INCL}/'						>> /etc/mysql/my.cnf"


###
### Cleanup unecessary packages
###
print_headline "6. Cleanup unecessary packages"
run "yum -y autoremove"


###
### Fix Cleanup
###
print_headline "7. Fix Cleanup"
run "yum -y install hostname" # required for mysql_install_db

