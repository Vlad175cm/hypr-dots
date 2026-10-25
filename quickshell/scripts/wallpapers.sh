#!/usr/bin/env bash
#
# wallpapers.sh — wallpaper backend for the quickshell island.
#
#   wallpapers.sh list          print the wallpaper index as json
#   wallpapers.sh thumbs        generate any missing previews (parallel)
#   wallpapers.sh apply <file>  remember the choice and re-run matugen
#
set -euo pipefail

WALL_DIR="${WALLPAPER_DIR:-$HOME/.wallpapers}"
STATE="$HOME/.local/state/hypr/wallpaper"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallthumbs"
PALETTE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/palettes"
MATUGEN_TEMPLATE="$HOME/.config/matugen/templates/quickshell.json"
ISLAND_COLORS="$HOME/.config/quickshell/theme/colors.json"
THUMB_W=440
THUMB_H=248
PARALLEL=4

json_str() {
	local s="$1"
	s="${s//\\/\\\\}"
	s="${s//\"/\\\"}"
	s="${s//$'\n'/\\n}"
	s="${s//$'\r'/}"
	s="${s//$'\t'/\\t}"
	printf '"%s"' "$s"
}

thumb_for() {
	printf '%s/%s.jpg' "$CACHE" "$(printf '%s' "$1" | md5sum | cut -d' ' -f1)"
}

list_walls() {
	find "$WALL_DIR" -maxdepth 1 -type f \
		\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
		-o -iname '*.bmp' \) \
		-printf '%p\n' 2>/dev/null | sort -f
}

cmd_list() {
	mkdir -p "$CACHE"

	local current=""
	[ -f "$STATE" ] && current="$(head -n1 "$STATE")"

	printf '{"current":%s,"wallpapers":[' "$(json_str "$current")"

	local first=1 path thumb name
	while IFS= read -r path; do
		[ -f "$path" ] || continue
		thumb="$(thumb_for "$path")"
		name="$(basename "$path")"

		[ "$first" -eq 1 ] || printf ','
		first=0

		if [ -f "$thumb" ]; then
			printf '{"path":%s,"name":%s,"thumb":%s}' "$(json_str "$path")" "$(json_str "$name")" "$(json_str "$thumb")"
		else
			printf '{"path":%s,"name":%s}' "$(json_str "$path")" "$(json_str "$name")"
		fi
	done < <(list_walls)

	printf ']}'
}

cmd_thumbs() {
	mkdir -p "$CACHE"
	export THUMB_W THUMB_H

	while IFS= read -r path; do
		local thumb
		thumb="$(thumb_for "$path")"
		[ -f "$thumb" ] || printf '%s\0%s\0' "$path" "$thumb"
	done < <(list_walls) | xargs -0 -r -n2 -P"$PARALLEL" bash -c '
		src="$1"; dst="$2"
		[ -f "$dst" ] && exit 0
		tmp="$dst.tmp.$$"
		if magick "$src[0]" -auto-orient -resize "${THUMB_W}x${THUMB_H}^" -gravity center \
			-extent "${THUMB_W}x${THUMB_H}" -strip -quality 82 "$tmp" 2>/dev/null; then
			mv -f "$tmp" "$dst"
		else
			rm -f "$tmp"
		fi
	' _

	echo done
}

palette_for() {
	printf '%s/%s.json' "$PALETTE_CACHE" "$(printf '%s' "$1" | md5sum | cut -d' ' -f1)"
}

scheme_for() {
	printf '%s/%s.scheme.json' "$PALETTE_CACHE" "$(printf '%s' "$1" | md5sum | cut -d' ' -f1)"
}

lock_palette_cache() {
	mkdir -p "$PALETTE_CACHE"
	exec 9>"$PALETTE_CACHE/.matugen.lock"
	flock -x 9
}

copy_atomic() {
	local src="$1" dst="$2" tmp="${2}.tmp.$$"
	cp -- "$src" "$tmp"
	mv -f -- "$tmp" "$dst"
}

# matugen can render every template from a saved *scheme* instead of the image.
# Decoding a 6144×3710 jpeg costs ~1.8 s; rendering from the scheme is ~0.1 s.
# The scheme is generated once per image and cached next to the palette.
make_scheme_template() {
	local tpl="$PALETTE_CACHE/.scheme.tmpl"
	mkdir -p "$PALETTE_CACHE"
	python3 - "$(dirname "$MATUGEN_TEMPLATE")" "$tpl" <<'PY'
import glob, re, sys, pathlib
src, dst = sys.argv[1], sys.argv[2]
names = set()
for f in glob.glob(src + '/*'):
    try:
        text = open(f, encoding='utf-8', errors='ignore').read()
    except OSError:
        continue
    for m in re.finditer(r'colors\.([a-z_]+)\.default\.', text):
        names.add(m.group(1))
names = sorted(names)
out = ['{', '  "image": "{{image}}",', '  "colors": {']
for i, n in enumerate(names):
    comma = ',' if i < len(names) - 1 else ''
    out += [
        '\t\t"%s": {' % n,
        '\t\t\t"default": {',
        '\t\t\t\t"hex": "{{colors.%s.default.hex}}",' % n,
        '\t\t\t\t"hex_stripped": "{{colors.%s.default.hex_stripped}}",' % n,
        '\t\t\t\t"red": {{colors.%s.default.red}},' % n,
        '\t\t\t\t"green": {{colors.%s.default.green}},' % n,
        '\t\t\t\t"blue": {{colors.%s.default.blue}}' % n,
        '\t\t\t}',
        '\t\t}%s' % comma,
    ]
out += ['  }', '}', '']
pathlib.Path(dst).write_text('\n'.join(out))
PY
}

