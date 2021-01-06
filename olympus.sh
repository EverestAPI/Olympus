#!/bin/sh
# Olympus launch script bundled with Linux and macOS builds.

cd "$(dirname "$0")" || exit 1

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
    LD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:$(pwd)"
    export LD_LIBRARY_PATH
fi

if [ -f "love" ]; then
    ./love --fused olympus.love $@
elif command -v love >/dev/null 2>&1; then
    love --fused olympus.love $@
elif command -v love2d >/dev/null 2>&1; then
    love2d --fused olympus.love $@
else
    echo "love2d not found!"
fi
