#!/bin/sh
cd $(dirname "$0")

if [ -f "olympus.new.love" ]; then
    mv "olympus.love" "olympus.old.love"
    mv "olympus.new.love" "olympus.love"
fi

./love --fused olympus.love
