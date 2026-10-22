# Agent runbook: configure this machine like the reference laptop

This repo turns a Fedora 43 Workstation install into a copy of one specific
developer laptop: Hyprland desktop, Waybar, Ghostty, the dev toolchain, the AI
coding agents and their settings. If the person you're working with asked you
to "set up this machine", "configure it like the repo", or similar, follow
this runbook. README.md explains every component; read it when you need the
why.

## Ground rules

- **You cannot type a sudo password.** Never run `sudo` yourself. When a step
  needs root, give the person the exact command and ask them to run it,
  either by typing `! <command>` in this Claude Code prompt or in a separate
  terminal. Then read the log it wrote (below) to see the result.
- **Every bootstrap stage logs to** `~/.local/state/fedora-dev-2026/logs/<stage>.log`.
  Read the log rather than asking the person to paste output.
- **Check before you change, and report what you changed.** Run
  `./scripts/verify.sh` (read-only, no sudo) before starting and after each
  phase. PASS = done, WARN = personal step or local drift, FAIL = re-run the
  stage named on the line.
- **Don't run `toolbox`, `podman system migrate` or `podman system reset`.**
  After a podman upgrade, the first `toolbox` call migrates storage and
  *stops every running container*.
- **Keep scans small.** Don't read big trees or logs whole into memory; use
  `grep -l`, `head`, and `capped -m 2G <cmd>` (installed by stage 60) for
  anything heavy. This laptop's swap is small, and a runaway process gets the
  whole terminal killed.
- **This is someone else's public repo.** Don't commit or push unless the
  person asks. Never add personal data to it (names, emails, hostnames, home
  paths, Wi-Fi names, wallpapers).
- **Respect existing files.** Stage 60 backs up anything it replaces to
  `~/.dotfiles-backup-<timestamp>/`. Before running it on a machine that has
  been in use, run verify and tell the person which files will be replaced.

## Phase 0: preflight (you run these)

```bash
rpm -E %fedora                              # expect 43
cat /sys/class/dmi/id/product_name          # reference hardware: N175B
df -h / | tail -1                           # need ~40 GB free (Steam, toolchains, caches)
./scripts/verify.sh                         # baseline; many FAILs on a fresh install is normal
```

A different Fedora release or laptop model still works, but tell the person:
the third-party repos are pinned to Fedora 43 builds, and the thermal and
touchpad tuning was done on the N175B (AMD Ryzen 9 8945HS, Radeon 780M).

## Phase 1: system packages (the person runs these, with sudo)

Ask them to run:

```bash
./bootstrap.sh 00 10
```

- `00` adds the COPRs (Hyprland from `nett00n/hyprland`, Ghostty), the VS Code
  repo and RPM Fusion's Steam repo, then checks the key packages resolve.
- `10` installs every dnf package (desktop, CLI, dev toolchain, fonts, apps,
  gaming incl. 32-bit drivers).

If `00` reports packages that "resolve from no enabled repository", a COPR has
probably dropped its Fedora 43 build. Show the person the error and the
chroot-list URL it prints. **Don't switch to a different COPR on your own.**

## Phase 2: user-level stages (you run these)

```bash
./bootstrap.sh 20          # Flatpaks: GNOME shows a password dialog; tell the person to expect it
./bootstrap.sh 30 40 45 50 60 66
```

30 Rust (rustup, components, wasm target, sqlx-cli; compiling sqlx takes
several minutes), 40 mise (node, uv, CLI tools; uv Pythons 3.11 to 3.13),
45 pinned binaries (sccache, cosign, terraform, docker-compose, mcp-publisher,
git-filter-repo; each checksum-verified), 50 Nerd Font, 60 dotfiles, desktop
settings and the agent baselines, 66 touchpad service.

Then ask the person to run the last root stage:

```bash
./bootstrap.sh 65          # thermal circuit breaker (AMD only; skips elsewhere)
```

## Phase 3: AI tools and logins

```bash
./scripts/70-extras.sh     # you run it: Codex, opencode, clawhub, smithery, gh alias
```

Then walk the person through the interactive parts, one at a time:
1. `gh auth login` (they run it; choose HTTPS and the browser login).
2. Git identity: ask for their name and email, then you run
   `git config --global user.name "…"` and `git config --global user.email "…"`.
3. `codex` once, to log in (they run it).
4. Optional ChatGPT desktop app: 70-extras prints the download link and the
   two sudo commands.

Claude Code's settings come from `dotfiles/claude/settings.json`. Stage 60
*merges* it, adding only keys the person doesn't already have.

## Phase 4: first Hyprland login

1. Ask the person to put a `wallpaper.png` in `~/Pictures/wallpapers/`
   (any image; the desktop stays blank otherwise).
2. They log out, pick **Hyprland** from the gear on the login screen, and
   log in. GNOME stays available there as a fallback.
3. They press `SUPER + Q` for a terminal, open Claude Code in this repo again,
   and you run `./scripts/verify.sh`. The Session section confirms Hyprland,
   lists which display holds which workspaces, and checks the cheat sheet is
   bound.
4. Show them `SUPER + /` (or the keyboard icon in Waybar) for the cheat sheet.

## Monitors

Workspaces are pinned to displays by **role**, not connector name, so any
setup works with no edits. `hypr-monitors` runs at login and on every
hotplug:

| role | display | workspaces | keys |
|---|---|---|---|
| HOME | built-in panel | 1-4, 11-14 | `SUPER+CTRL+G` focus, `SUPER+SHIFT+G` move window |
| STUDIO | largest external | 5-8, 15-18 | `SUPER+CTRL+F` / `SUPER+SHIFT+F` |
| READ | next external | 9-10, 19-20 | `SUPER+CTRL+D` / `SUPER+SHIFT+D` |

Displays come up at their preferred mode with automatic position and scale.
If one needs rotating (portrait), a different scale or a fixed position, fix it
live (`hyprctl monitors` shows names), then run `hypr-monitors --save` to
record the current arrangement in `~/.config/hypr/monitors.json`. Edit that
file for anything else: keys are output names; values take `mode`,
`position`, `scale`, `transform` (1 = 90°, 3 = 270°). Run `hypr-monitors` to
apply. `hypr-monitors --list` shows the role assignment.

## Troubleshooting

| Symptom | Check |
|---|---|
| Hyprland shows a red config error bar | `hyprctl configerrors`; `cd ~ && Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` |
| Waybar missing or wrong after plugging a display | `hypr-monitors` (regenerates and reloads); `pkill waybar; waybar & disown` |
| Taps on the touchpad don't work, or won't stop | `~/.config/hypr/scripts/touchpad-calm.sh --explain` |
| A stage failed | its log in `~/.local/state/fedora-dev-2026/logs/` |
| dnf warns about the ChatGPT repo signature | `sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-chatgpt-*.asc` |
| CPU suddenly slow under heavy load | `journalctl -u thermal-breaker`: it clamps to 2 GHz at 95 °C and restores below 80 °C |
| A keybinding is missing from the cheat sheet | give it a `"Group: action"` description in `hyprland.lua` |

## Known hardware notes (N175B)

- The FocalTech fingerprint reader (`2808:c652`) has no Linux driver, so
  enrollment isn't possible.
- The built-in panel is 1920x1080 @ 60 Hz with no VRR; the gaming rules are
  tuned for that (see the GAMING section of `hyprland.lua`).
- Swap is Fedora's default 8 GB zram. For heavy VM or build work, raise it in
  `/etc/systemd/zram-generator.conf` or run jobs under `capped`.
