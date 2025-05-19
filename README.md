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

Create a directory (eg `master`) and mount it to the `/app` directory in the MultiPaper-Master container. (See the examples below)

If you have existing world files you want to use, place them in this directory before starting the MultiPaper-Master container.

### Docker Compose (recommended)

Create the following `docker-compose.yaml` file, then simply run `docker-compose up -d` to launch the servers.

(Note: The `multipaperMasterAddress` variable uses the service name `master` as a host name instead of specifying an IP address.)

```yaml
---
version: "3"

services:

  master:
    container_name: master
    image: ghcr.io/munenick/multipaper-master:1.20
    ports:
      - 25565:25565 # Opens the proxy port
    volumes:
      - ./master:/app # Required to access world files
  
  server:
    image: ghcr.io/munenick/multipaper:1.20
    environment:
      - EULA=true # Setting this to true will automatically accept the Minecraft EULA upon launch
      - JAVA_TOOL_OPTIONS=-Xmx1G
        -DmultipaperMasterAddress=master:35353 
        -Dspigot.settings.bungeecord=true
```

### Docker CLI

```bash
# Start the MultiPaper-Master container
docker run -d \
    --name=multipaper-master 
    -p 25565:25565 
    -v $(pwd)/master:/app
    ghcr.io/munenick/multipaper-master:1.20

# Start the MultiPaper server container
docker run -d \
    -e EULA=true \
    -e JAVA_TOOL_OPTIONS="-Xmx1G -DmultipaperMasterAddress=multipaper-master:35353" \
    ghcr.io/munenick/multipaper:1.20 [server_opts]
```


## Configuring the Server

MultiPaper provides support for updating the server configuration files files via system properties provided to the `java` command. You can see an example of this in the `JAVA_TOOL_OPTIONS` environment variable above.

See the MultiPaper docs regarding [Command line options](https://github.com/MultiPaper/MultiPaper#command-line-options) for more information.

Configuration should be done via the method above whenever possible to ensure server containers are disposable.

If you require direct access to the server files, you can attach a volume to the `/app` directory before launching the container.


## Parameters

### MultiPaper-Master

| Parameter | Function |
| :---: | --- |
| `-p 25565:25565` | Opens the port to the proxy |
| `-p 35353:35353` | Opens the port to the MultiPaper Master server |
| `-v ./master:/app` | Directory containing World files and other synced files <br>(Only required if Multipaper servers are connecting from outside the network) |

### MultiPaper Server

| Parameter | Function |
| :---: | --- |
| `-p 25565:25565` | Optional. Only required if connecting to a Master server outside of the network | 
| `-e EULA=true` | Specifies that the EULA has been accepted. Required for the server to launch |
| `-e JAVA_TOOL_OPTIONS="..."` | Sets the environment variable to pass options into Java at runtime |
| `[server_opts]` | Optional parameters sent to the `multipaper.jar` (Default value: `--max-players=30`) |


## Updating

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

# Also stop any running server containers
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
# Build the Multipaper server image
docker build --target server -t ghcr.io/munenick/multipaper .
```

## Troubleshooting

### World files are not being generated by the server

On many systems the Docker daemon runs as root. If the directories being mounted to your containers don't exist, they will be created by Docker.

MultiPaper processes within these containers do not run as the root user and therefore may be unable to write files into any directories created by the Docker daemon.

If you find that your generated world files are not being synced to the `master` directory, please ensure that the directory is **not** owned by `root`.

Alternatively, you may add the following line to the `master` service to specify that application processes should run as `root` inside the container.

```yaml
  master:
    container_name: master
    image: ghcr.io/munenick/multipaper-master:1.20
    user: root # this line sets the user inside the container
    ports:
      - 25565:25565 # Opens the proxy port
    volumes:
      - ./master:/app # Required to access world files
```
