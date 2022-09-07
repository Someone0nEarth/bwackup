#!/bin/bash

DIR_NAME=$(dirname "$0")

source "$DIR_NAME"/../common/global_flags.sh
source "$DIR_NAME"/../common/log.sh
source "$DIR_NAME"/../common/mount.sh
source "$DIR_NAME"/../common/init-file-parser.sh

declare SCRIPT_NAME="$0"
declare config="$DIR_NAME/../etc/bwackup_rs_crypt_sshfs.conf"
declare -i loglevel=LOG_LEVEL_INFO

mount_or_unmount() {
    local mount_or_unmount=$1
    local section=$2

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

    if [ $mount_or_unmount == "mount" ]; then
        ensure_sshfs_is_mounted "$sshfs_identity_file" "$sshfs_mountpoint" "$sshfs_url" "$sshfs_url_port"
        ensure_crypt_is_mounted "$crypt_luks_file" "$crypt_partition" "$crypt_key" "$crypt_mountpoint"
    elif [ $mount_or_unmount == "unmount" ]; then
        unmount_crypt "$crypt_mountpoint" "$crypt_partition"
        unmount_sshfs "$sshfs_mountpoint"
    else
        syslog_and_exit_with_error "Should be mount or unmount: '$mount_or_unmount'"
    fi
}

show_help() {
    echo " Usage: $SCRIPT_NAME [options] mount|unmount"
    echo " Options:"
    echo "  -h  | --help      - Show help (this)"
    echo "  -t  | --test      - No logging to syslog."
    echo "  -c  | --config    - Use the given config instead of the default one '$config'"
    echo "  -ll | --loglevel  - Set the log level of THIS script (not the ones of the used commands): 0 (debug), 1 (info), 2 (warning), 3 (error) or 4 (off)."
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
        GLOBAL_SYSLOG="false"
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

[ "$1" == "" ] && syslog_and_exit_with_error "No given command: '$1'"

mount_or_unmount="$1"

if [ $mount_or_unmount != 'mount' ] && [ $mount_or_unmount != 'unmount' ]; then
    syslog_and_exit_with_error "Not mount or unmount: '$mount_or_unmount'"
fi

exit_if_a_cmd_is_missing

set_log_level $loglevel

# Load config
keys_without_section_warning=false
process_ini_file "$config" || syslog_and_exit_with_error "Loading config "$config" error"

for section in "${sections[@]}"; do
    if [ $DEFAULT_SECTION == "$section" ]; then
        continue
    fi

    log_info "Starting $mount_or_unmount for '$section'"

    mount_or_unmount "$mount_or_unmount" "$section"

    log_info ".. $mount_or_unmount done for '$section'"
done
