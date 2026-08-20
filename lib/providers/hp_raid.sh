#!/bin/bash

###############################################################################
# HP Smart Array Provider
###############################################################################
declare -A SAS_MAP
declare -A HP_INVENTORY_MODEL
declare -A HP_INVENTORY_SERIAL
declare -A HP_INVENTORY_SIZE
declare -A HP_INVENTORY_INTERFACE
hp_discover_sas()
{
    local hp_output
    local device
    local serial
    local cciss
    local found
    local total

    hp_output="$(ssacli ctrl all show config detail 2>/dev/null)" || return

    total=0

    while read -r device serial
    do
        [[ -z "$serial" ]] && continue
        ((total++))
    done < <(
        echo "$hp_output" |
        awk '
            /physicaldrive/ {
                location=$2
                in_drive=1
                next
            }

            in_drive && /^         Serial Number:/ {
                print location, $3
                in_drive=0
            }
        '
    )

    found=0

    for cciss in $(seq 0 31)
    do
        serial="$(
            smartctl -x -d "cciss,$cciss" /dev/sda 2>/dev/null |
            awk '/^Serial number:/ {print $3; exit}'
        )"

        [[ -z "$serial" ]] && continue
        while read -r device expected_serial
        do
            if [[ "$serial" == "$expected_serial" ]]
            then
                SAS_MAP["$device"]="$cciss"
                ((found++))
                break
            fi
        done < <(
            echo "$hp_output" |
            awk '
                /physicaldrive/ {
                    location=$2
                    in_drive=1
                    next
                }

                in_drive && /^         Serial Number:/ {
                    print location, $3
                    in_drive=0
                }
            '
        )

        ((found >= total)) && break
    done

}
hp_get_inventory()
{
    local hp_output="$1"
    local physicaldrive=""
    local bay=""
    local interface=""
    local size=""
    local serial=""
    local model=""

    while IFS= read -r line
    do
        if [[ "$line" =~ ^[[:space:]]*physicaldrive[[:space:]]+([^[:space:]]+)[[:space:]]*$ ]]; then
            physicaldrive="${BASH_REMATCH[1]}"
            bay=""
            interface=""
            size=""
            serial=""
            model=""
            continue
        fi

        [[ -z "$physicaldrive" ]] && continue

        case "$line" in
        *"Bay:"*)
            bay="${line#*: }"
            ;;
        *"Interface Type:"*)
            interface="${line#*: }"
            ;;
        *"Size:"*)
        [[ "$line" != *"Logical/Physical Block Size:"* ]] &&
            size="${line#*: }"
            ;;
        *"Serial Number:"*)
            serial="${line#*: }"
            ;;
        *"Model:"*)
            model="${line#*: }"
            model="$(echo "$model" | xargs)"

	key="$physicaldrive"
	HP_INVENTORY_INTERFACE["$key"]="$interface"
	HP_INVENTORY_SIZE["$key"]="$size"
	HP_INVENTORY_SERIAL["$key"]="$serial"
	HP_INVENTORY_MODEL["$key"]="$model"
                physicaldrive=""
                ;;
        esac

    done <<< "$hp_output"
}

collect_hp_findings()
{
    local hp_output

    command -v ssacli >/dev/null 2>&1 || return

    if ! hp_output="$(ssacli ctrl all show config detail 2>/dev/null)"
    then
        return
    fi
hp_discover_sas
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
        "hp.logical" \
        "HP Smart Array" \
        "Logical drives" \
        "$(hp_check_block_status "$hp_output" "Logical Drive:")"
while read -r device
do
[[ -z "$device" ]] && continue

    CHECK_DETAILS=()
    cciss_index="${SAS_MAP[$device]}"
    sas_smart_output="$(hp_get_smart "/dev/sda" "$cciss_index")"

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
   box="${device#*:}"
   box="${box%%:*}"

   bay="${device##*:}"

add_finding \
    "hp.${device}" \
    "HP Smart Array" \
    "SAS Box ${box} Bay ${bay}" \
    "$status" \
    "Grown: $grown_detail | Read corrected: $read_corrected_detail | Read uncorrected: $read_uncorrected_detail | Write corrected: $write_corrected_detail | Write uncorrected: $write_uncorrected_detail | Non-medium: $non_medium_detail" \
    "$notify_message"
done < <(printf '%s\n' "${!SAS_MAP[@]}" | sort)

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

