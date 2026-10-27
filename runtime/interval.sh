#!/system/bin/sh
# Sourced by the supervisor and controls. Values are seconds, whole minutes only.
valid_interval() {
    case "${1:-}" in ''|0*|*[!0-9]*) return 1;; esac
    [ "${#1}" -le 5 ] && [ "$1" -ge 60 ] && [ "$1" -le 86400 ] && [ "$(( $1 % 60 ))" = 0 ]
}
read_interval() {
    interval=$(cat "$BASE/check-interval" 2>/dev/null || :)
    valid_interval "$interval" || interval=300
}
