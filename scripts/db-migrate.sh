#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/db-common.sh"

psql_in_container -f /docker-entrypoint-initdb.d/migrations/001_init.sql
