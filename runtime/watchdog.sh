#!/system/bin/sh
set +x
umask 077
export PATH=/system/bin:/system/xbin
BASE=/data/adb/ddns-go
BB=
for candidate in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
    if [ -x "$candidate" ]; then BB=$candidate; break; fi
done
[ -n "$BB" ] || exit 20
. "$BASE/process.sh"
exec 6>"$BASE/watchdog.lock"
"$BB" flock -n 6 || exit 0
echo $$ > "$BASE/watchdog.pid"
cleanup() {
    [ -z "${sleeper:-}" ] || kill "$sleeper" 2>/dev/null || :
    rm -f "$BASE/watchdog.pid"
}
trap cleanup EXIT
trap 'exit 0' TERM INT HUP
last=; stale=0; heartbeat_tick=0
service_event WATCHDOG_START
while [ ! -f "$BASE/disabled" ]; do
    pid=$(cat "$BASE/daemon.pid" 2>/dev/null)
    if process_running "$pid" daemon.sh; then
        if [ "$heartbeat_tick" -eq 0 ]; then
            beat=$(cat "$BASE/daemon.heartbeat" 2>/dev/null)
            if [ -n "$beat" ] && [ "$beat" != "$last" ]; then stale=0; else stale=$((stale+1)); fi
            last=$beat
            # Four completed 30-second checks, NOT four fast liveness polls.
            # Suspend/resume cannot turn the usual ~120s allowance into 4s.
            if [ "$stale" -ge 4 ]; then
                service_event DAEMON_STALLED
                stop_process "$pid" daemon.sh || :
                stale=0; last=
            fi
        fi
    else
        stale=0; last=; heartbeat_tick=0
        if [ ! -f "$BASE/disabled" ]; then
            "$BB" setsid "$BB" ash "$BASE/daemon.sh" 6>&- </dev/null >/dev/null 2>&1 &
        fi
    fi
    heartbeat_tick=$(( (heartbeat_tick+1)%30 ))
    /system/bin/sleep 1 6>&- & # fast-liveness-poll
    sleeper=$!; wait "$sleeper"; sleeper=
done
