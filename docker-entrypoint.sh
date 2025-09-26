#!/usr/bin/env bash
set -euo pipefail

# Wait for Postgres when connection details are provided
if [[ -n "${POSTGRES_HOST:-}" && -n "${POSTGRES_PORT:-}" ]]; then
  echo "Waiting for Postgres at ${POSTGRES_HOST}:${POSTGRES_PORT}..."
  until nc -z "${POSTGRES_HOST}" "${POSTGRES_PORT}"; do
    sleep 0.5
  done
  echo "Postgres is up."
else
  echo "Skipping Postgres wait; no host/port configured."
fi

# Run migrations unless explicitly skipped
if [[ "${RUN_DB_MIGRATIONS:-1}" = "1" ]]; then
  echo "Applying database migrations..."
  python manage.py migrate --noinput
else
  echo "Skipping database migrations (RUN_DB_MIGRATIONS=${RUN_DB_MIGRATIONS:-0})."
fi

# Optional: load initial data
# python manage.py loaddata initial_data.json || true

exec "$@"
