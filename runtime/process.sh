#!/system/bin/sh
# Shared process checks. A stale PID file must never authorize an unrelated kill.
process_running() {
    case "${1:-}" in ''|*[!0-9]*|0|1) return 1;; esac
    [ -r "/proc/$1/cmdline" ] && kill -0 "$1" 2>/dev/null || return 1
    "$BB" tr '\000' '\n' < "/proc/$1/cmdline" | "$BB" grep -Fxq "$BASE/$2"
}
stop_process() {
    process_running "$1" "$2" || return 0
    kill "$1" 2>/dev/null || :
    for stop_attempt in 1 2 3 4 5; do
        process_running "$1" "$2" || return 0
        /system/bin/sleep 1
    done
    process_running "$1" "$2" && kill -9 "$1" 2>/dev/null || :
    for stop_attempt in 1 2; do
        process_running "$1" "$2" || return 0
        /system/bin/sleep 1
    done
    ! process_running "$1" "$2"
}
engine_healthy() {
    # Overall and read deadlines also bound a connected but stuck HTTP peer.
    "$BB" timeout -k 1 4 "$BB" wget -q -T 2 -O /dev/null http://127.0.0.1:9876/ 6>&- 8>&- 9>&- 2>/dev/null
}
service_event() {
    printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> "$BASE/service.log"
    if [ "$(wc -c < "$BASE/service.log")" -gt 65536 ]; then
        "$BB" tail -n 100 "$BASE/service.log" > "$BASE/service-tail.$$"
        cat "$BASE/service-tail.$$" > "$BASE/service.log"
        rm -f "$BASE/service-tail.$$"
    fi
}
