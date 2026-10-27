#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. runtime/interval.sh
for value in 60 120 300 3600 86400; do
    valid_interval "$value" || { echo 'Valid interval rejected.'; exit 1; }
done
for value in '' 0 1 59 61 299 86401 99999 100000 00060 -60 1.5 '60;exit' 99999999999999999999; do
    if valid_interval "$value"; then echo 'Invalid interval accepted.'; exit 1; fi
done
BASE=$(mktemp -d "${TMPDIR:-/tmp}/ddns-interval.XXXXXX")
trap 'rm -f "$BASE/check-interval"; rmdir "$BASE"' EXIT
read_interval
[ "$interval" = 300 ]
printf '120\n' > "$BASE/check-interval"
read_interval
[ "$interval" = 120 ]
printf 'invalid\n' > "$BASE/check-interval"
read_interval
[ "$interval" = 300 ]
echo 'Interval validation and default fallback passed.'
