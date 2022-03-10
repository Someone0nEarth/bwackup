#!/bin/bash

if [ -z "$GLOBALS_ALREADY_SOURCED" ]; then
    GLOBALS_ALREADY_SOURCED="true"

    GLOBAL_RSNAPSHOT_TEST_RUN="false"
    GLOBAL_SYSLOG="true"
    GLOBAL_LOG_WITH_TIMESTAMPS="false"

    declare -a DEPENDED_CMDS_FOR_FAILING_FAST_CHECK=()

    readonly REGEX_DIR_PATH_WITHOUT_TRAILING_SLASH="^(\/[a-zA-Z_0-9 -]+)+[a-zA-Z_0-9-]$" # /a, /a/b, /a/b/c and so on..
    readonly REGEX_DIR_PATH_WITH_TRAILING_SLASH="^(\/[a-zA-Z_0-9 -]+)+\/$"               # /a/, /a/b/, /a/b/c/ and so on..
    readonly REGEX_DIR_PATH_WITHOUT_ROOT="^(\/[a-zA-Z_0-9 -]+)+[a-zA-Z_0-9 \/-]$"        # /a, /a/, /a/b/, /a/b/c and so on.. but not /, //, /// and so on..
fi

function exit_if_a_cmd_is_missing() {
    for command in "${DEPENDED_CMDS_FOR_FAILING_FAST_CHECK[@]}"; do
        if ! command -v "$command" >/dev/null 2>&1; then
            syslog_and_exit_with_error "Command not found: $command"
        fi
    done
}

function add_cmds_for_failing_fast_check() {
    DEPENDED_CMDS_FOR_FAILING_FAST_CHECK=("${DEPENDED_CMDS_FOR_FAILING_FAST_CHECK[@]}" "$@")
}

function directory_path_has_trailing_slash() {
    if [[ "$1" =~ $REGEX_DIR_PATH_WITH_TRAILING_SLASH ]]; then
        return 0
    fi
    return 1
}

function is_an_existing_directory_and_not_root_dir() {
    local path="$1"
    if [[ -d "$path" && "$path" =~ $REGEX_DIR_PATH_WITHOUT_ROOT ]]; then
        return 0
    fi
    return 1
}

function remove_trailing_slash() {
    echo "${1%/}"
}
