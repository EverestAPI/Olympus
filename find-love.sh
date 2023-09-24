#!/bin/sh
#
# A linux-only script for running a love file using the correct engine binary
# This script's working directory must be the bundled love's one and it'll set 
# everything up by itself

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
		    cd $(dirname $1)
            echo "Using system wide love installation"
            love --fused $@ # Go with it
            exit
        fi # Too old, check other options
    else # if no bundled love, just use it
        echo "Using system wide love installation, unknown target version"
		cd $(dirname $1)
        love --fused $@
        exit
    fi
fi
if [ -f "love" ]; then
    echo "Using bundled love"
	cd $(dirname $1)
    ./love --fused $@
elif command -v love >/dev/null 2>&1; then # We know it is old, but go for it anyway
    echo "Using oudated system wide love installation"
	cd $(dirname $1)
    love --fused $@
elif command -v love2d >/dev/null 2>&1; then
    echo "Using love2d, trouble incoming (hopefully not)"
	cd $(dirname $1)
    love2d --fused $@
else
    echo "love2d not found!"
	exit 1
fi

