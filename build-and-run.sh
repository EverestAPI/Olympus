#!/bin/bash

set -xeo pipefail

# Make sure we are in the right directory
cd "$(dirname "$0")"

# Reset the love directory
rm -rfv love
mkdir love

# Download and install latest Olympus as a base
cd love
wget -O linux.main.zip 'https://maddie480.ovh/celeste/download-olympus?branch=main&platform=linux'
unzip linux.main.zip
mv -v linux.main/dist.zip dist.zip
unzip dist.zip
rm -rfv linux.main dist.zip linux.main.zip olympus.love
cd ..

# Build Olympus.Sharp and copy it to love
cd sharp
dotnet build --configuration Release Olympus.Sharp.sln
cp -vf bin/Release/net452/* ../love/sharp
cd ..

# Run our fresh build!
cd love
./love --console ../src --debug