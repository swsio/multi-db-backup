## Introduction

This will build a container for backing up multiple type of DB Servers

Currently backs up CouchDB, InfluxDB, MySQL, MongoDB, Postgres, Redis servers, MSSQL.

* dump to local filesystem or backup to S3 Compatible services
* select database user and password
* backup all databases
* choose to have an MD5 sum after backup for verification
* delete old backups after specific amount of time from filesystem or S3
* choose compression type (none, gz, bz, xz, zstd)
* connect to any container running on the same system of reachable by the container network
* select how often to run a dump
* select when to start the first dump, whether time of day or relative to container start time
* Execute script after backup for monitoring/alerting purposes

* This Container uses a standard [Alpine Linux base](https://github.com/alpinelinux/docker-alpine) custom enabled for PID 1 Init capabilities and running as non root user support for OpenShift/OKD


## Author

[Florian Fröhlich - SWS Computersysteme AG](florian.froehlich@sws.de)
## Table of Contents

- [Introduction](#introduction)
- [Authors](#authors)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Data-Volumes](#data-volumes)
  - [Environment Variables](#environment-variables)
- [Maintenance](#maintenance)
  - [Shell Access](#shell-access)
    - [Custom Scripts](#custom-scripts)

## Prerequisites

You must have a working DB server or container available for this to work properly, it does not provide server functionality!

## Installation

Automated builds of the image are available at [Quay.io](https://quay.io/repository/agileio/multi-db-backup)

### Currently available tags
- latest
- v1.1

### Get it from shell
```bash
docker pull quay.io/agileio/multi-db-backup:latest
```

### Quick Start

* Run desired image in your environment (Docker, OpenShift, K8S,...)
* Set various [environment variables](#environment-variables) to understand the capabiltiies of this image.
* Map [persistent storage](#data-volumes) for access to configuration and data files for backup.

> **NOTE**: If you are using this with a docker-compose file along with a seperate SQL container, take care not to set the variables to backup immediately, more so have it delay execution for a minute, otherwise you will get a failed first backup.

## Configuration

### Data-Volumes

The following directories are used for configuration and can be mapped for persistent storage.

| Directory                | Description                                                                        |
| ------------------------ | ---------------------------------------------------------------------------------- |
| `/backup`                | Backups                                                                            |
| `/tmp/backup`            | Temp space for backups                                                             |
| `/assets/custom-scripts` | *Optional* Put custom scripts in this directory to execute after backup operations |

### Environment Variables

The complete list of available options that can be used to customize your installation.

| Parameter              | Description                                                                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BACKUP_LOCATION`      | Backup to `FILESYSTEM` or `S3` compatible services like S3, Minio, Wasabi - Default `FILESYSTEM`                                                                                                   |
| `COMPRESSION`          | Use either Gzip `GZ`, Bzip2 `BZ`, XZip `XZ`, ZSTD `ZSTD` or none `NONE` - Default `GZ`                                                                                                             |
| `COMPRESSION_LEVEL`    | Numerical value of what level of compression to use, most allow `1` to `9` except for `ZSTD` which allows for `1` to `19` - Default `3`                                                           |
| `DB_TYPE`              | Type of DB Server to backup `couch` `influx` `mysql` `pgsql` `mongo` `redis` `sqlite3` `mssql`                                                                                                             |
| `DB_HOST`              | Server Hostname e.g. `mariadb`. For `sqlite3`, full path to DB file e.g. `/backup/db.sqlite3`                                                                                                      |
| `DB_NAME`              | Schema Name e.g. `database`                                                                                                                                                                        |
| `DB_USER`              | username for the database - use `root` to backup all MySQL of them.                                                                                                                                |
| `DB_PASS`              | (optional if DB doesn't require it) password for the database                                                                                                                                      |
| `DB_PORT`              | (optional) Set port to connect to DB_HOST. Defaults are provided                                                                                                                                   |
| `DB_DUMP_FREQ`         | How often to do a dump, in minutes. Defaults to 1440 minutes, or once per day.                                                                                                                     |
| `DB_DUMP_BEGIN`        | What time to do the first dump. Defaults to immediate. Must be in one of two formats                                                                                                               |
|                        | Absolute HHMM, e.g. `2330` or `0415`                                                                                                                                                               |
|                        | Relative +MM, i.e. how many minutes after starting the container, e.g. `+0` (immediate), `+10` (in 10 minutes), or `+90` in an hour and a half                                                     |
| `DB_CLEANUP_TIME`      | Value in minutes to delete old backups (only fired when dump freqency fires). 1440 would delete anything above 1 day old. You don't need to set this variable if you want to hold onto everything. |
| `DB_CLEANUP_TIME_S3`   | Value in complex format (time described by STRING) to delete old backups (only fired when dump freqency fires). "1 day" would delete everything older than 1 day, "2 hours" would delete everything older than 2 hours. You don't need to set this variable if you want to hold onto everything or perform manual cleanup. For more Information use [GNU docs](https://www.gnu.org/software/coreutils/manual/html_node/Relative-items-in-date-strings.html#Relative-items-in-date-strings) |
| `DEBUG_MODE`           | If set to `true`, print copious shell script messages to the container log. Otherwise only basic messages are printed.                                                                             |
| `EXTRA_OPTS`           | If you need to pass extra arguments to the backup command, add them here e.g. "--extra-command"                                                                                                    |
| `MD5`                  | Generate MD5 Sum in Directory, `TRUE` or `FALSE` - Default `TRUE`                                                                                                                                  |
| `PARALLEL_COMPRESSION` | Use multiple cores when compressing backups `TRUE` or `FALSE` - Default `TRUE`                                                                                                                     |
| `POST_SCRIPT`          | Fill this variable in with a command to execute post the script backing up                                                                                                                         |  |
| `SPLIT_DB`             | If using root as username and multiple DBs on system, set to TRUE to create Seperate DB Backups instead of all in one. - Default `TRUE`                                                           |

When using compression with MongoDB, only `GZ` compression is possible.

**Backing Up to S3 Compatible Services**

If `BACKUP_LOCATION` = `S3` then the following options are used.

| Parameter       | Description                                                                             |
| --------------- | --------------------------------------------------------------------------------------- |
| `S3_BUCKET`     | S3 Bucket name e.g. 'mybucket'                                                          |
| `S3_HOST`       | Hostname of S3 Server e.g "s3.amazonaws.com" - You can also include a port if necessary |
| `S3_KEY_ID`     | S3 Access Key                                                                              |
| `S3_KEY_SECRET` | S3 Secret Key                                                                           |
| `S3_PATH`       | S3 Pathname to save to e.g. '`backup`'                                                  |
| `S3_PROTOCOL`   | Use either `http` or `https` to access service - Default `https`                        |
| `S3_URI_STYLE`  | Choose either `VIRTUALHOST` or `PATH` style - Default `VIRTUALHOST`                     |

## Maintenance

Manual Backups can be performed by entering the container and typing `backup-now`
- Cleanup will also be performed if set

### Shell Access

For debugging and maintenance purposes you may want access the containers shell.

```bash
docker exec -it (whatever your container name is e.g.) db-backup bash
```

#### Custom Scripts

If you want to execute a custom script at the end of backup, you can drop bash scripts with the extension of `.sh` in this directory. See the following example to utilize delivered variables:

````bash
$ cat post-script.sh
#!/usr/bin/env bash

## Example Post Script
## $1=EXIT_CODE (After running backup routine)
## $2=DB_TYPE (Type of Backup)
## $3=DB_HOST (Backup Host)
## #4=DB_NAME (Name of Database backed up
## $5=DATE (Date of Backup)
## $6=TIME (Time of Backup)
## $7=BACKUP_FILENAME (Filename of Backup)
## $8=FILESIZE (Filesize of backup)
## $9=MD5_RESULT (MD5Sum if enabled)

echo "${1} ${2} Backup Completed on ${3} for ${4} on ${5} ${6}. Filename: ${7} Size: ${8} bytes MD5: ${9}"
````

Outputs the following on the console:

`0 mysql Backup Completed on example-db for example on 2020-04-22 05:19:10. Filename: mysql_example_example-db_20200422-051910.sql.bz2 Size: 7795 bytes MD5: 952fbaafa30437494fdf3989a662cd40`

If you wish to change the size value from bytes to megabytes set environment variable `SIZE_VALUE=megabytes`

#### NOTE
You can only use features available in the container image an running as non root with unprivileged capabilities 
