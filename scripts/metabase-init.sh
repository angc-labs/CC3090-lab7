#!/bin/sh
set -eu
MB_URL=${MB_URL:-http://metabase:3000}
POSTGRES_HOST=${POSTGRES_HOST:-postgres}
POSTGRES_DB=${POSTGRES_DB:-retailmax}
POSTGRES_USER=${POSTGRES_USER:-calificar}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-secret123+}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
ADMIN_EMAIL=${METABASE_ADMIN_EMAIL:-calificar@uvg.edu.gt}
ADMIN_PASSWORD=${METABASE_ADMIN_PASSWORD:-secret123+}
SITE_NAME=${METABASE_SITE_NAME:-RetailMax Lab}
METABASE_DATABASE_NAME=${METABASE_DATABASE_NAME:-RetailMax}

COOKIE_JAR=$(mktemp)
cleanup() {
  rm -f "$COOKIE_JAR"
}
trap cleanup EXIT

log() {
  echo "[metabase-init] $1" >&2
}

api_post() {
  path=$1
  body=$2
  response_file=$(mktemp)
  code=$(curl -sS -o "$response_file" -w "%{http_code}" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -X POST "$MB_URL$path" \
    -H "Content-Type: application/json" \
    -d "$body" || true)
  response_body=$(cat "$response_file")
  rm -f "$response_file"

  printf '%s\n%s' "$code" "$response_body"
}

api_get() {
  path=$1
  response_file=$(mktemp)
  code=$(curl -sS -o "$response_file" -w "%{http_code}" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    "$MB_URL$path" || true)
  response_body=$(cat "$response_file")
  rm -f "$response_file"

  printf '%s\n%s' "$code" "$response_body"
}

get_setup_token() {
  curl -sS "$MB_URL/api/session/properties" \
    | tr -d '\n' \
    | sed -n 's/.*"setup-token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

# wait for Metabase to be reachable
until curl -sSf "$MB_URL/" >/dev/null 2>&1; do
  log "Waiting for Metabase..."
  sleep 2
done
log "Metabase reachable, attempting setup..."

login_payload=$(cat <<EOF
{"username":"$ADMIN_EMAIL","password":"$ADMIN_PASSWORD"}
EOF
)

# helper: wait for setup-token to appear (returns token or empty)
wait_for_setup_token() {
  attempts=0
  while [ $attempts -lt 30 ]; do
    attempts=$((attempts+1))
    token=$(get_setup_token || true)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
      printf '%s' "$token"
      return 0
    fi
    sleep 2
  done
  return 1
}

# Try to login; if login fails, attempt initial /api/setup using the setup-token (if available).
login_response=$(api_post "/api/session" "$login_payload")
login_code=$(printf '%s' "$login_response" | sed -n '1p')
login_body=$(printf '%s' "$login_response" | sed -n '2,$p')

if [ "$login_code" != "200" ]; then
  log "Initial login failed with HTTP $login_code"
  if [ -n "$login_body" ]; then
    log "Login response body: $login_body"
  fi

  # Wait a bit for Metabase to surface the setup-token (if it's still initializing)
  setup_token=""
  if setup_token=$(wait_for_setup_token); then
    log "Found setup token; attempting first-time setup"
    setup_payload=$(cat <<EOF
{"token":"$setup_token","prefs":{"site_name":"$SITE_NAME","site_locale":"en"},"user":{"first_name":"Calificar","last_name":"Admin","email":"$ADMIN_EMAIL","password":"$ADMIN_PASSWORD"}}
EOF
)

    # Try POST /api/setup a few times
    i=0
    while [ $i -lt 5 ]; do
      i=$((i+1))
      setup_response=$(api_post "/api/setup" "$setup_payload")
      setup_code=$(printf '%s' "$setup_response" | sed -n '1p')
      setup_body=$(printf '%s' "$setup_response" | sed -n '2,$p')

      log "Setup attempt $i response HTTP $setup_code"
      if [ -n "$setup_body" ]; then
        log "Setup response body: $setup_body"
      fi

      if [ "$setup_code" = "200" ] || [ "$setup_code" = "201" ] || [ "$setup_code" = "400" ] || [ "$setup_code" = "403" ]; then
        break
      fi

      sleep 2
    done
  else
    log "No setup token available after waiting; Metabase may already be initialized or still starting."
  fi

  # Try login again after possible setup
  login_response=$(api_post "/api/session" "$login_payload")
  login_code=$(printf '%s' "$login_response" | sed -n '1p')
  login_body=$(printf '%s' "$login_response" | sed -n '2,$p')

  if [ "$login_code" != "200" ]; then
    log "Login failed with HTTP $login_code after setup attempts"
    if [ -n "$login_body" ]; then
      log "Login response body: $login_body"
    fi
    exit 0
  fi
fi

log "Logged into Metabase as $ADMIN_EMAIL"

databases_response=$(api_get "/api/database")
databases_code=$(printf '%s' "$databases_response" | sed -n '1p')
databases_body=$(printf '%s' "$databases_response" | sed -n '2,$p')

if [ "$databases_code" != "200" ]; then
  log "Could not read database list (HTTP $databases_code)"
  if [ -n "$databases_body" ]; then
    log "Database list response body: $databases_body"
  fi
  exit 0
fi

if printf '%s' "$databases_body" | grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$METABASE_DATABASE_NAME\""; then
  log "Database $METABASE_DATABASE_NAME is already registered in Metabase."
  exit 0
fi

database_payload=$(cat <<EOF
{"name":"$METABASE_DATABASE_NAME","engine":"postgres","details":{"host":"$POSTGRES_HOST","port":$POSTGRES_PORT,"dbname":"$POSTGRES_DB","user":"$POSTGRES_USER","password":"$POSTGRES_PASSWORD"}}
EOF
)

database_response=$(api_post "/api/database" "$database_payload")
database_code=$(printf '%s' "$database_response" | sed -n '1p')
database_body=$(printf '%s' "$database_response" | sed -n '2,$p')

if [ "$database_code" = "200" ] || [ "$database_code" = "201" ]; then
  log "Registered PostgreSQL database $METABASE_DATABASE_NAME in Metabase."
else
  log "Failed to register database (HTTP $database_code)"
  if [ -n "$database_body" ]; then
    log "Database create response body: $database_body"
  fi
fi

exit 0
