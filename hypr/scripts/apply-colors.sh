#!/usr/bin/env bash
set -euo pipefail

IMG="${1:-}"
[ -n "$IMG" ] && [ -f "$IMG" ] || { echo "usage: apply-colors.sh <image>" >&2; exit 1; }

matugen image "$IMG" --mode dark --prefer lightness

kitty @ set-colors --all "$HOME/.config/kitty/matugen.conf" 2>/dev/null || true
notify-send -t 2000 "palette updated" "$(basename "$IMG")" || true
