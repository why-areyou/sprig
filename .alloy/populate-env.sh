#!/usr/bin/env bash
# Idempotent env setup for Alloy sessions.
# Creates/updates .env with local-dev-safe defaults without clobbering real values.
set -euo pipefail

cd "$(dirname "$0")/.."
ENV_FILE=".env"
touch "$ENV_FILE"

set_default() {
  local key="$1" value="$2"
  local current=""
  if grep -q "^${key}=" "$ENV_FILE"; then
    current="$(sed -n "s/^${key}=//p" "$ENV_FILE" | head -n1)"
  fi
  # Prefer a value already present in the process environment.
  local from_env="${!key:-}"
  if [ -n "$from_env" ]; then
    value="$from_env"
  elif [ -n "$current" ]; then
    return 0
  fi
  if grep -q "^${key}=" "$ENV_FILE"; then
    python3 - "$ENV_FILE" "$key" "$value" <<'PY'
import sys
path, key, value = sys.argv[1:4]
lines = open(path).read().splitlines()
out = [f"{key}={value}" if l.startswith(key + "=") else l for l in lines]
open(path, "w").write("\n".join(out) + "\n")
PY
  else
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  fi
}

set_default PUBLIC_MAX_ITERATIONS 20000
set_default PUBLIC_MAX_LOOP_TIME_MS 5000
set_default PUBLIC_SIGNALING_SERVER_HOST localhost:4444
set_default MAX_ATTEMPTS 10
set_default LOCKOUT_DURATION_MS 600000
set_default DEV_CODE "$(openssl rand -hex 16)"
set_default IS_ALLOY "${IS_ALLOY:-true}"

# Optional integrations: leave blank placeholders so import.meta.env lookups resolve.
for key in FIREBASE_CREDENTIAL RECAPTCHA_API_KEY AIRTABLE_TOKEN GRAPHITE_HOST \
  STUCK_AIRTABLE_BASE SENDGRID_API_KEY LOOPS_API_KEY PUBLIC_SPRIG_LLM_API \
  EMAIL_FROM EMAIL_REPLY_TO GITHUB_CLIENT_SECRET PUBLIC_GITHUB_CLIENT_ID \
  PUBLIC_GITHUB_REDIRECT_URI PUBLIC_GALLERY_API; do
  if ! grep -q "^${key}=" "$ENV_FILE"; then
    printf '%s=%s\n' "$key" "${!key:-}" >> "$ENV_FILE"
  fi
done

echo "env file ready at $(pwd)/$ENV_FILE"
