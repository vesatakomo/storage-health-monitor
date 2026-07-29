#!/usr/bin/env bash

usage()
{
cat << EOF
${PROGRAM} v${VERSION}

Usage:

    storage_health [OPTION]

Options

    --help
    --version
    --full
    --reset

EOF
}

parse_args()
{
    MODE="full"

    while [[ $# -gt 0 ]]
    do
        case "$1" in

            --help|-h)
                usage
                exit 0
                ;;

            --version|-V)
                echo "${PROGRAM} v${VERSION}"
                exit 0
                ;;

            --full)
                MODE="full"
                ;;

            --reset)
                MODE="reset"
                ;;

            *)
                echo "Unknown option: $1"
                usage
                exit 2
                ;;
        esac

        shift
    done
}
