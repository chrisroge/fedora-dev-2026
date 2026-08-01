#!/usr/bin/env bash
# 50 — JetBrainsMono Nerd Font (terminal font with powerline/dev glyphs).
# Fedora doesn't package Nerd Fonts, so install per-user from the official
# nerd-fonts release.
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if fc-list | grep -qi 'JetBrainsMono Nerd Font'; then
  echo "==> JetBrainsMono Nerd Font already installed"
  exit 0
fi

mkdir -p "$FONT_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL -o "$TMP/JetBrainsMono.zip" \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -q "$TMP/JetBrainsMono.zip" -d "$FONT_DIR"
fc-cache -f "$FONT_DIR"

echo "==> Installed: $(fc-list | grep -ci 'JetBrainsMono Nerd Font') JetBrainsMono Nerd Font faces"
