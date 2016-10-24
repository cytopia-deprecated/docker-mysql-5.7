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

COUNT="$( docker ps | grep -c "cytopia/${NAME}" || true)"
if [ "${COUNT}" != "1" ]; then
	echo "${COUNT} container running. Unable to attach."
	exit 1
fi

DID="$(docker ps | grep "cytopia/${NAME}" | awk '{print $1}')"

echo "Attaching to: cytopia/${NAME}"
run "docker exec -i -t ${DID} env TERM=xterm /bin/bash -l"

