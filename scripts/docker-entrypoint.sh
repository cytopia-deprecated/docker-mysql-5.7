#!/bin/sh -eu

###
### Variables
###
DEBUG_COMMANDS=0


###
### Functions
###
run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"


	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi


	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"
	_clr_info="\033[0;34m"
	_clr_warn="\033[0;33m"
	_clr_err="\033[0;31m"
	_clr_rst="\033[0m"

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}


###
### Read out MySQL Default config
###
get_mysql_default_config() {
	_key="${1}"
	mysqld --verbose --help  2>/dev/null  | awk -v key="${_key}" '$1 == key { print $2; exit }'
}


###
### Set MySQL Custom options
###
set_mysql_custom_settings() {
	_conf_sect="${1}"
	_mysql_key="${2}"
	_shell_var="${3}"
	_extra_val="${4}"	# Extra value to append to _shell_var
	_conf_file="${5}"


	if ! set | grep "^${_shell_var}=" >/dev/null 2>&1; then
		_mysql_val="$( get_mysql_default_config "${_mysql_key}" )"
		log "info" "\$${_shell_var} not set. Keeping default: [${_conf_sect}] ${_mysql_key}=${_mysql_val}"

	else
		_shell_val="$( eval "echo \${${_shell_var}}" )"
		_value="${_shell_val}${_extra_val}"

		if [ "${_value}" = "" ]; then
			_mysql_val="$( get_mysql_default_config "${_mysql_key}" )"
			log "warn" "\$${_shell_var} is empty. Keeping default: [${_conf_sect}] ${_mysql_key}=${_mysql_val}"

		else
			log "info" "Setting MySQL: [${_conf_sect}] ${_mysql_key}=${_value}"

			# Add file
			if [ ! -f "${_conf_file}" ]; then
				run "touch ${_conf_file}"
			fi

			# Add section
			if ! grep -q "\[${_conf_sect}\]" "${_conf_file}"; then
				run "echo '[${_conf_sect}]' >> ${_conf_file}"
				run "echo '${_mysql_key} = ${_value}' >> ${_conf_file}"

			else
				run "sed -i'' 's|\[${_conf_sect}\]|\[${_conf_sect}\]\n${_mysql_key} = ${_value}|g' ${_conf_file}"
			fi
		fi
	fi
}




################################################################################
# BOOTSTRAP
################################################################################

if set | grep '^DEBUG_COMPOSE_ENTRYPOINT='  >/dev/null 2>&1; then
	if [ "${DEBUG_COMPOSE_ENTRYPOINT}" = "1" ]; then
		DEBUG_COMMANDS=1
	fi
fi



################################################################################
# ENVIRONMENTAL CHECKS
################################################################################



###
### MySQL Password Options
###
if ! set | grep '^MYSQL_ROOT_PASSWORD=' >/dev/null 2>&1; then
	log "err" "\$MYSQL_ROOT_PASSWORD must be set."
	exit 1
fi


################################################################################
# MAIN ENTRY POINT
################################################################################


###
### Adjust timezone
###

if ! set | grep '^TIMEZONE='  >/dev/null 2>&1; then
	log "warn" "\$TIMEZONE not set."
