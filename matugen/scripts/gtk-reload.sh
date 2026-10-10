#!/usr/bin/env bash
set -u

OLD_WS=$(hyprctl -j clients 2>/dev/null | python3 -c 'import json,sys
try:
	ws=[w["workspace"]["id"] for w in json.load(sys.stdin) if w.get("class")=="org.gnome.Nautilus"]
	print(ws[0] if ws else "")
except Exception:
	pass' 2>/dev/null)

pgrep -x nautilus >/dev/null 2>&1 || exit 0

pkill -x nautilus >/dev/null 2>&1
sleep 0.2
setsid -f nautilus --new-window >/dev/null 2>&1 </dev/null
sleep 0.8

[ -n "$OLD_WS" ] || exit 0
ADDR=$(hyprctl -j clients 2>/dev/null | python3 -c 'import json,sys
for w in json.load(sys.stdin):
	if w.get("class")=="org.gnome.Nautilus":
		print(w["address"])
		break' 2>/dev/null)
[ -n "$ADDR" ] && hyprctl eval "hl.dispatch(hl.dsp.window.move({ window = \"address:$ADDR\", workspace = tostring($OLD_WS) }))" >/dev/null 2>&1
exit 0
