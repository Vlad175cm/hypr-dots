#!/usr/bin/env bash
#
# stats.sh — one line of system statistics for the island's info panel.
# Everything is read from /proc and /sys so there is no external dependency.
#
# Output is a single line of key=value pairs separated by spaces:
#   cpu  memory  temperature  disk   uptime  load  ip  frequency  cores
# cpu is per mille, memory is per mille, temperature is milli-degrees,
# memory sizes are in kB and frequency is in kHz.
#
set -u

# ── cpu load, sampled over a short window so a single run is meaningful ──
read -r _ a b c d e f g h _ _ < /proc/stat
total1=$((a + b + c + d + e + f + g + h))
idle1=$((d + e))

sleep 0.35

read -r _ a b c d e f g h _ _ < /proc/stat
total2=$((a + b + c + d + e + f + g + h))
idle2=$((d + e))

cpu=0
if [ $((total2 - total1)) -gt 0 ]; then
	cpu=$(((total2 - total1 - (idle2 - idle1)) * 1000 / (total2 - total1)))
fi

# ── memory ──
memtotal=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)
memavail=$(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo)
memused=$((memtotal - memavail))
mem=0
[ "$memtotal" -gt 0 ] && mem=$((memused * 1000 / memtotal))

# ── cpu package temperature ──
temp=0
for zone in /sys/class/thermal/thermal_zone*; do
	[ -r "$zone/type" ] || continue
	if [ "$(cat "$zone/type" 2>/dev/null)" = "x86_pkg_temp" ]; then
		temp=$(cat "$zone/temp" 2>/dev/null || echo 0)
		break
	fi
done

# ── disks ──
disk=$(df --output=pcent / 2>/dev/null | tail -n1 | tr -dc '0-9')
disk=${disk:-0}
homedisk=$(df --output=pcent /home 2>/dev/null | tail -n1 | tr -dc '0-9')
homedisk=${homedisk:-$disk}

# ── the rest ──
uptime=$(cut -d. -f1 /proc/uptime)
load=$(cut -d' ' -f1-3 /proc/loadavg | tr ' ' ',')
ip=$(ip -4 -o addr show scope global 2>/dev/null | awk '{ print $4 }' | head -n1 | cut -d/ -f1)
freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo 0)
cores=$(nproc 2>/dev/null || echo 0)

printf 'cpu=%s mem=%s memused=%s memtotal=%s temp=%s disk=%s homedisk=%s uptime=%s load=%s ip=%s freq=%s cores=%s\n' \
	"$cpu" "$mem" "$memused" "$memtotal" "$temp" "$disk" "$homedisk" \
	"$uptime" "$load" "${ip:-none}" "$freq" "$cores"
