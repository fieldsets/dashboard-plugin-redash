#!/usr/bin/env bash

# This script will set up foreign data servers for our fieldsets postgresql instance.

set -e

export PRIORITY=10
export PGPASSWORD="${DASHBOARD_DB_PASSWORD}"
LOCKFILE_PATH="/data/checkpoints/${ENVIRONMENT}/plugins/dashboard-plugin-redash/"
LOCKFILE="${PRIORITY}-import-foreign-data.complete"

mkdir -p "${LOCKFILE_PATH}"
if [[ ! -f "${LOCKFILE_PATH}${LOCKFILE}" ]]; then

    psql -v ON_ERROR_STOP=1 --host "${DASHBOARD_DB_HOST}" --port "${DASHBOARD_DB_PORT}" --username "${DASHBOARD_DB_USER}" --dbname "${DASHBOARD_DB}" <<-EOSQL
        CREATE EXTENSION IF NOT EXISTS postgres_fdw;
        CREATE SCHEMA IF NOT EXISTS fieldsets;
	EOSQL

    psql -v ON_ERROR_STOP=1 --host "${POSTGRES_HOST}" --port "${POSTGRES_PORT}" --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        CREATE SERVER IF NOT EXISTS redash_server
            FOREIGN DATA WRAPPER postgres_fdw
            OPTIONS (host '${DASHBOARD_DB_HOST}', port '${DASHBOARD_DB_PORT}', dbname '${DASHBOARD_DB}');

        CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER SERVER redash_server OPTIONS (user '${DASHBOARD_DB_USER}', password '${DASHBOARD_DB_PASSWORD}');

        CREATE SCHEMA IF NOT EXISTS ${DASHBOARD_DB};

        IMPORT FOREIGN SCHEMA public
        FROM SERVER redash_server INTO ${DASHBOARD_DB};
	EOSQL


    # Postgres
    #psql -v ON_ERROR_STOP=1 --host "${DASHBOARD_DB_HOST}" --port "${DASHBOARD_DB_PORT}" --username "${DASHBOARD_DB_USER}" --dbname "${DASHBOARD_DB}" <<-EOSQL
    #CREATE EXTENSION IF NOT EXISTS postgres_fdw;
    #CREATE SERVER IF NOT EXISTS fieldsets_server
    #    FOREIGN DATA WRAPPER postgres_fdw
    #    OPTIONS (host '${POSTGRES_HOST}', port '${POSTGRES_PORT}', dbname '${POSTGRES_DB}');

    #CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER SERVER fieldsets_server OPTIONS (user '${POSTGRES_USER}', password '${POSTGRES_PASSWORD}');
    
    #CREATE SCHEMA IF NOT EXISTS ${POSTGRES_DB};

	#EOSQL

    #IMPORT FOREIGN SCHEMA ${POSTGRES_DB}
    #FROM SERVER fieldsets_server INTO ${POSTGRES_DB};


    echo "Complete!"

    touch "${LOCKFILE_PATH}${LOCKFILE}";
    echo "Mapped External Data."
fi