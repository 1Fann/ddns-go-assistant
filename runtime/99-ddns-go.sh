#!/system/bin/sh
umask 077
BASE=/data/adb/ddns-go
[ -f "$BASE/disabled" ] && exit 0
/data/adb/ksu/bin/busybox setsid /data/adb/ksu/bin/busybox ash "$BASE/daemon.sh" </dev/null >/dev/null 2>&1 &
exit 0
