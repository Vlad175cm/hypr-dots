#!/usr/bin/env bash
# Point btop at the freshly written matugen theme and make it reload.

conf="$HOME/.config/btop/btop.conf"
[ -f "$conf" ] && sed -i 's|^color_theme.*|color_theme = "matugen"|' "$conf" 2>/dev/null || true
pkill -USR2 -x btop >/dev/null 2>&1 || true
