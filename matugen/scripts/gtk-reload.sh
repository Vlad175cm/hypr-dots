#!/usr/bin/env bash
set -u

# nautilus интересен нам только если у него ЕСТЬ живое окно в Hyprland
WS=$(hyprctl -j clients 2>/dev/null | python3 -c 'import json,sys
try:
	ws=[w["workspace"]["id"] for w in json.load(sys.stdin) if w.get("class")=="org.gnome.Nautilus"]
	print(ws[0] if ws else "")
except Exception:
	pass' 2>/dev/null)

if [ -z "$WS" ]; then
	# окна нет: был фоновый/скрытый процесс — тихо убрать его,
	# чтобы при ручном запуске (Super+E) уже нарисовались новые цвета
	pkill -x nautilus >/dev/null 2>&1
	exit 0
fi

pkill -x nautilus >/dev/null 2>&1
sleep 0.2
setsid -f nautilus --new-window >/dev/null 2>&1 </dev/null
sleep 0.8

ADDR=$(hyprctl -j clients 2>/dev/null | python3 -c 'import json,sys
for w in json.load(sys.stdin):
	if w.get("class")=="org.gnome.Nautilus":
		print(w["address"])
		break' 2>/dev/null)
[ -n "$ADDR" ] && hyprctl eval "hl.dispatch(hl.dsp.window.move({ window = \"address:$ADDR\", workspace = tostring($WS) }))" >/dev/null 2>&1
exit 0
