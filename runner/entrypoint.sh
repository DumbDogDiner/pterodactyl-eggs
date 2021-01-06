#!/bin/bash
shopt -s nullglob
set -euo pipefail

UPDATER_VERSION="1.0.0"
UPDATER_AUTHORS="SkyezerFox"

# TARGET_SOFTWARE="waterfall"
# TARGET_VERSION="latest"
# TARGET_BUILD="latest"
# SERVER_JARFILE=server.jar

# pretty log function
log() {
    echo $(printf '\e[1;30m')"=> $(printf '\033[m')$@"
}

# download the target build
download_jar() {
    log "Downloading $TARGET_SOFTWARE v$TARGET_VERSION (build $TARGET_BUILD)"
    echo
    curl -OJ https://papermc.io/api/v1/$TARGET_SOFTWARE/$TARGET_VERSION/$TARGET_BUILD/download
    echo

    if [ $? -ne 0 ]; then
        log ERROR Could not download server jar.
        exit 1
    fi

    log Up to date.
}

# start the server
start_server() {
    echo test
    JAR_PATH=$(find . -iname "$TARGET_SOFTWARE-*.jar")
    CURRENT_BUILD=$(echo $JAR_PATH | grep -Eo '[0-9]+')
    
    log "Starting $TARGET_SOFTWARE v$TARGET_VERSION (build $CURRENT_BUILD)"
    echo
    
    java --version
    echo
    
    # interpolate args from daemon
    MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
    echo + $MODIFIED_STARTUP
    ${MODIFIED_STARTUP}
}

# splash - there's a newline issue here
printf "\n\u001b[35;1mdddMC - MinecraftAutoUpdate \u001b[36;1mv"
printf $UPDATER_VERSION
printf "\u001b[0m\n\n"


# ensure environment variables are set
if [[ $TARGET_SOFTWARE != "waterfall" ]]; then
    TARGET_SOFTWARE="paper"
fi

if [[ -z $TARGET_VERSION ]]; then
    TARGET_VERSION="latest"
fi

if [[ -z $TARGET_BUILD ]]; then
    TARGET_BUILD="latest"
fi

if [[ ! -e .alkyne.lock ]]; then
    log Lockfile does not exist - creating it now...
    touch .alkyne.lock
    echo "TARGET_VERSION=$TARGET_VERSION" >> .alkyne.lock
    echo "TARGET_BUILD=$TARGET_BUILD" >> .alkyne.lock
fi

# fetch the latest mc version if we need to
if [[ $TARGET_VERSION == "latest" ]]; then
    log Fetching latest MC version information...
    TARGET_VERSION=$(curl -s https://papermc.io/api/v1/$TARGET_SOFTWARE | jq -r ".versions[0]")
    if [ $? -ne 0 ]; then
        log ERROR Could not fetch latest MC version.
        exit 1
    fi
fi

# check if jar does not exist
if [[ -z $JAR_PATH ]]; then
    log "No server jar found - downloading..."
    download_jar
    start_server
    exit
fi

# if not wanting latest, skip version check
if [[ $TARGET_BUILD != "latest" ]]; then
    start_server
    exit
fi

log "Latest build specified - checking for updates..."

# check if the currently downloaded jar is the latest version
LATEST_BUILD=$(curl -s https://papermc.io/api/v1/$TARGET_SOFTWARE/$TARGET_VERSION | jq -r ".builds.latest")

# if the current jar build is greater than or equal to the latest build,
# there is no need to update the jar.
if [[ $CURRENT_BUILD -ge $LATEST_BUILD ]]; then
    log Up to date.
    start_server
    exit
fi

log Jar out of date - downloading new version...
# remove the jar so curl can download
rm $JAR_PATH
download_jar
start_server
