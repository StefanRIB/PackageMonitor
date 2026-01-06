#!/bin/bash

WORKDIR="/var/lib/packagemonitor"
CACHE_FILE="$WORKDIR/undo_cache"
MAX_UNDO=5 

mkdir -p "$WORKDIR"
touch "$CACHE_FILE"

#adauga pachet in undo cache
add_to_undo_cache() {
    local pkg="$1"

    echo "DEBUG: add_to_undo_cache called with $pkg" >> /tmp/undo_debug.log

    #creeaza cache
    touch "$CACHE_FILE"

    #scoate pachetul daca exista
    grep -v "^$pkg$" "$CACHE_FILE" > "$CACHE_FILE.tmp" || true

    # adauga pachetul ca CEL MAI RECENT
    {
        echo "$pkg"
        cat "$CACHE_FILE.tmp"
    } > "$CACHE_FILE"

    rm -f "$CACHE_FILE.tmp"

    # limiteaza la 5 intrari 
    head -n "$MAX_UNDO" "$CACHE_FILE" > "$CACHE_FILE.tmp"
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

# afiseaza undo cache
undo_list() {
    echo "Cele mai recente remove-uri:"
    nl -w2 -s'. ' "$CACHE_FILE"
}

# reinstaleaza pachetul cu indexul dat
undo_install() {
    local index="$1"
    pkg=$(sed -n "${index}p" "$CACHE_FILE")

    if [ -z "$pkg" ]; then
        echo "Index invalid"
        return 1
    fi

    echo "Reinstalez pachetul: $pkg"
    sudo apt-get install -y "$pkg"
}