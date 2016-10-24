#!/bin/sh -eu

run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

# Check Dockerfile
if [ ! -f "Dockerfile" ]; then
	echo "Dockerfile not found."
	exit 1
fi

# Get docker Name
if ! grep -q 'image=".*"' Dockerfile > /dev/null 2>&1; then
	echo "No 'image' LABEL found"
	exit
fi
NAME="$( grep 'image=".*"' Dockerfile | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
DATE="$( date '+%Y-%m-%d' )"


# Update build date
run "sed -i'' 's/build-date=\".*\"/build-date=\"${DATE}\"/g' Dockerfile"

# Build Docker
run "docker build -t cytopia/${NAME} ."
