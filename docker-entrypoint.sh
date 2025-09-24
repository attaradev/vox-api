#!/usr/bin/env bash
set -euo pipefail

# Wait for Postgres
echo "Waiting for Postgres at ${POSTGRES_HOST}:${POSTGRES_PORT}..."
until nc -z "${POSTGRES_HOST}" "${POSTGRES_PORT}"; do
  sleep 0.5
done
echo "Postgres is up."

# Run migrations unless explicitly skipped
if [ "${RUN_DB_MIGRATIONS:-1}" = "1" ]; then
  python manage.py migrate --noinput
fi

# Optional: load initial data
# python manage.py loaddata initial_data.json || true

exec "$@"
