#!/data/adb/ksu/bin/busybox ash
set +x
umask 077
BASE=/data/adb/ddns-go
BB=/data/adb/ksu/bin/busybox
exec 7>"$BASE/wake.lock"
"$BB" flock 7 || exit 1
release() { printf '%s\n' ddns_go > /sys/power/wake_unlock 2>/dev/null || :; }
case "${1:-apply}" in
    off) touch "$BASE/wake-disabled"; release; exit 0;;
    on) rm -f "$BASE/wake-disabled";;
    release) release; exit 0;;
    apply) ;;
    *) exit 2;;
esac
if [ -f "$BASE/wake-disabled" ] || [ -f "$BASE/disabled" ]; then release; exit 0; fi
pid=$(cat "$BASE/daemon.pid" 2>/dev/null)
case "$pid" in ''|*[!0-9]*) exit 0;; esac
if [ -r "/proc/$pid/cmdline" ] && "$BB" tr '\000' ' ' < "/proc/$pid/cmdline" | "$BB" grep -qF "$BASE/daemon.sh"; then
    printf '%s\n' 'ddns_go 600000000000' > /sys/power/wake_lock
fi
