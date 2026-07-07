#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/db-common.sh"

mkdir -p backup
backup_file="backup/${DB_NAME}-$(date +%Y%m%d-%H%M%S).sql.gz"

docker exec -i "${DB_CONTAINER}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" | gzip > "${backup_file}"
echo "Backup written to ${backup_file}"
