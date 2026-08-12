# Fedora Developer Workstation, 2026 Edition

A fully scripted, documented build of a developer laptop: **Fedora 43 Workstation**
with the GNOME base intact, running the **Hyprland** tiling compositor with
**Waybar**, **Ghostty**, a modern CLI stack, **mise**-managed runtimes, Rust via
rustup, rootless **Podman**, and a tuned Steam/gamescope gaming layer.

Everything here was extracted from a real, daily-driven machine and sanitized
for public use. Clone it, run one script, log into Hyprland, and you have the
whole environment.

```bash
git clone https://github.com/chrisroge/fedora-dev-2026.git
cd fedora-dev-2026
./bootstrap.sh
```

## Design decisions (the "why")

| Choice | Over | Because |
|---|---|---|
| Fedora Workstation + Hyprland session | a minimal/DIY spin | You keep GDM, NetworkManager, PipeWire, portals, printing — all maintained by Fedora — and add Hyprland as *just another session* selectable at login. GNOME remains available as a fallback session. |
| Hyprland (solopasha COPR) | Fedora's own packaging pace | The COPR tracks upstream closely; you get current Hyprland (`0.51.x` at time of writing) with the matching portal, hypridle, hyprlock, hyprpaper. |
| Ghostty | kitty/alacritty | GPU-rendered, native Wayland, config hot-reload over D-Bus (this repo's light/dark toggle uses it), sane defaults. |
| mise | asdf / per-tool installers | One tool pins node (LTS), uv, and the modern CLI utilities (`eza`, `fd`, `fzf`, `zoxide`, `lazygit`, `delta`, `yq`) — versioned in one TOML file, upgradable with one command. |
| rustup | dnf rust | Toolchain management, `rust-analyzer`, painless `stable` updates. |
| Podman + toolbox | Docker CE | Rootless by default, ships with Fedora, `docker-compose` works against the Podman socket. |
| zram swap only | disk swap | Default Fedora zram-generator setup: fast compressed swap in RAM, no SSD wear. Size it in `/etc/systemd/zram-generator.conf` if you run heavy VM/ffmpeg workloads. |

## What the bootstrap installs

`bootstrap.sh` runs these stages in order; each is idempotent and can be run
alone:

| Stage | What it does |
|---|---|
| `scripts/00-repos.sh` | COPRs (`solopasha/hyprland`, `scottames/ghostty`), VS Code repo, RPM Fusion Steam repo, dnf5 plugins |
| `scripts/10-packages.sh` | dnf packages, grouped: Hyprland desktop, everyday CLI, dev toolchain, fonts, gaming |
| `scripts/20-flatpaks.sh` | Flathub remote + Chrome |
| `scripts/30-rust.sh` | rustup (stable), rust-analyzer/clippy/rustfmt, sqlx-cli |
| `scripts/40-mise.sh` | mise itself + everything in `dotfiles/config/mise/config.toml` |
| `scripts/50-fonts.sh` | JetBrainsMono Nerd Font (per-user, from official releases) |
| `scripts/60-dotfiles.sh` | Installs all configs below, backing up anything it would overwrite |
| `scripts/65-thermal-breaker.sh` | Root daemon that clamps the CPU to 2 GHz at 95°C and restores full boost below 80°C — a software safety net under the hardware throttle for unattended build/test load. AMD-only (k10temp); skips itself elsewhere |
| `scripts/66-touchpad-calm.sh` | User service that disables touchpad tap-to-click while an external mouse is attached. Skips itself on machines with no touchpad |
| `scripts/70-extras.sh` | *(manual)* Claude Code + Codex CLI, `gh auth login`, git identity |

## The desktop

### Hyprland (`dotfiles/config/hypr/`)

The config is the shipped Hyprland default, deliberately kept close to stock so
the wiki still maps onto it, plus a documented multi-monitor scheme:

- **Workspace-per-monitor pinning.** Each monitor owns a block of workspaces
  (`0 1 | 2 3 4 5 | 6 7 8 9`), so `SUPER+<n>` always lands on the same physical
  screen and each monitor keeps its own current workspace. The example layout
  is a portrait document monitor, a 4K main display at 1.5x scale, and the
  laptop panel — adapt the `monitor =` lines to your hardware (`hyprctl monitors`
  lists names).
- **Monitor-aware movement.** `SUPER+CTRL+D/F/G` focuses a specific monitor,
  `SUPER+SHIFT+D/F/G` throws the focused window at one, `SUPER+ALT+S` swaps
  what two monitors are showing.
- **Workspace 10 renders as "0"** in Waybar so the bar reads the way the number
  row does.
- **Idle policy** (`hypridle.conf`): dim at 2.5 min → lock at 5 → screen off at
  6 → suspend at 30. Gaming rules suspend all of that while a game is fullscreen.
- **Gaming rules** (`gaming.conf`): Steam menu fixes, compositor effects
  stripped from fullscreen windows (enables direct scanout), `content game`
  hints, gamescope handling, and commented opt-in tearing rules — every rule
  explained inline.
- **Wallpaper**: `animated-wallpaper.sh` uses `mpvpaper` for a video wallpaper
  if installed, otherwise falls back to `hyprpaper`. Drop `wallpaper.png` (and
  optionally `wallpaper.mp4`) into `~/Pictures/wallpapers/`.

Key bindings you'll use in the first five minutes (`SUPER` = Windows key):

| Keys | Action |
|---|---|
| `SUPER+Q` | terminal (Ghostty) |
| `SUPER+R` | launcher (wofi) |
| `SUPER+E` | file manager |
| `SUPER+C` | close window |
| `SUPER+V` | toggle floating |
| `SUPER+1..0` | workspace on its pinned monitor |
| `SUPER+SHIFT+1..0` | move window to workspace |
| `SUPER+arrows` | move focus |
| `SUPER+ALT+H/J/K/L` | aim the next split (dwindle preselect) |
| `SUPER+S` | scratchpad |
| `Print` | region screenshot → clipboard (grim+slurp) |

### Waybar (`dotfiles/config/waybar/`)

Per-monitor workspace pills (`persistent-workspaces` keyed by output), window
title, and a right side of: idle inhibitor, **Ghostty theme toggle**, audio,
network, power profile, CPU/RAM/temp, backlight, battery, clock, tray. The
stylesheet renders workspaces as three visually distinct states (empty /
occupied / active) with the active pill matching the Hyprland border accent.

### Ghostty + one-click light/dark (`dotfiles/config/ghostty/`, `dotfiles/local/bin/ghostty-theme`)

Ghostty runs the iTerm2 Solarized pair with contrast-corrected foreground and
selection colors (the stock Solarized selection is a 1.15:1 contrast —
invisible). `ghostty-theme` flips light/dark:

- rewrites the theme + the mode-dependent color overrides atomically,
- **validates the candidate config** with `ghostty +validate-config` before
  overwriting a working one,
- hot-reloads every open Ghostty window via its D-Bus `reload-config` action,
- re-signals Waybar (`SIGRTMIN+8`) so the sun/moon icon flips instantly.

Click the icon in Waybar, or run `ghostty-theme toggle|light|dark`.

### Touchpad calming (`dotfiles/config/hypr/scripts/touchpad-calm.sh`)

On a laptop docked to an external mouse, a palm brushing the touchpad lands as
a stray click mid-sentence. `touchpad-calm.service` watches udev for mouse
hotplug and turns **tap-to-click and tap-and-drag off whenever a USB or
Bluetooth mouse is present**, restoring them when it's unplugged. Pointer
motion, two-finger scroll, and physical clickpad presses keep working
throughout — only taps are suppressed.

It re-resolves the Hyprland instance signature on every call, so it survives
compositor restarts, and re-applies every 30 seconds to heal config reloads.

## The shell & CLI stack

`~/.bashrc` stays close to Fedora stock and layers on:

- **mise** activation — provides `node` (LTS), `uv`, and shims for the tools below
- **zoxide** (`z` = frecency-ranked cd) and **fzf** keybindings (`Ctrl+R` history, `Ctrl+T` files)
- `ls` → **eza**, `cat` → **bat**
- From dnf: `ripgrep`, `fd` (mise), `jq`/`yq`, `btop`, `tmux`, `lazygit`, `delta`

`capped` (`dotfiles/local/bin/capped`) runs a command inside a memory-capped
systemd scope, so a runaway build, VM, or transcode gets OOM-killed on its own
instead of taking the desktop down with it. `MemoryHigh` throttles and reclaims
at 90% of the cap before the hard kill:

```bash
capped cargo build --release      # default 16G cap (override with $CAPPED_MAX)
capped -m 8G ffmpeg -i in.mkv out.mp4
```

Runtimes and tool versions live in one file, `dotfiles/config/mise/config.toml`:

```toml
[tools]
delta = "latest"
node = "lts"
uv = "latest"
zoxide = "latest"
eza = "latest"
fd = "latest"
fzf = "latest"
yq = "latest"
lazygit = "latest"
```

`mise upgrade` bumps the lot; a per-project `.mise.toml` (or `.tool-versions`)
overrides any of them per repository.

## Languages, containers, cloud

- **Rust**: rustup stable + `rust-analyzer`, `clippy`, `rustfmt`, `sqlx-cli`.
- **Node**: LTS via mise (`corepack` available for pnpm/yarn).
- **Python**: `uv` for everything — venvs, tools (`uv tool install`), and
  Python versions themselves (`uv python install 3.13`).
- **Native builds**: gcc, clang, cmake, plus `openssl-devel`/`dbus-devel`/
  `alsa-lib-devel`, the three headers Rust crates most often want.
- **Containers**: rootless Podman; `toolbox` for disposable pet containers.
  `docker-compose` works via the Podman socket:
  `systemctl --user enable --now podman.socket`.
- **Cloud**: AWS CLI v2 + Session Manager plugin; `gh` for GitHub.
- **Editors**: VS Code (Microsoft repo); Ghostty + tmux + lazygit for terminal life.
- **AI CLIs** *(optional, `scripts/70-extras.sh`)*: Claude Code and Codex CLI.

## Gaming layer

Steam (RPM Fusion), **gamemode** (renice + performance governor while a game
runs), **MangoHud** (overlay with FPS/frametime/temps/gamemode status — enable
per-game with `mangohud %command%`), **gamescope**, and **goverlay** as the GUI
for tuning MangoHud. The Hyprland `gaming.conf` and both tool configs are
annotated with the reasoning — including why GPU clock forcing is deliberately
*off* for APUs.

## After bootstrap: first login checklist

1. Log out; on the GDM login screen click the gear and pick **Hyprland**.
2. `SUPER+Q` for a terminal; `nmtui` or the nm-applet tray icon for Wi-Fi.
3. Drop a `wallpaper.png` in `~/Pictures/wallpapers/`.
4. Run `./scripts/70-extras.sh`, then `gh auth login` and set your git identity.
5. Sanity checks: `hyprctl monitors`, `mise doctor`, `cargo --version`,
   `podman run --rm hello-world`, `fc-list | grep -c JetBrainsMono`.

## Repo layout

```
bootstrap.sh              # run everything
scripts/                  # numbered, idempotent stages
dotfiles/
  bashrc  bash_profile  gitconfig
  config/
    hypr/                 # hyprland, hypridle, hyprpaper, gaming rules, wallpaper script
      scripts/            # touchpad-calm.sh
    waybar/               # config.jsonc + style.css
    ghostty/config
    mise/config.toml
    MangoHud/MangoHud.conf
    gamemode.ini
  local/bin/
    ghostty-theme         # solarized light/dark toggle
    capped                # run a command under a memory cap
  systemd/user/           # touchpad-calm.service
```

No secrets, no personal data: git identity is a placeholder, GitHub auth goes
through `gh auth login` (OS keyring), and machine-specific paths are expanded
at install time from a `__HOME__` placeholder.

## License

MIT — see [LICENSE](LICENSE).