# decode the image once and remember its scheme
gen_scheme() {
	local image="$1" scheme cfg
	scheme="$(scheme_for "$image")"
	[ -f "$scheme" ] && return 0
	make_scheme_template
	cfg="$PALETTE_CACHE/.scheme.toml"
	cat > "$cfg" <<-EOF
		[config]
		mode = "dark"
		type = "scheme_tonal_spot"

		[templates.scheme]
		input_path = "$PALETTE_CACHE/.scheme.tmpl"
		output_path = "$scheme"
	EOF
	if ! matugen image "$image" -c "$cfg" --mode dark --prefer lightness >/dev/null 2>&1; then
		rm -f "$cfg"
		return 1
	fi
	rm -f "$cfg"
}

# Extracting a palette means decoding the whole image (a couple of hundred
# milliseconds for a 2560×1440 png), and that is what used to delay the island's
# recolour. The palette only depends on the image, so it is cached per image and
# generated ahead of time while you browse.
cmd_prewarm() {
	local image="${1:-}"
	[ -n "$image" ] || { echo "usage: wallpapers.sh prewarm <image>" >&2; exit 1; }
	[ -f "$image" ] || exit 1

	local palette scheme cfg
	lock_palette_cache

	palette="$(palette_for "$image")"
	scheme="$(scheme_for "$image")"
	if [ -f "$palette" ] && [ -f "$scheme" ]; then exit 0; fi

	make_scheme_template
	cfg="$PALETTE_CACHE/.prewarm.toml"

	# Only the island's palette and the colour scheme are generated here —
	# nothing gets restyled while you are merely moving through the list. The
	# scheme is what makes the real switch fast later: every template is then
	# rendered with `matugen json`, without decoding the image again.
	cat > "$cfg" <<-EOF
		[config]
		mode = "dark"
		type = "scheme_tonal_spot"

		[templates.quickshell]
		input_path = "$MATUGEN_TEMPLATE"
		output_path = "$palette"

		[templates.scheme]
		input_path = "$PALETTE_CACHE/.scheme.tmpl"
		output_path = "$scheme"
	EOF

	if ! matugen image "$image" -c "$cfg" --mode dark --prefer lightness >/dev/null 2>&1; then
		rm -f "$cfg"
		return 1
	fi
	rm -f "$cfg"
}

cmd_apply() {
	local image="${1:-}"
	[ -n "$image" ] || { echo "usage: wallpapers.sh apply <image>" >&2; exit 1; }
	[ -f "$image" ] || { echo "no such file: $image" >&2; exit 1; }

	local palette scheme
	lock_palette_cache

	mkdir -p "$(dirname "$STATE")" "$(dirname "$ISLAND_COLORS")"
	printf '%s\n' "$image" > "$STATE"

	palette="$(palette_for "$image")"
	scheme="$(scheme_for "$image")"

	# a cached palette means the island can recolour right now
	if [ -f "$palette" ]; then
		copy_atomic "$palette" "$ISLAND_COLORS"
	fi

	# Re-tint everything matugen knows about. When the scheme is cached this
	# renders straight from it — no image decode — which is what makes the
	# switch ~20× faster (far more on big pictures). The scheme is built once
	# per image, on the first switch or while browsing.
	if [ ! -f "$scheme" ] && ! gen_scheme "$image"; then
		matugen image "$image" --mode dark --prefer lightness >/dev/null 2>&1
		if [ -f "$ISLAND_COLORS" ] && [ ! -f "$palette" ]; then
			copy_atomic "$ISLAND_COLORS" "$palette"
		fi
		return 0
	fi

	if ! matugen json "$scheme" --mode dark >/dev/null 2>&1; then
		matugen image "$image" --mode dark --prefer lightness >/dev/null 2>&1
	fi

	# remember the palette for the next time this wallpaper comes up
	if [ -f "$ISLAND_COLORS" ] && [ ! -f "$palette" ]; then
		copy_atomic "$ISLAND_COLORS" "$palette"
	fi

	return 0
}

case "${1:-list}" in
	list) cmd_list ;;
	thumbs) cmd_thumbs ;;
	prewarm) shift; cmd_prewarm "$@" ;;
	apply) shift; cmd_apply "$@" ;;
	*) echo "usage: wallpapers.sh [list|thumbs|prewarm <image>|apply <image>]" >&2; exit 1 ;;
esac
