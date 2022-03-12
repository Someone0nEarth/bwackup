#!/bin/bash

DIR_NAME=$(dirname "$0")

source "$DIR_NAME"/../common/global_flags.sh
source "$DIR_NAME"/../common/log.sh
source "$DIR_NAME"/../common/mount.sh
source "$DIR_NAME"/../common/backup.sh
source "$DIR_NAME"/../common/init-file-parser.sh

declare SCRIPT_NAME="$0"
declare config="$DIR_NAME/../etc/bwackup_rs_crypt_sshfs.conf"
declare -i loglevel=LOG_LEVEL_INFO

do_backup() {
    local section=$1
    local rsnapshot_interval=$2

    local sshfs_identity_file
    sshfs_identity_file=$(get_value $section 'sshfs_identity_file')
    local sshfs_url
    sshfs_url=$(get_value $section 'sshfs_url')
    local sshfs_url_port
    sshfs_url_port=$(get_value $section 'sshfs_url_port')
    local sshfs_mountpoint
    sshfs_mountpoint=$(get_value $section 'sshfs_mountpoint')

    local crypt_luks_file
    crypt_luks_file=$(get_value $section 'crypt_luks_file')
    local crypt_partition
    crypt_partition=$(get_value $section 'crypt_partition')
    local crypt_key
    crypt_key=$(get_value $section 'crypt_key')
    local crypt_mountpoint
    crypt_mountpoint=$(get_value $section 'crypt_mountpoint')

    local rsnapshot_conf
    rsnapshot_conf=$(get_value $section 'rsnapshot_conf')

    local sshfs_was_already_mounted=false
    local crypt_was_already_mounted=false

    ensure_sshfs_is_mounted "$sshfs_identity_file" "$sshfs_mountpoint" "$sshfs_url" "$sshfs_url_port" && sshfs_was_already_mounted=true
    ensure_crypt_is_mounted "$crypt_luks_file" "$crypt_partition" "$crypt_key" "$crypt_mountpoint" && crypt_was_already_mounted=true

    do_rsnapshot $rsnapshot_conf "$rsnapshot_interval"

    ! $crypt_was_already_mounted && unmount_crypt "$crypt_mountpoint" "$crypt_partition"
    ! $sshfs_was_already_mounted && unmount_sshfs "$sshfs_mountpoint"
}

show_help() {
    echo " Usage: $SCRIPT_NAME [options] rsnapshot_interval"
    echo " Options:"
    echo "  -h  | --help - Show help (this)"
    echo "  -t  | --test - Will mount/unmout but run rsnapshot in test-mode (won't touch anything) and no logging to syslog."
    echo "  -ts | --timestamps - Will log to console with timestamps."
    echo "  -c  | --config - Use the given config instead of the default one '$config'"
    echo "  -ll | --loglevel - Set the log level of THIS script (not the ones of the used commands): 0 (debug), 1 (info), 2 (warning), 3 (error) or 4 (off)."
}

[[ $# -eq 0 ]] && syslog_and_exit_with_error "No given arguments.\n$(show_help)"

while :; do
    case $1 in
    -h | -\? | --help)
        show_help # Display a usage synopsis.
        exit
        ;;
    -c | --config)
        config="$2"
        shift
        ;;
    -t | --test)
        GLOBAL_RSNAPSHOT_TEST_RUN="true"
        GLOBAL_SYSLOG="false"
        ;;
    -ts | --timestamps)
        GLOBAL_LOG_WITH_TIMESTAMPS="true"
        ;;
    -ll | --loglevel)
        loglevel=$(($2))
        shift
        ;;
    -?*)
        syslog_and_exit_with_error "Unknown option: '$1'"
        ;;
    *) # Default case: No more options, so break out of the loop.
        break ;;
    esac

    shift
done

[ "$2" != "" ] && syslog_and_exit_with_error "Unexpected argument '$2'"

[ "$1" == "" ] && syslog_and_exit_with_error "No given rsnapshot interval: '$1'"
rsnapshot_interval="$1"

exit_if_a_cmd_is_missing

set_log_level $loglevel

# Load config
keys_without_section_warning=false
process_ini_file "$config" || syslog_and_exit_with_error "Loading config "$config" error"

# Do the backups for the config sections
for section in "${sections[@]}"; do
    if [ $DEFAULT_SECTION == "$section" ]; then
        continue
    fi

    log_info "Starting backup for '$section'"

    do_backup "$section" "$rsnapshot_interval"

    log_info "Backup done for '$section'"
done
