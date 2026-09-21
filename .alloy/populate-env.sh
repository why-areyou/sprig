#!/usr/bin/env bash
# Idempotently create/populate .env for local Alloy dev runs.
set -euo pipefail

cd "$(dirname "$0")/.."
ENV_FILE=".env"
touch "$ENV_FILE"

get_val() {
  sed -n "s/^$1=//p" "$ENV_FILE" | tail -n1
}

set_if_blank() {
  local key="$1" val="$2"
  local current
  current="$(get_val "$key")"
  if [ -n "$current" ]; then
    return 0
  fi
  if grep -q "^$key=" "$ENV_FILE"; then
    # replace the blank entry
    local tmp
    tmp="$(mktemp)"
    awk -v k="$key" -v v="$val" -F= '
      $1 == k && !done { print k "=" v; done=1; next }
      { print }
    ' "$ENV_FILE" > "$tmp"
    mv "$tmp" "$ENV_FILE"
  else
    printf '%s=%s\n' "$key" "$val" >> "$ENV_FILE"
  fi
}

# Values taken from the process env when available, otherwise local-dev-safe defaults.
set_if_blank FIREBASE_CREDENTIAL "${FIREBASE_CREDENTIAL:-}"
set_if_blank RECAPTCHA_API_KEY "${RECAPTCHA_API_KEY:-}"
set_if_blank AIRTABLE_TOKEN "${AIRTABLE_TOKEN:-}"
set_if_blank PUBLIC_MAX_ITERATIONS "${PUBLIC_MAX_ITERATIONS:-100000}"
set_if_blank PUBLIC_MAX_LOOP_TIME_MS "${PUBLIC_MAX_LOOP_TIME_MS:-1500}"
# node-statsd just fires UDP packets; localhost keeps it a no-op locally.
set_if_blank GRAPHITE_HOST "${GRAPHITE_HOST:-127.0.0.1}"
set_if_blank STUCK_AIRTABLE_BASE "${STUCK_AIRTABLE_BASE:-}"
set_if_blank SENDGRID_API_KEY "${SENDGRID_API_KEY:-}"
set_if_blank LOOPS_API_KEY "${LOOPS_API_KEY:-}"
set_if_blank DEV_CODE "$(printf '%s' "${DEV_CODE:-}" || true)"
if [ -z "$(get_val DEV_CODE)" ]; then
  set_if_blank DEV_CODE "$(openssl rand -hex 16)"
fi
set_if_blank PUBLIC_SPRIG_LLM_API "${PUBLIC_SPRIG_LLM_API:-}"
set_if_blank EMAIL_FROM "${EMAIL_FROM:-dev@example.com}"
set_if_blank EMAIL_REPLY_TO "${EMAIL_REPLY_TO:-dev@example.com}"
set_if_blank PUBLIC_SIGNALING_SERVER_HOST "${PUBLIC_SIGNALING_SERVER_HOST:-localhost:8000}"
set_if_blank GITHUB_CLIENT_SECRET "${GITHUB_CLIENT_SECRET:-}"
set_if_blank PUBLIC_GITHUB_CLIENT_ID "${PUBLIC_GITHUB_CLIENT_ID:-}"
set_if_blank PUBLIC_GITHUB_REDIRECT_URI "${PUBLIC_GITHUB_REDIRECT_URI:-http://localhost:8080/api/auth/github/callback}"
set_if_blank PUBLIC_GALLERY_API "${PUBLIC_GALLERY_API:-}"
set_if_blank MAX_ATTEMPTS "${MAX_ATTEMPTS:-10}"
set_if_blank LOCKOUT_DURATION_MS "${LOCKOUT_DURATION_MS:-900000}"
set_if_blank IS_ALLOY "${IS_ALLOY:-false}"

echo "populate-env: .env is ready"
