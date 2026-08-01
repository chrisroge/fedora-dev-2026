#!/usr/bin/env bash
# 20 — Flatpaks. Desktop apps that update on their own cadence.
set -euo pipefail

flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install -y --noninteractive flathub com.google.Chrome

echo "==> Flatpaks installed"
