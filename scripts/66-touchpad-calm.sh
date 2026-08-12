#!/usr/bin/env bash
# 66 — Touchpad calming (laptops). Enables the user service that turns
# tap-to-click and tap-and-drag off while an external mouse is attached, so a
# palm brushing the pad stops registering as a click. Pointer motion,
# two-finger scroll, and physical clickpad presses are untouched; unplug the
# mouse and taps come back.
#
# The watcher itself is dotfiles/config/hypr/scripts/touchpad-calm.sh, put in
# place by 60-dotfiles.sh. It talks to Hyprland over hyprctl, so it only does
# anything inside a Hyprland session — harmless elsewhere.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WATCHER="$HOME/.config/hypr/scripts/touchpad-calm.sh"

if [ ! -x "$WATCHER" ]; then
  echo "==> $WATCHER missing — run scripts/60-dotfiles.sh first" >&2
  exit 1
fi

# Skip on machines with no touchpad at all (desktops).
if ! grep -qi touchpad /proc/bus/input/devices 2>/dev/null; then
  echo "==> No touchpad detected — skipping touchpad-calm"
  exit 0
fi

install -d -m 755 "$HOME/.config/systemd/user"
install -m 644 "$REPO_DIR/dotfiles/systemd/user/touchpad-calm.service" \
               "$HOME/.config/systemd/user/touchpad-calm.service"

systemctl --user daemon-reload
systemctl --user enable --now touchpad-calm.service

echo "==> touchpad-calm: $(systemctl --user is-active touchpad-calm.service)" \
     "(journalctl --user -u touchpad-calm)"
