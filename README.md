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
      - MASTER_PORT=35353     # マスターサーバーデータベースポート
      - PROXY_PORT=25565      # プロキシポート
      - JAVA_OPTS=-Xmx512M    # マスターサーバー用のJavaオプション
  
  node1:
    image: ghcr.io/munenick/multipaper:1.20
    environment:
      - EULA=true                             # Minecraft EULAの自動承認
      - JAVA_OPTS=-Xmx1G                      # ノード用のJavaオプション
      - MULTIPAPER_MASTER_ADDRESS=master:35353 # マスターサーバーのアドレス
      - BUNGEECORD_NAME=node1                 # BungeeCord識別名
      - PROP_VIEW_DISTANCE=16                 # server.propertiesのview-distance設定
      - SPIGOT_SETTINGS_BUNGEECORD=true       # spigot.ymlのbungeecord設定
      - NOGUI=true                            # GUIを無効化

  node2:
    image: ghcr.io/munenick/multipaper:1.20
    environment:
      - EULA=true                             # Minecraft EULAの自動承認
      - JAVA_OPTS=-Xmx1G                      # ノード用のJavaオプション
      - MULTIPAPER_MASTER_ADDRESS=master:35353 # マスターサーバーのアドレス
      - BUNGEECORD_NAME=node2                 # BungeeCord識別名
      - PROP_VIEW_DISTANCE=16                 # server.propertiesのview-distance設定
      - SPIGOT_SETTINGS_BUNGEECORD=true       # spigot.ymlのbungeecord設定
      - NOGUI=true                            # GUIを無効化

volumes:
  master-data:
    # このボリュームはDockerが管理し、適切な権限が設定される
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


## 環境変数によるコンフィグレーション

MultiPaperは環境変数を使用して様々な設定をカスタマイズできます。

### MultiPaper-Master の環境変数

| 環境変数 | 説明 | デフォルト値 |
| :--- | :--- | :--- |
| `MASTER_PORT` | マスターデータベースがリッスンするポート | `35353` |
| `PROXY_PORT` | プロキシのリッスンポート | `25565` |
| `JAVA_OPTS` | JVM起動オプション（メモリ設定など） | なし |

### MultiPaper Node の環境変数

| 環境変数 | 説明 | 例 |
| :--- | :--- | :--- |
| `EULA` | Minecraft EULAの同意 | `true` |
| `JAVA_OPTS` | JVM起動オプション | `-Xmx1G` |
| `MULTIPAPER_MASTER_ADDRESS` | マスターサーバーのアドレス | `master:35353` |
| `BUNGEECORD_NAME` | BungeeCord/Velocityでの識別名 | `node1` |
| `NOGUI` | GUIを無効化 | `true` |
| `PROP_*` | server.propertiesの設定 | `PROP_VIEW_DISTANCE=16` |
| `PAPER_*` | paper.ymlの設定 | `PAPER_GLOBAL_PROXIES_PROXY_PROTOCOL=true` |
| `SPIGOT_*` | spigot.ymlの設定 | `SPIGOT_SETTINGS_BUNGEECORD=true` |
| `MULTIPAPER_*` | multipaper.ymlの設定 | `MULTIPAPER_SYNC_SETTINGS_FILES_FILES_TO_SYNC_ON_STARTUP=plugins/MyPlugin.jar` |

#### 環境変数の命名規則

- `PROP_*`: `server.properties`の設定を上書き
  - `view-distance=16` → `PROP_VIEW_DISTANCE=16`
  - ハイフン(-)はアンダースコア(_)に変換

- `PAPER_*`: `paper.yml`の設定を上書き
  - `paper.global.proxies.proxy-protocol=true` → `PAPER_GLOBAL_PROXIES_PROXY_PROTOCOL=true`
  - ドット(.)と大文字/小文字はそのまま保持

- `SPIGOT_*`: `spigot.yml`の設定を上書き
  - `spigot.world-settings.default.entity-tracking-range.players=128` → `SPIGOT_WORLD_SETTINGS_DEFAULT_ENTITY_TRACKING_RANGE_PLAYERS=128`

- `MULTIPAPER_*`: `multipaper.yml`の設定を上書き
  - `multipaper.sync-settings.files.files-to-sync-on-startup` → `MULTIPAPER_SYNC_SETTINGS_FILES_FILES_TO_SYNC_ON_STARTUP`


## パラメータ

### MultiPaper-Master

| パラメータ | 機能 |
| :---: | --- |
| `-p 25565:25565` | プロキシへのポートを開く |
| `-p 35353:35353` | MultiPaper Masterサーバーへのポートを開く |
| `-v master-data:/app` | ワールドファイルと他の同期ファイルを含むディレクトリ |

### MultiPaper Node

| パラメータ | 機能 |
| :---: | --- |
| `-p 25565:25565` | オプション。ネットワーク外からマスターサーバーに接続する場合のみ必要 | 
| `-e EULA=true` | EULAを承認したことを指定。ノードの起動に必要 |
| `-e JAVA_OPTS="..."` | Java実行時に渡すオプションを設定 |
| その他の環境変数 | 上記の環境変数表を参照 |


## 更新

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

このプロジェクトでは、最近のアップデートで名前付きボリュームを使用するよう変更されています。これにより、権限の問題は自動的に解決されるはずです。問題が解決しない場合は以下の方法を試してください：

```yaml
  master:
    container_name: master
    image: ghcr.io/munenick/multipaper-master:1.20
    user: root # このラインはコンテナ内のユーザーをrootに設定
    ports:
      - 25565:25565 
    volumes:
      - ./master:/app # ローカルディレクトリをマウントする場合
```

しかし、セキュリティ上の理由からrootユーザーの使用は推奨されません。代わりに名前付きボリュームを使用するか、マウントするディレクトリの所有権を適切に設定することをお勧めします。