else
	if [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
		# Unix Time
		log "info" "Setting docker timezone to: ${TIMEZONE}"
		run "rm /etc/localtime"
		run "ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
	else
		log "err" "Invalid timezone for \$TIMEZONE."
		log "err" "\$TIMEZONE: '${TIMEZONE}' does not exist."
		exit 1
	fi
fi
log "info" "Docker date set to: $(date)"




###
### Add custom Configuration
###

# MYSQL_GENERAL_LOG
set_mysql_custom_settings "mysqld" "general-log" "MYSQL_GENERAL_LOG" "" "${MYSQL_BASE_INCL}/logging.cnf"

# MYSQL_SOCKET_DIR
set_mysql_custom_settings "client" "socket" "MYSQL_SOCKET_DIR" "/mysqld.sock" "${MYSQL_BASE_INCL}/socket.cnf"
set_mysql_custom_settings "mysql"  "socket" "MYSQL_SOCKET_DIR" "/mysqld.sock" "${MYSQL_BASE_INCL}/socket.cnf"
set_mysql_custom_settings "mysqld" "socket" "MYSQL_SOCKET_DIR" "/mysqld.sock" "${MYSQL_BASE_INCL}/socket.cnf"

# Take care about custom socket directories
if set | grep "^MYSQL_SOCKET_DIR=" >/dev/null 2>&1; then

	# Create socket directory
	if [ ! -d "${MYSQL_SOCKET_DIR}" ]; then
		run "mkdir -p ${MYSQL_SOCKET_DIR}"

	# Delete existing socket file
	elif [ -f "${MYSQL_SOCKET_DIR}/mysqld.sock" ]; then
		run "rm -f ${MYSQL_SOCKET_DIR}/mysqld.sock"
	fi

	# Set socket permission
	run "chown ${MY_USER}:${MY_GROUP} ${MYSQL_SOCKET_DIR}"
	run "chmod 0777 ${MYSQL_SOCKET_DIR}"
fi




################################################################################
# INSTALLATION
################################################################################

DB_DATA_DIR="$( get_mysql_default_config "datadir" )"


##
## INSTALLATION
##

# Fixing permissions
if [ ! -f "${MYSQL_LOG_QUERY}" ]; then
	run "touch ${MYSQL_LOG_QUERY}"
fi
if [ ! -f "${MYSQL_LOG_SLOW}" ]; then
	run "touch ${MYSQL_LOG_SLOW}"
fi
if [ ! -f "${MYSQL_LOG_ERROR}" ]; then
	run "touch ${MYSQL_LOG_ERROR}"
fi

run "chown -R ${MY_USER}:${MY_GROUP} ${DB_DATA_DIR}"
run "chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_DAT}"
run "chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_LOG}"
run "chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_PID}"
run "chown -R ${MY_USER}:${MY_GROUP} ${MYSQL_DEF_SCK}"

run "chmod 0775 ${DB_DATA_DIR}"
run "chmod 0775 ${MYSQL_DEF_DAT}"
run "chmod 0775 ${MYSQL_DEF_LOG}"
run "chmod 0775 ${MYSQL_DEF_PID}"
run "chmod 0775 ${MYSQL_DEF_SCK}"

run "find ${MYSQL_DEF_LOG}/ -type f -exec chmod 0664 {} \;"

# Directory already exists and has content (other thab '.' and '..')
if [ -d "${DB_DATA_DIR}/mysql" ] && [ "$( ls -A "${DB_DATA_DIR}/mysql" )" ]; then
	log "info" "Found existing data directory. MySQL already setup."

else

	log "info" "No existing MySQL data directory found. Setting up MySQL for the first time."

	# Create datadir if not exist yet
	if [ ! -d "${DB_DATA_DIR}" ]; then
		log "info" "Creating empty data directory in: ${DB_DATA_DIR}."
		run "mkdir -p ${DB_DATA_DIR}"
		run "chown -R ${MY_USER}:${MY_GROUP} ${DB_DATA_DIR}"
		run "chmod 0777 ${MY_USER}:${MY_GROUP} ${DB_DATA_DIR}"
	fi


	# Install Database
	run "mysqld --initialize-insecure --datadir=${DB_DATA_DIR} --user=${MY_USER}"


	# Start server
	run "mysqld --skip-networking &"


	# Wait at max 60 seconds for it to start up
	i=0
	max=60
	while [ $i -lt $max ]; do
		if echo 'SELECT 1' |  mysql --protocol=socket -uroot  > /dev/null 2>&1; then
			break
		fi
		log "info" "Initializing ..."
		sleep 1s
		i=$(( i + 1 ))
	done


	# Get current pid
	pid="$(pgrep mysqld | head -1)"
	if [ "${pid}" = "" ]; then
		log "err" "Could not find running MySQL PID."
		log "err" "MySQL init process failed."
		exit 1
	fi


	# Bootstrap MySQL
	log "info" "Setting up root user permissions."
	echo "DELETE FROM mysql.user ;" | mysql --protocol=socket -uroot
	echo "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;" | mysql --protocol=socket -uroot
	echo "GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;" | mysql --protocol=socket -uroot
	echo "DROP DATABASE IF EXISTS test ;" | mysql --protocol=socket -uroot
	echo "FLUSH PRIVILEGES ;" | mysql --protocol=socket -uroot


	# Shutdown MySQL
	log "info" "Shutting down MySQL."
	run "kill -s TERM ${pid}"
	i=0
	max=60
	while [ $i -lt $max ]; do
		if ! pgrep mysqld >/dev/null 2>&1; then
			break
		fi
		sleep 1s
		i=$(( i + 1 ))
	done


	# Check if it is still running
	if pgrep mysqld >/dev/null 2>&1; then
		log "err" "Unable to shutdown MySQL server."
		log "err" "MySQL init process failed."
		exit 1
	fi
	log "info" "MySQL successfully installed."

fi



###
### Start
###
log "info" "Starting $(mysqld --version)"
exec mysqld
