#!/usr/bin/env bash
# Release Play app bundle with prod dart-defines (flavors/prod.json).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLAVOR="${CARDGAME_FLAVOR:-flavors/prod.json}"

cd "${ROOT}"

if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
else
  FLUTTER=(flutter)
fi

"${FLUTTER[@]}" build appbundle --release --dart-define-from-file="${FLAVOR}" "$@"
