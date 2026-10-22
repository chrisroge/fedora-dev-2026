-- Hyprland 0.56 configuration (Lua). Reference: /usr/share/hypr/hyprland.lua,
-- API stubs: /usr/share/hypr/stubs/hl.meta.lua, wiki: https://wiki.hypr.land/
--
-- Generated companions, loaded below:
--   monitors.lua  hypr-monitors: monitor modes and workspace-to-monitor pinning
--   layouts.lua   hypr-layout:   per-workspace dwindle / column layouts
local home = os.getenv("HOME")
local bin = home .. "/.local/bin/"

local function load_generated(name)
    local path = home .. "/.config/hypr/" .. name
    local f = io.open(path, "r")
    if f then
        f:close()
        dofile(path)
        return true
    end
    return false
end

-------------------
--- LOOK & FEEL ---
-------------------
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        -- Tearing must be allowed globally before any window can opt in with
        -- an `immediate` rule (see GAMING below). On its own it changes nothing.
        allow_tearing = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 4, render_power = 3, color = "rgba(1a1a1aee)" },
        blur = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },
    dwindle = { preserve_split = true },
    master = { new_status = "slave", orientation = "center", mfact = 0.333333, slave_count_for_center_master = 2 },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
        disable_hyprland_guiutils_check = true,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        -- Tap-to-click is toggled at runtime by touchpad-calm.service.
        touchpad = { natural_scroll = false },
    },
    cursor = { warp_on_change_workspace = 2 },
    animations = { enabled = true },
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1.0 }, { 0.32, 1.0 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1.0 } } })
hl.curve("linear", { type = "bezier", points = { { 0.0, 0.0 }, { 1.0, 1.0 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0.0 }, { 0.1, 1.0 } } })
for _, a in ipairs({
    { "global", 10.0, "default" },
    { "border", 5.39, "easeOutQuint" },
    { "windows", 4.79, "easeOutQuint" },
    { "windowsIn", 4.1, "easeOutQuint", "popin 87%" },
    { "windowsOut", 1.49, "linear", "popin 87%" },
    { "fadeIn", 1.73, "almostLinear" },
    { "fadeOut", 1.46, "almostLinear" },
    { "fade", 3.03, "quick" },
    { "layers", 3.81, "easeOutQuint" },
    { "layersIn", 4.0, "easeOutQuint", "fade" },
    { "layersOut", 1.5, "linear", "fade" },
    { "fadeLayersIn", 1.79, "almostLinear" },
    { "fadeLayersOut", 1.39, "almostLinear" },
    { "workspaces", 1.94, "almostLinear", "fade" },
    { "workspacesIn", 1.21, "almostLinear", "fade" },
    { "workspacesOut", 1.94, "almostLinear", "fade" },
    { "zoomFactor", 7.0, "quick" },
}) do
    hl.animation({ leaf = a[1], enabled = true, speed = a[2], bezier = a[3], style = a[4] })
end

-----------------
--- MONITORS  ---
-----------------
-- Workspaces are pinned to monitors by ROLE, not by connector name, so this
-- works with any set of displays (see ~/.local/bin/hypr-monitors):
--   home   = built-in panel        workspaces 1-4,  11-14
--   studio = largest external      workspaces 5-8,  15-18
--   read   = next external         workspaces 9-10, 19-20
-- Modes/positions/scales per output live in ~/.config/hypr/monitors.json.
if not load_generated("monitors.lua") then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
end
local function refresh_monitors()
    hl.exec_cmd(bin .. "hypr-monitors --settle")
end
hl.on("monitor.added", refresh_monitors)
hl.on("monitor.removed", refresh_monitors)

-----------------
--- AUTOSTART ---
-----------------
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("/usr/libexec/polkit-mate-authentication-agent-1")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd(bin .. "hypr-monitors")
    -- Start on the primary display. This runs only at login.
    hl.dispatch(hl.dsp.focus({ workspace = 1 }))
end)

