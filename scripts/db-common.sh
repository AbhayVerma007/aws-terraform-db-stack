#!/usr/bin/env bash
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-tfdb-postgres}"
DB_USER="${DB_USER:-appuser}"
DB_NAME="${DB_NAME:-appdb}"

psql_in_container() {
  docker exec -i "${DB_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" "$@"
}
