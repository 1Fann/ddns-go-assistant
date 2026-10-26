#!/data/adb/ksu/bin/busybox ash
set +x
umask 077
BASE=/data/adb/ddns-go
BB=/data/adb/ksu/bin/busybox
running() {
    pid=$(cat "$BASE/daemon.pid" 2>/dev/null)
    case "$pid" in ''|*[!0-9]*) return 1;; esac
    [ -r "/proc/$pid/cmdline" ] && "$BB" tr '\000' ' ' < "/proc/$pid/cmdline" | "$BB" grep -qF "$BASE/daemon.sh"
}
case "${1:-state}" in
    state|status)
        printf 'engine=ddns-go '; cat "$BASE/engine-version" 2>/dev/null || echo unknown
        [ -f "$BASE/disabled" ] && echo 'enabled=0' || echo 'enabled=1'
        engine_pid=$(cat "$BASE/engine.pid" 2>/dev/null)
        engine_running=0
        case "$engine_pid" in ''|*[!0-9]*) ;; *)
            if [ -r "/proc/$engine_pid/cmdline" ] && "$BB" tr '\000' ' ' < "/proc/$engine_pid/cmdline" | "$BB" grep -qF "$BASE/ddns-go -l "; then engine_running=1; fi;;
        esac
        if running && [ "$engine_running" = 1 ]; then echo 'running=1'; else echo 'running=0'; fi
        [ -f "$BASE/wake-disabled" ] && echo 'wake_enabled=0' || echo 'wake_enabled=1'
        if "$BB" grep -qw ddns_go /sys/power/wake_lock 2>/dev/null; then echo 'wake_held=1'; else echo 'wake_held=0'; fi
        printf 'address='; "$BB" ash "$BASE/ipv6.sh"; printf '\nsynced=\n'
        echo '---LOG---'
        [ ! -f "$BASE/ddns-go.log" ] || "$BB" tail -n 12 "$BASE/ddns-go.log";;
    start)
        rm -f "$BASE/disabled"
        /system/bin/sh /data/adb/service.d/99-ddns-go.sh;;
    stop)
        touch "$BASE/disabled"
        if running; then kill "$pid"; fi
        attempts=0
        while running && [ "$attempts" -lt 8 ]; do /system/bin/sleep 1; attempts=$((attempts+1)); done
        "$BB" ash "$BASE/wake.sh" release;;
    wake-on) exec "$BB" ash "$BASE/wake.sh" on;;
    wake-off) exec "$BB" ash "$BASE/wake.sh" off;;
    *) exit 2;;
esac
