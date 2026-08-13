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
    # `command ls`: an interactive shell may alias ls to eza, whose -t takes
    # an argument and would silently return nothing here.
    sig=$(command ls -t "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr" 2>/dev/null | head -1)
    [ -n "$sig" ] || return 1
    HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl "$@" >/dev/null 2>&1
}

is_mouse_node() {
    # A candidate is an ID_INPUT_MOUSE node on a usb/bluetooth bus. The
    # internal touchpad and its companion mouse node carry no ID_BUS, so the
    # bus test alone excludes them.
    local props=$1 ifaces
    grep -q '^ID_INPUT_MOUSE=1$' <<<"$props" || return 1
    grep -q '^ID_INPUT_TOUCHPAD=1$' <<<"$props" && return 1
    grep -Eq '^ID_BUS=(usb|bluetooth)$' <<<"$props" || return 1

    # Manual override, e.g. IGNORE_RE='Gaming_Keyboard|My_Dock'
    if [ -n "${IGNORE_RE:-}" ] &&
       grep -Eq "^(ID_SERIAL|ID_MODEL|ID_VENDOR)=.*(${IGNORE_RE})" <<<"$props"; then
        return 1
    fi

    # Keyboards routinely expose a SECOND HID interface carrying relative
    # axes (media wheels, vendor blobs); udev tags it ID_INPUT_MOUSE=1, so a
    # permanently plugged-in keyboard would otherwise read as an external
    # mouse and calm the touchpad forever.
    #
    # ID_USB_INTERFACES lists every interface the physical device declares as
    # :CCSSPP: — class/subclass/protocol. Under HID (03), protocol 01 is a
    # boot keyboard and 02 a boot mouse. A device that declares a keyboard
    # interface and no mouse interface is a keyboard: skip it. Receivers that
    # carry both (unifying dongles) still count, and Bluetooth devices expose
    # no ID_USB_INTERFACES at all, so they fall through and count.
    ifaces=$(sed -n 's/^ID_USB_INTERFACES=//p' <<<"$props")
    if [[ -n $ifaces ]] &&
       [[ $ifaces =~ :03[0-9a-f]{2}01: ]] &&
       [[ ! $ifaces =~ :03[0-9a-f]{2}02: ]]; then
        return 1
    fi
    return 0
}

external_mouse_present() {
    local dev props
    for dev in /dev/input/event*; do
        props=$(udevadm info --query=property --name="$dev" 2>/dev/null) || continue
        is_mouse_node "$props" && return 0
    done
    return 1
}

apply() {
    local taps=true
    external_mouse_present && taps=false
    hctl --batch "keyword input:touchpad:tap-to-click $taps; keyword input:touchpad:tap-and-drag $taps"
}

# --explain: show every pointer node and why it did or didn't count, then the
# resulting decision. Use this when taps are stuck off (or stubbornly on) to
# find the device responsible.
if [ "${1:-}" = "--explain" ]; then
    for dev in /dev/input/event*; do
        props=$(udevadm info --query=property --name="$dev" 2>/dev/null) || continue
        grep -q '^ID_INPUT_MOUSE=1$' <<<"$props" || continue
        name=$(sed -n 's/^ID_SERIAL=//p' <<<"$props")
        printf '%-18s %-38s %s\n' "$dev" "${name:-(internal)}" \
            "$(is_mouse_node "$props" && echo 'COUNTS as external mouse' || echo 'ignored')"
        sed -n 's/^ID_USB_INTERFACES=/    interfaces: /p' <<<"$props"
    done
    if external_mouse_present; then
        echo "=> external mouse present: taps DISABLED"
    else
        echo "=> no external mouse: taps ENABLED"
    fi
    exit 0
fi

apply
[ "${1:-}" = "--watch" ] || exit 0

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
