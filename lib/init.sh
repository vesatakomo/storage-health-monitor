#!/usr/bin/env bash

init()
{
    command -v ssacli >/dev/null 2>&1 \
        || die "ssacli not found."

    command -v smartctl >/dev/null 2>&1 \
        || die "smartctl not found."

    if [[ "$MODE" == "reset" ]]
    then
        echo "Reset not implemented yet."
        exit 0
    fi
}
