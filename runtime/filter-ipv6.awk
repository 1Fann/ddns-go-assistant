# Input: /system/bin/ip -o -6 addr show dev wlan0 scope global
# Output: eligible unicast addresses, without prefixes. No credentials involved.
/inet6/ {
    bad=0; global=0; addr=""
    for(i=1;i<=NF;i++) {
        if($i=="temporary" || $i=="secondary" || $i=="deprecated" || $i=="tentative" || $i=="dadfailed") bad=1
        if($i=="global") global=1
        if($i=="inet6") addr=$(i+1)
        if($i=="preferred_lft" && ($(i+1)=="0sec" || $(i+1)=="0")) bad=1
    }
    sub(/\/.*/,"",addr)
    if(!bad && global && addr ~ /^[23][0-9a-fA-F]*:/) print addr
}
