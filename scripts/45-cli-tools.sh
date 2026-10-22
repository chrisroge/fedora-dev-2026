#!/usr/bin/env bash
# 45 — Standalone CLI binaries from upstream releases, into ~/.local/bin.
# No sudo. Each download is pinned to a version AND its SHA-256, so this
# reproduces exactly the binaries on the reference machine; bump both
# together. Already-correct installs are skipped.
#
#   sccache        shared Rust compile cache (wired up by 60-dotfiles.sh)
#   cosign         sigstore signing/verification
#   terraform      1.9.8 as `terraform`, 1.13.5 as `terraform-1.13`
#   docker-compose Compose v2 CLI plugin, talks to the Podman socket
#   mcp-publisher  MCP Registry publishing CLI
#   git-filter-repo  via uv (installed by 40-mise.sh, so run that first)
set -euo pipefail

BIN="$HOME/.local/bin"
mkdir -p "$BIN" "$HOME/.docker/cli-plugins"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# fetch URL SHA256 FILE — download and verify, or fail the stage
fetch() {
  curl -fsSL -o "$3" "$1"
  echo "$2  $3" | sha256sum -c --quiet - || { echo "checksum mismatch: $1" >&2; exit 1; }
}

# have FILE VERSION_SUBSTRING ARGS... — true if FILE already reports VERSION
have() {
  local f="$1" v="$2"; shift 2
  [ -x "$f" ] && "$f" "$@" 2>&1 | grep -qF "$v"
}

if ! have "$BIN/sccache" 0.17.0 --version; then
  fetch https://github.com/mozilla/sccache/releases/download/v0.17.0/sccache-v0.17.0-x86_64-unknown-linux-musl.tar.gz \
        67c4a96dd237c1f518f6b36083f270f9976d516f1e57fce891755ea782e50006 "$TMP/sccache.tgz"
  tar -xzf "$TMP/sccache.tgz" -C "$TMP"
  install -m 755 "$TMP/sccache-v0.17.0-x86_64-unknown-linux-musl/sccache" "$BIN/sccache"
fi

if ! have "$BIN/cosign" v3.1.1 version; then
  fetch https://github.com/sigstore/cosign/releases/download/v3.1.1/cosign-linux-amd64 \
        ae1ecd212663f3693ad9edf8b1a183900c9a52d3155ba6e354237f9a0f6463fc "$TMP/cosign"
  install -m 755 "$TMP/cosign" "$BIN/cosign"
fi

install_terraform() {  # VERSION SHA256 TARGET_NAME
  if ! have "$BIN/$3" "v$1" version; then
    fetch "https://releases.hashicorp.com/terraform/$1/terraform_$1_linux_amd64.zip" "$2" "$TMP/tf.zip"
    unzip -qo "$TMP/tf.zip" terraform -d "$TMP/tf-$1"
    install -m 755 "$TMP/tf-$1/terraform" "$BIN/$3"
  fi
}
install_terraform 1.9.8  186e0145f5e5f2eb97cbd785bc78f21bae4ef15119349f6ad4fa535b83b10df8 terraform
install_terraform 1.13.5 0dbe3fcc268eb670801af6a6456799d1ae26e72e73797f6c6167e18aafd1fd9a terraform-1.13

COMPOSE="$HOME/.docker/cli-plugins/docker-compose"
if ! have "$COMPOSE" v5.3.1 version; then
  fetch https://github.com/docker/compose/releases/download/v5.3.1/docker-compose-linux-x86_64 \
        f9ebc6ebdb19d769b793c245a736caaeb198c62587f13b25c660c13b4987f959 "$TMP/compose"
  install -m 755 "$TMP/compose" "$COMPOSE"
fi
# Also callable as plain `docker-compose`. DOCKER_HOST (set by 60-dotfiles.sh
# in ~/.config/environment.d/podman.conf) points it at the Podman socket.
ln -sf "$COMPOSE" "$BIN/docker-compose"

if ! have "$BIN/mcp-publisher" 1.8.1 --version; then
  fetch https://github.com/modelcontextprotocol/registry/releases/download/v1.8.1/mcp-publisher_linux_amd64.tar.gz \
        a06c9096dcb9727c13555b6be26c7effa707b01f06a4c561ba7a3635443cf2cc "$TMP/mcp.tgz"
  tar -xzf "$TMP/mcp.tgz" -C "$TMP" mcp-publisher
  install -m 755 "$TMP/mcp-publisher" "$BIN/mcp-publisher"
fi

# git-filter-repo is a Python tool; uv installs it into its own venv.
UV="$("$HOME/.local/bin/mise" which uv 2>/dev/null || command -v uv || true)"
if [ -z "$UV" ]; then
  echo "uv not found — run scripts/40-mise.sh first" >&2
  exit 1
fi
"$UV" tool list 2>/dev/null | grep -q '^git-filter-repo v2.47.0' \
  || "$UV" tool install --force git-filter-repo==2.47.0

echo "==> CLI tools: sccache cosign terraform terraform-1.13 docker-compose mcp-publisher git-filter-repo"
