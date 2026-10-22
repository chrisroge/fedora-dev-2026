#!/usr/bin/env bash
# verify — check this machine against what the repo installs.
# Read-only and needs no sudo, so an agent (or you) can run it at any time:
#   ./scripts/verify.sh
#
#   PASS  in place
#   WARN  personal step not done yet, or a file differs from the repo copy
#         (expected if you customized it after installing)
#   FAIL  the build is incomplete — re-run the stage named on the line
#
# Exits 1 if anything FAILed.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_DIR/dotfiles"
fails=0 warns=0

pass() { printf '  PASS  %s\n' "$*"; }
warn() { printf '  WARN  %s\n' "$*"; warns=$((warns + 1)); }
fail() { printf '  FAIL  %s\n' "$*"; fails=$((fails + 1)); }
section() { printf '\n== %s\n' "$*"; }

# The machine this repo was built on. A different model still works, but the
# monitor names, thermal limits and touchpad behavior were tuned for this one.
EXPECTED_PRODUCT="N175B"
EXPECTED_FEDORA=43

section "Platform"
fedora="$(rpm -E %fedora 2>/dev/null)"
if [ "$fedora" = "$EXPECTED_FEDORA" ]; then pass "Fedora $fedora"
else warn "Fedora $fedora (repo is built and tested on Fedora $EXPECTED_FEDORA)"; fi
product="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
if [ "$product" = "$EXPECTED_PRODUCT" ]; then pass "hardware: $product"
else warn "hardware: ${product:-unknown} (repo is tuned for $EXPECTED_PRODUCT)"; fi

section "Packages (00-repos.sh, 10-packages.sh)"
for p in hyprland hypridle hyprlock hyprpaper xdg-desktop-portal-hyprland \
         waybar mako wofi mate-polkit ghostty \
         bat btop jq ripgrep tmux lm_sensors \
         git gh code gcc clang cmake podman toolbox postgresql awscli2 \
         session-manager-plugin fontawesome-6-free-fonts rsms-inter-fonts \
         gimp restic rocm-smi \
         steam steam-devices gamemode gamescope mangohud mesa-vulkan-drivers.i686; do
  rpm -q "$p" >/dev/null 2>&1 && pass "$p" || fail "$p not installed (10-packages.sh)"
done

section "Flatpaks (20-flatpaks.sh)"
for app in com.google.Chrome org.videolan.VLC us.zoom.Zoom com.obsproject.Studio; do
  flatpak info "$app" >/dev/null 2>&1 && pass "$app" || fail "$app flatpak (20-flatpaks.sh)"
done

section "Rust (30-rust.sh)"
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
if command -v rustc >/dev/null 2>&1; then pass "$(rustc --version)"
else fail "rustup/rustc (30-rust.sh)"; fi
for c in rust-analyzer clippy rustfmt rust-src; do
  rustup component list --installed 2>/dev/null | grep -q "^$c" \
    && pass "component $c" || fail "rustup component $c (30-rust.sh)"
done
rustup target list --installed 2>/dev/null | grep -qx wasm32-unknown-unknown \
  && pass "target wasm32-unknown-unknown" || fail "rustup target wasm32-unknown-unknown (30-rust.sh)"
command -v sqlx >/dev/null 2>&1 && pass "sqlx-cli" || fail "sqlx-cli (30-rust.sh)"

section "mise (40-mise.sh)"
MISE="$HOME/.local/bin/mise"
if [ -x "$MISE" ]; then
  pass "mise $("$MISE" --version 2>/dev/null | awk '{print $1}')"
  missing="$("$MISE" ls --global --missing 2>/dev/null)"
  if [ -z "$missing" ]; then pass "all tools in ~/.config/mise/config.toml installed"
  else fail "mise tools missing (40-mise.sh): $(awk '{print $1}' <<<"$missing" | tr '\n' ' ')"; fi
  for v in 3.11 3.12 3.13; do
    "$("$MISE" which uv 2>/dev/null)" python find "$v" >/dev/null 2>&1 \
      && pass "uv Python $v" || fail "uv Python $v (40-mise.sh)"
  done
