#!/bin/sh

set -eu

MB_URL=${MB_URL:-http://metabase:3000}
RETRY_INTERVAL=${RETRY_INTERVAL:-3}
MAX_WAIT=${MAX_WAIT:-300}

start_ts=$(date +%s)

log() { printf "[wait-and-init] %s\n" "$*"; }

wait_for_metabase() {
  while true; do
    now=$(date +%s)
    elapsed=$((now - start_ts))
    if [ "$elapsed" -ge "$MAX_WAIT" ]; then
      log "Timed out waiting for Metabase after ${MAX_WAIT}s"
      return 1
    fi

    # Try a simple HTTP probe; handle DNS failures by retrying
    if curl -fsS "${MB_URL}/api/session/properties" >/dev/null 2>&1; then
      log "Metabase HTTP probe succeeded"
      return 0
    fi

    log "Waiting for Metabase..."
    sleep "$RETRY_INTERVAL"
  done
}

log "Starting wait-and-init (max wait ${MAX_WAIT}s, interval ${RETRY_INTERVAL}s)"
if wait_for_metabase; then
  log "Calling metabase-init.sh"
  exec /bin/sh /metabase-init.sh
else
  log "Metabase did not become ready; exiting with failure"
  exit 2
fi
