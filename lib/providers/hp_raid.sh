#!/bin/bash

###############################################################################
# HP Smart Array Provider
###############################################################################
declare -A SAS_MAP=(
    ["/dev/sda"]="0:1"
    ["/dev/sdb"]="1:2"
    ["/dev/sdd"]="3:4"
    ["/dev/sde"]="4:5"
)
hp_check_status()
{
    local hp_output="$1"
    local object="$2"

    echo "$hp_output" | awk -v object="$object" '
    BEGIN {
        in_object = 0
    }

    $0 ~ "^[[:space:]]*" object {
        in_object = 1
        next
    }

    in_object && /^[[:space:]]*Status:/ {

        if ($2 != "OK") {
            print "'"$STATUS_FAIL"'"
            exit
        }

        in_object = 0
    }

    END {
        print "'"$STATUS_OK"'"
    }'
}
collect_hp_findings()
{
    local hp_output

    command -v ssacli >/dev/null 2>&1 || return

    if ! hp_output="$(ssacli ctrl all show config detail 2>/dev/null)"
    then
        return
    fi
    add_finding \
        "hp.controller" \
        "HP Smart Array" \
        "Controller" \
        "$(hp_controller_status "$hp_output")"

    add_finding \
        "hp.cache" \
        "HP Smart Array" \
        "Cache" \
        "$(hp_cache_status "$hp_output")"

    add_finding \
        "hp.physical" \
        "HP Smart Array" \
        "Physical drives" \
        "$(hp_check_block_status "$hp_output" "physicaldrive")"
    add_finding \
        "hp.logical" \
        "HP Smart Array" \
        "Logical drives" \
        "$(hp_check_block_status "$hp_output" "Logical Drive:")"
for device in "${!SAS_MAP[@]}"
do
    CHECK_DETAILS=()
    IFS=":" read -r cciss_index bay <<< "${SAS_MAP[$device]}"
    sas_smart_output="$(hp_get_smart "$device" "$cciss_index")"

    grown_defects="$(echo "$sas_smart_output" |
    awk -F: '/Elements in grown defect list/ {print $2}' |
    tr -d ' ')"
    read_corrected="$(echo "$sas_smart_output" | awk '/^read:/ {print $5}')"
    read_uncorrected="$(echo "$sas_smart_output" | awk '/^read:/ {print $8}')"
    write_corrected="$(echo "$sas_smart_output" | awk '/^write:/ {print $5}')"
    write_uncorrected="$(echo "$sas_smart_output" | awk '/^write:/ {print $8}')"
    non_medium="$(echo "$sas_smart_output" |
    awk -F: '/Non-medium error count/ {print $2}' | tr -d ' ')"

    check_value "hp.${device}.grown_defects" "$grown_defects" "Grown defects"
    grown_old="$CHECK_OLD_VALUE"
    grown_change="$CHECK_CHANGE"

    check_value "hp.${device}.read_corrected" "$read_corrected" "Read corrected"
    read_corrected_old="$CHECK_OLD_VALUE"
    read_corrected_change="$CHECK_CHANGE"

    check_value "hp.${device}.read_uncorrected" "$read_uncorrected" "Read uncorrected"
    read_uncorrected_old="$CHECK_OLD_VALUE"
    read_uncorrected_change="$CHECK_CHANGE"

    check_value "hp.${device}.write_corrected" "$write_corrected" "Write corrected"
    write_corrected_old="$CHECK_OLD_VALUE"
    write_corrected_change="$CHECK_CHANGE"

    check_value "hp.${device}.write_uncorrected" "$write_uncorrected" "Write uncorrected"
    write_uncorrected_old="$CHECK_OLD_VALUE"
    write_uncorrected_change="$CHECK_CHANGE"

    check_value "hp.${device}.non_medium" "$non_medium" "Non medium"
    non_medium_old="$CHECK_OLD_VALUE"
    non_medium_change="$CHECK_CHANGE"
    grown_detail="$grown_defects"
    [[ "$grown_change" != "$CHANGE_NONE" && -n "$grown_old" ]] &&
    grown_detail="$grown_old -> $grown_defects"

    read_corrected_detail="$read_corrected"
    [[ "$read_corrected_change" != "$CHANGE_NONE" && -n "$read_corrected_old" ]] &&
    read_corrected_detail="$read_corrected_old -> $read_corrected"

    read_uncorrected_detail="$read_uncorrected"
    [[ "$read_uncorrected_change" != "$CHANGE_NONE" && -n "$read_uncorrected_old" ]] &&
    read_uncorrected_detail="$read_uncorrected_old -> $read_uncorrected"

    write_corrected_detail="$write_corrected"
    [[ "$write_corrected_change" != "$CHANGE_NONE" && -n "$write_corrected_old" ]] &&
    write_corrected_detail="$write_corrected_old -> $write_corrected"

    write_uncorrected_detail="$write_uncorrected"
    [[ "$write_uncorrected_change" != "$CHANGE_NONE" && -n "$write_uncorrected_old" ]] &&
    write_uncorrected_detail="$write_uncorrected_old -> $write_uncorrected"

    non_medium_detail="$non_medium"
    [[ "$non_medium_change" != "$CHANGE_NONE" && -n "$non_medium_old" ]] &&
    non_medium_detail="$non_medium_old -> $non_medium"

status="$STATUS_OK"

for change in \
    "$grown_change" \
    "$read_corrected_change" \
    "$read_uncorrected_change" \
    "$write_corrected_change" \
    "$write_uncorrected_change" \
    "$non_medium_change"
do
    candidate="$(change_to_status "$change")"

    if (( candidate > status )); then
        status="$candidate"
    fi
done

notify_message="$(printf '%s\n' "${CHECK_DETAILS[@]}")"
add_finding \
    "hp.${device}" \
    "HP Smart Array" \
    "SAS BAY ${bay}" \
    "$status" \
    "Grown: $grown_detail | Read corrected: $read_corrected_detail | Read uncorrected: $read_uncorrected_detail | Write corrected: $write_corrected_detail | Write uncorrected: $write_uncorrected_detail | Non-medium: $non_medium_detail" \
    "$notify_message"

done
}
###############################################################################
# Private helpers
###############################################################################

hp_check_block_status()
{
    local hp_output="$1"
    local block="$2"

    echo "$hp_output" | awk -v block="$block" '
    BEGIN {
        in_block = 0
        result = '"$STATUS_OK"'
    }

    $0 ~ "^[[:space:]]*" block {
        in_block = 1
        next
    }

    in_block && /^[[:space:]]*Status:/ {

        if ($2 != "OK") {
            result = '"$STATUS_FAIL"'
            exit
        }

        in_block = 0
    }

    END {
        print result
    }'
}
hp_controller_status()
{
    local hp_output="$1"

    if echo "$hp_output" | grep -q "Controller Status: OK"
    then
        echo "$STATUS_OK"
    else
        echo "$STATUS_FAIL"
    fi
}

hp_cache_status()
{
    local hp_output="$1"

    if echo "$hp_output" | grep -q "Cache Status: OK"
    then
        echo "$STATUS_OK"
    else
        echo "$STATUS_FAIL"
    fi
}
hp_get_smart()
{
    local device="$1"
    local cciss_index="$2"

    smartctl -x -d "cciss,$cciss_index" "$device" 2>/dev/null
}
hp_get_attribute()
{
    local smart_output="$1"
    local attribute="$2"

    echo "$smart_output" |
        awk -F: -v attribute="$attribute" '
            $0 ~ attribute {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
                print $2
                exit
            }
        '
}

