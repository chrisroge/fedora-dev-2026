#!/usr/bin/env bash
# 30 — Rust via rustup (not dnf: you want rustup's toolchain management,
# rust-analyzer, clippy, and painless updates).
set -euo pipefail

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable
fi
# shellcheck disable=SC1091
. "$HOME/.cargo/env"

rustup component add rust-analyzer clippy rustfmt

# SQLx CLI for database migrations (compile-time-checked SQL workflow)
command -v sqlx >/dev/null 2>&1 || cargo install sqlx-cli

echo "==> Rust: $(rustc --version)"
