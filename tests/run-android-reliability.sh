#!/system/bin/sh
set -eu
BASE_TEST=/data/local/tmp/ddns-reliability-test-20261031
for candidate in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
    if [ -x "$candidate" ]; then BUSYBOX=$candidate; break; fi
done
: "${BUSYBOX:?Root manager BusyBox is required}"
export BUSYBOX
TEST_ROOT=$BASE_TEST
export TEST_ROOT
"$BUSYBOX" ash "$BASE_TEST/tests/test-reliability.sh"
