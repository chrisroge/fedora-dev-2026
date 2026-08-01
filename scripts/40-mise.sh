#!/usr/bin/env bash
# 40 — mise: one manager for language runtimes AND modern CLI tools.
# The tool list lives in dotfiles/config/mise/config.toml; this script installs
# mise itself and then everything the config declares:
#   node (LTS), uv, delta, eza, fd, fzf, lazygit, yq, zoxide
set -euo pipefail

if ! command -v "$HOME/.local/bin/mise" >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi

mkdir -p "$HOME/.config/mise"
if [ ! -f "$HOME/.config/mise/config.toml" ]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  cp "$REPO_DIR/dotfiles/config/mise/config.toml" "$HOME/.config/mise/config.toml"
fi

"$HOME/.local/bin/mise" install --yes
"$HOME/.local/bin/mise" ls

echo "==> mise + runtimes installed (restart your shell to pick up shims)"
