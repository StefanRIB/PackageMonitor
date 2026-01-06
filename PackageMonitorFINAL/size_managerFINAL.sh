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
    OLD_SIZE=0
    [ -f "$PKGDIR/size" ] && OLD_SIZE=$(cat "$PKGDIR/size")

    echo "$SIZE" > "$PKGDIR/size"

    if [ "$OLD_SIZE" -eq 0 ]; then
        add_to_total "$SIZE"
    fi

    echo "$date install" >> "$PKGDIR/history.log"
    echo "installed" > "$PKGDIR/status"
    
    recalculate_total_size
}

handle_remove() {
    local pkg="$1"
    local date="$2"

    PKGDIR="$WORKDIR/$pkg"
    mkdir -p "$PKGDIR"

    if [ -f "$PKGDIR/size" ]; then
        SIZE=$(cat "$PKGDIR/size")
        remove_from_total "$SIZE"
    fi

    echo "$date remove" >> "$PKGDIR/history.log"
    echo "removed" > "$PKGDIR/status"
    
    recalculate_total_size
}

TOTAL_SIZE_FILE="$WORKDIR/total_size"

init_total_size() {
    if [ ! -f "$TOTAL_SIZE_FILE" ]; then
        echo 0 > "$TOTAL_SIZE_FILE"
    fi
}

add_to_total() {
    local size="$1"
    init_total_size
    current=$(cat "$TOTAL_SIZE_FILE")
    echo $((current + size)) > "$TOTAL_SIZE_FILE"
}

remove_from_total() {
    local size="$1"
    init_total_size
    current=$(cat "$TOTAL_SIZE_FILE")
    new=$((current - size))
    [ "$new" -lt 0 ] && new=0
    echo "$new" > "$TOTAL_SIZE_FILE"
}

recalculate_total_size() {
    total=0
    for pkgdir in "$WORKDIR"/*; do
        [ -d "$pkgdir" ] || continue
        [ -f "$pkgdir/status" ] || continue
        [ -f "$pkgdir/size" ] || continue

        status=$(cat "$pkgdir/status")
        if [ "$status" = "installed" ]; then
            size=$(cat "$pkgdir/size")
            total=$((total + size))
        fi
    done
    echo "$total" > "$WORKDIR/total_size"
}