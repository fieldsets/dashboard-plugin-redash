#!/usr/bin/env bash

#===
# 00-init.sh: Wrapper script for your docker container
# See shell coding standards for details of formatting.
# https://github.com/Fieldsets/fieldsets-pipeline/blob/main/docs/developer/coding-standards/shell.md
#
# @envvar VERSION | String
# @envvar ENVIRONMENT | String
#
#===

set -eEa -o pipefail

#===
# Variables
#===

##
# start: Wrapper start up function. Executes everything in mapped init directory.
##
start() {
	# Let's wait for our DBs to accept connections.
	echo "Waiting for Postgres container...."
	timeout 90s bash -c "until pg_isready -h "${DASHBOARD_DB_HOST}" -p "${DASHBOARD_DB_PORT}" -U "${DASHBOARD_DB_USER}"; do printf '.'; sleep 5; done; printf '\n'"
	echo "PostgreSQL is ready for connections."

	#make sure our scripts are flagged at executable.
	chmod +x /docker-entrypoint-init.d/*.sh
	# After everything has booted, run any custom scripts.
	for f in /docker-entrypoint-init.d/*.sh; do
		echo $f;
		bash -c "exec ${f}";
	done
}

#===
# Main
#===
start

env >> /etc/environment

exec /app/bin/docker-entrypoint "$@"
