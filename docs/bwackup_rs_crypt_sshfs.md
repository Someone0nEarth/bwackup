# Rsnapshot wrapper for encrypted LUKS SSHFS Mounts in BASH

Will mount an encrypted LUKS file via SSHFS, run rsnapshot and unmount for every configured section in the configuration file `etc/bwackup_rs_crypt_sshfs.conf`

If the LUKS file is already mounted, the script WILL NOT unmount it when done.

General informations on bwackup are [here](../README.md)
## Usage

bwackup/bin:

```
Usage: ./bwackup_rs_crypt_sshfs.sh [options] rsnapshot_interval
 Options:
  -h  | --help - Show help (this)
  -t  | --test - Will mount/unmout but run rsnapshot in test-mode (won't touch anything) and no logging to syslog.
  -ts | --timestamps - Will log to console with timestamps.
  -c  | --config - Use the given config instead of the default one './../etc/bwackup_rs_crypt_sshfs.conf'
  -ll | --loglevel - Set the log level of THIS script (not the ones of the used commands): 0 (debug), 1 (info), 2 (warning), 3 (error) or 4 (off).
```

## /etc/cron.d/rsnapshot

Adding the following to the top of the file (if you wanna use cron.d):

```
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
```

Example cron.d/rsnapshot entries:

```
55 01           * * *           root    /opt/bwackup/bin/bwackup_rs_crypt_sshfs.sh -ts daily
50 01           * * 7           root    /opt/bwackup/bin/bwackup_rs_crypt_sshfs.sh -ts weekly
45 01           1 * *           root    /opt/bwackup/bin/bwackup_rs_crypt_sshfs.sh -ts monthly
```

## Configuration Example

etc/bwackup_rs_crypt_sshfs.conf

```
[Backup to crypt sshfs mount 1]
sshfs_identity_file=/opt/bwackup/.ssh/remote_backup_1
sshfs_url=your_backup_user@example.com:/backup/remote_backup/data
sshfs_mountpoint=/mnt/remote_backup_1

crypt_luks_file=/mnt/remote_backup_1/backup.luks
crypt_partition=backup-partition_1
crypt_key=/opt/bwackup/luks/backup_1.key
crypt_mountpoint=/mnt/remote_backup_1_data/

rsnapshot_conf=/etc/rsnapshot_bwackup_to_1.conf

[Backup to crypt sshfs mount 2]
sshfs_identity_file=/opt/bwackup/.ssh/remote_backup_2
sshfs_url=your_backup_user@other-example.com:backup/remote_backup/data
sshfs_url_port=12345
sshfs_mountpoint=/mnt/remote_backup_2

crypt_luks_file=/mnt/remote_backup_2/backup.luks
crypt_partition=backup_2-partition
crypt_key=/opt/bwackup/luks/backup_2.key
crypt_mountpoint=/mnt/remote_backup_2_data/

rsnapshot_conf=/etc/rsnapshot_bwackup_to_2.conf
```

## Notes, hints etc.

Thanks to the people behind https://github.com/DevelopersToolbox/ini-file-parser for the BASH INI-Parser!

### Nice and short guide for encrypted LUKS via SSHS

<https://ruderich.org/simon/notes/encrypted-remote-backups>