else
  fail "mise (40-mise.sh)"
fi

section "CLI tools (45-cli-tools.sh)"
for t in "sccache:0.17.0:--version" "cosign:v3.1.1:version" "terraform:v1.9.8:version" \
         "terraform-1.13:v1.13.5:version" "mcp-publisher:1.8.1:--version"; do
  IFS=: read -r name ver arg <<<"$t"
  "$HOME/.local/bin/$name" "$arg" 2>&1 | grep -qF "$ver" \
    && pass "$name $ver" || fail "$name $ver (45-cli-tools.sh)"
done
"$HOME/.docker/cli-plugins/docker-compose" version 2>/dev/null | grep -qF v5.3.1 \
  && pass "docker-compose v5.3.1" || fail "docker-compose (45-cli-tools.sh)"
command -v git-filter-repo >/dev/null 2>&1 || [ -x "$HOME/.local/bin/git-filter-repo" ] \
  && pass "git-filter-repo" || fail "git-filter-repo (45-cli-tools.sh)"

section "Fonts (50-fonts.sh)"
fc-list | grep -qi 'JetBrainsMono Nerd Font' && pass "JetBrainsMono Nerd Font" \
  || fail "JetBrainsMono Nerd Font (50-fonts.sh)"

section "Dotfiles (60-dotfiles.sh)"
check_file() {
  local src="$1" dest="$2"
  if [ ! -e "$dest" ]; then fail "$dest missing (60-dotfiles.sh)"; return; fi
  if sed "s|__HOME__|$HOME|g" "$src" | cmp -s - "$dest"; then pass "${dest/#$HOME/\~}"
  else warn "${dest/#$HOME/\~} differs from repo (diff it before re-running 60-dotfiles.sh)"; fi
}
check_file "$SRC/bashrc"                          "$HOME/.bashrc"
check_file "$SRC/bash_profile"                    "$HOME/.bash_profile"
for f in hyprland.lua hypridle.conf hyprpaper.conf; do
  check_file "$SRC/config/hypr/$f" "$HOME/.config/hypr/$f"
done
check_file "$SRC/config/hypr/scripts/touchpad-calm.sh" "$HOME/.config/hypr/scripts/touchpad-calm.sh"
for f in modules.jsonc style.css; do
  check_file "$SRC/config/waybar/$f" "$HOME/.config/waybar/$f"
done
check_file "$SRC/config/ghostty/config"            "$HOME/.config/ghostty/config"
check_file "$SRC/config/mise/config.toml"          "$HOME/.config/mise/config.toml"
check_file "$SRC/config/btop/btop.conf"            "$HOME/.config/btop/btop.conf"
check_file "$SRC/config/MangoHud/MangoHud.conf"    "$HOME/.config/MangoHud/MangoHud.conf"
check_file "$SRC/config/gamemode.ini"              "$HOME/.config/gamemode.ini"
check_file "$SRC/config/Code/User/settings.json"   "$HOME/.config/Code/User/settings.json"
check_file "$SRC/cargo/config.toml"                "$HOME/.cargo/config.toml"
check_file "$SRC/config/sccache/config"            "$HOME/.config/sccache/config"
check_file "$SRC/config/environment.d/sccache.conf" "$HOME/.config/environment.d/sccache.conf"
check_file "$SRC/config/environment.d/podman.conf"  "$HOME/.config/environment.d/podman.conf"
[ -f "$HOME/.claude/hooks/secret-path-guard.py" ] && pass "~/.claude/hooks/secret-path-guard.py" \
  || fail "~/.claude/hooks/secret-path-guard.py missing (60-dotfiles.sh)"
for b in ghostty-theme capped hypr-layout hypr-monitors hypr-cheatsheet; do
  check_file "$SRC/local/bin/$b" "$HOME/.local/bin/$b"
done
for g in hypr/layouts.lua hypr/monitors.lua waybar/config.jsonc; do
  [ -f "$HOME/.config/$g" ] && pass "~/.config/$g (generated)" \
    || fail "~/.config/$g missing (60-dotfiles.sh generates it)"
