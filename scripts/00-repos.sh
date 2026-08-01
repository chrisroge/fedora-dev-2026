#!/usr/bin/env bash
# 00 — Third-party repositories.
# Everything below is a well-known, GPG-checked source; nothing is curl|bash'd
# into root here.
set -euo pipefail

echo "==> Enabling third-party repositories"

# dnf5 copr plugin + Fedora's pre-packaged third-party repo definitions
sudo dnf -y install dnf5-plugins fedora-workstation-repositories

# Hyprland ecosystem (hyprland, hypridle, hyprlock, hyprpaper, portal) — the
# de-facto standard Fedora COPR for Hyprland.
sudo dnf -y copr enable solopasha/hyprland

# Ghostty terminal
sudo dnf -y copr enable scottames/ghostty

# Visual Studio Code (Microsoft's official repo)
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/code
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Steam ships from RPM Fusion nonfree; Fedora packages the repo definition,
# it just needs to be switched on.
sudo dnf config-manager setopt rpmfusion-nonfree-steam.enabled=1

sudo dnf -y makecache
echo "==> Repositories ready"
