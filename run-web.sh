#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$APP_DIR/.env.local"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Copy .env.example to .env.local and set your Supabase values."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a
: "${API_BASE_URL:?Set API_BASE_URL in .env.local}"
: "${SUPABASE_URL:?Set SUPABASE_URL in .env.local}"
: "${SUPABASE_PUBLISHABLE_KEY:?Set SUPABASE_PUBLISHABLE_KEY in .env.local}"

WEB_PORT="${WEB_PORT:-8094}"
python3 - "$WEB_PORT" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket()
try:
    sock.bind(("127.0.0.1", port))
except OSError:
    print(f"Flutter web port {port} is already in use. Stop the existing app or set WEB_PORT.", file=sys.stderr)
    raise SystemExit(1)
finally:
    sock.close()
PY

exec flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port "$WEB_PORT" \
  --dart-define="API_BASE_URL=$API_BASE_URL" \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_PUBLISHABLE_KEY"