-------------------
--- KEYBINDINGS ---
-------------------
-- Every binding carries a description in "Group: action" form. The cheat
-- sheet (SUPER + /, or the keyboard icon in Waybar) is rendered live from
-- these, so keep them accurate when you add or change a binding.
-- The sheet stars (★) every binding that differs from Hyprland's stock
-- config: keys stock doesn't bind are detected automatically; pass
-- `changed = true` for a stock key that does something different here.
local function bind(keys, dispatcher, description, opts)
    opts = opts or {}
    if opts.changed then
        description = description .. " ★"
    end
    opts.changed = nil
    opts.description = description
    hl.bind(keys, dispatcher, opts)
end
local media = { locked = true, repeating = true }

bind("SUPER + slash", hl.dsp.exec_cmd(bin .. "hypr-cheatsheet"), "Help: Show this cheat sheet")

-- Stock binds these keys to kitty, hyprlauncher and dolphin.
bind("SUPER + Q", hl.dsp.exec_cmd("ghostty"), "Apps: Terminal (Ghostty)", { changed = true })
bind("SUPER + R", hl.dsp.exec_cmd("wofi --show drun"), "Apps: Launcher (wofi)", { changed = true })
bind("SUPER + E", hl.dsp.exec_cmd("nautilus"), "Apps: File manager (Nautilus)", { changed = true })
bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"), "Apps: Screenshot a region to the clipboard")

bind("SUPER + C", hl.dsp.window.close(), "Windows: Close")
bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }), "Windows: Toggle floating")
bind("SUPER + P", hl.dsp.window.pseudo(), "Windows: Pseudo-tile (dwindle)")
bind("SUPER + J", hl.dsp.layout("togglesplit"), "Windows: Toggle split direction (dwindle)")
bind("SUPER + left", hl.dsp.focus({ direction = "left" }), "Windows: Focus left")
bind("SUPER + right", hl.dsp.focus({ direction = "right" }), "Windows: Focus right")
bind("SUPER + up", hl.dsp.focus({ direction = "up" }), "Windows: Focus up")
bind("SUPER + down", hl.dsp.focus({ direction = "down" }), "Windows: Focus down")
bind("SUPER + ALT + H", hl.dsp.layout("preselect l"), "Windows: Open next window to the left (dwindle)")
bind("SUPER + ALT + J", hl.dsp.layout("preselect d"), "Windows: Open next window below (dwindle)")
bind("SUPER + ALT + K", hl.dsp.layout("preselect u"), "Windows: Open next window above (dwindle)")
bind("SUPER + ALT + L", hl.dsp.layout("preselect r"), "Windows: Open next window to the right (dwindle)")
bind("SUPER + mouse:272", hl.dsp.window.drag(), "Windows: Drag to move", { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), "Windows: Drag to resize", { mouse = true })

bind("SUPER + CTRL + L", hl.dsp.exec_cmd(bin .. "hypr-layout --menu"), "Layout: Choose this workspace's layout")

-- Workspaces 1-10 on the number row (0 = 10); ALT adds ten (11-20).
for i = 1, 10 do
    local key = tostring(i % 10)
    bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }), "Workspaces: Go to workspace " .. i)
    bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Workspaces: Move window to workspace " .. i)
    bind("SUPER + ALT + " .. key, hl.dsp.focus({ workspace = i + 10 }), "Workspaces: Go to workspace " .. (i + 10))
    bind("SUPER + ALT + SHIFT + " .. key, hl.dsp.window.move({ workspace = i + 10 }),
        "Workspaces: Move window to workspace " .. (i + 10))
end
bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"), "Workspaces: Toggle scratchpad")
bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), "Workspaces: Move window to scratchpad")
-- Stock scrolls through every workspace (e+1); here it stays on this monitor.
bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m+1" }), "Workspaces: Next on this monitor (scroll)",
    { changed = true })
bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m-1" }), "Workspaces: Previous on this monitor (scroll)",
    { changed = true })

