#syntax=docker/dockerfile:1.4

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

# Run the MultiPaper Master jar file with environment variables
exec java $JAVA_OPTS -jar /opt/multipaper-master/multipaper-master.jar $MASTER_PORT $PROXY_PORT
EOT

ARG RELEASE_URL
ADD --chown=multipaper:multipaper $RELEASE_URL /opt/multipaper-master/multipaper-master.jar

ENTRYPOINT [ "/opt/multipaper-master/entry.sh" ]

EXPOSE 35353/tcp 25565/tcp
VOLUME [ "/app" ]


# Build the Multipaper node container
FROM base as node

# Create an entry script based on akiicat/MultiPaper-Container
COPY --chown=multipaper:multipaper --chmod=744 <<-"EOT" /opt/multipaper/entry.sh
#!/usr/bin/env bash
# If the EULA environment variable is true, accept it
if [[ -n "$EULA" ]]; then
    echo "Accepting the EULA..."
    echo "eula=$EULA" > eula.txt
fi

# Default JVM options
JAVA_OPTS=${JAVA_OPTS:-""}

# Process environment variables for system properties
SYSTEM_PROPS=""

# Handle bungeecord name if set
if [[ -n "$BUNGEECORD_NAME" ]]; then
    SYSTEM_PROPS="$SYSTEM_PROPS -DbungeecordName=$BUNGEECORD_NAME"
fi

# Handle master address if set
if [[ -n "$MULTIPAPER_MASTER_ADDRESS" ]]; then
    SYSTEM_PROPS="$SYSTEM_PROPS -DmultipaperMasterAddress=$MULTIPAPER_MASTER_ADDRESS"
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

# Debug: show the final command being executed
echo "Executing: java $JAVA_OPTS $SYSTEM_PROPS -jar $@ $NOGUI_OPT"

# Run the MultiPaper Server jar file with all options
exec java $JAVA_OPTS $SYSTEM_PROPS -jar "$@" $NOGUI_OPT
EOT

ARG RELEASE_URL
ADD --chown=multipaper:multipaper $RELEASE_URL /opt/multipaper/multipaper.jar

ENTRYPOINT [ "/opt/multipaper/entry.sh", "/opt/multipaper/multipaper.jar" ]
CMD [ "--max-players=30" ]

EXPOSE 25565/tcp
VOLUME [ "/app" ]