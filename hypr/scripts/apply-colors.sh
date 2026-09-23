#!/usr/bin/env bash
set -euo pipefail

IMG="${1:-}"
[ -n "$IMG" ] && [ -f "$IMG" ] || { echo "usage: apply-colors.sh <image>" >&2; exit 1; }

matugen image "$IMG" --mode dark --prefer lightness

pkill -HUP mako 2>/dev/null; makoctl reload 2>/dev/null || true
kitty @ set-colors --all "$HOME/.config/kitty/matugen.conf" 2>/dev/null || true
notify-send -t 3000 "wallpaper" "palette updated: $(basename "$IMG")" || true
