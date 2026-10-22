# Fedora Developer Workstation, 2026 Edition

A fully scripted, documented build of a developer laptop: **Fedora 43 Workstation**
with the GNOME base intact, running the **Hyprland** tiling compositor with
**Waybar** and **Ghostty**, a modern CLI stack, **mise**-managed runtimes, Rust via
rustup, rootless **Podman**, AI coding agents (**Claude Code**, **Codex**,
opencode), and a tuned Steam/gamescope gaming layer.

Everything here was extracted from a real, daily-driven laptop (a Nimo N175B:
Ryzen 9 8945HS, Radeon 780M) and sanitized for public use. Every app and
setting that was changed on that machine since its first boot is captured here.

## Two ways to install

**With an agent (recommended).** Clone the repo, open it in Claude Code and ask
it to set the machine up. [`CLAUDE.md`](CLAUDE.md) is its runbook: it runs the
per-user stages itself, hands you the few commands that need your password,
checks each phase with `scripts/verify.sh`, and walks you through the logins.

```bash
git clone https://github.com/chrisroge/fedora-dev-2026.git
cd fedora-dev-2026
claude          # then: "configure this machine like the repo"
```

**By hand.**

```bash
./bootstrap.sh            # all stages (asks for your sudo password once)
./scripts/70-extras.sh    # AI CLIs + logins
./scripts/verify.sh       # PASS / WARN / FAIL for every piece
```

## Design decisions (the "why")

