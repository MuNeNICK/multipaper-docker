#syntax=docker/dockerfile:1.4
FROM --platform=$BUILDPLATFORM gradle:latest as build

WORKDIR /app

# Config a git user for the build process
RUN <<EOT
    git config --global user.name "Automated build"
    git config --global user.email "build@example.com"
EOT

# If the repo is updated, the request body will change which should invalidate cache for the next step`
ADD https://api.github.com/repos/MultiPaper/MultiPaper/git/refs/heads/main version.json
# Clone the repo
RUN git clone https://github.com/MultiPaper/MultiPaper.git

# CD into the new repo
WORKDIR /app/MultiPaper
# Multipaper build process
RUN <<EOT
    ./gradlew applyPatches
    ./gradlew shadowjar createReobfPaperclipJar

    MULTIPAPER_VERSION=$(gradle properties | grep version | awk '{print $NF}')
    MULTIPAPER_MASTER_VERSION=$(gradle MultiPaper-Master:properties | grep version | awk '{print $NF}')
    
    # Move build artifacts to more accessible place
    mkdir /artifacts

    # Discarded version numbers for easy copying later on
    mv LICENSE.txt /artifacts/multipaper-license.txt
    mv build/libs/MultiPaper-paperclip-$MULTIPAPER_VERSION-reobf.jar /artifacts/multipaper.jar
    mv MultiPaper-Master/LICENSE.txt /artifacts/multipaper-master-license.txt
    mv MultiPaper-Master/build/libs/MultiPaper-Master-$MULTIPAPER_MASTER_VERSION-all.jar /artifacts/multipaper-master.jar
EOT

# CD into a new directory to run the jars
WORKDIR /app/multipaper-config

# Run the jars to generate some files
RUN <<EOT bash
    # Start the server once to download the mojang_*.jar
    grep -m 1 "Applying patches" <(java -jar /artifacts/multipaper.jar)

    # Start the mojang server once to generate eula.txt
    java -jar ./cache/mojang_*.jar

    # Move the eula to /artifacts
    mv eula.txt /artifacts
EOT


# Create a shared base container
FROM eclipse-temurin:19-jre as base

RUN useradd -d /app -s /bin/false multipaper
USER multipaper
WORKDIR /app


# Build the MultiPaper-Master container
FROM base as master

# Create an entry script for the master that fixes permissions and handles environment variables
COPY --chown=multipaper:multipaper --chmod=744 <<-"EOT" /opt/multipaper-master/entry.sh
#!/usr/bin/env bash
# Check and fix permissions for the app directory
APP_DIR="/app"
if [ ! -w "$APP_DIR" ]; then
    echo "Warning: No write permissions to $APP_DIR, attempting to create a writable subdirectory..."
    mkdir -p "$APP_DIR/master-data" 2>/dev/null || true
    
    # If we still can't write, notify but continue
    if [ ! -w "$APP_DIR" ] && [ ! -w "$APP_DIR/master-data" ]; then
        echo "Warning: Cannot write to $APP_DIR or $APP_DIR/master-data. Map generation may fail."
        echo "Consider mounting the volume with proper permissions or using a subdirectory."
    fi
fi

# Set default values for command line arguments
MASTER_PORT=${MASTER_PORT:-35353}
PROXY_PORT=${PROXY_PORT:-25565}

# Additional JVM options
JAVA_OPTS=${JAVA_OPTS:-""}

# Show the final command being executed
echo "Starting MultiPaper Master with options:"
echo "MASTER_PORT: $MASTER_PORT"
echo "PROXY_PORT: $PROXY_PORT"
echo "JVM options: $JAVA_OPTS"
echo "Full command: java $JAVA_OPTS -jar /opt/multipaper-master/multipaper-master.jar $MASTER_PORT $PROXY_PORT"

# Run the MultiPaper Master jar file with environment variables
exec java $JAVA_OPTS -jar /opt/multipaper-master/multipaper-master.jar $MASTER_PORT $PROXY_PORT
EOT

COPY --from=build --chown=multipaper:multipaper /artifacts/multipaper-master-license.txt /opt/multipaper-master/LICENSE.txt
COPY --from=build --chown=multipaper:multipaper /artifacts/multipaper-master.jar /opt/multipaper-master/multipaper-master.jar

ENTRYPOINT [ "/opt/multipaper-master/entry.sh" ]

EXPOSE 35353/tcp 25565/tcp
VOLUME [ "/app" ]


# Build the Multipaper node container
FROM base as node

