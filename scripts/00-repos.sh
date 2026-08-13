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
# This was solopasha/hyprland, which is where the packages on the machine this
# repo was extracted from came from. That project has since gone
# rawhide-only — it prunes old chroots (auto_prune), and its fedora-43 tree is
# now a 404, which silently leaves you with no Hyprland and no updates.
# sachesi/hyprland carries the same 20-package set (compositor, hypridle,
# hyprlock, hyprpaper, portal, plus aquamarine/hyprutils/hyprlang deps) and
# builds for fedora-44 and rawhide.
#
# COPRs are volunteer-run and can be pruned like this at any time. If the
# enable below fails, check which chroots the project still has:
#   https://copr.fedorainfracloud.org/api_3/project?ownername=sachesi&projectname=hyprland
sudo dnf -y copr enable sachesi/hyprland

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
  https://copr.fedorainfracloud.org/api_3/project?ownername=sachesi&projectname=hyprland

EOF
  exit 1
fi

echo "==> Repositories ready"
