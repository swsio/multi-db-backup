## Introduction

This will build a container for backing up multiple type of DB Servers

Currently backs up CouchDB, InfluxDB, MySQL, MongoDB, Postgres, Redis servers, MSSQL.

* dump to local filesystem or backup to S3 Compatible services
* select database user and password
* backup all databases
* choose to have an MD5 sum after backup for verification
* delete old backups after specific amount of time
* choose compression type (none, gz, bz, xz, zstd)
* connect to any container running on the same system
* select how often to run a dump
* select when to start the first dump, whether time of day or relative to container start time
* Execute script after backup for monitoring/alerting purposes

* This Container uses a [customized Alpine Linux base](https://quay.io/repository/agileio/alpine-base-s6) which includes [s6 overlay](https://github.com/just-containers/s6-overlay) enabled for PID 1 Init capabilities


## Authors

Florian Fröhlich - SWS Computersysteme AG
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

Automated builds of the image are available

```bash
docker pull quay.io/agileio/multi-db-backup:latest
```

### Quick Start

* The quickest way to get started is using [docker-compose](https://docs.docker.com/compose/). See the examples folder for a working [docker-compose.yml](examples/docker-compose.yml) that can be modified for development or production use.

* Set various [environment variables](#environment-variables) to understand the capabiltiies of this image.
* Map [persistent storage](#data-volumes) for access to configuration and data files for backup.

> **NOTE**: If you are using this with a docker-compose file along with a seperate SQL container, take care not to set the variables to backup immediately, more so have it delay execution for a minute, otherwise you will get a failed first backup.

## Configuration

### Data-Volumes

The following directories are used for configuration and can be mapped for persistent storage.

| Directory                | Description                                                                        |
| ------------------------ | ---------------------------------------------------------------------------------- |
| `/backup`                | Backups                                                                            |
| `/assets/custom-scripts` | *Optional* Put custom scripts in this directory to execute after backup operations |

### Environment Variables

Along with the Environment Variables from the [Base image](https://github.com/swsio/alpine-base-s6), below is the complete list of available options that can be used to customize your installation.

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
| `DEBUG_MODE`           | If set to `true`, print copious shell script messages to the container log. Otherwise only basic messages are printed.                                                                             |
| `EXTRA_OPTS`           | If you need to pass extra arguments to the backup command, add them here e.g. "--extra-command"                                                                                                    |
| `MD5`                  | Generate MD5 Sum in Directory, `TRUE` or `FALSE` - Default `TRUE`                                                                                                                                  |
| `PARALLEL_COMPRESSION` | Use multiple cores when compressing backups `TRUE` or `FALSE` - Default `TRUE`                                                                                                                     |
| `POST_SCRIPT`          | Fill this variable in with a command to execute post the script backing up                                                                                                                         |  |
| `SPLIT_DB`             | If using root as username and multiple DBs on system, set to TRUE to create Seperate DB Backups instead of all in one. - Default `FALSE`                                                           |

When using compression with MongoDB, only `GZ` compression is possible.

**Backing Up to S3 Compatible Services**

If `BACKUP_LOCATION` = `S3` then the following options are used.

| Parameter       | Description                                                                             |
| --------------- | --------------------------------------------------------------------------------------- |
| `S3_BUCKET`     | S3 Bucket name e.g. 'mybucket'                                                          |
| `S3_HOST`       | Hostname of S3 Server e.g "s3.amazonaws.com" - You can also include a port if necessary |
| `S3_KEY_ID`     | S3 Key ID                                                                               |
| `S3_KEY_SECRET` | S3 Key Secret                                                                           |
| `S3_PATH`       | S3 Pathname to save to e.g. '`backup`'                                                  |
| `S3_PROTOCOL`   | Use either `http` or `https` to access service - Default `https`                        |
| `S3_URI_STYLE`  | Choose either `VIRTUALHOST` or `PATH` style - Default `VIRTUALHOST`                     |

## Maintenance

Manual Backups can be performed by entering the container and typing `backup-now`

### Shell Access

For debugging and maintenance purposes you may want access the containers shell.

```bash
docker exec -it (whatever your container name is e.g.) db-backup bash
```

#### Custom Scripts

If you want to execute a custom script at the end of backup, you can drop bash scripts with the extension of `.sh` in this directory. See the following example to utilize:

````bash
$ cat post-script.sh
##!/bin/bash

# #### Example Post Script
# #### $1=EXIT_CODE (After running backup routine)
# #### $2=DB_TYPE (Type of Backup)
# #### $3=DB_HOST (Backup Host)
# #### #4=DB_NAME (Name of Database backed up
# #### $5=DATE (Date of Backup)
# ####  $6=TIME (Time of Backup)
# ####  $7=BACKUP_FILENAME (Filename of Backup)
# ####  $8=FILESIZE (Filesize of backup)
# ####  $9=MD5_RESULT (MD5Sum if enabled)

echo "${1} ${2} Backup Completed on ${3} for ${4} on ${5} ${6}. Filename: ${7} Size: ${8} bytes MD5: ${9}"
````

Outputs the following on the console:

`0 mysql Backup Completed on example-db for example on 2020-04-22 05:19:10. Filename: mysql_example_example-db_20200422-051910.sql.bz2 Size: 7795 bytes MD5: 952fbaafa30437494fdf3989a662cd40`

If you wish to change the size value from bytes to megabytes set environment variable `SIZE_VALUE=megabytes`