# Create an entry script based on akiicat/MultiPaper-Container
COPY --chown=multipaper:multipaper --chmod=744 <<-"EOT" /opt/multipaper/entry.sh
#!/usr/bin/env bash
# Make sure the config files exist
if [[ -f "/opt/multipaper/eula.txt" && ! -f "/app/eula.txt" ]]; then
    echo "Copying eula.txt"
    cp "/opt/multipaper/eula.txt" "/app/eula.txt"
fi
# If the EULA environment variable is true, accept it
if [[ -n "$EULA" ]]; then
    echo "Accepting the EULA..."
    sed -i "s/eula=.*$/eula=$EULA/g" eula.txt
fi

# Default JVM options
JAVA_OPTS=${JAVA_OPTS:-""}

# Process environment variables for system properties
SYSTEM_PROPS=""

# Handle master address if set - this is a critical setting
if [[ -n "$MULTIPAPER_MASTER_ADDRESS" ]]; then
    SYSTEM_PROPS="$SYSTEM_PROPS -DmultipaperMasterAddress=$MULTIPAPER_MASTER_ADDRESS"
    echo "Setting MultiPaper Master Address to: $MULTIPAPER_MASTER_ADDRESS"
fi

# Handle bungeecord name if set
if [[ -n "$BUNGEECORD_NAME" ]]; then
    SYSTEM_PROPS="$SYSTEM_PROPS -DbungeecordName=$BUNGEECORD_NAME"
fi

# Handle server.properties overrides
for var in $(env | grep '^PROP_' | cut -d= -f1); do
    prop_name=$(echo "$var" | sed 's/^PROP_//g' | tr '_' '-' | tr '[:upper:]' '[:lower:]')
    prop_value=$(eval echo "\$$var")
    SYSTEM_PROPS="$SYSTEM_PROPS -Dproperties.$prop_name=$prop_value"
done

# Handle paper.yml overrides
for var in $(env | grep '^PAPER_' | cut -d= -f1); do
    paper_path=$(echo "$var" | sed 's/^PAPER_//g' | tr '_' '.' | tr '[:upper:]' '[:lower:]')
    paper_value=$(eval echo "\$$var")
    SYSTEM_PROPS="$SYSTEM_PROPS -Dpaper.$paper_path=$paper_value"
done

# Handle spigot.yml overrides
for var in $(env | grep '^SPIGOT_' | cut -d= -f1); do
    spigot_path=$(echo "$var" | sed 's/^SPIGOT_//g' | tr '_' '.' | tr '[:upper:]' '[:lower:]')
    spigot_value=$(eval echo "\$$var")
    SYSTEM_PROPS="$SYSTEM_PROPS -Dspigot.$spigot_path=$spigot_value"
done

# Handle multipaper.yml overrides
for var in $(env | grep '^MULTIPAPER_' | cut -d= -f1); do
    # Skip the master address which was handled separately
    if [[ "$var" == "MULTIPAPER_MASTER_ADDRESS" ]]; then
        continue
    fi
    multipaper_path=$(echo "$var" | sed 's/^MULTIPAPER_//g' | tr '_' '.' | tr '[:upper:]' '[:lower:]')
    multipaper_value=$(eval echo "\$$var")
    SYSTEM_PROPS="$SYSTEM_PROPS -Dmultipaper.$multipaper_path=$multipaper_value"
done

# Handle nogui option
NOGUI_OPT=""
if [[ "$NOGUI" == "true" ]]; then
    NOGUI_OPT="nogui"
fi

# Show the final command being executed
echo "Starting MultiPaper with options:"
echo "JVM options: $JAVA_OPTS"
echo "System properties: $SYSTEM_PROPS"
echo "Extra arguments: $NOGUI_OPT"
echo "Full command: java $JAVA_OPTS $SYSTEM_PROPS -jar $@ $NOGUI_OPT"

# Run the MultiPaper Server jar file with all options
exec java $JAVA_OPTS $SYSTEM_PROPS -jar "$@" $NOGUI_OPT
EOT
COPY --from=build --chown=multipaper:multipaper /artifacts/multipaper-license.txt /opt/multipaper/LICENSE.txt
COPY --from=build --chown=multipaper:multipaper /artifacts/eula.txt /opt/multipaper/eula.txt
COPY --from=build --chown=multipaper:multipaper /artifacts/multipaper.jar /opt/multipaper/multipaper.jar

ENTRYPOINT [ "/opt/multipaper/entry.sh", "/opt/multipaper/multipaper.jar" ]
CMD [ "--max-players=30" ]

EXPOSE 25565/tcp
VOLUME [ "/app" ]