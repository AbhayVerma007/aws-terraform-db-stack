#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/db-common.sh"

backup_file="${1:-}"

if [[ -z "${backup_file}" ]]; then
  backup_file="$(ls -1t backup/*.sql.gz 2>/dev/null | head -n 1)"
fi

if [[ -z "${backup_file}" ]]; then
  echo "No backup files found in ./backup"
  exit 1
fi

gunzip -c "${backup_file}" | docker exec -i "${DB_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}"
echo "Restored from ${backup_file}"
