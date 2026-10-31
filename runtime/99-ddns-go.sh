#!/system/bin/sh
umask 077
BASE=/data/adb/ddns-go
BB=
for candidate in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
  if [ -x "$candidate" ]; then BB=$candidate; break; fi
done
[ -n "$BB" ] || { echo busybox_missing; exit 20; }
[ -f "$BASE/disabled" ] && exit 0
"$BB" setsid "$BB" ash "$BASE/watchdog.sh" </dev/null >/dev/null 2>&1 &
exit 0
