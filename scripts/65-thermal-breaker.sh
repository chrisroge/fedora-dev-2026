#!/usr/bin/env bash
# 65 — CPU thermal circuit breaker (AMD only). A tiny root daemon that watches
# the k10temp Tctl sensor and clamps every core to 2 GHz when the die hits
# 95C, then restores full boost after 30 continuous seconds below 80C. A
# second line of defense under the hardware throttle for boxes that run
# unattended compile/test load. Skips cleanly on machines without k10temp.
# Optional: announces trips out loud if quindar-tone-api is listening on
# 127.0.0.1:42069 (silently skipped otherwise).
set -euo pipefail

if ! grep -qx k10temp /sys/class/hwmon/hwmon*/name 2>/dev/null; then
  echo "==> No k10temp sensor (not an AMD CPU?) — skipping thermal breaker"
  exit 0
fi

sudo install -m 755 /dev/stdin /usr/local/sbin/thermal-breaker <<'DAEMON_EOF'
#!/usr/bin/bash
# Thermal circuit breaker: clamp CPU frequency when Tctl reaches TRIP_C,
# restore full speed once it stays below RESET_C for RESET_HOLD seconds.
# Runs as a systemd service; stdout lands in the journal.

TRIP_C=${TRIP_C:-95}
RESET_C=${RESET_C:-80}
RESET_HOLD=${RESET_HOLD:-30}
POLL=${POLL:-2}
CLAMP_KHZ=${CLAMP_KHZ:-2000000}
QUINDAR=${QUINDAR:-http://127.0.0.1:42069/play}
QUINDAR_VOICE=${QUINDAR_VOICE:-hfc_female}

# k10temp's hwmon index shifts across boots; resolve it by name
for h in /sys/class/hwmon/hwmon*; do
    if [[ $(<"$h/name") == k10temp ]]; then
        TEMP_FILE=$h/temp1_input
        break
    fi
done
if [[ ! -r $TEMP_FILE ]]; then
    echo "k10temp hwmon not found" >&2
    exit 1
fi

POLICIES=(/sys/devices/system/cpu/cpufreq/policy*)

clamp() {
    local p
    for p in "${POLICIES[@]}"; do
        echo "$CLAMP_KHZ" > "$p/scaling_max_freq"
    done
}

# cores have individual boost ceilings, so restore each to its own rated max
restore() {
    local p
    for p in "${POLICIES[@]}"; do
        cat "$p/cpuinfo_max_freq" > "$p/scaling_max_freq"
    done
}

announce() {
    [[ -n $QUINDAR ]] || return 0
    curl -sf -m 3 -X POST "$QUINDAR" -H 'Content-Type: application/json' \
        -d "{\"text\": \"$1\", \"voice\": \"$QUINDAR_VOICE\"}" >/dev/null 2>&1 || true
}

trap restore EXIT

tripped=0
cool=0
echo "armed: trip=${TRIP_C}C reset=${RESET_C}C hold=${RESET_HOLD}s clamp=$((CLAMP_KHZ / 1000))MHz poll=${POLL}s sensor=$TEMP_FILE"

while sleep "$POLL"; do
    t=$(( $(<"$TEMP_FILE") / 1000 ))
    if (( tripped == 0 )); then
        if (( t >= TRIP_C )); then
            tripped=1
            cool=0
            clamp
            echo "TRIP at ${t}C: clamped to $((CLAMP_KHZ / 1000))MHz"
            announce "Thermal circuit breaker tripped at ${t} degrees. Processor clamped."
        fi
    else
        if (( t < RESET_C )); then
            (( cool += POLL ))
            if (( cool >= RESET_HOLD )); then
                tripped=0
                restore
                echo "RESET at ${t}C: full speed restored"
                announce "Thermal breaker reset. Full speed restored."
            fi
        else
            cool=0
        fi
    fi
done
DAEMON_EOF

sudo install -m 644 /dev/stdin /etc/systemd/system/thermal-breaker.service <<'UNIT_EOF'
[Unit]
Description=CPU thermal circuit breaker (clamp at 95C, restore below 80C)

[Service]
ExecStart=/usr/local/sbin/thermal-breaker
Restart=always
RestartSec=5
Nice=-10

[Install]
WantedBy=multi-user.target
UNIT_EOF

sudo systemctl daemon-reload
sudo systemctl enable --now thermal-breaker.service
echo "==> thermal-breaker: $(systemctl is-active thermal-breaker.service) (journalctl -u thermal-breaker)"
