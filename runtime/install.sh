#!/system/bin/sh
# Run from the extracted, verified runtime directory as root.
set -eu
set +x
umask 077
BASE=/data/adb/ddns-go
BOOT=/data/adb/service.d/99-ddns-go.sh
BB=/data/adb/ksu/bin/busybox
SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
[ "$(id -u)" = 0 ] || { echo 'Root is required.' >&2; exit 1; }
[ -x "$BB" ] || { echo 'BakaSU/KernelSU BusyBox not found.' >&2; exit 1; }
[ "$(getprop ro.product.cpu.abi)" = arm64-v8a ] || { echo 'This bundle requires ARM64.' >&2; exit 1; }
[ "$SRC" != "$BASE" ] || { echo 'Install from a staging directory.' >&2; exit 1; }
[ ! -L "$BASE" ] && [ ! -L /data/adb/service.d ] && [ ! -L "$BOOT" ] || { echo 'Refusing linked install paths.' >&2; exit 1; }
for f in ddns-go control.sh daemon.sh ipv6.sh filter-ipv6.awk wake.sh 99-ddns-go.sh engine-version LICENSE.ddns-go; do
    [ -f "$SRC/$f" ] && [ ! -L "$SRC/$f" ] || { echo "Missing or linked payload: $f" >&2; exit 1; }
done
mode=${1:-install}
case "$mode" in install|--upgrade) ;; *) echo 'Usage: install.sh [--upgrade]' >&2; exit 2;; esac
if [ -e "$BASE" ] || [ -e "$BOOT" ]; then
    [ "$mode" = --upgrade ] && [ -f "$BASE/.ddns-go-android-root" ] || {
        echo 'Existing installation detected. No files changed. See migration instructions.' >&2; exit 1;
    }
    was_disabled=0; [ ! -f "$BASE/disabled" ] || was_disabled=1
    "$BB" ash "$BASE/control.sh" stop
    "$BB" flock -n "$BASE/daemon.lock" true || { echo 'Service still running; upgrade aborted.' >&2; exit 1; }
else
    [ "$mode" = install ] || { echo 'Nothing to upgrade.' >&2; exit 1; }
    was_disabled=1
fi
mkdir -p "$BASE" /data/adb/service.d
chmod 700 "$BASE"
for f in ddns-go control.sh daemon.sh ipv6.sh filter-ipv6.awk wake.sh engine-version LICENSE.ddns-go; do
    # Replace files rather than following any pre-existing file symlink.
    [ ! -L "$BASE/$f" ] && [ ! -L "$BASE/$f.new" ] || { echo "Linked destination: $f" >&2; exit 1; }
    cp "$SRC/$f" "$BASE/$f.new"
    mv -f "$BASE/$f.new" "$BASE/$f"
done
chmod 700 "$BASE/ddns-go" "$BASE/"*.sh
chmod 600 "$BASE/filter-ipv6.awk" "$BASE/engine-version" "$BASE/LICENSE.ddns-go"
cp "$SRC/99-ddns-go.sh" "$BOOT"
chmod 700 "$BOOT"
touch "$BASE/.ddns-go-android-root"
if [ "$mode" = install ]; then
    # Battery-saving default for new users. Enable a wake lock explicitly in the app.
    touch "$BASE/disabled" "$BASE/wake-disabled"
fi
if [ "$was_disabled" = 0 ]; then "$BB" ash "$BASE/control.sh" start; fi
echo 'Installed. Open the assistant, grant root, and enable background running.'
echo 'Configure ddns-go locally at http://127.0.0.1:9876. No DNS credentials were installed.'
