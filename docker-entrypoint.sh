#!/usr/bin/env bash
set -euo pipefail

log() {
  local level="$1"; shift
  printf '[%s] %s\n' "$level" "$*"
}

wait_for_service() {
  local name="$1" host="$2" port="$3" timeout="${4:-300}" interval="${5:-1}"
  local start end
  start=$(date +%s)
  end=$((start + timeout))
  log INFO "Waiting for ${name} at ${host}:${port} (timeout: ${timeout}s)..."
  while true; do
    if nc -z "$host" "$port" >/dev/null 2>&1; then
      log INFO "${name} is up."
      return 0
    fi
    log INFO "${name} not ready yet; retrying in ${interval}s..."
    if (( $(date +%s) >= end )); then
      log ERROR "Timed out waiting for ${name} at ${host}:${port}."
      return 1
    fi
    sleep "$interval"
  done
}

# Parse database connection info from DATABASE_URL or discrete env vars
normalise_db_env() {
  local url="${DATABASE_URL:-}"
  local env_host="${POSTGRES_HOST:-}"
  local env_port="${POSTGRES_PORT:-}"
  local env_user="${POSTGRES_USER:-}"
  local env_pass="${POSTGRES_PASSWORD:-}"
  local env_db="${POSTGRES_DB:-postgres}"

  local url_scheme="" url_userinfo="" url_host="" url_port="" url_path="" url_query=""

  if [[ -n "$url" ]]; then
    if [[ "$url" =~ ^([^:]+)://([^@/]+@)?([^/:?]+)(:([0-9]+))?([^?]*)(\?.*)?$ ]]; then
      url_scheme="${BASH_REMATCH[1]}"
      url_userinfo="${BASH_REMATCH[2]}"
      url_host="${BASH_REMATCH[3]}"
      url_port="${BASH_REMATCH[5]}"
      url_path="${BASH_REMATCH[6]}"
      url_query="${BASH_REMATCH[7]}"
      if [[ -n "$url_userinfo" ]]; then
        url_userinfo="${url_userinfo%@}"
      fi
    fi
  fi

  local host="$env_host"
  local port="$env_port"

  if [[ -z "$host" && -n "$url_host" ]]; then
    host="$url_host"
  fi
  if [[ -z "$port" && -n "$url_port" ]]; then
    port="$url_port"
  fi

  host="${host}"
  port="${port:-5432}"

  export POSTGRES_HOST="$host"
  export POSTGRES_PORT="$port"

  if [[ -n "$url" ]]; then
    local rebuild=0
    if [[ -n "$url_host" && "$url_host" != "$host" ]]; then
      rebuild=1
    fi
    if [[ -n "$url_port" && "$url_port" != "$port" ]]; then
      rebuild=1
    fi
    if (( rebuild )); then
      local auth="$url_userinfo"
      if [[ -z "$auth" && -n "$env_user" ]]; then
        auth="$env_user"
        if [[ -n "$env_pass" ]]; then
          auth+=":${env_pass}"
        fi
      fi
      local path="$url_path"
      if [[ -z "$path" ]]; then
        path="/${env_db}"
      fi
      local new_url="${url_scheme:-postgresql}://"
      if [[ -n "$auth" ]]; then
        new_url+="$auth@"
      fi
      new_url+="${host}:${port}${path}${url_query}"
      export DATABASE_URL="$new_url"
    fi
  elif [[ -n "$host" ]]; then
    local auth=""
    if [[ -n "$env_user" ]]; then
      auth="$env_user"
      if [[ -n "$env_pass" ]]; then
        auth+=":${env_pass}"
      fi
      auth+="@"
    fi
    export DATABASE_URL="postgresql://${auth}${host}:${port}/${env_db}"
  fi
}

normalise_db_env

# Export DATABASE_URL derived from components when missing
if [[ -z "${DATABASE_URL:-}" && -n "${POSTGRES_HOST:-}" ]]; then
  auth=""
  if [[ -n "${POSTGRES_USER:-}" ]]; then
    auth="${POSTGRES_USER}"
    if [[ -n "${POSTGRES_PASSWORD:-}" ]]; then
      auth+=":${POSTGRES_PASSWORD}"
    fi
    auth+="@"
  fi
  db="${POSTGRES_DB:-postgres}"
  export DATABASE_URL="postgresql://${auth}${POSTGRES_HOST}:${POSTGRES_PORT:-5432}/${db}"
fi


# Wait for Postgres when connection details are provided
if [[ -n "${POSTGRES_HOST:-}" ]]; then
  host="${POSTGRES_HOST}"
  port="${POSTGRES_PORT:-}"

  # Allow POSTGRES_HOST to include a port (host:port) and normalise the values.
  if [[ "$host" == *:* ]]; then
    host_part="${host%%:*}"
    port_part="${host##*:}"
    if [[ "$host_part" != "" && "$port_part" != "$host_part" ]]; then
      host="$host_part"
      if [[ -z "$port" ]]; then
        port="$port_part"
      fi
    fi
  fi

  port="${port:-5432}"
  export POSTGRES_HOST="$host"
  export POSTGRES_PORT="$port"
  # Use longer timeout for migrations, shorter for regular app startup
  if [[ "${SERVICE_ROLE:-}" == "migrate" ]]; then
    db_timeout="${POSTGRES_WAIT_TIMEOUT:-300}"
  else
    db_timeout="${POSTGRES_WAIT_TIMEOUT:-60}"
  fi
  wait_for_service "Postgres" "$host" "$port" "$db_timeout" "${POSTGRES_WAIT_INTERVAL:-1}"
else
  log INFO "Skipping Postgres wait; no host configured."
fi

# Run migrations unless explicitly skipped
if [[ "${RUN_DB_MIGRATIONS:-1}" = "1" && "${SKIP_DB_MIGRATIONS:-0}" != "1" ]]; then
  log INFO "Applying database migrations..."
  python manage.py migrate --noinput || {
    log ERROR "Database migrations failed."
    exit 1
  }
else
  if [[ "${SKIP_DB_MIGRATIONS:-0}" = "1" ]]; then
    log INFO "Skipping database migrations (SKIP_DB_MIGRATIONS=1)."
  else
    log INFO "Skipping database migrations (RUN_DB_MIGRATIONS=${RUN_DB_MIGRATIONS:-0})."
  fi
fi

# Optional: load initial data
# python manage.py loaddata initial_data.json || true

log INFO "Starting application process: $*"
log INFO "Application environment: DJANGO_ENV=${DJANGO_ENV:-unknown}, SERVICE_ROLE=${SERVICE_ROLE:-unknown}"
exec "$@"
