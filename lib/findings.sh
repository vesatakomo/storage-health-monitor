show_findings()
{
    local id
    local last_group=""
    local group
    echo
    echo "========================================================="
    echo " Storage Health Monitor v$VERSION"
    echo "========================================================="
    echo

    for id in "${FINDING_ORDER[@]}"
    do
    group="${FINDING_SECTION[$id]}"

    if [[ "$group" != "$last_group" ]]; then
        print_group "$group"
        last_group="$group"
    fi

    print_finding \
        "${FINDING_SECTION[$id]}" \
        "${FINDING_ITEM[$id]}" \
        "${FINDING_STATUS[$id]}"
    done
}
declare -a FINDING_ORDER=()

declare -A FINDING_SECTION
declare -A FINDING_ITEM
declare -A FINDING_STATUS
status_icon()
{
    case "$1" in
        $STATUS_OK)   echo "✓" ;;
        $STATUS_INFO) echo "i" ;;
        $STATUS_WARN) echo "!" ;;
        $STATUS_FAIL) echo "✗" ;;
        *)            echo "?" ;;
    esac
}

status_text()
{
    case "$1" in
        $STATUS_OK)   echo "Healthy" ;;
        $STATUS_INFO) echo "Information" ;;
        $STATUS_WARN) echo "Warning" ;;
        $STATUS_FAIL) echo "Failed" ;;
        *)            echo "Unknown" ;;
    esac
}
print_group()
{
    local group="$1"

    echo
    echo "$group"
    echo "----------------------------------------"
}
print_finding()
{
    local section="$1"
    local item="$2"
    local status="$3"

    printf "%s %-22s %s\n" \
        "$(status_icon "$status")" \
        "$item" \
        "$(status_text "$status")"
}