| Choice | Over | Because |
|---|---|---|
| Fedora Workstation + Hyprland session | a minimal/DIY spin | You keep GDM, NetworkManager, PipeWire, portals, printing — all maintained by Fedora — and add Hyprland as *just another session* selectable at login. GNOME remains available as a fallback session. |
| Hyprland (nett00n COPR) | Fedora's own packaging | Fedora ships only `xdg-desktop-portal-hyprland`, so the compositor must come from a COPR. This project carries the whole set — compositor, hypridle, hyprlock, hyprpaper, portal, and the aquamarine/hyprutils/hyprlang deps — for Fedora 43. |
| Workspaces pinned by monitor *role* | by connector name | The same config works on any laptop with any mix of displays; nothing to edit when you dock somewhere new. |
| Ghostty | kitty/alacritty | GPU-rendered, native Wayland, config hot-reload over D-Bus (this repo's light/dark toggle uses it), sane defaults. |
| mise | asdf / per-tool installers | One tool manages node (LTS), uv, and the modern CLI utilities (`eza`, `fd`, `fzf`, `zoxide`, `lazygit`, `delta`, `yq`) — one TOML file, upgradable with one command. |
| Pinned + checksummed release binaries | `curl \| tar` of "latest" | sccache, cosign, terraform, docker-compose and mcp-publisher install at exact versions with SHA-256 checks, so every machine gets identical bits. |
| rustup | dnf rust | Toolchain management, `rust-analyzer`, painless `stable` updates. |
| Podman + toolbox | Docker CE | Rootless by default, ships with Fedora; `docker-compose` talks to the Podman socket via `DOCKER_HOST`. |
| zram swap only | disk swap | Default Fedora zram-generator setup: fast compressed swap in RAM, no SSD wear. Size it in `/etc/systemd/zram-generator.conf` if you run heavy VM/ffmpeg workloads. |

## What the bootstrap installs

`bootstrap.sh` runs these stages in order (or any subset: `./bootstrap.sh 30 60`).
Each is idempotent and logs to `~/.local/state/fedora-dev-2026/logs/<stage>.log`.

| Stage | Needs | What it does |
|---|---|---|
| `00-repos.sh` | sudo | COPRs (`nett00n/hyprland`, `scottames/ghostty`), VS Code repo, RPM Fusion Steam repo, dnf5 plugins. Ends by verifying the key packages actually resolve, so a pruned COPR fails here instead of at login |
| `10-packages.sh` | sudo | dnf packages, grouped: Hyprland desktop, everyday CLI, dev toolchain, fonts, apps, gaming (incl. 32-bit Mesa/Vulkan for Steam) |
| `20-flatpaks.sh` | password dialog | Chrome, VLC (default `.mp4` player), Zoom from Flathub; OBS Studio from Fedora's remote |
| `30-rust.sh` | — | rustup stable, rust-analyzer/clippy/rustfmt/rust-src, `wasm32-unknown-unknown`, sqlx-cli |
| `40-mise.sh` | — | mise + everything in `dotfiles/config/mise/config.toml`; uv-managed Python 3.11–3.13 |
| `45-cli-tools.sh` | — | Pinned, checksum-verified binaries: sccache, cosign, terraform 1.9.8 (+ `terraform-1.13`), docker-compose, mcp-publisher; git-filter-repo via uv |
| `50-fonts.sh` | — | JetBrainsMono Nerd Font (per-user, from official releases) |
| `60-dotfiles.sh` | — | All configs below (backing up anything it replaces), generated monitor/layout files, VS Code extensions, Claude Code + Codex baselines, Podman socket, desktop settings |
| `65-thermal-breaker.sh` | sudo | Root daemon that clamps the CPU to 2 GHz at 95°C and restores full boost below 80°C — a software safety net under the hardware throttle for unattended build/test load. AMD-only (k10temp); skips itself elsewhere |
| `66-touchpad-calm.sh` | — | User service that disables touchpad tap-to-click while an external mouse is attached. Skips itself on machines with no touchpad |
| `70-extras.sh` | — | *(manual)* Claude Code, Codex, opencode, clawhub, smithery; then `gh auth login`, git identity, agent logins, optional ChatGPT desktop app |
| `verify.sh` | — | Read-only check of every item above |

### Installed applications

| Area | Apps |
|---|---|
| Desktop | Hyprland, Waybar, Ghostty, wofi, mako, hyprlock/hypridle/hyprpaper, Nautilus, pavucontrol, nm-applet, grim + slurp |
| Browsers & media | Google Chrome, VLC, OBS Studio, Zoom, GIMP (plus Fedora's Firefox and LibreOffice) |
| Editors & agents | VS Code (+ Claude Code and DOCX-reader extensions), Claude Code, Codex CLI, opencode, ChatGPT desktop (optional) |
| Languages | Rust (rustup), Node LTS (mise), Python (Fedora's 3.14 + uv-managed 3.11–3.13), gcc/clang/cmake |
| Dev & cloud | git, gh, lazygit, delta, Podman + toolbox, docker-compose, PostgreSQL client, AWS CLI v2 + SSM plugin, terraform, cosign, sccache, git-filter-repo, mcp-publisher, clawhub, smithery |
| CLI | bat, eza, fd, fzf, ripgrep, jq, yq, zoxide, btop, tmux, plocate, mtr, nmap-ncat, bind-utils, whois |
| System | restic, gdisk, rocm-smi, lm_sensors, radeontop, vulkan-tools, libva-utils |
| Gaming | Steam, gamescope, gamemode, MangoHud, goverlay |

## The desktop

### Hyprland (`dotfiles/config/hypr/`)

Hyprland **0.56**, configured in Lua (`hyprland.lua`, commented section by
section). Two generated companions are loaded from it:
`monitors.lua` (from `hypr-monitors`) and `layouts.lua` (from `hypr-layout`).

**Workspaces follow monitor roles, so any display setup works.** At login and
on every hotplug, `hypr-monitors` sorts the connected displays (the built-in
panel first, then externals from largest to smallest) and pins a block of
workspaces to each:

| Role | Display | Workspaces | Focus / move window | Waybar |
|---|---|---|---|---|
| home | built-in panel | 1–4, 11–14 | `SUPER+CTRL+G` / `SUPER+SHIFT+G` | HOME |
| studio | largest external | 5–8, 15–18 | `SUPER+CTRL+F` / `SUPER+SHIFT+F` | STUDIO |
| read | next external | 9–10, 19–20 | `SUPER+CTRL+D` / `SUPER+SHIFT+D` | READ |

So `SUPER+<n>` always lands on the same *kind* of screen, each display keeps
its own current workspace, and `SUPER+ALT+S` swaps what STUDIO and READ are
showing. A laptop on its own is just HOME: the other workspaces open wherever
you are. Plug a display in and its workspaces move onto it; unplug it and
Hyprland brings them back. A fourth display gets a bar but no pinned block.

Displays default to their preferred mode with automatic position and scale.
For rotation (a portrait reading monitor), a custom scale or fixed positions,
arrange them, then run `hypr-monitors --save` to record the arrangement in
`~/.config/hypr/monitors.json` (per machine, never overwritten). For example,
the reference machine has a pivoted ultrawide left of a 4K display at 1.5x,
then the laptop panel:

```json
{ "outputs": {
    "DP-1":     { "mode": "2560x1080@60", "position": "0x0",    "scale": 1,   "transform": 1 },
    "HDMI-A-1": { "mode": "3840x2160@60", "position": "1080x0", "scale": 1.5, "transform": 0 },
    "eDP-1":    { "mode": "1920x1080@60", "position": "3640x0", "scale": 1,   "transform": 0 } } }
```

`hypr-monitors --list` shows which display holds which role.

- **Twenty workspaces**: the number row is 1–10 (`0` = 10); add `ALT` for 11–20.
- **Idle policy** (`hypridle.conf`): dim at 2.5 min → lock at 5 → screen off at
  6 → suspend at 30. Gaming rules suspend all of that while a game is fullscreen.
- **Gaming rules** (GAMING section of `hyprland.lua`): Steam menu fixes,
  compositor effects stripped from fullscreen windows (enables direct scanout),
  `content game` hints, gamescope handling, and an opt-in tearing example —
  each explained inline.
- **Wallpaper**: hyprpaper 0.8 shows `~/Pictures/wallpapers/wallpaper.png`,
  scaled to cover each display.
- **Per-workspace layouts**: `SUPER+CTRL+L` opens a chooser for the focused
  workspace: Inherit, Dwindle, or 2, 3 or 4 full-height columns. Column presets
  use the native scrolling layout with equal-width columns; additional windows
  extend the workspace sideways (`SUPER+Left/Right` scrolls to them), a single
  window fills it, and fewer windows than columns are centered. Choices persist
  per workspace in `~/.config/hypr/layouts.json`. The defaults shipped here
  match the reference machine: workspaces 1, 6 and 7 in two columns, 5 in three.

```bash
hypr-layout two-columns          # focused workspace: halves
hypr-layout three-columns 5      # an explicit workspace
hypr-layout dwindle 5            # explicit override
hypr-layout inherit 5            # follow the default again
hypr-layout --default dwindle    # or any of the column presets
hypr-layout --list               # JSON for inspection
```

### Keyboard cheat sheet (`hypr-cheatsheet`)

Press **`SUPER + /`**, or click the keyboard icon in Waybar, for a floating
panel listing every shortcut, grouped (Apps, Windows, Layout, Workspaces,
Monitors, Media, Session). Press it again (or `q`) to close it.
`hypr-cheatsheet --print` prints the same list in any terminal.

The sheet is rendered **live from the running bindings** (`hyprctl -j binds`),
not from a hand-kept list: every binding in `hyprland.lua` carries a
`"Group: action"` description, so adding a binding with a description is all
it takes to document it. The monitor keys show the display each one targets
right now.

The shortcuts you'll use in the first five minutes (`SUPER` = Windows key):

| Keys | Action |
|---|---|
| `SUPER+/` | this cheat sheet |
| `SUPER+Q` | terminal (Ghostty) |
| `SUPER+R` | launcher (wofi) |
| `SUPER+E` | file manager |
| `SUPER+C` | close window |
| `SUPER+V` | toggle floating |
| `SUPER+1..0` / `SUPER+ALT+1..0` | workspace 1–10 / 11–20 |
| `SUPER+SHIFT+1..0` | move window to workspace |
| `SUPER+CTRL+L` | choose this workspace's layout |
| `SUPER+arrows` | move focus |
| `SUPER+S` | scratchpad |
| `Print` | region screenshot → clipboard |

### Waybar (`dotfiles/config/waybar/`)

Floating charcoal-and-brass bars, one per display, labelled by role (**HOME**,
**STUDIO**, **READ**). Every pinned workspace number stays visible on its
display, empty or not. Gold fill marks the focused workspace; a gold outline
marks a workspace visible on another display; a blue underline marks an
occupied workspace. The READ bar is compact (no window title, short clock).

`config.jsonc` is generated per display by `hypr-monitors`; `modules.jsonc`
holds the shared controls; `style.css` is set in Inter with Font Awesome icons.
Controls: **cheat sheet**, idle inhibitor, **Ghostty theme toggle**, audio,
network, CPU/RAM/temperature, power profile, brightness, battery, clock, tray.
Click CPU to open btop, audio for the mixer, the clock for the date.

### Ghostty + one-click light/dark (`dotfiles/config/ghostty/`, `dotfiles/local/bin/ghostty-theme`)

Ghostty runs the iTerm2 Solarized pair with contrast-corrected foreground and
selection colors (the stock Solarized selection is a 1.15:1 contrast —
invisible), and shows the terminal bell as window attention plus a title
flag, so a finished Codex turn gets noticed. The bell is deliberately silent:
in Ghostty 1.3.1 every *audible* bell leaks GStreamer threads that are never
freed. `ghostty-theme`
flips light/dark:

- rewrites the theme + the mode-dependent color overrides,
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

It re-resolves the Hyprland instance on every call, so it survives compositor
restarts, and re-applies every 30 seconds to heal config reloads.

Deciding what counts as an external mouse takes more care than
`ID_INPUT_MOUSE=1`: keyboards routinely expose a second HID interface carrying
relative axes, which udev tags as a mouse, so a permanently plugged-in keyboard
would calm the touchpad forever. The script reads `ID_USB_INTERFACES` — the
list of interfaces the physical device declares as `:CCSSPP:` — and skips
anything declaring an HID boot **keyboard** (protocol `01`) but no boot
**mouse** (protocol `02`). Unifying receivers that carry both still count, and
Bluetooth mice expose no `ID_USB_INTERFACES` at all, so they count too.

If taps are stuck off (or stubbornly on), ask it why:

```bash
~/.config/hypr/scripts/touchpad-calm.sh --explain
```

To force-ignore a device that still fools it, set `IGNORE_RE` (matched against
`ID_SERIAL`/`ID_MODEL`/`ID_VENDOR`): `systemctl --user edit touchpad-calm` →
`Environment=IGNORE_RE=My_Weird_Dock`.

### Desktop settings

- Power profile pinned to **Performance** (tuned-ppd; switch it from Waybar's
  power icon).
- Nautilus opens folders in list view.
- btop uses the Solarized Dark theme, per-core CPU, and hides the disk pane.

## The shell & CLI stack

`~/.bashrc` stays close to Fedora stock and layers on:

- **mise** activation — provides `node` (LTS), `uv`, and the tools below
- **zoxide** (`z` = frecency-ranked cd) and **fzf** keybindings (`Ctrl+R` history, `Ctrl+T` files)
- `ls` → **eza**, `cat` → **bat**
- From dnf: `ripgrep`, `jq`, `btop`, `tmux`; from mise: `fd`, `yq`, `lazygit`, `delta`

`capped` (`dotfiles/local/bin/capped`) runs a command inside a memory-capped
systemd scope, so a runaway build, VM, or transcode gets OOM-killed on its own
instead of taking the desktop down with it. `MemoryHigh` throttles and reclaims
at 90% of the cap before the hard kill:

```bash
capped cargo build --release      # default 16G cap (override with $CAPPED_MAX)
capped -m 8G ffmpeg -i in.mkv out.mp4
```

Runtimes and tool versions live in one file, `dotfiles/config/mise/config.toml`;
`mise upgrade` bumps the lot, and a per-project `.mise.toml` overrides any of
them per repository.

## Languages, containers, cloud

- **Rust**: rustup stable + `rust-analyzer`, `clippy`, `rustfmt`, `rust-src`,
  the `wasm32-unknown-unknown` target, and `sqlx-cli`. **sccache** is cargo's
  compiler wrapper (`~/.cargo/config.toml`, 40 GB cache), so many worktrees
  or agents building the same dependencies share the work; incremental
  compilation is off because sccache can't cache it. Opt out once with
  `RUSTC_WRAPPER= CARGO_INCREMENTAL=1 cargo build`.
- **Node**: LTS via mise (`corepack` available for pnpm/yarn).
- **Python**: `uv` for everything — venvs, tools (`uv tool install`), and
  Python versions (3.11, 3.12 and 3.13 are preinstalled).
- **Native builds**: gcc, clang, cmake, plus `openssl-devel`/`dbus-devel`/
  `alsa-lib-devel`, the three headers Rust crates most often want.
- **Containers**: rootless Podman with its socket enabled and `DOCKER_HOST`
  pointing at it, so `docker-compose` and other Docker clients just work;
  `toolbox` for disposable pet containers. (Note: the first `toolbox` command
  after a podman upgrade migrates storage and stops running containers.)
- **Cloud**: AWS CLI v2 (dnf) + Session Manager plugin (from AWS's RPM URL);
  terraform (1.9.8, plus 1.13.5 as `terraform-1.13`); cosign; `gh`.
- **Editors**: VS Code (Microsoft repo; autosave, Solarized Dark); Ghostty +
  tmux + lazygit for terminal life.

## AI coding agents

Installed by `70-extras.sh`: **Claude Code**, **Codex CLI**, **opencode**, and
the **clawhub** (agent skills) and **smithery** (MCP servers) registry CLIs;
the ChatGPT desktop app is an optional manual step.

Stage 60 also gives the agents a baseline, adding only settings you don't
already have:

- **Claude Code** (`dotfiles/claude/`): Opus with extended thinking, a
  one-line status line (model · directory), sound cues when it needs you,
  fails or asks a question (no chime on every finished turn), a small allow-list of read-only
  commands, the Solarized Dark theme (`/theme`), and a hook that refuses
  any command naming `~/.aws`.
- **Codex** (`dotfiles/codex/config.toml`, seeded once): high reasoning
  effort and terminal-bell notifications.
- **sccache** and `capped`, above, exist largely for agents: parallel agent
  builds share one compile cache, and runaway jobs can't take the desktop down.

## Gaming layer

Steam (RPM Fusion) with the 32-bit Mesa/Vulkan drivers games need,
**gamemode** (renice + performance governor while a game runs), **MangoHud**
(overlay with FPS/frametime/temps/gamemode status — enable per game with
`mangohud %command%`), **gamescope**, and **goverlay** as the GUI for tuning
MangoHud. The gaming rules in `hyprland.lua` and both tool configs are
annotated with the reasoning — including why GPU clock forcing is deliberately
*off* for APUs.

## After bootstrap: first login checklist

1. Drop a `wallpaper.png` in `~/Pictures/wallpapers/`.
2. Log out; on the login screen click the gear and pick **Hyprland**.
3. `SUPER+Q` for a terminal; `nmtui` or the nm-applet tray icon for Wi-Fi.
   `SUPER+/` shows every shortcut.
4. Run `./scripts/70-extras.sh`, then `gh auth login` and set your git identity.
5. Run `./scripts/verify.sh`; everything should PASS except personal steps.

## Repo layout

```
CLAUDE.md                 # runbook for an agent setting up a machine
bootstrap.sh              # run all (or some) stages, with logs
scripts/                  # numbered, idempotent stages + verify.sh
  lib/merge-json.py       # adds baseline settings without overwriting yours
dotfiles/
  bashrc  bash_profile  gitconfig
  cargo/config.toml       # sccache as rustc wrapper
  claude/                 # Claude Code baseline settings, theme, hook
  codex/config.toml
  config/
    hypr/                 # hyprland.lua, hypridle, hyprpaper, layouts/monitors defaults
      scripts/            # touchpad-calm.sh
    waybar/               # shared modules + style.css (per-display config is generated)
    ghostty/config
    btop/  Code/User/  MangoHud/  mise/  sccache/  environment.d/
    gamemode.ini
  local/bin/
    hypr-monitors         # role-based monitor/workspace pinning + Waybar bars
    hypr-cheatsheet       # SUPER+/ live keyboard cheat sheet
    hypr-layout           # per-workspace layouts
    ghostty-theme         # Solarized light/dark toggle
    capped                # run a command under a memory cap
  systemd/user/           # touchpad-calm.service
```

No secrets, no personal data: git identity is a placeholder, GitHub auth goes
through `gh auth login` (OS keyring), the agents log in with your own
accounts, and machine-specific paths are expanded at install time from a
`__HOME__` placeholder.

## License

MIT — see [LICENSE](LICENSE).
