#!/usr/bin/env bash
# Calm the touchpad while an external mouse is attached: tap-to-click and
# tap-and-drag are turned off so palm brushes stop registering as clicks.
# Pointer motion, two-finger scroll, and physical clickpad presses keep
# working. With no external mouse, taps are restored.
#
# Run with --watch to keep monitoring udev for mouse hotplug (used by
# touchpad-calm.service); without it, evaluate once and exit.

hctl() {
    # Resolve the current Hyprland instance each call so we survive
    # Hyprland restarts (each restart mints a new signature dir).
    local sig
    sig=$(ls -t "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr" 2>/dev/null | head -1)
    [ -n "$sig" ] || return 1
    HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl "$@" >/dev/null 2>&1
}

external_mouse_present() {
    # External mouse = ID_INPUT_MOUSE with a usb/bluetooth ID_BUS. The
    # internal touchpad and its companion mouse node carry no ID_BUS.
    local dev props
    for dev in /dev/input/event*; do
        props=$(udevadm info --query=property --name="$dev" 2>/dev/null) || continue
        grep -q '^ID_INPUT_MOUSE=1$' <<<"$props" || continue
        grep -q '^ID_INPUT_TOUCHPAD=1$' <<<"$props" && continue
        grep -Eq '^ID_BUS=(usb|bluetooth)$' <<<"$props" && return 0
    done
    return 1
}

apply() {
    local taps=true
    external_mouse_present && taps=false
    hctl --batch "keyword input:touchpad:tap-to-click $taps; keyword input:touchpad:tap-and-drag $taps"
}

apply
[ "$1" = "--watch" ] || exit 0

exec 3< <(udevadm monitor --udev --subsystem-match=input)
while :; do
    read -r -t 30 _ <&3
    rc=$?
    if [ "$rc" -gt 128 ]; then
        : # timeout: periodic re-apply heals Hyprland reloads/restarts
    elif [ "$rc" -ne 0 ]; then
        exit 1 # udevadm died; let systemd restart us
    else
        while read -r -t 0.5 _ <&3; do :; done # drain the hotplug event burst
    fi
    apply
done
