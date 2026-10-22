#!/usr/bin/env bash
# 60 — Install dotfiles and per-user desktop settings. No sudo.
# Copies configs into place, backing up anything that already exists to
# ~/.dotfiles-backup-<timestamp>/. The __HOME__ placeholder in configs that
# can't expand ~ themselves is replaced with your real home directory.
#
# Seeded once, never overwritten (your choices win on re-runs):
#   ~/.gitconfig, ~/.config/hypr/layouts.json, ~/.config/hypr/monitors.json,
#   ~/.codex/config.toml; ~/.claude/settings.json only gains missing keys.
# Generated here for this machine's monitors (and on every hotplug):
#   ~/.config/hypr/monitors.lua, ~/.config/waybar/config.jsonc
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_DIR/dotfiles"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

install_file() {
  local src="$1" dest="$2" staged
  # Expand the __HOME__ placeholder (for tools that don't do ~ themselves)
  # BEFORE comparing: the destination is always the expanded form, so diffing
  # the raw source against it would report every placeholder-bearing file as
  # changed and re-back it up on every run.
  staged="$(mktemp)"
  sed "s|__HOME__|$HOME|g" "$src" > "$staged"

  if [ -e "$dest" ] && ! cmp -s "$staged" "$dest"; then
    mkdir -p "$BACKUP/$(dirname "${dest#"$HOME"/}")"
    cp -a "$dest" "$BACKUP/${dest#"$HOME"/}"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$staged" "$dest"
  rm -f "$staged"
}
seed_file() { [ -e "$2" ] || install_file "$1" "$2"; }
install_bin() { install_file "$SRC/local/bin/$1" "$HOME/.local/bin/$1"; chmod +x "$HOME/.local/bin/$1"; }

# --- Shell & git -------------------------------------------------------------
install_file "$SRC/bashrc"       "$HOME/.bashrc"
install_file "$SRC/bash_profile" "$HOME/.bash_profile"
# Don't clobber an existing git identity/config — only seed if absent.
seed_file "$SRC/gitconfig" "$HOME/.gitconfig"

# --- Hyprland ----------------------------------------------------------------
# hyprland.lua takes monitor modes/positions/rotation from monitors.json. On a
# machine already running Hyprland, record the live arrangement first —
# Hyprland reloads the moment hyprland.lua is replaced, and an empty
# monitors.json would reset rotated or repositioned displays to defaults.
if [ ! -e "$HOME/.config/hypr/monitors.json" ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  python3 "$SRC/local/bin/hypr-monitors" --save --render
fi
for f in hyprland.lua hypridle.conf hyprpaper.conf; do
  install_file "$SRC/config/hypr/$f" "$HOME/.config/hypr/$f"
done
install_file "$SRC/config/hypr/scripts/touchpad-calm.sh" "$HOME/.config/hypr/scripts/touchpad-calm.sh"
chmod +x "$HOME/.config/hypr/scripts/touchpad-calm.sh"   # unit: 66-touchpad-calm.sh
seed_file "$SRC/config/hypr/layouts.json"  "$HOME/.config/hypr/layouts.json"
seed_file "$SRC/config/hypr/monitors.json" "$HOME/.config/hypr/monitors.json"

for b in hypr-layout hypr-monitors hypr-cheatsheet ghostty-theme capped; do
  install_bin "$b"
done

# --- Waybar ------------------------------------------------------------------
install_file "$SRC/config/waybar/modules.jsonc" "$HOME/.config/waybar/modules.jsonc"
install_file "$SRC/config/waybar/style.css"     "$HOME/.config/waybar/style.css"

# Generated files: layouts.lua from layouts.json; monitors.lua and Waybar's
# config.jsonc from the connected monitors (a generic single bar when run
# outside Hyprland — the first login regenerates them per display).
"$HOME/.local/bin/hypr-layout" --render
"$HOME/.local/bin/hypr-monitors" --render

# --- Terminal & apps ---------------------------------------------------------
install_file "$SRC/config/ghostty/config"         "$HOME/.config/ghostty/config"
install_file "$SRC/config/mise/config.toml"       "$HOME/.config/mise/config.toml"
install_file "$SRC/config/btop/btop.conf"         "$HOME/.config/btop/btop.conf"
install_file "$SRC/config/MangoHud/MangoHud.conf" "$HOME/.config/MangoHud/MangoHud.conf"
install_file "$SRC/config/gamemode.ini"           "$HOME/.config/gamemode.ini"
install_file "$SRC/config/Code/User/settings.json" "$HOME/.config/Code/User/settings.json"
if command -v code >/dev/null 2>&1; then
  for ext in anthropic.claude-code shahilkumar.docxreader; do
    code --list-extensions 2>/dev/null | grep -qx "$ext" || code --install-extension "$ext" >/dev/null 2>&1
  done
fi

# --- Build cache & containers ------------------------------------------------
# sccache (binary from 45-cli-tools.sh) as cargo's compiler wrapper, and the
# session environment for it and for Docker clients talking to Podman.
install_file "$SRC/cargo/config.toml"                  "$HOME/.cargo/config.toml"
install_file "$SRC/config/sccache/config"              "$HOME/.config/sccache/config"
install_file "$SRC/config/environment.d/sccache.conf"  "$HOME/.config/environment.d/sccache.conf"
install_file "$SRC/config/environment.d/podman.conf"   "$HOME/.config/environment.d/podman.conf"
systemctl --user enable --now podman.socket >/dev/null 2>&1 || true

# --- AI coding agents (CLIs themselves: 70-extras.sh) ------------------------
# Seeded only: an existing hook or theme of the same name is yours to keep.
mkdir -p "$HOME/.claude/themes" "$HOME/.claude/hooks"
seed_file "$SRC/claude/themes/solarized-dark.json"   "$HOME/.claude/themes/solarized-dark.json"
seed_file "$SRC/claude/hooks/secret-path-guard.py"   "$HOME/.claude/hooks/secret-path-guard.py"
python3 "$REPO_DIR/scripts/lib/merge-json.py" "$SRC/claude/settings.json" "$HOME/.claude/settings.json"
seed_file "$SRC/codex/config.toml" "$HOME/.codex/config.toml"

# --- Desktop settings ----------------------------------------------------------
# Files open in list view; the power profile is pinned to Performance (the
# same switch as Waybar's power icon — tuned-ppd remembers it across boots).
command -v gsettings >/dev/null 2>&1 &&
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
  net.hadess.PowerProfiles ActiveProfile s performance 2>/dev/null ||
  echo "    (couldn't set the power profile; pick Performance from Waybar's power icon)"

# Wallpaper directory hyprpaper.conf points at — drop wallpaper.png here.
mkdir -p "$HOME/Pictures/wallpapers"

if [ -d "$BACKUP" ]; then
  echo "==> Existing files backed up to $BACKUP"
fi
echo "==> Dotfiles installed. Put a wallpaper.png in ~/Pictures/wallpapers/"
