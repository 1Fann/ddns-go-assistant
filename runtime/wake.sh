#!/system/bin/sh
set +x
umask 077
BASE=/data/adb/ddns-go
BB=
for candidate in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
  if [ -x "$candidate" ]; then BB=$candidate; break; fi
done
[ -n "$BB" ] || { echo busybox_missing; exit 20; }
. "$BASE/process.sh"
exec 7>"$BASE/wake.lock"
# Magisk BusyBox does not provide flock -w. Bound retries explicitly instead.
lock_attempt=0
while ! "$BB" flock -n 7; do
    lock_attempt=$((lock_attempt+1))
    [ "$lock_attempt" -lt 3 ] || exit 1
    "$BB" sleep 1
done
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
if process_running "$pid" daemon.sh; then
    printf '%s\n' 'ddns_go 600000000000' > /sys/power/wake_lock
fi
