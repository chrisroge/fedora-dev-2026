#!/usr/bin/env bash
# Fedora Workstation -> developer machine, one command:
#   ./bootstrap.sh
#
# Each stage is idempotent and lives in scripts/ — run them individually if
# you'd rather cherry-pick. 70-extras.sh (AI CLIs + interactive logins) is NOT
# run automatically; invoke it yourself afterwards.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

for stage in scripts/00-repos.sh \
             scripts/10-packages.sh \
             scripts/20-flatpaks.sh \
             scripts/30-rust.sh \
             scripts/40-mise.sh \
             scripts/50-fonts.sh \
             scripts/60-dotfiles.sh \
             scripts/65-thermal-breaker.sh; do
  echo
  echo "######## $stage ########"
  bash "$stage"
done

cat <<'EOF'

========================================================================
 Done. Next:
   1. Log out, and at GDM pick the "Hyprland" session (gear icon).
   2. Drop a wallpaper.png into ~/Pictures/wallpapers/
   3. Optional: ./scripts/70-extras.sh   (AI CLIs, gh auth, git identity)
========================================================================
EOF
