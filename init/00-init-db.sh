#!/usr/bin/env bash

#===
# 00-init-db.sh: Wrapper script for the setting up schemas, users and data types
# @priority 0
#
#===

set -eEa -o pipefail

#===
# Variables
#===
export PGPASSWORD="${DASHBOARD_DB_PASSWORD}"
export PRIORITY=1
LOCKFILE_PATH="/checkpoints/${ENVIRONMENT}/plugins/dashboard-plugin-redash/"
LOCKFILE="0${PRIORITY}-init-db.complete"


#===
# Functions
#===

##
# traperr: Better error handling
##
traperr() {
  echo "ERROR: ${BASH_SOURCE[1]} at about ${BASH_LINENO[0]}"
}

##
# create_db: Create dashboard DB
##
create_db() {
    psql -v ON_ERROR_STOP=1 --host "${DASHBOARD_DB_HOST}" --port "${DASHBOARD_DB_PORT}" --username "${DASHBOARD_DB_USER}" --dbname "postgres" <<-EOSQL
        SELECT 'CREATE DATABASE ${DASHBOARD_DB} TABLESPACE plugins' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DASHBOARD_DB}')\gexec
	EOSQL
    psql -v ON_ERROR_STOP=1 --host "${DASHBOARD_DB_HOST}" --port "${DASHBOARD_DB_PORT}" --username "${DASHBOARD_DB_USER}" --dbname "postgres" <<-EOSQL
        CREATE EXTENSION IF NOT EXISTS postgres_fdw;
	EOSQL
}

##
# init: Initialize DB
##
init() {
    # Create schemas, accounts ENUMs etc.
    echo "Initializing DB...."
    CURRENT_HOST=$(hostname)
    if [[ "${CURRENT_HOST}" = "fieldsets-dashboard" ]]; then
        create_db
        exec /app/manage.py database create_tables
    fi;
    echo "DB Initialized."
}

#===
# Main
#===
mkdir -p "${LOCKFILE_PATH}"
if [[ ! -f "${LOCKFILE_PATH}${LOCKFILE}" ]]; then
    init
    touch "${LOCKFILE_PATH}${LOCKFILE}";
fi

trap '' 2 3
trap traperr ERR