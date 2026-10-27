#!/data/adb/ksu/bin/busybox ash
set +x
umask 077
export PATH=/system/bin:/system/xbin
BASE=/data/adb/ddns-go
BB=/data/adb/ksu/bin/busybox
. "$BASE/interval.sh"
exec 9>"$BASE/daemon.lock"
"$BB" flock -n 9 || exit 0
echo $$ > "$BASE/daemon.pid"
cleanup() {
    [ -z "${sleeper:-}" ] || kill "$sleeper" 2>/dev/null || :
    if [ -n "${child:-}" ]; then kill "$child" 2>/dev/null || :; wait "$child" 2>/dev/null || :; fi
    "$BB" ash "$BASE/wake.sh" release 9>&- || :
    rm -f "$BASE/daemon.pid" "$BASE/engine.pid"
}
trap cleanup EXIT
trap 'exit 0' TERM INT
printf '%s START pid=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$$" >> "$BASE/service.log"
cd "$BASE" || exit 1
while [ ! -f "$BASE/disabled" ]; do
    if [ -z "${child:-}" ] || ! kill -0 "$child" 2>/dev/null; then
        [ -z "${child:-}" ] || wait "$child" 2>/dev/null || :
        # Explicit bootstrap DNS avoids Android Go builds falling back to ::1:53.
        # Adapt this resolver for your network; it is not the DDNS provider.
        read_interval
        "$BASE/ddns-go" -l 127.0.0.1:9876 -f "$interval" -cacheTimes 1 -dns 223.5.5.5 -c "$BASE/config.yaml" 9>&- </dev/null >> "$BASE/ddns-go.log" 2>&1 &
        child=$!
        echo "$child" > "$BASE/engine.pid"
    fi
    "$BB" ash "$BASE/wake.sh" apply 9>&- || :
    if [ -f "$BASE/ddns-go.log" ] && [ "$(wc -c < "$BASE/ddns-go.log")" -gt 262144 ]; then
        "$BB" tail -n 100 "$BASE/ddns-go.log" > "$BASE/log-tail"
        cat "$BASE/log-tail" > "$BASE/ddns-go.log"
        rm -f "$BASE/log-tail"
    fi
    /system/bin/sleep 30 9>&- &
    sleeper=$!; wait "$sleeper"; sleeper=
done
