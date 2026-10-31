#!/bin/sh
# Real process/lock fault injection in a fresh, isolated directory. No production
# services, credentials, ports or kernel wake-lock files are used.
set -eu
BB=${BUSYBOX:-busybox}
POLL_SECONDS=${TEST_POLL_SECONDS:-0.02}
SRC=$(CDPATH= cd -- "$(dirname -- "$0")/../runtime" && pwd -P)
TEST_ROOT=${TEST_ROOT:-${TMPDIR:-/tmp}}
BASE=$("$BB" mktemp -d "$TEST_ROOT/ddns-reliability.XXXXXX")
export BASE BB
cleanup() {
    touch "$BASE/disabled"
    for name in watchdog daemon engine; do
        pid=$(cat "$BASE/$name.pid" 2>/dev/null || :)
        case "$pid" in ''|*[!0-9]*|0|1) continue;; esac
        if [ -r "/proc/$pid/cmdline" ] && "$BB" tr '\000' '\n' < "/proc/$pid/cmdline" | "$BB" grep -Fq "$BASE/"; then
            kill -9 "$pid" 2>/dev/null || :
        fi
    done
    # mktemp's directory is the only removable target.
    case "$BASE" in "$TEST_ROOT"/ddns-reliability.*) rm -rf "$BASE";; esac
}
trap cleanup EXIT
trap 'exit 1' INT TERM HUP
for name in process.sh interval.sh control.sh daemon.sh watchdog.sh 99-ddns-go.sh; do
    "$BB" sed \
        -e "s|/data/adb/ddns-go|$BASE|g" \
        -e "s|/data/adb/service.d/99-ddns-go.sh|$BASE/99-ddns-go.sh|g" \
        -e "s|/data/adb/magisk/busybox|$BB|g" \
        -e 's|export PATH=/system/bin:/system/xbin|# Keep test PATH|' \
        -e "s|/system/bin/sh|$BB ash|g" \
        -e "/# fast-liveness-poll/s|/system/bin/sleep 1|$BB sleep $POLL_SECONDS|" \
        -e "s|/system/bin/sleep 1|$BB sleep 0.1|g" \
        "$SRC/$name" > "$BASE/$name"
done
# Inject only the health response; supervision, identities, locks, signaling and
# state transitions are the production code. The HTTP timeout is checked below.
cat >> "$BASE/process.sh" <<'EOF'
engine_healthy() { echo check >> "$BASE/health-checks"; [ ! -f "$BASE/unhealthy" ]; }
EOF
cat > "$BASE/wake.sh" <<'EOF'
#!/bin/sh
echo apply >> "$BASE/wake-checks"
exit 0
EOF
printf '#!%s ash\n' "$BB" > "$BASE/ddns-go"
cat >> "$BASE/ddns-go" <<'EOF'
echo start >> "$BASE/engine-starts"
[ ! -f "$BASE/crash-engine" ] || exit 1
trap 'exit 0' TERM INT HUP
while :; do "$BB" sleep 0.2 & wait $!; done
EOF
chmod 700 "$BASE/ddns-go"
wait_pid() {
    name=$1; previous=${2:-}
    for attempt in $("$BB" seq 1 100); do
        current=$(cat "$BASE/$name.pid" 2>/dev/null || :)
        if [ -n "$current" ] && [ "$current" != "$previous" ] && kill -0 "$current" 2>/dev/null; then return 0; fi
        "$BB" sleep 0.1
    done
    echo "FAIL: $name did not recover" >&2; return 1
}
uptime_ms() { "$BB" awk '{printf "%.0f\n",$1*1000}' /proc/uptime; }
"$BB" ash "$BASE/control.sh" start
wait_pid watchdog; wait_pid daemon; wait_pid engine
first_engine=$(cat "$BASE/engine.pid")
first_daemon=$(cat "$BASE/daemon.pid")
# Duplicate boot delivery must retain one engine and one lock owner.
"$BB" ash "$BASE/99-ddns-go.sh"
"$BB" sleep 0.5
[ "$("$BB" wc -l < "$BASE/engine-starts")" -eq 1 ]
started=$(uptime_ms)
kill -9 "$first_daemon"
wait_pid daemon "$first_daemon"
echo "daemon_recovery_ms=$(( $(uptime_ms)-started ))"
"$BB" sleep 0.5
[ "$(cat "$BASE/engine.pid")" = "$first_engine" ]
[ "$("$BB" wc -l < "$BASE/engine-starts")" -eq 1 ]
echo 'PASS: daemon SIGKILL recovery adopts the existing engine; duplicate boot is safe'
first_watchdog=$(cat "$BASE/watchdog.pid")
started=$(uptime_ms)
kill -9 "$first_watchdog"
wait_pid watchdog "$first_watchdog"
echo "watchdog_recovery_ms=$(( $(uptime_ms)-started ))"
echo 'PASS: daemon repairs a killed watchdog'
first_engine=$(cat "$BASE/engine.pid")
started=$(uptime_ms)
kill -9 "$first_engine"
wait_pid engine "$first_engine"
echo "engine_recovery_ms=$(( $(uptime_ms)-started ))"
echo 'PASS: a first engine exit recovers on the fast liveness cadence'
if [ "${TEST_SPEED_ONLY:-0}" = 1 ]; then
    "$BB" ash "$BASE/control.sh" stop
    echo 'All isolated real-cadence recovery speed checks passed.'
    exit 0
