#!/bin/bash

CHECK_OLD_VALUE=""
CHECK_CHANGE=""
CHECK_DETAILS=()
compare_value()
{
    local old="$1"
    local new="$2"

    if [[ "$old" == "$new" ]]; then
        echo "$CHANGE_NONE"
    elif (( new > old )); then
        echo "$CHANGE_INCREASED"
    elif (( new < old )); then
        echo "$CHANGE_DECREASED"
    else
        echo "$CHANGE_CHANGED"
    fi
}
STATE_FILE="$SCRIPT_DIR/state.db"
save_value()
{
    local key="$1"
    local value="$2"

    grep -v "^${key}=" "$STATE_FILE" 2>/dev/null > "${STATE_FILE}.tmp"
    echo "${key}=${value}" >> "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
}
load_value()
{
    local key="$1"

    grep "^${key}=" "$STATE_FILE" 2>/dev/null |
        tail -n 1 |
        cut -d= -f2-
}
check_value()
{
    local key="$1"
    local new="$2"
    local label="${3:-}"
    local old

    old="$(load_value "$key")"

    CHECK_OLD_VALUE="$old"

    if [[ -z "$old" ]]; then
        save_value "$key" "$new"
        CHECK_CHANGE="$CHANGE_NONE"
        CHECK_DETAIL=""
        return
    fi

    CHECK_CHANGE="$(compare_value "$old" "$new")"

    if [[ "$CHECK_CHANGE" == "$CHANGE_NONE" ]]; then
        CHECK_DETAIL=""
    else
        CHECK_DETAIL="${label}: $old -> $new"
        CHECK_DETAILS+=("$CHECK_DETAIL")
    fi

    save_value "$key" "$new"
}
change_to_status()
{
    case "$1" in
        $CHANGE_INCREASED)
            echo "$STATUS_WARN"
            ;;
        $CHANGE_DECREASED|$CHANGE_CHANGED)
            echo "$STATUS_INFO"
            ;;
        *)
            echo "$STATUS_OK"
            ;;
    esac
}
