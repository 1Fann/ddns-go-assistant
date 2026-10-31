#!/system/bin/sh
# Shared by the APK and manual deployment. Never prints configuration or tokens.
set -eu
set +x
umask 077
export PATH=/system/bin:/system/xbin
BASE=/data/adb/ddns-go
BOOT=/data/adb/service.d/99-ddns-go.sh
BB=
for candidate in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
  if [ -x "$candidate" ]; then BB=$candidate; break; fi
done
[ -n "$BB" ] || { echo busybox_missing; exit 20; }
STAGE=$BASE.pending
BACKUP=$BASE.rollback
SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
[ "$(id -u)" = 0 ] || { echo ROOT_REQUIRED; exit 1; }
[ -x "$BB" ] || { echo ENVIRONMENT_UNSUPPORTED; exit 1; }
[ "$(getprop ro.product.cpu.abi)" = arm64-v8a ] || { echo ARCHITECTURE_UNSUPPORTED; exit 1; }
[ "$SRC" != "$BASE" ] && [ "$SRC" != "$STAGE" ] && [ "$SRC" != "$BACKUP" ] || exit 1
for p in "$BASE" "$BOOT" /data/adb/service.d "$STAGE" "$BACKUP" "$BASE.install.lock"; do [ ! -L "$p" ] || { echo UNSAFE_PATH; exit 1; }; done
exec 8>"$BASE.install.lock"
"$BB" flock -n 8 || { echo INSTALL_BUSY; exit 1; }
# Never discard a previous interrupted transaction or its credential backup.
[ ! -e "$BACKUP" ] && [ ! -e "$STAGE" ] || { echo RECOVERY_REQUIRED; exit 1; }
mode=${1:-install}
case "$mode" in install|--upgrade|--app) ;; *) echo 'Usage: install.sh [--upgrade|--app]'; exit 2;; esac
existing=0;was_enabled=0;switched=0;stopped=0;committed=0;had_boot=0
if [ -e "$BASE" ] || [ -e "$BOOT" ]; then
    [ "$mode" != install ] && [ -f "$BASE/.ddns-go-android-root" ] && [ ! -L "$BASE/.ddns-go-android-root" ] || { echo EXISTING_INSTALLATION; exit 1; }
    existing=1
    [ -f "$BASE/disabled" ] || was_enabled=1
    [ ! -e "$BOOT" ] || had_boot=1
else
    [ "$mode" != --upgrade ] || { echo NOTHING_TO_UPGRADE; exit 1; }
