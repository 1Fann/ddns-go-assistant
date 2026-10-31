#!/system/bin/sh
set +x
umask 077
export PATH=/system/bin:/system/xbin
BASE=/data/adb/ddns-go
BB=
for candidate in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
  if [ -x "$candidate" ]; then BB=$candidate; break; fi
done
[ -n "$BB" ] || { echo busybox_missing; exit 20; }
. "$BASE/interval.sh"
. "$BASE/process.sh"
exec 9>"$BASE/daemon.lock"
"$BB" flock -n 9 || exit 0
echo $$ > "$BASE/daemon.pid"
cleanup() {
    [ -z "${sleeper:-}" ] || kill "$sleeper" 2>/dev/null || :
    stopped=1
    if [ -n "${child:-}" ]; then stop_process "$child" ddns-go || stopped=0; fi
    "$BB" timeout -k 1 4 "$BB" ash "$BASE/wake.sh" release 9>&- || :
    rm -f "$BASE/daemon.pid" "$BASE/daemon.heartbeat"
    # Retain an unkillable/orphaned engine's identity for the next owner.
    [ "$stopped" = 0 ] || rm -f "$BASE/engine.pid"
}
trap cleanup EXIT
trap 'exit 0' TERM INT HUP
service_event DAEMON_START
cd "$BASE" || exit 1
# SIGKILL bypasses cleanup. Adopt a verified orphan instead of creating two
# writers against the same configuration and listening socket.
child=$(cat "$BASE/engine.pid" 2>/dev/null)
process_running "$child" ddns-go || child=
sequence=0; failures=0; slow_tick=0; retry_ticks=0; backoff_ticks=0
while [ ! -f "$BASE/disabled" ]; do
    # Cheap liveness runs every second. HTTP, heartbeat writes, wake-lock
    # renewal and log housekeeping retain their separate 30-second cadence.
    watchdog_pid=$(cat "$BASE/watchdog.pid" 2>/dev/null)
    if ! process_running "$watchdog_pid" watchdog.sh; then
        "$BB" setsid "$BB" ash "$BASE/watchdog.sh" 9>&- </dev/null >/dev/null 2>&1 &
    fi
    new_engine=0
    if ! process_running "$child" ddns-go; then
        [ ! -f "$BASE/disabled" ] || break
        if [ -n "$child" ]; then
            # The first unexpected exit recovers immediately. Repeated crashes
            # back off by 2, 4, 8, 16, then 30 seconds instead of looping rapidly.
            child=; retry_ticks=$backoff_ticks
            if [ "$backoff_ticks" -eq 0 ]; then backoff_ticks=2; else backoff_ticks=$((backoff_ticks*2)); fi
            [ "$backoff_ticks" -le 30 ] || backoff_ticks=30
        fi
        if [ "$retry_ticks" -gt 0 ]; then
            retry_ticks=$((retry_ticks-1))
        else
            # Explicit bootstrap DNS avoids Android Go builds falling back to ::1:53.
            read_interval
            "$BASE/ddns-go" -l 127.0.0.1:9876 -f "$interval" -cacheTimes 1 -dns 223.5.5.5 -c "$BASE/config.yaml" 9>&- </dev/null >> "$BASE/ddns-go.log" 2>&1 &
            child=$!; echo "$child" > "$BASE/engine.pid"
            new_engine=1
            failures=0
            service_event ENGINE_START
        fi
    fi
    if [ "$slow_tick" -eq 0 ]; then
        sequence=$((sequence+1)); printf '%s:%s\n' "$$" "$sequence" > "$BASE/daemon.heartbeat"
        if [ "$new_engine" = 0 ] && process_running "$child" ddns-go; then
            if engine_healthy; then
                failures=0; backoff_ticks=0
            else
                failures=$((failures+1))
                if [ "$failures" -ge 3 ]; then
                    service_event ENGINE_UNRESPONSIVE
                    if stop_process "$child" ddns-go; then child=; rm -f "$BASE/engine.pid"; fi
                    failures=0
                fi
            fi
        fi
        "$BB" timeout -k 1 4 "$BB" ash "$BASE/wake.sh" apply 9>&- || :
        if [ -f "$BASE/ddns-go.log" ] && [ "$(wc -c < "$BASE/ddns-go.log")" -gt 262144 ]; then
            "$BB" tail -n 100 "$BASE/ddns-go.log" > "$BASE/log-tail"
            cat "$BASE/log-tail" > "$BASE/ddns-go.log"
            rm -f "$BASE/log-tail"
        fi
    fi
    slow_tick=$(( (slow_tick+1)%30 ))
    /system/bin/sleep 1 9>&- & # fast-liveness-poll
    sleeper=$!; wait "$sleeper"; sleeper=
done
