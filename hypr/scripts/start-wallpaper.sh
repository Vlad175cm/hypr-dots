#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.local/state/hypr/wallpaper"
[ -f "$STATE" ] || exit 0
WALL="$(cat "$STATE")"
[ -f "$WALL" ] || exit 0

exec swaybg -m stretch -i "$WALL" >/dev/null 2>&1
