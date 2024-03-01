#!/usr/bin/env bash

export PGPASSWORD="${POSTGRES_PASSWORD}"

psql -v ON_ERROR_STOP=1 --host "${DASHBOARD_DB_HOST}" --port "${DASHBOARD_DB_PORT}" --username "${DASHBOARD_DB_USER}" --dbname "postgres" <<-EOSQL
    SELECT 'CREATE DATABASE ${DASHBOARD_DB} TABLESPACE plugins' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DASHBOARD_DB}')\gexec
EOSQL

