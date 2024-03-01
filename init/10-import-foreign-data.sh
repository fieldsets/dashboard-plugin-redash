#!/usr/bin/env bash

# This script will set up foreign data servers for our fieldsets postgresql instance.

set -e

export PRIORITY=10
export PGPASSWORD="${DASHBOARD_DB_PASSWORD}"
LOCKFILE_PATH="/data/checkpoints/${ENVIRONMENT}/plugins/dashboard-plugin-redash/"
LOCKFILE="${PRIORITY}-import-foreign-data.complete"

mkdir -p "${LOCKFILE_PATH}"
if [[ ! -f "${LOCKFILE_PATH}${LOCKFILE}" ]]; then

    psql -v ON_ERROR_STOP=0 --host "${DASHBOARD_DB_HOST}" --port "${DASHBOARD_DB_PORT}" --username "${DASHBOARD_DB_USER}" --dbname "${DASHBOARD_DB}" <<-EOSQL
        CREATE EXTENSION IF NOT EXISTS postgres_fdw;
	EOSQL

    psql -v ON_ERROR_STOP=0 --host "${POSTGRES_HOST}" --port "${POSTGRES_PORT}" --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        CREATE SERVER IF NOT EXISTS redash_server
            FOREIGN DATA WRAPPER postgres_fdw
            OPTIONS (host '${DASHBOARD_DB_HOST}', port '${DASHBOARD_DB_PORT}', dbname '${DASHBOARD_DB}');

        CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER SERVER redash_server OPTIONS (user '${DASHBOARD_DB_USER}', password '${DASHBOARD_DB_PASSWORD}');
	EOSQL
    echo "Complete!"

    touch "${LOCKFILE_PATH}${LOCKFILE}";
    echo "Mapped External Data."
fi