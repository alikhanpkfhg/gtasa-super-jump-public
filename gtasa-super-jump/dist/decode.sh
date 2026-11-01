#!/usr/bin/env bash
# decode.sh - restore gtasa.super_jump.csi from the base64 copy in this repo.
#
# The compiled binary is stored as base64 so the repository stays text-only.
# Always verify the SHA-256 afterwards (see README).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/gtasa.super_jump.csi"
base64 -d "$HERE/gtasa.super_jump.csi.b64" > "$OUT"
echo "wrote $OUT ($(stat -c%s "$OUT") bytes)"
sha256sum "$OUT"
echo "expected: af56c16335373710e22b11ede25c839ccf50e8db83c72a2c774d32a1107606fb"
