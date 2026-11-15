#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_DIR="${TMPDIR:-/tmp}/flutter-sdk"
API_BASE_URL="${API_BASE_URL:?Set API_BASE_URL in Vercel project settings}"
SUPABASE_URL="${SUPABASE_URL:-${NEXT_PUBLIC_SUPABASE_URL:-}}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-${NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY:-}}"
: "${SUPABASE_URL:?Set SUPABASE_URL or NEXT_PUBLIC_SUPABASE_URL in Vercel project settings}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY or NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY in Vercel project settings}"

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

"$FLUTTER_DIR/bin/flutter" config --enable-web
"$FLUTTER_DIR/bin/flutter" pub get
"$FLUTTER_DIR/bin/flutter" build web --release \
  --dart-define="API_BASE_URL=$API_BASE_URL" \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
