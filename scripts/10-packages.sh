#!/usr/bin/env bash
# 10 — Package installation (dnf).
# Grouped so you can cherry-pick: comment out a group you don't want.
set -euo pipefail

# --- Hyprland desktop -------------------------------------------------------
# Compositor + the small ecosystem it expects at runtime (see the exec-once
# lines in dotfiles/config/hypr/hyprland.conf).
HYPRLAND=(
  hyprland hypridle hyprlock hyprpaper xdg-desktop-portal-hyprland
  waybar                  # status bar
  mako                    # notification daemon
  wofi                    # app launcher (SUPER+R)
  mate-polkit             # polkit auth agent (lightweight, GTK)
  network-manager-applet  # nm-applet tray icon
  brightnessctl playerctl # media/brightness keys
  grim slurp wl-clipboard # region screenshot -> clipboard (Print key)
  pavucontrol             # volume mixer (click the waybar audio module)
  ghostty                 # terminal (SUPER+Q)
)

# --- Everyday CLI -----------------------------------------------------------
# Note: eza/fd/fzf/zoxide/lazygit/delta/yq are managed by mise (40-mise.sh),
# not dnf, so they track upstream releases instead of the distro.
CLI=(
  bash-color-prompt bash-completion
  bat btop jq ripgrep tmux
  plocate dos2unix whois mtr nmap-ncat bind-utils
)

# --- Development ------------------------------------------------------------
DEV=(
  git gh code
  gcc clang clang-devel cmake
  openssl-devel dbus-devel alsa-lib-devel   # common native-crate build deps
  podman toolbox                            # containers, rootless by default
  postgresql                                # psql client
  awscli2 session-manager-plugin            # AWS CLI + SSM sessions
)

# --- Fonts ------------------------------------------------------------------
# Waybar's stylesheet wants Font Awesome for its glyphs. JetBrainsMono Nerd
# Font is handled separately in 50-fonts.sh (not packaged by Fedora).
FONTS=(
  fontawesome-6-free-fonts
  adobe-source-code-pro-fonts
)

# --- Gaming (optional) ------------------------------------------------------
GAMING=(
  steam gamemode gamescope mangohud goverlay
)

sudo dnf -y install \
  "${HYPRLAND[@]}" "${CLI[@]}" "${DEV[@]}" "${FONTS[@]}" "${GAMING[@]}"

echo "==> Packages installed"
