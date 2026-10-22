#!/usr/bin/env bash
# 40 — mise: one manager for language runtimes AND modern CLI tools.
# The tool list lives in dotfiles/config/mise/config.toml; this script installs
# mise itself and then everything the config declares:
#   node (LTS), uv, delta, eza, fd, fzf, lazygit, yq, zoxide
set -euo pipefail

if ! command -v "$HOME/.local/bin/mise" >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi

# Seed the tool list so this stage can install it; 60-dotfiles.sh later keeps
# it in sync with the repo copy (backing up local edits), like every dotfile.
mkdir -p "$HOME/.config/mise"
if [ ! -f "$HOME/.config/mise/config.toml" ]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  cp "$REPO_DIR/dotfiles/config/mise/config.toml" "$HOME/.config/mise/config.toml"
fi

"$HOME/.local/bin/mise" install --yes
"$HOME/.local/bin/mise" ls

# Python: Fedora's python3 stays the system interpreter; uv manages the
# others for projects that pin an older version.
"$("$HOME/.local/bin/mise" which uv)" python install 3.11 3.12 3.13

echo "==> mise + runtimes installed (restart your shell to pick up shims)"