-- Monitor keys by role (SUPER+CTRL/SHIFT + G/F/D, SUPER+ALT+S) are generated
-- into monitors.lua by hypr-monitors, for whichever displays are connected.
bind("SUPER + CTRL + left", hl.dsp.focus({ monitor = "l" }), "Monitors: Focus monitor to the left")
bind("SUPER + CTRL + right", hl.dsp.focus({ monitor = "r" }), "Monitors: Focus monitor to the right")
bind("SUPER + SHIFT + left", hl.dsp.window.move({ monitor = "l" }), "Monitors: Move window to monitor on the left")
bind("SUPER + SHIFT + right", hl.dsp.window.move({ monitor = "r" }), "Monitors: Move window to monitor on the right")
bind("SUPER + ALT + left", hl.dsp.workspace.move({ monitor = "l" }), "Monitors: Move workspace to monitor on the left")
bind("SUPER + ALT + right", hl.dsp.workspace.move({ monitor = "r" }), "Monitors: Move workspace to monitor on the right")

bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Media: Volume up", media)
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), "Media: Volume down", media)
bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), "Media: Mute", media)
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), "Media: Mute microphone", media)
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), "Media: Brightness up", media)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), "Media: Brightness down", media)
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Media: Next track", { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Media: Play / pause", { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Media: Play / pause", { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Media: Previous track", { locked = true })

-- Stock runs hyprshutdown (a confirmation screen) when installed; here it exits directly.
bind("SUPER + M", hl.dsp.exit(), "Session: Exit Hyprland (log out)", { changed = true })

-- Default and per-workspace layout selections are managed by hypr-layout.
load_generated("layouts.lua")

--------------------
--- WINDOW RULES ---
--------------------
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
-- XWayland drag-and-drop helper windows must never take focus.
hl.window_rule({ name = "xwayland-drag",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true })
-- The cheat sheet opens as a centered floating panel; hypr-cheatsheet sizes
-- the window to its content.
hl.window_rule({ name = "cheatsheet", match = { class = "^local\\.hypr-cheatsheet$" },
    float = true, center = true })

--------------
--- GAMING ---
--------------
-- The built-in panel is 1920x1080 @ 60 Hz with no VRR, so what matters is
-- (a) keeping compositor effects off the game's frames and (b) not letting
-- the desktop interrupt a controller session.

-- The Steam client's dropdown menus are borderless XWayland windows with an
-- empty title; without these rules they close as the pointer moves to them.
hl.window_rule({ name = "steam-menus", match = { class = "^(steam)$", title = "^()$" },
    stay_focused = true, min_size = { 1, 1 } })
-- Steam's utility windows are dialogs, not tiles.
hl.window_rule({ name = "steam-dialogs",
    match = { class = "^(steam)$", title = "^(Friends List|Steam Settings|Screenshot Uploader|Special Offers|Steam - Self Updater)$" },
    float = true })
hl.window_rule({ name = "steam-big-picture", match = { title = "^(Steam Big Picture Mode)$" }, float = true })

-- Strip compositor effects from anything fullscreen: blur and shadow there
-- are wasted work and block direct scanout. Keep the screen awake during
-- controller-only play (normal hypridle timings still apply elsewhere), and
-- hint the driver toward a latency-oriented profile.
hl.window_rule({ name = "fullscreen-effects", match = { fullscreen = true },
    no_blur = true, no_shadow = true, rounding = 0, no_anim = true,
    idle_inhibit = "fullscreen", content = "game" })
-- Steam launches each game with class steam_app_<appid>.
hl.window_rule({ name = "steam-games", match = { class = "^steam_app_[0-9]+$" },
    no_blur = true, no_anim = true, idle_inhibit = "always", content = "game" })
-- gamescope owns the whole output while it runs.
hl.window_rule({ name = "gamescope", match = { class = "^gamescope$" },
    fullscreen = true, idle_inhibit = "always", no_blur = true, no_anim = true })

-- Tearing trades a visible seam for about one frame (~16 ms at 60 Hz) less
-- input latency: worth it in fast shooters, distracting elsewhere, so opt in
-- per game by appid, e.g.:
-- hl.window_rule({ name = "tear-game", match = { class = "^steam_app_1091500$" }, immediate = true })
