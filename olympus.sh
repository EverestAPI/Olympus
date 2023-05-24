#!/bin/sh
# Olympus launch script bundled with Linux and macOS builds.

# macOS doesn't have readlink -f and Linux can symlink this launch script.
realpath() {
    [ "." = "${1}" ] && n=${PWD} || n=${1}; while nn=$( readlink -n "$n" ); do n=$nn; done; echo "$n"
}

cd "$(dirname "$(realpath "$0")")" || exit 1

if [ -f "olympus.new.love" ]; then
    if [ -n "${OLYMPUS_RESTARTER_PID+x}" ]; then
        attempt=0
        while [ "$attempt" -lt 30 ] && kill -0 "$OLYMPUS_RESTARTER_PID"; do
            attempt=$((attempt + 1))
            sleep 0.1
        done
    fi

    mv "olympus.love" "olympus.old.love"
    mv "olympus.new.love" "olympus.love"
fi

if [ "$(uname)" = "Darwin" ]; then
    DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:$(pwd)"
    export DYLD_LIBRARY_PATH
else
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:$(pwd)"
    export LD_LIBRARY_PATH
fi

# Order priority goes as follows:
# 1. love if its not too old, if too old or missing then
# 2. bundled love, if missing then
# 3. love even tho we know its old, if missing then
# 4. love2d is always too old, but it is used as a last resource, if missing just cry

if command -v love >/dev/null 2>&1; then
    # Get installed love version
    LOVE_VER=$(love --version | awk '{split($0,ver," "); print ver[2]}')
    LOVE_VER_MAJ=$(echo $LOVE_VER | awk '{split($0,mver,"."); print mver[1]}')
    LOVE_VER_MIN=$(echo $LOVE_VER | awk '{split($0,mver,"."); print mver[2]}')

    # Get bundled love version
    if [ -f "love" ]; then
        BUN_LOVE_VER=$(./love --version | awk '{split($0,ver," "); print ver[2]}')
        BUN_LOVE_VER_MAJ=$(echo $BUN_LOVE_VER | awk '{split($0,mver,"."); print mver[1]}')
        BUN_LOVE_VER_MIN=$(echo $BUN_LOVE_VER | awk '{split($0,mver,"."); print mver[2]}')
        # Compare versions
        if [ $LOVE_VER_MAJ -gt $BUN_LOVE_VER_MAJ ] ||
            ([ $LOVE_VER_MAJ -eq $BUN_LOVE_VER_MAJ ] && [ $LOVE_VER_MIN -ge $BUN_LOVE_VER_MIN ]); then
            echo "Using system wide love installation"
            love --fused olympus.love $@ # Go with it
            exit
        fi # Too old, check other options
    else # if no bundled love, just use it
        echo "Using system wide love installation, unknown target version"
        love --fused olympus.love $@
        exit
    fi
fi
if [ -f "love" ]; then
    echo "Using bundled love"
    ./love --fused olympus.love $@
elif command -v love >/dev/null 2>&1; then # We know it is old, but go for it anyway
    echo "Using oudated system wide love installation"
    love --fused olympus.love $@
elif command -v love2d >/dev/null 2>&1; then
    echo "Using love2d, trouble incoming (hopefully not)"
    love2d --fused olympus.love $@
else
    echo "love2d not found!"
fi

