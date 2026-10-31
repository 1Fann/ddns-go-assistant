#!/system/bin/sh
set +x
umask 077
BASE=/data/adb/ddns-go
BB=
for candidate in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
  if [ -x "$candidate" ]; then BB=$candidate; break; fi
done
[ -n "$BB" ] || { echo busybox_missing; exit 20; }
. "$BASE/interval.sh"
. "$BASE/process.sh"
running() {
    pid=$(cat "$BASE/daemon.pid" 2>/dev/null)
    process_running "$pid" daemon.sh
}
restart_enabled() {
    # The upstream engine performs a provider comparison on startup. Keep a
    # single writer rather than launching a second engine against the config.
    "$BB" ash "$BASE/control.sh" stop 8>&- || return 1
    "$BB" ash "$BASE/control.sh" start 8>&- || return 1
    attempt=0
    while [ "$attempt" -lt 5 ]; do
        engine_pid=$(cat "$BASE/engine.pid" 2>/dev/null)
        case "$engine_pid" in ''|*[!0-9]*) ;; *)
            if running && process_running "$engine_pid" ddns-go && engine_healthy; then return 0; fi;;
        esac
        attempt=$((attempt+1)); /system/bin/sleep 1
    done
    echo SERVICE_NOT_READY
    return 1
}
case "${1:-state}" in
    state|status)
        echo control_api=2
        read_interval; echo "interval_seconds=$interval"
        printf 'engine=ddns-go '; cat "$BASE/engine-version" 2>/dev/null || echo unknown
        [ -f "$BASE/disabled" ] && echo 'enabled=0' || echo 'enabled=1'
        engine_pid=$(cat "$BASE/engine.pid" 2>/dev/null)
        engine_running=0
        case "$engine_pid" in ''|*[!0-9]*) ;; *)
            if process_running "$engine_pid" ddns-go; then engine_running=1; fi;;
        esac
        if running && [ "$engine_running" = 1 ]; then echo 'running=1'; else echo 'running=0'; fi
        watchdog_pid=$(cat "$BASE/watchdog.pid" 2>/dev/null)
        if process_running "$watchdog_pid" watchdog.sh; then echo 'watchdog_running=1'; else echo 'watchdog_running=0'; fi
        if [ "$engine_running" = 1 ] && engine_healthy; then echo 'healthy=1'; else echo 'healthy=0'; fi
        [ -f "$BASE/wake-disabled" ] && echo 'wake_enabled=0' || echo 'wake_enabled=1'
        if "$BB" grep -qw ddns_go /sys/power/wake_lock 2>/dev/null; then echo 'wake_held=1'; else echo 'wake_held=0'; fi
        printf 'address='; "$BB" ash "$BASE/ipv6.sh"; printf '\nsynced=\n'
        echo '---LOG---'
        [ ! -f "$BASE/ddns-go.log" ] || "$BB" tail -n 12 "$BASE/ddns-go.log";;
    start)
        rm -f "$BASE/disabled"
        /system/bin/sh /data/adb/service.d/99-ddns-go.sh 8>&-;;
    stop)
        touch "$BASE/disabled"
        # Mark paused before signaling either peer, so recovery cannot undo an
        # intentional stop. Escalate only PIDs whose exact component still matches.
        watchdog_pid=$(cat "$BASE/watchdog.pid" 2>/dev/null)
        stop_process "$watchdog_pid" watchdog.sh || { echo SERVICE_BUSY; exit 1; }
        pid=$(cat "$BASE/daemon.pid" 2>/dev/null)
        stop_process "$pid" daemon.sh || { echo SERVICE_BUSY; exit 1; }
        engine_pid=$(cat "$BASE/engine.pid" 2>/dev/null)
        stop_process "$engine_pid" ddns-go || { echo SERVICE_BUSY; exit 1; }
        "$BB" timeout -k 1 4 "$BB" ash "$BASE/wake.sh" release;;
    wake-on) exec "$BB" ash "$BASE/wake.sh" on;;
    wake-off) exec "$BB" ash "$BASE/wake.sh" off;;
    sync|interval)
        operation=$1
        if [ "$operation" = interval ]; then
            valid_interval "${2:-}" || { echo INVALID_INTERVAL; exit 2; }
            requested=$2
        else
            [ ! -f "$BASE/disabled" ] && running || { echo SERVICE_PAUSED; exit 1; }
        fi
        [ ! -L "$BASE.install.lock" ] && [ ! -L "$BASE/check-interval" ] && [ ! -L "$BASE/.interval.pending" ] || exit 1
        exec 8>"$BASE.install.lock"
        "$BB" flock -n 8 || { echo INSTALL_BUSY; exit 1; }
        [ ! -e "$BASE.pending" ] && [ ! -e "$BASE.rollback" ] || { echo RECOVERY_REQUIRED; exit 1; }
        if [ "$operation" = interval ]; then
            read_interval; previous=$interval
            printf '%s\n' "$requested" > "$BASE/.interval.pending"
            chmod 600 "$BASE/.interval.pending"
            mv -f "$BASE/.interval.pending" "$BASE/check-interval"
            if [ -f "$BASE/disabled" ]; then echo INTERVAL_SAVED_PAUSED; exit 0; fi
            if ! restart_enabled; then
                printf '%s\n' "$previous" > "$BASE/check-interval"
                chmod 600 "$BASE/check-interval"
                restart_enabled >/dev/null 2>&1 || :
                echo INTERVAL_ROLLED_BACK
                exit 1
            fi
            echo INTERVAL_APPLIED
        else
            restart_enabled || exit 1
            echo SYNC_TRIGGERED
        fi;;
    *) exit 2;;
esac
