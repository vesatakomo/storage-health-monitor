#!/bin/bash

###############################################################################
# HP Smart Array Provider
###############################################################################
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
