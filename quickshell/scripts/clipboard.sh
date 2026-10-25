#!/usr/bin/env bash
#
# clipboard.sh — the island's clipboard history.
#
#   clipboard.sh watch          run the clipboard watcher (login autostart)
#   clipboard.sh store          record whatever is on the clipboard now
#   clipboard.sh list           print the history as json (newest first)
#   clipboard.sh copy  <id>     put that entry back on the clipboard
#   clipboard.sh remove <id>    forget one entry
#   clipboard.sh clear          forget everything
#
# One entry is one file in ~/.cache/quickshell/clipboard: <unixtime>-<sha1>.txt
# for text, .png for an image. The name carries both the time (so pruning is
# just a filename comparison) and the content hash (so copying the same thing
# again moves the old entry to the top instead of piling up). Nothing is ever
# looked up in a database — reading the directory is the whole index, which is
# why the panel opens instantly.
set -uo pipefail

DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/clipboard"
TTL=$((4 * 24 * 60 * 60))
MAX_BYTES=$((1024 * 1024))
PREVIEW=160

mkdir -p "$DIR"
# the panel watches this file: touching it means "the history changed"
[ -e "$DIR/.changed" ] || : > "$DIR/.changed"

json_str() {
	local s="$1"
	s="${s//\\/\\\\}"
	s="${s//\"/\\\"}"
	s="${s//$'\n'/ }"
	s="${s//$'\r'/}"
	s="${s//$'\t'/ }"
	printf '"%s"' "$s"
}

prune() {
	local now cutoff f base ts
	now=$(date +%s)
	cutoff=$((now - TTL))
	for f in "$DIR"/*.txt "$DIR"/*.png; do
		[ -e "$f" ] || continue
		base=${f##*/}
		ts=${base%%-*}
		case "$ts" in ''|*[!0-9]*) continue ;; esac
		[ "$ts" -lt "$cutoff" ] && rm -f "$f"
	done
}

store() {
	local tmp types kind ext hash ts id

	# wl-paste --watch hands the new content to us on stdin. Drain it and read
	# the clipboard ourselves instead, so a clipboard that offers both text and
	# an image is recorded the way it should be.
	if [ ! -t 0 ]; then cat > /dev/null 2>&1 || true; fi

	types=$(timeout 3 wl-paste --list-types 2>/dev/null || true)
	tmp=$(mktemp "$DIR/.tmp.XXXXXX")
	if printf '%s\n' "$types" | grep -q '^text/'; then
		kind=text; ext=txt
		timeout 3 wl-paste --type text --no-newline > "$tmp" 2>/dev/null || true
	elif printf '%s\n' "$types" | grep -q '^image/'; then
		kind=image; ext=png
		timeout 3 wl-paste --type image > "$tmp" 2>/dev/null || true
	else
		rm -f "$tmp"; prune; return 0
	fi

	if [ ! -s "$tmp" ] || [ "$(wc -c < "$tmp")" -gt "$MAX_BYTES" ]; then
		rm -f "$tmp"; prune; return 0
	fi

	hash=$(sha1sum < "$tmp" | cut -d' ' -f1)
	rm -f "$DIR"/*-"$hash".txt "$DIR"/*-"$hash".png

	ts=$(date +%s)
	id="$ts-$hash"
	mv -f "$tmp" "$DIR/$id.$ext"
	touch "$DIR/.changed"
	prune
}

list() {
	local now f base ts id kind age preview thumb first
	prune
	now=$(date +%s)
	printf '{"now":%s,"entries":[' "$now"
	first=1
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		base=${f##*/}
		ts=${base%%-*}
		case "$ts" in ''|*[!0-9]*) continue ;; esac

		id=$base
		age=$((now - ts))
		thumb=""

		case "$base" in
			*.txt)
				kind=text
				preview=$(head -c "$PREVIEW" "$f" 2>/dev/null | tr '\n\t' '  ')
				if [ "$(wc -c < "$f")" -gt "$PREVIEW" ]; then preview="$preview…"; fi
				;;
			*)
				kind=image
				preview=""
				thumb="$f"
				;;
		esac

		[ "$first" -eq 1 ] || printf ','
		first=0
		printf '{"id":%s,"kind":%s,"age":%s,"preview":%s,"thumb":%s}' \
			"$(json_str "$id")" "$(json_str "$kind")" "$age" \
			"$(json_str "$preview")" "$(json_str "$thumb")"
	done < <(ls -1 "$DIR"/*.txt "$DIR"/*.png 2>/dev/null | sort -r)
	printf ']}'
}

copy() {
	local f="$DIR/$1"
	[ -f "$f" ] || return 1
	case "$f" in
		*.png) wl-copy --type image/png < "$f" ;;
		*) wl-copy --type text/plain < "$f" ;;
	esac
}

remove() { rm -f "$DIR/$1"; touch "$DIR/.changed"; }

clear() { rm -f "$DIR"/*.txt "$DIR"/*.png; touch "$DIR/.changed"; }

watch() {
	# exactly one watcher may run: if another one holds the lock, bow out. The
	# lock is released the moment that process dies, so a stale watcher never
	# blocks a fresh one for long.
	mkdir -p "$DIR"
	exec 9>"$DIR/.watch.lock"
	flock -n 9 || exit 0
	exec wl-paste --watch "$0" store
}

case "${1:-list}" in
	watch) watch ;;
	store) store ;;
	list) list ;;
	copy) shift; copy "${1:-}" ;;
	remove) shift; remove "${1:-}" ;;
	clear) clear ;;
	*) echo "usage: clipboard.sh [watch|store|list|copy <id>|remove <id>|clear]" >&2; exit 1 ;;
esac
