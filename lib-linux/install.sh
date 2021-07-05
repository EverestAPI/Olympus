#!/usr/bin/env bash
# Olympus install script bundled with Linux builds.

SRCDIR="$(dirname "$(realpath "$0")")"
cd "$SRCDIR" || exit 1

echo "Olympus exists at $SRCDIR"
echo "For a full installation experience, this script will set up the following:"

DESKTOPSRCFILE="$SRCDIR/olympus.desktop"
BINSRCFILE="$SRCDIR/olympus"
ICONSRCFILE="$SRCDIR/olympus.png"

if [ "$EUID" -ne 0 ]; then
    if [ -n "$XDG_DATA_HOME" ]; then
        APPSDIR="$XDG_DATA_HOME/applications"
    else
        APPSDIR="$HOME/.local/share/applications"
    fi
    DESKTOPFILE="$APPSDIR/Olympus.desktop"
    echo "- A desktop file will be created at $DESKTOPFILE"
    echo "- The everest scheme handler will be registered for your user"
    echo
    echo "If you want to install Olympus system-wide, it is recommended to copy Olympus to /opt/olympus/, fix permissions and run install.sh as root."

else
    APPSDIR="/usr/share/applications"
    DESKTOPFILE="/usr/share/applications/Olympus.desktop"
    BINFILE="/usr/bin/olympus"
    ICONFILE="/usr/share/icons/hicolor/128x128/apps/olympus.png"
    echo "- olympus.desktop will be copied to $DESKTOPFILE"
    echo "- A symlink to olympus.sh will be created at $BINFILE"
    echo "- olympus.png will be copied to $ICONFILE"
    echo "- The everest scheme handler will be registered for everyone"
    echo
    echo "Olympus will be installed system-wide. Please make sure that permissions are set up properly."
fi

echo
read -p "Do you want to continue? y/N: " answer
case ${answer:0:1} in
    y|Y )
    ;;
    * )
        exit 2
    ;;
esac

if [ "$EUID" -ne 0 ]; then
    echo "Creating $DESKTOPFILE"
    mkdir -p "$(dirname "$DESKTOPFILE")"
    rm -f "$DESKTOPFILE"
    cat "$DESKTOPSRCFILE" \
    | sed "s/Exec=olympus/Exec=\"$(echo "$BINSRCFILE" | sed 's_/_\\/_g')\"/" \
    | sed "s/Icon=olympus/Icon=$(echo "$ICONSRCFILE" | sed 's_/_\\/_g')/" \
    > "$DESKTOPFILE"

else
    echo "Creating $DESKTOPFILE"
    mkdir -p "$(dirname "$DESKTOPFILE")"
    rm -f "$DESKTOPFILE"
    cp "$DESKTOPSRCFILE" "$DESKTOPFILE"
    chmod a+rx "$DESKTOPFILE"

    echo "Creating $BINFILE"
    mkdir -p "$(dirname "$BINFILE")"
    rm -f "$BINFILE"
    ln -s "$BINSRCFILE" "$BINFILE"
    chmod a+rx "$BINFILE"

    echo "Creating $ICONFILE"
    mkdir -p "$(dirname "$ICONFILE")"
    rm -f "$ICONFILE"
    cp "$ICONSRCFILE" "$ICONFILE"
    chmod a+r "$ICONFILE"
fi

echo "Registering everest scheme handler"
xdg-mime default "$DESKTOPFILE" "x-scheme-handler/everest"
echo "Updating desktop database"
update-desktop-database "$APPSDIR"

echo "Done!"
