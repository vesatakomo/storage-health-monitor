#!/bin/bash

notify_findings()
{
    local id
    local status
    local has_findings=false
    local message="Storage Health Monitor- $(hostname)"$'\n\n'
    message+="=============================="$'\n\n'
    for id in "${FINDING_ORDER[@]}"
    do
        status="${FINDING_STATUS[$id]}"

        if (( status >= STATUS_WARN )); then
	    has_findings=true
            message+="$(status_icon "$status") ${FINDING_ITEM[$id]}"$'\n'
            message+="${FINDING_NOTIFY[$id]}"$'\n\n'
        fi
    done
    [[ "$has_findings" == false ]] && return
    [[ "$message" == "Storage Health Monitor"$'\n\n' ]] && return
    case "$NOTIFY_METHOD" in
        none)
            return
            ;;
        apprise)
            notify_apprise "$message"
            ;;
        telegram)
            notify_telegram "$message"
            ;;
        *)
            echo "Unknown notification method: $NOTIFY_METHOD" >&2
            return 1
            ;;
    esac
}
notify_apprise()
{
    local message="$1"

    if [[ -z "$APPRISE_URL" ]]; then
        echo "ERROR: APPRISE_URL is not configured" >&2
        return 1
    fi
    curl -fsS -o /dev/null -X POST \
        -F "body=$message" \
        -F "tags=all" \
        "$APPRISE_URL"
}
notify_telegram()
{
    local message="$1"

    if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
        echo "ERROR: TELEGRAM_BOT_TOKEN is not configured" >&2
        return 1
    fi

    if [[ -z "$TELEGRAM_CHAT_ID" ]]; then
        echo "ERROR: TELEGRAM_CHAT_ID is not configured" >&2
        return 1
    fi

    curl -fsS -o /dev/null -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=$TELEGRAM_CHAT_ID" \
        --data-urlencode "text=$message"
}
