#!/usr/bin/env bash
# 00 — Third-party repositories.
# Everything below is a well-known, GPG-checked source; nothing is curl|bash'd
# into root here.
set -euo pipefail

echo "==> Enabling third-party repositories"

# dnf5 copr plugin + Fedora's pre-packaged third-party repo definitions
sudo dnf -y install dnf5-plugins fedora-workstation-repositories

# Hyprland ecosystem (hyprland, hypridle, hyprlock, hyprpaper, portal).
# Fedora proper ships only xdg-desktop-portal-hyprland, so the compositor has
# to come from a COPR.
#
# nett00n/hyprland provides Fedora 43 builds. Version 0.56.2 was verified
# on this laptop on 2026-10-06; solopasha's Fedora 43 tree returns 404.
# Check the live chroot list if a future Fedora release cannot resolve it:
# https://copr.fedorainfracloud.org/api_3/project?ownername=nett00n&projectname=hyprland
sudo dnf -y copr enable nett00n/hyprland
sudo dnf config-manager setopt 'copr:copr.fedorainfracloud.org:nett00n:hyprland.includepkgs=hyprland hyprutils hyprlang hyprcursor hyprgraphics hyprwire hyprtoolkit aquamarine hypridle hyprlock hyprpaper hyprpicker xdg-desktop-portal-hyprland'
if [ -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:solopasha:hyprland.repo ]; then
  sudo dnf copr disable solopasha/hyprland
fi

# Ghostty terminal
sudo dnf -y copr enable scottames/ghostty

# Visual Studio Code (Microsoft's official repo)
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Steam ships from RPM Fusion nonfree; Fedora packages the repo definition,
# it just needs to be switched on.
sudo dnf config-manager setopt rpmfusion-nonfree-steam.enabled=1

sudo dnf -y makecache

# `dnf copr enable` exits 0 even when the project has no chroot for this
# Fedora release — it just prints "Chroot not found" and writes a repo file
# pointing at a 404. Without this check the next stage installs everything
# EXCEPT the compositor and you find out at login. Fail here instead.
missing=()
for p in hyprland hypridle hyprlock hyprpaper ghostty code; do
  dnf -q repoquery --qf '%{name}' "$p" 2>/dev/null | grep -q . || missing+=("$p")
done
if [ ${#missing[@]} -gt 0 ]; then
  cat >&2 <<EOF

ERROR: these packages resolve from no enabled repository:
  ${missing[*]}

Fedora $(rpm -E %fedora) is what this machine reports. A third-party repo
above probably has no build for it — COPR projects prune old chroots, and
Microsoft moves the VS Code repo path. Check the project's live chroot list
before editing this script:
  https://copr.fedorainfracloud.org/api_3/project?ownername=nett00n&projectname=hyprland

EOF
  exit 1
fi

echo "==> Repositories ready"
