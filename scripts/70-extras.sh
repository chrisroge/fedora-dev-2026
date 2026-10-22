#!/usr/bin/env bash
# 70 — AI coding tools + the one-time interactive logins. No sudo.
# Run after bootstrap:  ./scripts/70-extras.sh
# Their settings (Claude Code baseline, Codex config) come from 60-dotfiles.sh.
set -euo pipefail

# Claude Code (Anthropic's agentic coding CLI)
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# npm-based agent CLIs, on the mise-managed node from 40-mise.sh:
#   @openai/codex  Codex CLI        opencode-ai  opencode
#   clawhub        agent-skill registry CLI
#   smithery       MCP server registry CLI
NPM="$("$HOME/.local/bin/mise" which npm 2>/dev/null || command -v npm || true)"
if [ -n "$NPM" ]; then
  "$NPM" install -g @openai/codex opencode-ai clawhub smithery
else
  echo "npm not found — run scripts/40-mise.sh first" >&2
  exit 1
fi

# gh alias used daily: `gh co 123` checks out PR #123.
gh alias set --clobber co 'pr checkout' >/dev/null

cat <<'EOF'

==> Interactive steps left for you (each takes under a minute):

  1. GitHub CLI auth (also becomes git's credential helper):
       gh auth login

  2. Git identity:
       git config --global user.name  "Your Name"
       git config --global user.email "you@example.com"

  3. Log in to the agents:
       claude        (then /theme → Solarized Dark, if you like it)
       codex

  4. ChatGPT desktop app (optional): download the Linux RPM from
       https://developers.openai.com/codex/app
     and install it with `sudo dnf install ./chatgpt*.rpm`. It adds its own
     update repo; import its signing key once so dnf can verify that repo:
       sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-chatgpt-*.asc

EOF
