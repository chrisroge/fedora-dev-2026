#!/usr/bin/env bash
# 20 — Flatpaks. Desktop apps that update on their own cadence.
# System-wide installs: GNOME shows a password dialog (polkit) the first time.
set -euo pipefail

flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install -y --noninteractive flathub \
  com.google.Chrome \
  org.videolan.VLC \
  us.zoom.Zoom

# OBS comes from Fedora's own Flatpak remote (preconfigured on Workstation).
flatpak install -y --noninteractive fedora com.obsproject.Studio

# VLC plays .mp4 by default.
xdg-mime default org.videolan.VLC.desktop video/mp4

echo "==> Flatpaks installed"
