#!/bin/bash

declare -A INVENTORY_BAY
declare -A INVENTORY_MODEL
declare -A INVENTORY_SERIAL
declare -A INVENTORY_SIZE
declare -A INVENTORY_INTERFACE

collect_inventory()
{
    while read -r device option type _
    do
        smart_info="$(smartctl -i "$device" 2>/dev/null)"

    model="$(awk -F: '/^Device Model:/ {sub(/^[[:space:]]+/, "", $2); print $2}' <<< "$smart_info")"
    serial="$(awk -F: '/^Serial Number:/ {sub(/^[[:space:]]+/, "", $2); print $2}' <<< "$smart_info")"
    size="$(grep '^User Capacity:' <<< "$smart_info" | sed 's/.*\[\(.*\)\].*/\1/')"
if grep -qE '^(SATA Version is:|ATA Version is:)' <<< "$smart_info"; then
    interface="SATA"
else
    interface="Unknown"
fi

    INVENTORY_MODEL["$device"]="$model"
    INVENTORY_SERIAL["$device"]="$serial"
    INVENTORY_SIZE["$device"]="$size"
    INVENTORY_INTERFACE["$device"]="$interface"
done < <(smart_discover_targets)
if [[ "$HP_RAID_ENABLED" == "yes" ]] && command -v ssacli >/dev/null 2>&1; then
    hp_discover_sas
    hp_output="$(ssacli ctrl all show config detail 2>/dev/null)"
    hp_get_inventory "$hp_output"
for device in "${!SAS_MAP[@]}"
do
    bay="${device##*:}"

    INVENTORY_BAY["$device"]="$bay"
    INVENTORY_MODEL["$device"]="${HP_INVENTORY_MODEL[$device]}"
    INVENTORY_SERIAL["$device"]="${HP_INVENTORY_SERIAL[$device]}"
    INVENTORY_SIZE["$device"]="${HP_INVENTORY_SIZE[$device]}"
    INVENTORY_INTERFACE["$device"]="${HP_INVENTORY_INTERFACE[$device]}"
done
fi
show_inventory
}
show_inventory()
{
    echo
    echo "=== Storage Inventory ==="

    while read -r device
    do
	box="${device#*:}"
	box="${box%%:*}"
	bay="${device##*:}"

        if [[ -n "${INVENTORY_BAY[$device]}" ]]; then
            printf 'Box %-2s Bay %-2s %-24s %-8s %-18s %s\n' \
		"$box" \
		"$bay" \
                "${INVENTORY_MODEL[$device]}" \
                "${INVENTORY_SIZE[$device]}" \
                "${INVENTORY_INTERFACE[$device]}" \
                "${INVENTORY_SERIAL[$device]}"
        else
            printf '%-9s     %-24s %-8s %-18s %s\n' \
                "$device" \
                "${INVENTORY_MODEL[$device]}" \
                "${INVENTORY_SIZE[$device]}" \
                "${INVENTORY_INTERFACE[$device]}" \
                "${INVENTORY_SERIAL[$device]}"
        fi
    done < <(printf '%s\n' "${!INVENTORY_MODEL[@]}" | sort)
}
