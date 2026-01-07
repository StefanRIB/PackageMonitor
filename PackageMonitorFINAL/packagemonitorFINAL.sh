#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="/var/lib/packagemonitor"

source core/size_manager.sh
source core/undo_cache.sh

#functii afisare

list_installed() {
    echo "Pachete instalate:"
    for pkg in "$WORKDIR"/*; do
        [ -d "$pkg" ] || continue
        [ "$(cat "$pkg/status" 2>/dev/null)" = "installed" ] || continue

        last_install=$(grep install "$pkg/history.log" | tail -1)
        echo "$(basename "$pkg") -> $last_install"
    done
}

list_removed() {
    echo "Pachete eliminate:"
    for pkg in "$WORKDIR"/*; do
        [ -d "$pkg" ] || continue
        [ "$(cat "$pkg/status" 2>/dev/null)" = "removed" ] || continue

        last_remove=$(grep remove "$pkg/history.log" | tail -1)
        echo "$(basename "$pkg") -> $last_remove"
    done
}

history_pkg() {
    local pkg="$1"
    cat "$WORKDIR/$pkg/history.log"
}

period() {
    local start="$1"
    local end="$2"

    awk -v s="$start" -v e="$end" '
        $1" "$2 >= s && $1" "$2 <= e {
            split(FILENAME,f,"/");
            print f[length(f)-1], $0
        }' "$WORKDIR"/*/history.log
}

pkg_size() {
    local pkg="$1"
    echo "Dimensiune $pkg:"
    cat "$WORKDIR/$pkg/size"
    echo "KB"
}

total_size() {
    echo "Dimensiune totala instalata:"
    cat "$WORKDIR/total_size"
    echo "KB"
}

#meniu client

case "$1" in
    installed)
        list_installed
        ;;
    removed)
        list_removed
        ;;
    history)
        history_pkg "$2"
        ;;
    period)
        period "$2" "$3"
        ;;
    size)
        pkg_size "$2"
        ;;
    totalsize)
        total_size
        ;;
    undo)
        undo_list
        ;;
    undo-install)
        undo_install "$2"
        ;;
    *)
        echo "Utilizare:"
        echo "  installed"
        echo "  removed"
        echo "  history <pachet>"
        echo "  period \"YYYY-MM-DD HH:MM:SS\" \"YYYY-MM-DD HH:MM:SS\""
        echo "  size <pachet>"
        echo "  totalsize"
        echo "  undo"
        echo "  undo-install <index pachet>"
        ;;
esac