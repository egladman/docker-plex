# docker-plex

A fork of [linuxserver/docker-plex](https://github.com/linuxserver/docker-plex)
with support for programmatically patching settings. This started out as a
[PR](https://github.com/linuxserver/docker-plex/pull/293).

## Quickstart

The image is automatically built weekly.

### [ghcr.io](https://github.com/egladman/docker-plex/pkgs/container/plex)
```
docker pull ghcr.io/egladman/plex:latest
```

### [docker.io](https://hub.docker.com/r/egladman/plex)
```
docker pull docker.io/egladman/plex:latest
```

## Build

```
make image
```

## Environment Variables

### Runtime

| Variable           | Description                                                                                                                   | Default               |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| `DEBUG`            | Print debug logs for 70-plex-modify-preferences                                                                               | `0`                   |
| `ALLOWED_NETWORKS` | A comma seperated list of IP addresses or IP/netmasks entries for networks that are considered to be local                    |                       |
| `NOAUTH_NETWORKS`  | A comma seperated list of IP addresses or IP/netmasks entries for networks that are allowed to access Plex without logging in |                       |
| `ADVERTISE_URLS`   | A comma seperated list of custom server access URLs                                                                           |                       |
| `SERVER_NAME`      | Friendly name used to indentify server on clients                                                                             |                       |
| `PUID`             | UserID                                                                                                                        |                       |
| `GUID`             | GroupID                                                                                                                       |                       |
| `VERSION`          | Plex version                                                                                                                  | `docker`              |
| `PLEX_CLAIM`       |                                                                                                                               |                       |

#### `VERSION`

- `docker`: Let Docker handle the Plex Version, we keep our Dockerhub Endpoint up to date with the latest public builds. This is the same as leaving this setting out of your create command.
- `latest`: will update plex to the latest version available that you are entitled to.
- `public`: will update plexpass users to the latest public version, useful for plexpass users that don't want to be on the bleeding edge but still want the latest public updates.
- `<specific-version>`: will select a specific version (eg 0.9.12.4.1192-9a47d21) of plex to install, note you cannot use this to access plexpass versions if you do not have plexpass.

## Example

### Docker Compose

An advanced example intended to be used in combination with a reverse proxy, and custom tld.

```
---
version: "3.9"
services:

  plex:
    image: ghcr.io/egladman/plex:x86_64-latest
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
      - TZ=$TZ
      - ALLOWED_NETWORKS=192.168.1.0/24,172.28.0.0/16
      - NOAUTH_NETWORKS=192.168.1.0/24,172.28.0.0/16
      - ADVERTISE_URLS=https://plex.custom.tld,http://192.168.1.34:32400
      - SERVER_NAME=
      - PLEX_CLAIM=
    volumes:
      - /path/to/library:/config
      - /path/to/tvseries:/tv
      - /path/to/movies:/movies
      - /path/to/trancsode:/transcode
    ports:
      - 32400:32400
    networks:
      plex_network:

networks:
  plex_network:
    ipam:
      driver: default
      config:
        - subnet: "172.28.0.0/16"
```

*Note:* `192.168.1.34:32400` is the ip address of the docker host
