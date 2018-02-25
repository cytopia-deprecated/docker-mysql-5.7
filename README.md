# MySQL 5.7 Docker

<small>**Latest build:** 2017-09-28</small>

[![Build Status](https://travis-ci.org/cytopia/docker-mysql-5.7.svg?branch=master)](https://travis-ci.org/cytopia/docker-mysql-5.7) [![](https://images.microbadger.com/badges/version/cytopia/mysql-5.7.svg)](https://microbadger.com/images/cytopia/mysql-5.7 "mysql-5.7") [![](https://images.microbadger.com/badges/image/cytopia/mysql-5.7.svg)](https://microbadger.com/images/cytopia/mysql-5.7 "mysql-5.7") [![](https://images.microbadger.com/badges/license/cytopia/mysql-5.7.svg)](https://microbadger.com/images/cytopia/mysql-5.7 "mysql-5.7")

[![cytopia/mysql-5.7](http://dockeri.co/image/cytopia/mysql-5.7)](https://hub.docker.com/r/cytopia/mysql-5.7/)

**[mysql 5.5](https://github.com/cytopia/docker-mysql-5.5) | [mysql 5.6](https://github.com/cytopia/docker-mysql-5.6) | mysql 5.7 | [mysql 8.0](https://github.com/cytopia/docker-mysql-8.0) | [mariadb 5.5](https://github.com/cytopia/docker-mariadb-5.5) | [mariadb 10.0](https://github.com/cytopia/docker-mariadb-10.0) | [mariadb 10.1](https://github.com/cytopia/docker-mariadb-10.1) | [mariadb 10.2](https://github.com/cytopia/docker-mariadb-10.2) | [mariadb 10.3](https://github.com/cytopia/docker-mariadb-10.3) | [percona 5.5](https://github.com/cytopia/docker-percona-5.5) | [percona 5.6](https://github.com/cytopia/docker-percona-5.6) | [percona 5.7](https://github.com/cytopia/docker-percona-5.7)**

----

**MySQL 5.7 Docker on CentOS 7**

[![Devilbox](https://raw.githubusercontent.com/cytopia/devilbox/master/.devilbox/www/htdocs/assets/img/devilbox_80.png)](https://github.com/cytopia/devilbox)

<sub>This docker image is part of the **[devilbox](https://github.com/cytopia/devilbox)**</sub>

----

## Options

### Environmental variables

#### Required environmental variables

| Variable | Type | Description |
|----------|------|-------------|
| MYSQL_ROOT_PASSWORD | string | MySQL root user password of either existing database or in case it does not exist it will initialize the new database with the given password. |

#### Optional environmental variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | `0` | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | `UTC` | Set docker OS timezone.<br/>Example: `Europe/Berlin` |
| MYSQL_SOCKET_DIR | string | `/var/sock/mysqld` | Path inside the docker to the socket directory.<br/><br/>Used to separate socket directory from data directory in order to mount it to the docker host or other docker containers.<br/><br/>Mount this directory to a PHP container and be able to use `mysqli_connect` with `localhost`. |
| MYSQL_GENERAL_LOG | bool | `0` | Turn on or off general logging<br/>Corresponds to mysql config: `general-log`<br/>Value: `0` or `1` |

### Default mount points

| Docker | Description |
|--------|-------------|
| /var/lib/mysql | MySQL data dir |
| /var/log/mysql | MySQL log dir |
| /var/sock/mysqld | MySQL socket dir |
| /etc/mysql/conf.d | MySQL configuration directory (used to overwrite MySQL config) |
| /etc/mysql/docker-default.d | MySQL configuration directory (used to overwrite MySQL config) |

### Default ports

| Docker | Description |
|--------|-------------|
| 3306   | MySQL listening Port |

## Usage

**1. Listen on loopback interface only**

```bash
$ docker run -i \
    -p 127.0.0.1:3306:3306 \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -t cytopia/mysql-5.7

# Access MySQL from your host computer
$ mysql --user=root --password=my-secret-pw --host=127.0.0.1 -e 'show databases;'
```

**2. Enable logging**

Enable logging and mount the log directory to your host to `~tmp/mysql-log`
```bash
$ docker run -i \
    -p 127.0.0.1:3306:3306 \
    -v ~tmp/mysql-log:/var/log/mysql \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -e MYSQL_GENERAL_LOG=1 \
    -t cytopia/mysql-5.7

# Access MySQL from your host computer
$ mysql --user=root --password=my-secret-pw --host=127.0.0.1 -e 'show databases;'
```

**3. Mount MySQL socket to the host**

Use MySQL socket for `localhost` connections through the socket. No need to expose the MySQL port to the host in this case.
```bash
$ docker run -i \
    -v ~tmp/mysql-sock:/var/sock/mysqld \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -t cytopia/mysql-5.7

# Access MySQL from your host computer via socket
$ mysql --user=root --password=my-secret-pw --socket=/var/sock/mysqld/mysqld.sock -e 'show databases;'
```

**4. Overwrite configuration**

You can also add any configuration settings prior startup to MySQL.
```bash
# Create local config with buffer overwrite
$ printf "[mysqld]\n%s\n" "key_buffer = 500M" > ~/tmp/mysqld_config/buffer.cnf

$ docker run -i \
    -p 127.0.0.1:3306:3306 \
    -v ~/tmp/mysqld_config:/etc/mysql/conf.d \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -t cytopia/mysql-5.7
```

## MySQL Configuration overview

Configuration files inside this docker are read in the following order:

| Order | File | Description |
|-------|------|-------------|
| 1     | `/etc/my.cnf` | Operating system default |
| 2     | `/etc/mysql/conf.d/` | Custom configuration (level 1). Can be mounted to provide custom `*.cnf` files which can overwrite anything of the above. (used by the devilbox for its base configuration) |
| 3     | `/etc/mysql/docker-default.d/*.cnf` | Custom configuration (level 2). Can be mounted to provide custom `*.cnf` files which can overwrite anything of the above. (used by the devilbox to allow custom user-defined configuration overwriting the default devilbox settings. |


## Modules

**[Version]**

mysqld  Ver 5.7.19 for Linux on x86_64 (MySQL Community Server (GPL))
