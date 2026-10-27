#!/system/bin/sh
set -eu
set +x
umask 077
BASE=/data/adb/ddns-go
BB=/data/adb/ksu/bin/busybox
[ "$(id -u)" = 0 ] || { echo 'Root is required.' >&2; exit 1; }
[ ! -L "$BASE.install.lock" ] || exit 1
exec 8>"$BASE.install.lock"
"$BB" flock -n 8 || { echo 'Installation in progress.' >&2; exit 1; }
[ ! -e "$BASE.pending" ] && [ ! -e "$BASE.rollback" ] || { echo 'Recover the interrupted installation first.' >&2; exit 1; }
[ "${1:-}" = --remove-data ] || {
    echo 'Usage: uninstall.sh --remove-data'
    echo 'Removes this backend and its local configuration, including credentials.'
    echo 'Does not uninstall the APK or delete DNS records at your provider.'
    exit 2
}
[ ! -L "$BASE" ] && [ -f "$BASE/.ddns-go-android-root" ] || { echo 'Unrecognized installation; refusing removal.' >&2; exit 1; }
"$BB" ash "$BASE/control.sh" stop
"$BB" flock -n "$BASE/daemon.lock" true || { echo 'Service still running; removal aborted.' >&2; exit 1; }
rm -f /data/adb/service.d/99-ddns-go.sh
# Fixed, ownership-marked path only. Never accept arbitrary deletion targets.
rm -rf /data/adb/ddns-go
echo 'Backend removed. DNS records at the provider are unchanged.'
