#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/.wallpapers"
STATE_DIR="$HOME/.local/state/hypr"
STATE="$STATE_DIR/wallpaper"

mkdir -p "$STATE_DIR"

mapfile -t names < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -printf '%f\n' | sort -f)

[ ${#names[@]} -gt 0 ] || exit 0

choice=$(printf '%s\n' "${names[@]}" | fuzzel --dmenu --prompt='wallpaper: ' -i)
[ -n "${choice:-}" ] || exit 0

full="$WALL_DIR/$choice"
[ -f "$full" ] || exit 0

pkill -x swaybg 2>/dev/null || true
swaybg -m stretch -i "$full" >/dev/null 2>&1 &

"$HOME/.config/hypr/scripts/apply-colors.sh" "$full"

printf '%s\n' "$full" > "$STATE"
