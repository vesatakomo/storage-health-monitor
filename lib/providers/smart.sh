collect_smart_findings()
{
    command -v smartctl >/dev/null 2>&1 || return

    while read -r device option type _
do
    status="$(smart_get_health "$device" "$type")"

    add_finding \
        "smart.$device" \
        "SMART" \
        "$device" \
        "$status"
done < <(smart_discover_targets)
}

smart_discover_targets()
{
    smartctl --scan 2>/dev/null
}

smart_get_health()
{
    local device="$1"
    local type="$2"

    smartctl -H -d "$type" "$device" 2>/dev/null |
    awk '
        /^SMART Health Status:/ {
            if ($4 == "OK")
                print "'"$STATUS_OK"'"
            else
                print "'"$STATUS_FAIL"'"
        }'
}
