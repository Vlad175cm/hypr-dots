#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/shot-$(date +%Y%m%d-%H%M%S).png"

mode="${1:-area}"
case "$mode" in
    area)
        GEOM=$(slurp) || exit 0
        [ -n "$GEOM" ] || exit 0
        grim -g "$GEOM" "$FILE"
        ;;
    window)
        GEOM=$(hyprctl -j activewindow | python3 -c 'import json,sys; w=json.load(sys.stdin); a=w["at"]; s=w["size"]; print("%d,%d %dx%d" % (a[0], a[1], s[0], s[1]))')
        [ -n "$GEOM" ] && [ "$GEOM" != "null" ] || exit 0
        grim -g "$GEOM" "$FILE"
        ;;
    full)
        grim "$FILE"
        ;;
    *)
        echo "usage: screenshot.sh area|window|full" >&2
        exit 1
        ;;
esac

wl-copy < "$FILE"
notify-send -t 2500 "screenshot saved" "$FILE" || true
