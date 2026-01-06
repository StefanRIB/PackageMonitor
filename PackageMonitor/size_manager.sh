#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

WORKDIR="/var/lib/packagemonitor"

mkdir -p "$WORKDIR"

get_package_size() {
    local pkg="$1"
    dpkg-query -W -f='${Installed-Size}' "$pkg" 2>/dev/null || echo 0
}

handle_install() {
    local pkg="$1"
    local date="$2"

    PKGDIR="$WORKDIR/$pkg"
    mkdir -p "$PKGDIR"

    SIZE=$(get_package_size "$pkg")
    echo "$SIZE" > "$PKGDIR/size"

    echo "$date install" >> "$PKGDIR/history.log"
    echo "installed" > "$PKGDIR/status"
}

handle_remove() {
    local pkg="$1"
    local date="$2"

    PKGDIR="$WORKDIR/$pkg"
    mkdir -p "$PKGDIR"

    echo "$date remove" >> "$PKGDIR/history.log"
    echo "removed" > "$PKGDIR/status"
}

