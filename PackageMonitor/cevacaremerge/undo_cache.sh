#!/bin/bash

CACHE_DIR="$WORKDIR/undo_cache"
CACHE_FILE="$CACHE_DIR/cache.log"
MAX_ENTRIES=5

init_undo_cache() {
    mkdir -p "$CACHE_DIR"
    touch "$CACHE_FILE"
}

add_to_undo_cache() {
    local pkg="$1"
    local size="$2"
    local date="$3"

    init_undo_cache

    echo "$date | $pkg | $size" >> "$CACHE_FILE"

    local lines
    lines=$(wc -l < "$CACHE_FILE")

    if [ "$lines" -gt "$MAX_ENTRIES" ]; then
        sed -i '1d' "$CACHE_FILE"
    fi
}

undo_list() {
    init_undo_cache

    if [ ! -s "$CACHE_FILE" ]; then
        echo "Undo cache gol"
        return
    fi

    echo "Cele mai recente remove-uri:"
    cat "$CACHE_FILE"
}

undo_install() {
    local pkg="$1"

    init_undo_cache

    if grep -q "| $pkg |" "$CACHE_FILE"; then
        echo "Reinstalez pachetul: $pkg"
        sudo apt install -y "$pkg"
    else
        echo "Pachetul nu exista in undo cache"
        return 1
    fi
}
