#!/usr/bin/env bash
set -euo pipefail

DOT="$(cd "$(dirname "$0")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

log()  { echo -e "\033[1;36m::\033[0m $*"; }
warn() { echo -e "\033[1;33m::\033[0m $*"; }

# ---------- 0. проверка окружения ----------
if ! command -v pacman >/dev/null 2>&1; then
    echo "Not an Arch-based distro (no pacman). Aborting." >&2
    exit 1
fi
[ -n "${WAYLAND_DISPLAY:-}" ] || { log "not running inside a graphical session — only pacman part will touch the system, that is OK"; }

# ---------- 1. пакеты ----------
log "installing packages"
sudo pacman -S --needed --noconfirm \
    hyprland hyprlock fuzzel mako swaybg wl-clipboard grim slurp \
    matugen brightnessctl blueman xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    inter-font kitty telegram-desktop nautilus btop cava zen-browser-bin uwsm

# ---------- 2. бэкап существующих конфигов, которые мы будем заменять ----------
BK="$HOME/hypr-dots-backup-$(date +%Y%m%d-%H%M%S)"
for t in hypr matugen mako; do
    if [ -e "$CFG/$t" ] && [ ! -L "$CFG/$t" ]; then
        mkdir -p "$BK"
        cp -a "$CFG/$t" "$BK/"
    fi
done
[ -d "$BK" ] && log "backup of previous configs saved in $BK"

# ---------- 3. копирование конфигов ----------
log "copying configs"
rm -rf "$CFG/hypr" "$CFG/matugen"
mkdir -p "$CFG"
cp -a "$DOT/hypr"      "$CFG/hypr"
cp -a "$DOT/matugen"   "$CFG/matugen"
chmod +x "$CFG/hypr/scripts/"*.sh

mkdir -p "$HOME/.wallpapers" "$HOME/Pictures/Screenshots" "$HOME/.local/state/hypr"

log "copying app configs (fuzzel, cava, btop)"
mkdir -p "$CFG/fuzzel" "$CFG/cava" "$CFG/btop/themes"
cp -a "$DOT/fuzzel/fuzzel.ini" "$CFG/fuzzel/fuzzel.ini" 2>/dev/null || true
cp -a "$DOT/cava/config"       "$CFG/cava/config"        2>/dev/null || true
cp -a "$DOT/btop/btop.conf"    "$CFG/btop/btop.conf"     2>/dev/null || true
cp -a "$DOT/btop/themes/."     "$CFG/btop/themes/"       2>/dev/null || true


# ---------- 4. kitty: добавить инклуд matugen-цветов (идемпотентно) ----------
log "patching kitty"
KITTY="$CFG/kitty/kitty.conf"
if [ ! -f "$KITTY" ]; then
    cat > "$KITTY" <<'EOF'
shell fish
EOF
fi
grep -q "include matugen.conf" "$KITTY" || cat >> "$KITTY" <<'EOF'

include matugen.conf
allow_remote_control socket-only
listen_on unix:@kitty
EOF

# ---------- 5. GTK: @import матугена (идемпотентно, темы не трогаем) ----------
log "patching GTK"
for v in 3.0 4.0; do
    d="$CFG/gtk-$v"
    mkdir -p "$d"
    f="$d/gtk.css"
    if [ -L "$f" ] || [ ! -f "$f" ]; then
        target=""
        [ -f "$d/gtk-dark.css" ] && target="$(readlink -f "$d/gtk-dark.css" 2>/dev/null || true)"
        [ -f "$f" ] || target="/usr/share/themes/adw-gtk3-dark/gtk-$v/gtk.css"
        [ -L "$f" ] && [ -e "$f" ] && target="$(readlink "$f")"
        rm -f "$f"
        { [ -n "$target" ] && [ -f "$target" ] && echo "@import url('$target');"; } || printf ""
        printf '@import "matugen.css";\n' > "$f"
    fi
    grep -q 'matugen.css' "$f" || printf '@import "matugen.css";\n' >> "$f"
done

# ---------- 6. аппаратура: NVIDIA предупреждение ----------
if lspci -nn 2>/dev/null | grep -qi 'vga.*nvidia'; then
    warn "NVIDIA GPU detected: install the driver (nvidia-open-dkms or nvidia-dkms) and read https://wiki.hypr.land/extra/nvidia/"
fi

# ---------- 7. первая генерация цветов ----------
if [ -d "$HOME/.wallpapers" ]; then
    FIRST=$(find "$HOME/.wallpapers" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -1)
    if [ -n "$FIRST" ]; then
        log "generating palette from $FIRST"
        mkdir -p "$HOME/.local/state/hypr"
        "$CFG/hypr/scripts/apply-colors.sh" "$FIRST" || true
        printf '%s\n' "$FIRST" > "$HOME/.local/state/hypr/wallpaper"
    fi
fi

# ---------- 8. done ----------
log "done. Select 'Hyprland (UWSM)' in your display manager and log in."
log "keybindings: docs/keybindings.txt in this repo (or ~/keybindings.txt)"
