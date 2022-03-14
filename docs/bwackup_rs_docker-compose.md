# Backup of docker-compose projects with a minimal downtime

Will stop, copy data and start each configured docker-compose project in the configuration file `etc/bwackup_rs_docker-compose.conf`. And finally run the configured `rsnapshot_conf`.

Following data will be copied:

* The docker-compose.conf file
* For every service:
 * Data volumes
 * Docker logs
 * docker config (via docker inspect)

 General informations on bwackup are [here](../README.md)

## Usage

bwackup/bin:

```
Usage: ./bwackup_rs_docker-compose.sh [options] rsnapshot_interval
 Options:
  -h  | --help - Show help (this)
  -t  | --test - Will stop, copy data and start docker-compose projects, but run rsnapshot in test-mode (won't touch anything) and no logging to syslog.
  -ts | --timestamps - Will log to console with timestamps.
  -c  | --config - Use the given config instead of the default one './../etc/bwackup_rs_docker-compose.conf'
  -ll | --loglevel - Set the log level of THIS script (not the ones of the used commands): 0 (debug), 1 (info), 2 (warning), 3 (error) or 4 (off).
```

## /etc/cron.d/rsnapshot

Adding the following to the top of the file:

```
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
```

Example cron.d/rsnapshot entries:

```
55 03           * * *           root    /opt/bwackup/bin/bwackup_rs_docker-compose.sh -ts daily
50 03           * * 7           root    /opt/bwackup/bin/bwackup_rs_docker-compose.sh -ts weekly
45 03           1 * *           root    /opt/bwackup/bin/bwackup_rs_docker-compose.sh -ts monthly
```

## Configuration

### Important: The data will be copied to sub directories of `docker_compose_backup_dir`. These sub directories will be DELETED and recreated when  this script will be executed (for a clean base).

etc/bwackup_rs_docker-compose.conf

```
rsnapshot_conf=/etc/rsnapshot_bwackup_docker-compose.conf
docker_compose_backup_dir=/path/to/docker-compose/backup/dir/ # The directory should be the one which is backup by your `rsnapshot_conf` 

[traefik]
docker_compose_path=/path/to/traefik-docker-compose-directory

[homeassistant]
docker_compose_path=/path/to/homeassistant-docker-compose-directory
```

## Notes, hints etc.

Thanks to "pirate" for his nice docker-compose backup script: https://gist.github.com/pirate/265e19a8a768a48cf12834ec87fb0eed
