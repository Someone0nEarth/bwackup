#!/bin/bash

DIR_NAME=$(dirname "$0")

source "$DIR_NAME"/../common/global_flags.sh
source "$DIR_NAME"/../common/log.sh
source "$DIR_NAME"/../common/backup.sh
source "$DIR_NAME"/../common/docker-compose.sh
source "$DIR_NAME"/../common/init-file-parser.sh

declare config="$DIR_NAME/../etc/bwackup_rs_docker-compose.conf"

backup_docker_compose_services_data_for_section() {
    local section="$1"
    local backup_dir="$2"

    local docker_compose_path
    docker_compose_path=$(get_value $section 'docker_compose_path')

    is_an_existing_directory_and_not_root_dir "$docker_compose_path" ||
        syslog_and_exit_with_error "'docker_compose_path' is not existing: '$docker_compose_path'"

    docker_compose_path=$(remove_trailing_slash "$docker_compose_path")

    backup_docker_compose_services_data "$docker_compose_path" "$backup_dir"
}

show_help() {
    echo " Usage: $SCRIPT_NAME [options] rsnapshot_interval"
    echo " Options:"
    echo "  -h  | --help - Show help (this)"
    echo "  -t  | --test - Will stop, copy data and start docker-compose projects, but run rsnapshot in test-mode (won't touch anything) and no logging to syslog."
    echo "  -ts | --timestamps - Will log to console with timestamps."
    echo "  -c  | --config - Use the given config instead of the default one '$config'"
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
    -?*)
        syslog_and_exit_with_error "Unknown option: '$1'"
        ;;
    *) # Default case: No more options, so break out of the loop.
        break ;;
    esac

    shift
done

rsnapshot_interval="$1"
[ "$rsnapshot_interval" == "" ] && syslog_and_exit_with_error "No given rsnapshot interval: '$1'"

[ "$2" != "" ] && syslog_and_exit_with_error "Unexpected argument '$2'"

exit_if_a_cmd_is_missing

# Load config
keys_without_section_warning=false
process_ini_file "$config" || syslog_and_exit_with_error "Loading config $config error"

docker_compose_backup_dir=$(get_value "$DEFAULT_SECTION" 'docker_compose_backup_dir')
docker_compose_backup_dir=$(remove_trailing_slash "$docker_compose_backup_dir")

is_an_existing_directory_and_not_root_dir "$docker_compose_backup_dir" ||
    syslog_and_exit_with_error "Docker-Compose backup directory is not existing (or it is root '/'): '$docker_compose_backup_dir'"

rsnapshot_conf=$(get_value "$DEFAULT_SECTION" 'rsnapshot_conf')

[ -f "$rsnapshot_conf" ] || syslog_and_exit_with_error "rsnapshot config is not existing: '$rsnapshot_conf'"

# Do the extracting of the docker-compose containers
for section in "${sections[@]}"; do
    if [ $DEFAULT_SECTION == "$section" ]; then
        continue
    fi

    log_info "Starting to backup the docker-compose data for '$section'"

    backup_docker_compose_services_data_for_section "$section" "$docker_compose_backup_dir"

    log_info "Backup done for '$section'"
done

do_rsnapshot $rsnapshot_conf "$rsnapshot_interval"
