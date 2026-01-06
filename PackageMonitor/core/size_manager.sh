#!/bin/bash

# Directorul comun de date
WORKDIR="$(cd "$(dirname "$0")/../data/packagemonitor" && pwd)"
TOTAL_SIZE_FILE="$WORKDIR/total_size"

# Initializare total_size
init_total_size() {
    if [ ! -f "$TOTAL_SIZE_FILE" ]; then
        echo 0 > "$TOTAL_SIZE_FILE"
    fi
}

# Obtine dimensiunea unui pachet (KB)
get_package_size() {
    local pkg="$1"
    dpkg-query -W -f='${Installed-Size}' "$pkg" 2>/dev/null || echo 0
}

# Apelata la INSTALL complet
handle_install() {
    local pkg="$1"
    local date="$2"
    local PKGDIR="$WORKDIR/$pkg"

    mkdir -p "$PKGDIR"

    # first_install (doar prima data)
    if [ ! -f "$PKGDIR/first_install" ]; then
        echo "$date" > "$PKGDIR/first_install"
    fi

    # size
    local size
    size=$(get_package_size "$pkg")
    echo "$size" > "$PKGDIR/size"

    # total_size
    init_total_size
    local total
    total=$(cat "$TOTAL_SIZE_FILE")
    echo $((total + size)) > "$TOTAL_SIZE_FILE"
}

# Apelata la REMOVE
handle_remove() {
    local pkg="$1"
    local PKGDIR="$WORKDIR/$pkg"

    if [ ! -f "$PKGDIR/size" ]; then
        return
    fi

    init_total_size
    local size
    size=$(cat "$PKGDIR/size")

    local total
    total=$(cat "$TOTAL_SIZE_FILE")
    echo $((total - size)) > "$TOTAL_SIZE_FILE"
}
