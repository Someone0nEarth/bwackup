#!/bin/bash

source "$(dirname "$0")/../common/global_flags.sh"
source "$(dirname "$0")/../common/global_flags.sh"

# Commands used by this script
add_cmds_for_failing_fast_check "docker" "docker-compose"

backup_docker_compose_services_data() {
    # Inspired by: https://gist.github.com/pirate/265e19a8a768a48cf12834ec87fb0eed

    current_builtin_options="$-"
    current_IFS="$IFS"

    set +o errexit
    set -o errtrace
    set -o nounset
    set -o pipefail
    IFS=$'\n'

    project_dir=$1
    backup_dir=$2

    directory_path_has_trailing_slash "$project_dir" &&
        syslog_and_exit_with_error "Docker-compose project directory has trailing slash.. please remove it: '$project_dir'"

    directory_path_has_trailing_slash "$backup_dir" &&
        syslog_and_exit_with_error "Docker-compose backup directory has trailing slash.. please remove it: '$backup_dir'"

    ! is_an_existing_directory_and_not_root_dir "$backup_dir" &&
        syslog_and_exit_with_error "Backup directory is not existing (or it is root '/'): '$backup_dir'"

    ! is_an_existing_directory_and_not_root_dir "$project_dir" &&
        syslog_and_exit_with_error "'docker_compose_path' not existing (or it is root '/'): '$project_dir'"

    ! [ -f "$project_dir/docker-compose.yml" ] &&
        syslog_and_exit_with_error "Could not find a docker-compose.yml file in '$project_dir'"

    log_debug "Found docker-compose config at $project_dir/docker-compose.yml"

    # Backup the docker-compose project,named and unnamed volumes, config, logs.

    project_name=$(basename "$project_dir")
    project_backup_dir="$backup_dir/$project_name"

    # Source any needed environment variables
    [ -f "$project_dir/docker-compose.env" ] && source "$project_dir/docker-compose.env"
    [ -f "$project_dir/.env" ] && source "$project_dir/.env"

    log_debug "Backing up '$project_name' project to '$project_backup_dir'"
    rm -rf "$project_backup_dir"
    mkdir -p "$project_backup_dir"

    log_debug "Saving docker-compose.yml config"
    cp "$project_dir/docker-compose.yml" "$project_backup_dir/docker-compose.yml"

    docker-compose --no-ansi -f "$project_dir/docker-compose.yml" stop

    for service_name in $(docker-compose -f $project_dir/docker-compose.yml config --services); do
        container_id=$(docker-compose -f $project_dir/docker-compose.yml ps -q "$service_name")

        service_dir="$project_backup_dir/$service_name"
        log_debug "Backing up ${project_name}__${service_name} to '$service_dir'..."
        mkdir -p "$service_dir"

        if [[ -z "$container_id" ]]; then
            log_warn "'$service_name' has no container yet (has it been started at least once?)."
            continue
        fi

        # save config
        log_debug "Saving container config to '$service_dir/config.json'"
        docker inspect "$container_id" >"$service_dir/config.json"

        # save logs
        log_debug "Saving stdout/stderr logs to '$service_dir/docker.{out,err}'"
        docker logs "$container_id" >"$service_dir/docker.out" 2>"$service_dir/docker.err"

        # save data volumes
        mkdir -p "$service_dir/volumes"
        for source in $(docker inspect -f '{{range .Mounts}}{{println .Source}}{{end}}' "$container_id"); do
            volume_dir="$service_dir/volumes$source"
            log_debug "Saving $source volume to '$service_dir/volumes$source'"
            mkdir -p "$(dirname "$volume_dir")"
            cp -a -r "$source" "$volume_dir"
        done
    done

    log_debug "Finished Backing up '$project_name' to '$project_backup_dir'"

    docker-compose --no-ansi -f "$project_dir/docker-compose.yml" start

    #Restore bash builtin option
    set "+$-"
    set "-$current_builtin_options"
    IFS="$current_IFS"
}
