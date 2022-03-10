# bwackup - a BASH Wrapper for Backuping

[bwackup](https://github.com/Someone0nEarth/bwackup) is small BASH "framework" for a comfy backuping of data. Currently supporting rsnapshot backups to an encrypted remote LUKS file via SSHFS and rsnapshot backups of docker-compose projects data with a minimal downtime.

## Encrypted backup on a remote host

The basic idea was, to have a solution for a secure backup on a remote host. Being simple, reliable, using standard tools and the encryption key will never exposed to the backup host.

Using rsnapshot, sshfs, cryptsetup, mount, umount, findmnt, logger.

Have a look [here](docs/bwackup_rs_crypt_sshfs.md) for more information, usage and stuff.

## Backup of docker-compose projects with minimal downtime

The goal here was, to backup data of docker-compose projects with less redundant configurations and a minimal downtime for each project. Information of the docker-compose file itself is used for copying the data. A minimal downtime for each project is achieved by stopping, copying data and starting every configured project on his own. When all projects are done, rsnapshot is used to backup the copied data of all projects.

Using rsnapshot, docker, docker-compose, logger.

Have a look [here](docs/bwackup_rs_docker-compose.md) for more information, usage and stuff.

## Installation

bwackup should run on every up-to-date Linux with BASH. It is developed and tested on Ubuntu Server 20.04.

Just clone this repo or download the archive and extract it. A good place would be `/opt/bwackup` . 

Keep in mind to set the right rights for the directoy. bwackup scripts will be usual executed by `root` and shouldn't be accessible by others. So the following should be done as root / with sudo:

```
chmod 750 /opt/bwackup

chown root:root /opt/bwackup
```

## Structure

```
bwackup
 \_ bin    - The bwackup scripts
 \_ common - The "framework" files
 \_ docs   - The docs for the bwackup scripts
 \_ etc    - The configuration files for the bwackup scripts
```

## Feedback

Have questions, suggestions or improvements? Just contact me or doing a pull request!

Have fun,

  Someone0nEarth