fi
files='ddns-go control.sh daemon.sh watchdog.sh process.sh interval.sh control-version ipv6.sh filter-ipv6.awk wake.sh engine-version LICENSE.ddns-go'
for f in $files 99-ddns-go.sh; do [ -f "$SRC/$f" ] && [ ! -L "$SRC/$f" ] || { echo MISSING_PAYLOAD; exit 1; }; done
for f in config.yaml disabled wake-disabled selected-ip check-interval control.sh daemon.sh wake.sh; do [ ! -L "$BASE/$f" ] || { echo UNSAFE_PATH; exit 1; }; done
rollback() {
    code=$?
    trap - EXIT TERM INT HUP
    if [ "$committed" = 0 ]; then
        if [ "$switched" = 1 ] && [ -f "$BASE/.ddns-go-android-root" ]; then
            "$BB" ash "$BASE/control.sh" stop 8>&- >/dev/null 2>&1 || :
            if ! "$BB" flock -n "$BASE/daemon.lock" true; then echo RECOVERY_REQUIRED; exit 1; fi
            if ! "$BB" flock -n "$BASE/watchdog.lock" true; then echo RECOVERY_REQUIRED; exit 1; fi
            rm -rf "$BASE"
        fi
        if [ -d "$BACKUP" ]; then
            mv "$BACKUP" "$BASE" || { echo RECOVERY_REQUIRED; exit 1; }
            if [ "$had_boot" = 1 ]; then cp "$BASE/.previous-boot" "$BOOT"; chmod 700 "$BOOT"; else rm -f "$BOOT"; fi
            rm -f "$BASE/.previous-boot"
            echo ROLLED_BACK
        elif [ "$switched" = 1 ]; then
            rm -f "$BOOT"
        fi
        if [ "$existing" = 1 ] && [ "$stopped" = 1 ] && [ "$was_enabled" = 1 ]; then
            "$BB" ash "$BASE/control.sh" start 8>&- >/dev/null 2>&1 || :
        fi
    fi
    [ ! -d "$STAGE" ] || rm -rf "$STAGE"
    exit "$code"
}
trap rollback EXIT
trap 'exit 1' TERM INT HUP
mkdir "$STAGE"
chmod 700 "$STAGE"
for f in $files; do cp "$SRC/$f" "$STAGE/$f"; done
chmod 700 "$STAGE/ddns-go" "$STAGE/"*.sh
chmod 600 "$STAGE/filter-ipv6.awk" "$STAGE/engine-version" "$STAGE/control-version" "$STAGE/LICENSE.ddns-go"
touch "$STAGE/.ddns-go-android-root"
version=$(cat "$STAGE/engine-version")
printf '%s\n' "$version" | "$BB" grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' || exit 1
"$BB" timeout -k 1 10 "$STAGE/ddns-go" -v 8>&- 2>/dev/null | "$BB" grep -Fxq "$version" || { echo ENGINE_CHECK_FAILED; exit 1; }
if [ "$existing" = 1 ]; then
    # Stop before snapshotting: an engine upgrade must not race a config write.
    stopped=1
    "$BB" ash "$BASE/control.sh" stop 8>&- >/dev/null 2>&1
    "$BB" flock -n "$BASE/daemon.lock" true || { echo SERVICE_BUSY; exit 1; }
    "$BB" flock -n "$BASE/watchdog.lock" true || { echo SERVICE_BUSY; exit 1; }
    for f in config.yaml disabled wake-disabled selected-ip check-interval; do
        [ ! -e "$BASE/$f" ] || cp -p "$BASE/$f" "$STAGE/$f"
    done
    [ "$was_enabled" = 0 ] || rm -f "$STAGE/disabled"
    if [ "$had_boot" = 1 ]; then cp "$BOOT" "$BASE/.previous-boot"; fi
    mv "$BASE" "$BACKUP"
else
    touch "$STAGE/wake-disabled"
    if [ "$mode" = --app ]; then was_enabled=1; else touch "$STAGE/disabled"; fi
fi
mv "$STAGE" "$BASE"
switched=1
mkdir -p /data/adb/service.d
cp "$SRC/99-ddns-go.sh" "$BOOT"
chmod 700 "$BOOT"
if [ "$was_enabled" = 1 ]; then
    "$BB" ash "$BASE/control.sh" start 8>&- >/dev/null 2>&1
    ready=0
    for attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        pid=$(cat "$BASE/engine.pid" 2>/dev/null || :)
        case "$pid" in ''|*[!0-9]*) ;; *)
            if kill -0 "$pid" 2>/dev/null && "$BB" timeout -k 1 3 "$BB" wget -q -O /dev/null http://127.0.0.1:9876/ 8>&- 2>/dev/null; then
                sleep 1
                if kill -0 "$pid" 2>/dev/null && "$BB" tr '\000' ' ' < "/proc/$pid/cmdline" | "$BB" grep -qF "$BASE/ddns-go -l "; then ready=1;break;fi
            fi;;
        esac
        sleep 2
    done
    [ "$ready" = 1 ] || { echo HEALTH_CHECK_FAILED; exit 1; }
fi
committed=1
# Credential-bearing rollback snapshot is needed only until the health check passes.
[ ! -d "$BACKUP" ] || rm -rf "$BACKUP"
if [ "$was_enabled" = 1 ]; then echo INSTALL_OK; else echo INSTALL_OK_PAUSED; fi
