#!/bin/bash

source "$(dirname "$0")/../common/global_flags.sh"

# Commands used by this script
add_cmds_for_failing_fast_check "sshfs" "cryptsetup" "mount" "umount" "findmnt"

mount_sshfs() {
    local identity_file="$1"
    local mountpoint="$2"
    local url="$3"
    local url_port=''
    local url_port_option=''

    if [[ "$4" != '' ]]; then
        url_port="$4"
        url_port_option="-p"
    fi

    [ -f "$identity_file" ] || syslog_and_exit_with_error "sshfs mount: identity_file not existing: '$identity_file'"
    [ -d "$mountpoint" ] || syslog_and_exit_with_error "sshfs mount: mountpoint not existing: '$mountpoint'"

    log_debug "mounting sshfs with '$identity_file' '$url' '$mountpoint' '$url_port_option' '$url_port'"

    sshfs -o IdentityFile="$identity_file" "$url" "$mountpoint" $url_port_option $url_port || syslog_and_exit_with_error "sshfs mount failed with $identity_file $url $url_port $mountpoint"
}

ensure_sshfs_is_mounted() {
    local identity_file="$1"
    local mountpoint="$2"
    local url="$3"
    local url_port

    if [[ "$4" != '' ]]; then
        url_port="$4"
    fi

    if ! is_mounted "$mountpoint"; then
        mount_sshfs "$identity_file" "$mountpoint" "$url" "$url_port"
        return 1
    fi

    log_warn "sshfs mountpoint '$mountpoint' is already mounted, so not mounting it."

    return 0
}

mount_crypt() {
    local luks_file="$1"
    local partition="$2"
    local key="$3"
    local mountpoint="$4"

    log_debug "mounting crypt with '$luks_file' '$partition' '$key $mountpoint'"

    cryptsetup luksOpen "$luks_file" "$partition" --key-file "$key" || syslog_and_exit_with_error "crypt_setup luksOpen failed with '$luks_file' '$partition' '$key'"
    mount "/dev/mapper/$partition" "$mountpoint" || syslog_and_exit_with_error "crypt mount failed with '$partition' '$mountpoint'"
}

ensure_crypt_is_mounted() {
    local luks_file="$1"
    local partition="$2"
    local key="$3"
    local mountpoint="$4"

    if ! is_mounted "$mountpoint"; then
        mount_crypt "$luks_file" "$partition" "$key" "$mountpoint"
        return 1
    fi

    log_warn "crypt mountpoint '$mountpoint' is already mounted, so not mounting it."

    return 0
}

unmount_sshfs() {
    local mountpoint="$1"

    log_debug "unmouting sshfs '$mountpoint'"

    umount "$mountpoint" || syslog_and_exit_with_error "unmout failed for '$mountpoint'"
}

unmount_crypt() {
    local mountpoint="$1"
    local partition="$2"

    log_debug "unmouting crypt '$mountpoint' '$partition'"

    umount "$mountpoint" || syslog_and_exit_with_error "unmout failed with '$mountpoint'"
    cryptsetup close "$partition" || syslog_and_exit_with_error "cryptsetup close failed with '$partition'"
}

umount_all() {
    local crypt_mountpoint="$1"
    local crypt_partition="$2"
    local sshfs_mountpoint="$3"

    log_debug "unmouting all with '$crypt_mountpoint' '$crypt_partition' '$sshfs_mountpoint'"

    unmount_crypt "$crypt_mountpoint" "$crypt_partition"
    unmount_sshfs "$sshfs_mountpoint"
}

is_mounted() {
    local mount_point="$1"

    is_mounted=$(findmnt "$mount_point")

    [ "$is_mounted" != "" ] && return 0

    return 1
}
