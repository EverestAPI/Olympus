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

# On Linux/osx we use the wrapper script, the .sh version is here for debugging purposes
if [ -f "find-love.sh" ]; then
	./find-love.sh olympus.love
elif [ -f "find-love" ]; then
	./find-love olympus.love
else
	echo "find-love script not found, can't proceed!"
	exit 1
fi

