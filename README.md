# MultiPaper Docker

[![Build from Releases](https://github.com/noevidenz/multipaper-docker/actions/workflows/build-releases.yaml/badge.svg?branch=main)](https://github.com/noevidenz/multipaper-docker/actions/workflows/build-releases.yaml)
[![Build Image (edge)](https://github.com/noevidenz/multipaper-docker/actions/workflows/build-images.yaml/badge.svg)](https://github.com/noevidenz/multipaper-docker/actions/workflows/build-images.yaml)

[MultiPaper Docker](https://github.com/noevidenz/multipaper-docker) automatically compiles the latest commit from the official MultiPaper repository and publishes the images to GitHub Container Registry.

## Images

- [ghcr.io/munenick/multipaper-master](https://github.com/MuNeNICK/multipaper-docker/pkgs/container/multipaper-master)
- [ghcr.io/munenick/multipaper](https://github.com/MuNeNICK/multipaper-docker/pkgs/container/multipaper)

## Version Tags

_All versions are built nightly at midnight AEST._

|   Tag    | Supported Architectures    | Description                                                                                                                                                                                                                          |
|:--------:|:---------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|  `edge`  | `amd64`, `arm64`, `arm/v7` | Built nightly using the latest commit on `main` from the official [MultiPaper](https://github.com/MultiPaper/MultiPaper) repository <br/><br/> _**Warning:** This version is not built from an official release and may be unstable_ |
|  `1.20`  | `amd64`, `arm64`, `arm/v7` | Built using the latest release from the 1.20 family                                                                                                                                                                                   |
|  `1.19`  | `amd64`, `arm64`, `arm/v7` | Built using the latest release from the 1.19 family                                                                                                                                                                                   |
|  `1.18`  | `amd64`, `arm64`, `arm/v7` | Built using the latest release from the 1.18 family <br/><br/>_**Warning:** This version is outdated and may not contain the latest security and stability features_                                                                 |
| `latest` | `amd64`, `arm64`, `arm/v7` | An alias for the latest available version. This tag is automatically assigned to the most recent Minecraft version release.                                                                                                           |

## Usage

### Directories

The MultiPaper-Master service requires a directory be mounted to `/app`. This is the directory where all shared files will be stored, including world files.

Create a directory (eg `master-data`) and mount it to the `/app` directory in the MultiPaper-Master container. (See the examples below)

If you have existing world files you want to use, place them in this directory before starting the MultiPaper-Master container.

### Docker Compose (recommended)

Create the following `docker-compose.yaml` file, then simply run `docker-compose up -d` to launch the servers.

```yaml
---
version: "3.8"

services:

  master:
    container_name: master
    image: ghcr.io/munenick/multipaper-master:1.20
    ports:
      - 25565:25565
    volumes:
      - master-data:/app
    environment:
      - MASTER_PORT=35353
      - PROXY_PORT=25565
      - JAVA_OPTS=-Xmx512M
  
  node1:
    image: ghcr.io/munenick/multipaper:1.20
    environment:
      - EULA=true
      - JAVA_OPTS=-Xmx1G
      - MULTIPAPER_MASTER_ADDRESS=master:35353
      - BUNGEECORD_NAME=node1
      - PROP_VIEW_DISTANCE=16
      - SPIGOT_SETTINGS_BUNGEECORD=true
      - NOGUI=true

  node2:
    image: ghcr.io/munenick/multipaper:1.20
    environment:
      - EULA=true
      - JAVA_OPTS=-Xmx1G
      - MULTIPAPER_MASTER_ADDRESS=master:35353
      - BUNGEECORD_NAME=node2
      - PROP_VIEW_DISTANCE=16
      - SPIGOT_SETTINGS_BUNGEECORD=true
      - NOGUI=true

volumes:
  master-data:
```

### Docker CLI

```bash
# Start the MultiPaper-Master container
docker run -d \
    --name=multipaper-master \
    -p 25565:25565 \
    -v multipaper-master-data:/app \
    -e MASTER_PORT=35353 \
    -e PROXY_PORT=25565 \
    -e JAVA_OPTS="-Xmx512M" \
    ghcr.io/munenick/multipaper-master:1.20

# Start the MultiPaper node container
docker run -d \
    --name=multipaper-node1 \
    -e EULA=true \
    -e JAVA_OPTS="-Xmx1G" \
    -e MULTIPAPER_MASTER_ADDRESS=multipaper-master:35353 \
    -e BUNGEECORD_NAME=node1 \
    -e PROP_VIEW_DISTANCE=16 \
    -e SPIGOT_SETTINGS_BUNGEECORD=true \
    -e NOGUI=true \
    ghcr.io/munenick/multipaper:1.20
```


## Configuration with Environment Variables

MultiPaper can be customized using various environment variables.

### MultiPaper-Master Environment Variables

| Environment Variable | Description | Default Value |
| :--- | :--- | :--- |
| `MASTER_PORT` | Port the master database listens on | `35353` |
| `PROXY_PORT` | Port the proxy listens on | `25565` |
| `JAVA_OPTS` | JVM startup options (memory settings, etc.) | None |

### MultiPaper Node Environment Variables

| Environment Variable | Description | Example |
| :--- | :--- | :--- |
| `EULA` | Minecraft EULA agreement | `true` |
| `JAVA_OPTS` | JVM startup options | `-Xmx1G` |
| `MULTIPAPER_MASTER_ADDRESS` | Master server address | `master:35353` |
| `BUNGEECORD_NAME` | Identification name in BungeeCord/Velocity | `node1` |
| `NOGUI` | Disable GUI | `true` |
| `PROP_*` | server.properties settings | `PROP_VIEW_DISTANCE=16` |
| `PAPER_*` | paper.yml settings | `PAPER_GLOBAL_PROXIES_PROXY_PROTOCOL=true` |
| `SPIGOT_*` | spigot.yml settings | `SPIGOT_SETTINGS_BUNGEECORD=true` |
| `MULTIPAPER_*` | multipaper.yml settings | `MULTIPAPER_SYNC_SETTINGS_FILES_FILES_TO_SYNC_ON_STARTUP=plugins/MyPlugin.jar` |

#### Environment Variable Naming Conventions

- `PROP_*`: Override `server.properties` settings
  - `view-distance=16` → `PROP_VIEW_DISTANCE=16`
  - Hyphens (-) are converted to underscores (_)

- `PAPER_*`: Override `paper.yml` settings
  - `paper.global.proxies.proxy-protocol=true` → `PAPER_GLOBAL_PROXIES_PROXY_PROTOCOL=true`
  - Dots (.) and uppercase/lowercase are preserved

- `SPIGOT_*`: Override `spigot.yml` settings
  - `spigot.world-settings.default.entity-tracking-range.players=128` → `SPIGOT_WORLD_SETTINGS_DEFAULT_ENTITY_TRACKING_RANGE_PLAYERS=128`

- `MULTIPAPER_*`: Override `multipaper.yml` settings
  - `multipaper.sync-settings.files.files-to-sync-on-startup` → `MULTIPAPER_SYNC_SETTINGS_FILES_FILES_TO_SYNC_ON_STARTUP`


## Parameters

### MultiPaper-Master

| Parameter | Function |
| :---: | --- |
| `-p 25565:25565` | Open port to the proxy |
| `-p 35353:35353` | Open port to the MultiPaper Master server |
| `-v master-data:/app` | Directory containing world files and other sync files |

### MultiPaper Node

| Parameter | Function |
| :---: | --- |
| `-p 25565:25565` | Optional. Only needed if connecting to the master server from outside the network | 
| `-e EULA=true` | Specify that you have accepted the EULA. Required to start the node |
| `-e JAVA_OPTS="..."` | Set options to pass to Java at runtime |
| Other environment variables | See the environment variables table above |


## Update

### Docker Compose

```bash
# Pull the updated images
docker-compose pull

# Update the containers
docker-compose up -d
```

### Docker CLI

```bash 
# Pull the updated images
docker pull ghcr.io/munenick/multipaper-master:1.20
docker pull ghcr.io/munenick/multipaper:1.20

# List running containers
docker ps | grep multipaper

# Stop the master container
docker stop multipaper-master
docker rm multipaper-master

# Also stop any running node containers
docker stop [container-name]
docker rm [container-name]
```

You can now recreate the servers using the commands from the [Usage](#usage) section.


## Building locally

If you want to customise the images:

```bash
# Clone the repository
git clone git@github.com:MuNeNICK/multipaper-docker.git

cd multipaper-docker

# Build the MultiPaper-Master image
docker build --target master -t ghcr.io/munenick/multipaper-master .
# Build the Multipaper node image
docker build --target node -t ghcr.io/munenick/multipaper .
```

## Troubleshooting

### World files are not being generated by the node

On many systems the Docker daemon runs as root. If the directories being mounted to your containers don't exist, they will be created by Docker.

MultiPaper processes within these containers do not run as the root user and therefore may be unable to write files into any directories created by the Docker daemon.

If you find that your generated world files are not being synced to the `master-data` directory, please ensure that the directory is **not** owned by `root`.

This project now uses named volumes in recent updates. This should automatically resolve permission issues. If problems persist, try the following:

```yaml
  master:
    container_name: master
    image: ghcr.io/munenick/multipaper-master:1.20
    user: root # This line sets the user in the container to root
    ports:
      - 25565:25565 
    volumes:
      - ./master:/app # If mounting a local directory
```

However, using the root user is not recommended for security reasons. Instead, it's recommended to use named volumes or set appropriate ownership for the directory being mounted.
