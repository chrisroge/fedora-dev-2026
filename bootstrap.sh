#!/usr/bin/env bash
# Fedora Workstation -> developer machine, one command:
#   ./bootstrap.sh            every stage, in order
#   ./bootstrap.sh 00 10 65   just these stages (by number)
#
# Each stage is idempotent and lives in scripts/. Output of every stage is
# also written to ~/.local/state/fedora-dev-2026/logs/<stage>.log, so an
# agent can read what happened even when you ran it in another terminal.
# 70-extras.sh (AI CLIs + interactive logins) is NOT run automatically.
#
# Stages that use sudo (you'll be asked for your password once):
#   00 repos · 10 packages · 65 thermal breaker
# 20 flatpaks may show a GNOME password dialog. Everything else is per-user.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

ALL=(00-repos 10-packages 20-flatpaks 30-rust 40-mise 45-cli-tools
     50-fonts 60-dotfiles 65-thermal-breaker 66-touchpad-calm)
SUDO_STAGES=" 00 10 65 "
LOG_DIR="$HOME/.local/state/fedora-dev-2026/logs"
mkdir -p "$LOG_DIR"

if [ "$(id -u)" -eq 0 ]; then
  echo "Run as your normal user, not root — stages call sudo where needed." >&2
  exit 1
fi

stages=()
if [ $# -eq 0 ]; then
  stages=("${ALL[@]}")
else
  for n in "$@"; do
    match=""
    for s in "${ALL[@]}"; do [ "${s%%-*}" = "$n" ] && match="$s"; done
    [ -n "$match" ] || { echo "unknown stage: $n (have: ${ALL[*]})" >&2; exit 1; }
    stages+=("$match")
  done
fi

# Ask for the sudo password once up front and keep it fresh, so a long stage
# (e.g. compiling sqlx-cli) doesn't leave a later one waiting at a prompt.
for s in "${stages[@]}"; do
  if [[ $SUDO_STAGES == *" ${s%%-*} "* ]]; then
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
    trap 'kill $! 2>/dev/null || true' EXIT
    break
  fi
done

for s in "${stages[@]}"; do
  echo
  echo "######## scripts/$s.sh ########"
  if ! bash "scripts/$s.sh" 2>&1 | tee "$LOG_DIR/$s.log"; then
    echo "!! scripts/$s.sh failed — see $LOG_DIR/$s.log" >&2
    exit 1
  fi
done

cat <<'EOF'

========================================================================
 Done. Next:
   1. Log out, and at the login screen pick the "Hyprland" session (gear).
   2. Drop a wallpaper.png into ~/Pictures/wallpapers/
   3. ./scripts/70-extras.sh   (AI CLIs, gh auth, git identity)
   4. ./scripts/verify.sh      (checks everything above)
   Press SUPER + / any time for the keyboard cheat sheet.
========================================================================
EOF
