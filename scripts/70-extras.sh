#!/usr/bin/env bash
# 70 — Optional extras: AI coding CLIs + interactive one-time setup.
# Run manually after bootstrap:  ./scripts/70-extras.sh
set -euo pipefail

# Claude Code (Anthropic's agentic coding CLI)
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Codex CLI (OpenAI) — installed through mise-managed node
if command -v npm >/dev/null 2>&1; then
  npm install -g @openai/codex
fi

cat <<'EOF'

==> Interactive steps left for you (each takes under a minute):

  1. GitHub CLI auth (also becomes git's credential helper):
       gh auth login

  2. Git identity:
       git config --global user.name  "Your Name"
       git config --global user.email "you@example.com"

  3. Claude Code first run:
       claude

EOF
