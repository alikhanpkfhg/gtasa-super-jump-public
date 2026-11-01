#!/usr/bin/env bash
# build.sh - compile gtasa.super_jump.txt into gtasa.super_jump.csi
#
# Requires: Sanny Builder 4.2.0 running under Wine (see the parent environment's
# setup.sh), $WINEPREFIX with $WINEPREFIX/drive_c/SannyBuilder/sanny.exe staged,
# and a display ($DISPLAY, Xvfb is fine - the CLI is a GUI app).
#
# Key point: the edit mode must be `sa_mobile` (Android). Compiling in the PC
# `sa` mode produces a .cs that GTA SA Android / CLEO Android will not load.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
: "${WINEPREFIX:=/workspace/.wine-sa}"
SB_DIR="$WINEPREFIX/drive_c/SannyBuilder"
WORK_HOST="$WINEPREFIX/drive_c/work/superjump"
WORK_WIN='C:\work\superjump'
SRC="$HERE/src/gtasa.super_jump.txt"
OUT_DIR="$HERE/dist"
NAME="gtasa.super_jump"

mkdir -p "$OUT_DIR" "$WORK_HOST" "$HERE/logs"
[[ -f "$SB_DIR/sanny.exe" ]] || { echo "FATAL: sanny.exe not staged in $SB_DIR" >&2; exit 3; }

if [[ ! -S "/tmp/.X11-unix/X${DISPLAY#:}" ]]; then
  echo "FATAL: no X display on $DISPLAY (Wine needs one; start Xvfb)" >&2
  exit 4
fi

# Sanny Builder is single-instance: a running GUI would swallow the CLI arguments.
wine taskkill /f /im sanny.exe >/dev/null 2>&1 || true
sleep 1

cp -f "$SRC" "$WORK_HOST/$NAME.txt"
rm -f "$WORK_HOST/$NAME.csi" "$SB_DIR/compile.log"
# Compiler::AddExtraInfo 0 strips the embedded source/debug chunk -> release size
# (351 bytes instead of 4142). Remove that --option to build the debug variant.
( cd "$SB_DIR" && timeout 90 wine sanny.exe --no-splash \
    --option Compiler::AddExtraInfo 0 \
    --compile "$WORK_WIN\\$NAME.txt" "$WORK_WIN\\$NAME.csi" --game sa_mobile \
    > "$HERE/logs/$NAME.wine.log" 2>&1 )

if [[ -s "$SB_DIR/compile.log" ]]; then
  echo "COMPILE FAILED:"; cat "$SB_DIR/compile.log"; exit 1
fi
[[ -s "$WORK_HOST/$NAME.csi" ]] || { echo "COMPILE FAILED: no output" >&2; exit 1; }

cp -f "$WORK_HOST/$NAME.csi" "$OUT_DIR/$NAME.csi"
cp -f "$SB_DIR/compile.log" "$HERE/logs/$NAME.compile.log" 2>/dev/null || \
  printf 'RESULT: PASS - compiler wrote no errors\n' > "$HERE/logs/$NAME.compile.log"
echo "OK: $OUT_DIR/$NAME.csi ($(stat -c%s "$OUT_DIR/$NAME.csi") bytes)"
sha256sum "$OUT_DIR/$NAME.csi"
