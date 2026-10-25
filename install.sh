#!/usr/bin/env bash
set -euo pipefail

DOT="$(cd "$(dirname "$0")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

log()  { echo -e "\033[1;36m::\033[0m $*"; }
warn() { echo -e "\033[1;33m::\033[0m $*"; }

# ---------- 0. environment ----------
if ! command -v pacman >/dev/null 2>&1; then
    echo "Not an Arch-based distro (no pacman). Aborting." >&2
    exit 1
fi
[ -n "${WAYLAND_DISPLAY:-}" ] || warn "not inside a graphical session — only the pacman part will touch the system"

# ---------- 1. packages ----------
# The desktop is built around Quickshell: it draws the wallpaper, owns the
# notification server, the launcher, the app switcher, the OSD and the
# wallpaper picker. fuzzel/mako/swaybg are deliberately NOT installed.
log "installing packages (official repos)"
sudo pacman -S --needed --noconfirm \
    hyprland hyprlock uwsm quickshell \
    matugen kitty yazi btop cava neovim fish \
    imagemagick python curl \
    wl-clipboard grim slurp brightnessctl playerctl \
    blueman xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    inter-font telegram-desktop \
    lua-language-server pyright clang

# zen-browser-bin lives in the AUR
if ! command -v zen-browser >/dev/null 2>&1; then
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm zen-browser-bin || warn "could not install zen-browser-bin"
    elif command -v paru >/dev/null 2>&1; then
        paru -S --needed --noconfirm zen-browser-bin || warn "could not install zen-browser-bin"
    else
        warn "zen-browser-bin is in the AUR — install it with your AUR helper if you want SUPER + B"
    fi
fi

# mako would fight Quickshell over org.freedesktop.Notifications
if command -v mako >/dev/null 2>&1; then
    systemctl --user mask mako >/dev/null 2>&1 || true
    pkill -x mako >/dev/null 2>&1 || true
    warn "mako is installed — masked it, because Quickshell owns notifications"
fi
# an old swaybg would paint over Quickshell's wallpaper
pkill -x swaybg >/dev/null 2>&1 || true

# ---------- 2. backup ----------
BK="$HOME/hypr-dots-backup-$(date +%Y%m%d-%H%M%S)"
for t in hypr matugen quickshell nvim; do
    if [ -e "$CFG/$t" ] && [ ! -L "$CFG/$t" ]; then
        mkdir -p "$BK"
        cp -a "$CFG/$t" "$BK/" 2>/dev/null || true
    fi
done
[ -d "$BK" ] && log "backup of previous configs saved in $BK"

# ---------- 3. configs ----------
log "copying configs (hypr, matugen, quickshell)"
rm -rf "$CFG/hypr" "$CFG/matugen" "$CFG/quickshell"
mkdir -p "$CFG"
cp -a "$DOT/hypr"       "$CFG/hypr"
cp -a "$DOT/matugen"    "$CFG/matugen"
cp -a "$DOT/quickshell" "$CFG/quickshell"
chmod +x "$CFG/hypr/scripts/"*.sh \
         "$CFG/matugen/scripts/"*.sh \
         "$CFG/quickshell/scripts/"*.sh 2>/dev/null || true

mkdir -p "$HOME/.wallpapers" "$HOME/Pictures/Screenshots" \
         "$HOME/.local/state/hypr" "$HOME/.cache/quickshell"

# ---------- 4. app configs ----------
log "copying app configs (cava, btop)"
mkdir -p "$CFG/cava" "$CFG/btop/themes"
cp -a "$DOT/cava/config"   "$CFG/cava/config"
cp -a "$DOT/btop/btop.conf" "$CFG/btop/btop.conf"
cp -a "$DOT/btop/themes/." "$CFG/btop/themes/"

# ---------- 5. kitty ----------
# kitty only needs the include; colours are written by matugen.
log "patching kitty"
KITTY="$CFG/kitty/kitty.conf"
mkdir -p "$CFG/kitty"
[ -f "$KITTY" ] || printf 'shell fish\n' > "$KITTY"
grep -q "include matugen.conf" "$KITTY" || cat >> "$KITTY" <<'EOF'

include matugen.conf
allow_remote_control socket-only
listen_on unix:@kitty
EOF
# kitty >= 0.49 restores window state on every launch and breaks Hyprland tiling
sed -i 's/^remember_window_size.*/remember_window_size  no/' "$KITTY"
grep -q "remember_window_size" "$KITTY" || printf 'remember_window_size  no\n' >> "$KITTY"
rm -f "$HOME/.cache/kitty/main.json"

# ---------- 6. nvim ----------
# Merge only the tracked files, so lazy-lock.json and the generated
# colors/matugen.lua survive an update.
log "updating nvim"
mkdir -p "$CFG/nvim/lua" "$CFG/nvim/colors"
cp -a "$DOT/nvim/init.lua" "$CFG/nvim/init.lua"
cp -a "$DOT/nvim/lua/."    "$CFG/nvim/lua/"

# ---------- 7. GTK ----------
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
        { [ -n "$target" ] && [ -f "$target" ] && echo "@import url('$target');"; } || true
        printf '@import "matugen.css";\n' > "$f"
    fi
    grep -q 'matugen.css' "$f" || printf '@import "matugen.css";\n' >> "$f"
done

# ---------- 8. NVIDIA ----------
if lspci -nn 2>/dev/null | grep -qi 'vga.*nvidia'; then
    warn "NVIDIA GPU detected: install the driver and read https://wiki.hypr.land/extra/nvidia/"
fi

# ---------- 9. first palette ----------
if [ -d "$HOME/.wallpapers" ]; then
    FIRST=$(find "$HOME/.wallpapers" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
        | sort | head -1)
    if [ -n "$FIRST" ]; then
        log "generating palette from $FIRST"
        bash "$CFG/quickshell/scripts/wallpapers.sh" apply "$FIRST" || warn "palette generation failed; pick a wallpaper with SUPER + W"
        printf '%s\n' "$FIRST" > "$HOME/.local/state/hypr/wallpaper"
    else
        warn "no wallpapers in ~/.wallpapers — drop some images there and press SUPER + W"
    fi
fi

# ---------- 10. done ----------
log "done. Select 'Hyprland (UWSM)' in your display manager and log in."
log "Quickshell starts automatically; SUPER + A opens the island dashboard."
log "keybindings: docs/keybindings.txt"
