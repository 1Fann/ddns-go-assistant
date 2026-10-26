#!/data/adb/ksu/bin/busybox ash
set +x
umask 077
BASE=/data/adb/ddns-go
BB=/data/adb/ksu/bin/busybox
addresses=$(/system/bin/ip -o -6 addr show dev wlan0 scope global 2>/dev/null | "$BB" awk -f "$BASE/filter-ipv6.awk" | "$BB" sort -u)
[ -n "$addresses" ] || exit 0
chosen=$(printf '%s\n' "$addresses" | "$BB" head -n 1)
previous=$(cat "$BASE/selected-ip" 2>/dev/null)
if [ -n "$previous" ] && printf '%s\n' "$addresses" | "$BB" grep -Fxq "$previous"; then chosen=$previous; fi
printf '%s\n' "$chosen" > "$BASE/selected-ip"
printf '%s\n' "$chosen"
