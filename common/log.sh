#!/bin/bash

source "$(dirname "$0")/../common/global_flags.sh"

declare -ri LOG_LEVEL_DEBUG=0
declare -ri LOG_LEVEL_INFO=1
declare -ri LOG_LEVEL_WARNING=2
declare -ri LOG_LEVEL_ERROR=3
declare -ri LOG_LEVEL_OFF=4

declare -i LOG_LEVEL

if [[ -z $LOG_ALREADY_SOURCED ]]; then
    LOG_ALREADY_SOURCED="true"
    
    SCRIPT_NAME=$0
    LOG_LEVEL=$LOG_LEVEL_INFO
fi

# Commands used by this script
add_cmds_for_failing_fast_check "logger"

set_log_level() {
    local loglevel=$(($1))
    
    if (($loglevel > $LOG_LEVEL_OFF || $loglevel < $LOG_LEVEL_DEBUG)); then
        syslog_and_exit_with_error "Unknown log level: '$loglevel'"
    fi
    
    LOG_LEVEL=$loglevel
}

syslog() {
    local log_text="$1"
    
    if [[ $GLOBAL_SYSLOG == "true" ]]; then
        logger "$SCRIPT_NAME $log_text"
    else
        echo "syslog: $(echo_formatted_date) $SCRIPT_NAME $log_text"
    fi
}

syslog_and_exit_with_error() {
    local log_text="$1"
    
    log_error "$log_text"
    syslog "ERROR: $log_text"
    exit 1
}

log() {
    local log_text="$1"
    
    log_to_console "$log_text"
    
    if [[ $GLOBAL_LOG_TO_FILE == "true" ]]; then
        log_to_file "$log_text"
    fi
}

log_to_console() {
    local log_text="$1"
    
    if [[ $GLOBAL_LOG_CONSOLE_TIMESTAMPS == "true" ]]; then
        log_text="$(echo_formatted_date) $log_text"
    fi
    
    echo -e "$log_text"
}

log_to_file() {
    local log_text="$1"
    
    log_text="$(echo_formatted_date) $log_text"
    
    echo -e "$log_text" >> $GLOBAL_LOG_LOGFILE
}

log_debug() {
    local log_text="$1"
    
    [[ $LOG_LEVEL_DEBUG -ge $LOG_LEVEL ]] && log "[D] $1"
}

log_info() {
    local log_text="$1"
    
    [[ $LOG_LEVEL_INFO -ge $LOG_LEVEL ]] && log "[I] $1"
}

log_warn() {
    local log_text="$1"
    
    [[ $LOG_LEVEL_WARNING -ge $LOG_LEVEL ]] && log "[W] $1"
}

log_error() {
    local log_text="$1"
    
    [[ $LOG_LEVEL_ERROR -ge $LOG_LEVEL ]] && log "[E] $1"
}

echo_formatted_date() {
    local formatted_date
    formatted_date=$(date +%Y-%m-%d\ %H:%M:%S)
    
    echo "$formatted_date"
}
