#!/usr/bin/env bash
# 60 — Install dotfiles.
# Copies configs into place, backing up anything that already exists to
# ~/.dotfiles-backup-<timestamp>/. The __HOME__ placeholder in configs that
# can't expand ~ themselves (hyprpaper, MangoHud) is replaced with your real
# home directory.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_DIR/dotfiles"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

install_file() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
    mkdir -p "$BACKUP/$(dirname "${dest#"$HOME"/}")"
    cp -a "$dest" "$BACKUP/${dest#"$HOME"/}"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  # Expand the placeholder for tools that don't do ~ themselves
  sed -i "s|__HOME__|$HOME|g" "$dest"
}

install_file "$SRC/bashrc"       "$HOME/.bashrc"
install_file "$SRC/bash_profile" "$HOME/.bash_profile"

# Don't clobber an existing git identity/config — only seed if absent.
[ -f "$HOME/.gitconfig" ] || install_file "$SRC/gitconfig" "$HOME/.gitconfig"

for f in hyprland.conf hypridle.conf hyprpaper.conf gaming.conf animated-wallpaper.sh; do
  install_file "$SRC/config/hypr/$f" "$HOME/.config/hypr/$f"
done
chmod +x "$HOME/.config/hypr/animated-wallpaper.sh"

# Helper scripts the Hyprland session drives (touchpad-calm.sh is wired to a
# user unit by 66-touchpad-calm.sh).
install_file "$SRC/config/hypr/scripts/touchpad-calm.sh" \
             "$HOME/.config/hypr/scripts/touchpad-calm.sh"
chmod +x "$HOME/.config/hypr/scripts/touchpad-calm.sh"

install_file "$SRC/config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
install_file "$SRC/config/waybar/style.css"    "$HOME/.config/waybar/style.css"
install_file "$SRC/config/ghostty/config"      "$HOME/.config/ghostty/config"
install_file "$SRC/config/mise/config.toml"    "$HOME/.config/mise/config.toml"
install_file "$SRC/config/MangoHud/MangoHud.conf" "$HOME/.config/MangoHud/MangoHud.conf"
install_file "$SRC/config/gamemode.ini"        "$HOME/.config/gamemode.ini"

install_file "$SRC/local/bin/ghostty-theme" "$HOME/.local/bin/ghostty-theme"
chmod +x "$HOME/.local/bin/ghostty-theme"

install_file "$SRC/local/bin/capped" "$HOME/.local/bin/capped"
chmod +x "$HOME/.local/bin/capped"

# Wallpaper directory the hypr configs point at — drop your own files here:
#   wallpaper.png  (hyprpaper static wallpaper)
#   wallpaper.mp4  (optional, used by animated-wallpaper.sh if mpvpaper exists)
mkdir -p "$HOME/Pictures/wallpapers"

if [ -d "$BACKUP" ]; then
  echo "==> Existing files backed up to $BACKUP"
fi
echo "==> Dotfiles installed. Put a wallpaper.png in ~/Pictures/wallpapers/"
