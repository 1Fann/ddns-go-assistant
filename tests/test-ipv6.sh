#!/bin/sh
# Run on Linux/macOS with awk, or Android with BusyBox: busybox ash test-ipv6.sh
set -eu
cd "$(dirname "$0")/.."
if [ -n "${BUSYBOX:-}" ]; then
    actual=$("$BUSYBOX" awk -f runtime/filter-ipv6.awk tests/ipv6-input.txt | "$BUSYBOX" sort -u)
else
    actual=$(awk -f runtime/filter-ipv6.awk tests/ipv6-input.txt | sort -u)
fi
expected=$(cat tests/ipv6-expected.txt)
[ "$actual" = "$expected" ] || { printf 'IPv6 selection failed.\nExpected:\n%s\nActual:\n%s\n' "$expected" "$actual"; exit 1; }
echo 'IPv6 filtering fixtures passed.'
