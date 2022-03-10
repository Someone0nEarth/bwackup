#!/bin/bash

source "$(dirname "$0")/../common/global_flags.sh"

add_cmds_for_failing_fast_check "rsnapshot"

do_rsnapshot() {
    local rsnapshot_config=$1
    local rsnapshot_interval=$2

    local test_flag=""

    if [ "$GLOBAL_RSNAPSHOT_TEST_RUN" = "true" ]; then
        test_flag="-t "
    fi

    params="$test_flag-c $rsnapshot_config $rsnapshot_interval"
    log_info "Executing rsnapshot with '$params'"
    
    rsnapshot $params || syslog_and_exit_with_error "rsnapshot failed with '$params'"
    
    log_info "rsnapshot done with '$params'"
}
