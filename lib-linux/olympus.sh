#!/bin/sh
cd $(dirname "$0")
if command -v love &> /dev/null; then
    love --fused olympus.love
elif command -v love2d &> /dev/null; then
    love2d --fused olympus.love
else
    echo "love2d not found!"
fi
