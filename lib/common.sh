###############################################################################
# Program
###############################################################################

PROGRAM="Storage Health Monitor"
VERSION="0.6"

###############################################################################
# Status codes
###############################################################################

STATUS_OK=0
STATUS_INFO=10
STATUS_WARN=20
STATUS_FAIL=30
CHANGE_NONE=0
CHANGE_INCREASED=1
CHANGE_DECREASED=2
CHANGE_CHANGED=3
###############################################################################
# Findings
###############################################################################

declare -A FINDING_SECTION
declare -A FINDING_ITEM
declare -A FINDING_STATUS
declare -A FINDING_MESSAGE

add_finding()
{
    local id="$1"

    FINDING_SECTION["$id"]="$2"
    FINDING_ITEM["$id"]="$3"
    FINDING_STATUS["$id"]="$4"
    FINDING_MESSAGE["$id"]="${5:-}"
    FINDING_ORDER+=("$id")
}
