#!/bin/bash

notify_findings()
{
    local id
    local status

    for id in "${FINDING_ORDER[@]}"
    do
        status="${FINDING_STATUS[$id]}"

        if (( status >= STATUS_WARN )); then
            printf '%s: %s\n' \
                "${FINDING_ITEM[$id]}" \
                "${FINDING_NOTIFY[$id]}"
        fi
    done
}