done
if command -v code >/dev/null 2>&1; then
  for ext in anthropic.claude-code shahilkumar.docxreader; do
    code --list-extensions 2>/dev/null | grep -qx "$ext" && pass "VS Code: $ext" \
      || fail "VS Code extension $ext (60-dotfiles.sh)"
  done
fi
[ -f "$HOME/.claude/settings.json" ] && jq -e '.hooks.PreToolUse' "$HOME/.claude/settings.json" >/dev/null 2>&1 \
  && pass "Claude Code baseline settings" || fail "Claude Code baseline (60-dotfiles.sh)"

if command -v Hyprland >/dev/null 2>&1; then
  if out="$(cd "$HOME" && timeout 30 Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua" 2>&1)" &&
     grep -q 'config ok' <<<"$out"; then
    pass "Hyprland accepts hyprland.lua"
  else
    fail "Hyprland rejects hyprland.lua:"$'\n'"$(tail -n 15 <<<"$out" | sed 's/^/          /')"
  fi
fi

section "Services (65-thermal-breaker.sh, 66-touchpad-calm.sh)"
if grep -qx k10temp /sys/class/hwmon/hwmon*/name 2>/dev/null; then
  [ "$(systemctl is-active thermal-breaker.service 2>/dev/null)" = active ] \
    && pass "thermal-breaker active" || fail "thermal-breaker not active (65-thermal-breaker.sh)"
fi
if grep -qi touchpad /proc/bus/input/devices 2>/dev/null; then
  systemctl --user is-enabled touchpad-calm.service >/dev/null 2>&1 \
    && pass "touchpad-calm enabled" || fail "touchpad-calm not enabled (66-touchpad-calm.sh)"
fi
systemctl --user is-enabled podman.socket >/dev/null 2>&1 \
  && pass "podman.socket enabled" || fail "podman.socket (60-dotfiles.sh)"
profile="$(busctl --system get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
  net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk -F'"' '{print $2}')"
[ "$profile" = performance ] && pass "power profile: performance" \
  || warn "power profile: ${profile:-unknown} (the reference machine runs performance)"

section "Personal steps (README: first login checklist)"
[ -f "$HOME/Pictures/wallpapers/wallpaper.png" ] && pass "wallpaper.png" \
  || warn "no ~/Pictures/wallpapers/wallpaper.png (the desktop background stays blank)"
[ -n "$(git config --global user.name 2>/dev/null)" ] && pass "git user.name set" \
  || warn "git identity not set (git config --global user.name / user.email)"
gh auth status >/dev/null 2>&1 && pass "gh authenticated" || warn "gh not authenticated (gh auth login)"
command -v claude >/dev/null 2>&1 && pass "Claude Code" || warn "Claude Code not installed (70-extras.sh)"
for c in codex opencode clawhub smithery; do
  command -v "$c" >/dev/null 2>&1 && pass "$c" || warn "$c not installed (70-extras.sh)"
done

section "Session"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
  pass "running inside Hyprland $(hyprctl -j version 2>/dev/null | jq -r .version 2>/dev/null)"
  # Show which display holds which workspace block (see hypr-monitors).
  "$HOME/.local/bin/hypr-monitors" --list 2>/dev/null |
    jq -r '.[] | "\(.role // "unpinned") \(.output) \(.workspaces | map(tostring) | join(","))"' |
    while read -r role out ws; do pass "$role → $out (workspaces ${ws:-none})"; done
  hyprctl -j binds 2>/dev/null | jq -e 'any(.[]; .description == "Help: Show this cheat sheet")' >/dev/null \
    && pass "cheat sheet bound (SUPER + /)" \
    || warn "cheat sheet binding not loaded — log out and back in to load the new hyprland.lua"
else
  warn "not inside a Hyprland session — log out and pick Hyprland at the login screen, then re-run"
fi

printf '\n%d failed, %d warnings\n' "$fails" "$warns"
[ "$fails" -eq 0 ]
