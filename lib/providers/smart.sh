collect_smart_findings()
{
    command -v smartctl >/dev/null 2>&1 || return

while read -r device option type _
do
    smart_output="$(smartctl -x "$device" 2>/dev/null)"
    reallocated="$(smart_get_attribute "$smart_output" "Reallocated_Sector_Ct")"
    events="$(smart_get_attribute "$smart_output" "Reallocated_Event_Count")"
    pending="$(smart_get_attribute "$smart_output" "Current_Pending_Sector")"
    uncorrectable="$(smart_get_attribute "$smart_output" "Offline_Uncorrectable")"
    health_status="$(smart_get_health "$device" "$type")"

    check_value "smart.${device}.reallocated" "$reallocated"
    reallocated_old="$CHECK_OLD_VALUE"
    reallocated_change="$CHECK_CHANGE"

    check_value "smart.${device}.events" "$events"
    events_old="$CHECK_OLD_VALUE"
    events_change="$CHECK_CHANGE"

    check_value "smart.${device}.pending" "$pending"
    pending_old="$CHECK_OLD_VALUE"
    pending_change="$CHECK_CHANGE"

    check_value "smart.${device}.uncorrectable" "$uncorrectable"
    uncorrectable_old="$CHECK_OLD_VALUE"
    uncorrectable_change="$CHECK_CHANGE"

reallocated_detail="$reallocated"
[[ "$reallocated_change" != "$CHANGE_NONE" && -n "$reallocated_old" ]] &&
    reallocated_detail="$reallocated_old -> $reallocated"

events_detail="$events"
[[ "$events_change" != "$CHANGE_NONE" && -n "$events_old" ]] &&
    events_detail="$events_old -> $events"

pending_detail="$pending"
[[ "$pending_change" != "$CHANGE_NONE" && -n "$pending_old" ]] &&
    pending_detail="$pending_old -> $pending"

uncorrectable_detail="$uncorrectable"
[[ "$uncorrectable_change" != "$CHANGE_NONE" && -n "$uncorrectable_old" ]] &&
    uncorrectable_detail="$uncorrectable_old -> $uncorrectable"

    status="$health_status"

    for change in \
        "$reallocated_change" \
        "$events_change" \
        "$pending_change" \
        "$uncorrectable_change"
    do
        candidate="$(change_to_status "$change")"

        if (( candidate > status )); then
            status="$candidate"
        fi
done

add_finding \
    "smart.${device}" \
    "SMART" \
    "$device" \
    "$status" \
    "Reallocated: $reallocated_detail | Events: $events_detail | Pending: $pending_detail | Uncorrectable: $uncorrectable_detail"
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
    local status

    status="$(
        smartctl -H -d "$type" "$device" 2>/dev/null |
awk '
    /^SMART Health Status:/ {
        found=1
        if ($4 == "OK")
            print "'"$STATUS_OK"'"
        else
            print "'"$STATUS_FAIL"'"
    }

    /^SMART overall-health self-assessment test result:/ {
        found=1
        if ($6 == "PASSED")
            print "'"$STATUS_OK"'"
        else
            print "'"$STATUS_FAIL"'"
    }

    END {
        if (!found)
            print "'"$STATUS_INFO"'"
    }'
    )"

    printf '%s\n' "$status"
}
smart_get_attribute()
{
    local smart_output="$1"
    local attribute="$2"

    echo "$smart_output" |
        awk -v attribute="$attribute" '
            $2 == attribute {
                print $NF
                exit
            }'
}