fi
# Fast liveness must neither write an event nor run HTTP/wake work every tick.
"$BB" sleep 0.4
before_health=$("$BB" wc -l < "$BASE/health-checks")
before_wake=$("$BB" wc -l < "$BASE/wake-checks")
before_log=$("$BB" wc -l < "$BASE/service.log")
before_heartbeat=$("$BB" cut -d : -f 2 "$BASE/daemon.heartbeat")
"$BB" sleep 1
health_delta=$(( $("$BB" wc -l < "$BASE/health-checks")-before_health ))
wake_delta=$(( $("$BB" wc -l < "$BASE/wake-checks")-before_wake ))
[ "$health_delta" -ge 1 ] && [ "$health_delta" -le 6 ]
[ "$wake_delta" -ge 1 ] && [ "$wake_delta" -le 6 ]
[ "$("$BB" wc -l < "$BASE/service.log")" -eq "$before_log" ]
heartbeat_delta=$(( $("$BB" cut -d : -f 2 "$BASE/daemon.heartbeat")-before_heartbeat ))
[ "$heartbeat_delta" -ge 1 ] && [ "$heartbeat_delta" -le 6 ]
echo 'PASS: HTTP/wake/heartbeat work stays on the slow cadence; fast polls do not append logs'
before_starts=$("$BB" wc -l < "$BASE/engine-starts")
touch "$BASE/crash-engine"
kill -9 "$(cat "$BASE/engine.pid")"
"$BB" sleep 1
crash_starts=$(( $("$BB" wc -l < "$BASE/engine-starts")-before_starts ))
[ "$crash_starts" -ge 2 ] && [ "$crash_starts" -le 8 ]
previous_engine=$(cat "$BASE/engine.pid")
rm "$BASE/crash-engine"
wait_pid engine "$previous_engine"
echo 'PASS: repeated engine crashes back off and recover after the fault clears'
first_daemon=$(cat "$BASE/daemon.pid")
kill -STOP "$first_daemon"
# More than four fast polls must not be mistaken for four 30-second heartbeats.
"$BB" sleep 0.25
[ "$(cat "$BASE/daemon.pid")" = "$first_daemon" ]
[ "$("$BB" awk '{print $3}' "/proc/$first_daemon/stat")" = T ]
wait_pid daemon "$first_daemon"
echo 'PASS: stalled daemon is replaced after heartbeat failures'
first_engine=$(cat "$BASE/engine.pid")
touch "$BASE/unhealthy"
wait_pid engine "$first_engine"
rm "$BASE/unhealthy"
echo 'PASS: repeated health failures replace a live but unhealthy engine'
# A reused PID for an unrelated process must never be killed.
"$BB" ash "$BASE/control.sh" stop
"$BB" sleep 0.7
starts=$("$BB" wc -l < "$BASE/engine-starts")
printf 'test-only-preserved-config\n' > "$BASE/config.yaml"
"$BB" ash "$BASE/control.sh" interval 120 >/dev/null
[ -f "$BASE/disabled" ]
[ "$(cat "$BASE/check-interval")" = 120 ]
[ "$(cat "$BASE/config.yaml")" = test-only-preserved-config ]
"$BB" ash "$BASE/99-ddns-go.sh"
"$BB" sleep 0.7
[ "$("$BB" wc -l < "$BASE/engine-starts")" -eq "$starts" ]
"$BB" sleep 10 & unrelated=$!
echo "$unrelated" > "$BASE/daemon.pid"
echo "$unrelated" > "$BASE/engine.pid"
"$BB" ash "$BASE/control.sh" stop
kill -0 "$unrelated"
kill "$unrelated"
echo 'PASS: manual stop stays paused and stale PIDs do not kill unrelated processes'
"$BB" ash "$BASE/control.sh" start
wait_pid daemon "$unrelated"; wait_pid engine "$unrelated"
echo 'PASS: stale PID/lock files do not prevent a deliberate restart'
"$BB" ash "$BASE/control.sh" stop
"$BB" sed \
    -e "s|/data/adb/ddns-go|$BASE|g" \
    -e "s|/data/adb/magisk/busybox|$BB|g" \
    -e "s|/sys/power/wake_lock|$BASE/fake-wake-lock|g" \
    -e "s|/sys/power/wake_unlock|$BASE/fake-wake-unlock|g" \
    "$SRC/wake.sh" > "$BASE/wake-real.sh"
"$BB" ash -c 'exec 7>"$BASE/wake.lock"; "$BB" flock 7; touch "$BASE/lock-ready"; "$BB" sleep 3' & locker=$!
for attempt in $("$BB" seq 1 50); do
    [ ! -f "$BASE/lock-ready" ] || break
    "$BB" sleep 0.1
done
if "$BB" ash "$BASE/wake-real.sh" release; then echo 'FAIL: contended wake lock unexpectedly acquired'; exit 1; fi
wait "$locker"
"$BB" ash "$BASE/wake-real.sh" release
echo 'PASS: wake-lock contention returns within its deadline and later recovers'
# Exercise the real HTTP deadline with a peer helper that ignores TERM. This
# needs no listening socket and cannot contact any network or production port.
REAL_BB=$BB; export REAL_BB
printf '#!%s ash\n' "$BB" > "$BASE/stuck-http"
cat >> "$BASE/stuck-http" <<'EOF'
case "$1" in
    timeout) shift; exec "$REAL_BB" timeout "$@";;
    wget) trap '' TERM; while :; do "$REAL_BB" sleep 0.1; done;;
esac
EOF
chmod 700 "$BASE/stuck-http"
. "$SRC/process.sh"
started=$("$BB" date +%s)
BB=$BASE/stuck-http
if engine_healthy; then echo 'FAIL: stuck HTTP probe reported success'; exit 1; fi
BB=$REAL_BB
elapsed=$(( $("$BB" date +%s) - started ))
[ "$elapsed" -le 7 ]
echo 'PASS: unresponsive HTTP probe is forcibly bounded'
echo 'All isolated reliability fault tests passed.'
