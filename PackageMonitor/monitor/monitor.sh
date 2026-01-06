#!/bin/bash

LOG="/var/log/dpkg.log"
WORKDIR="/var/lib/packagemonitor"
STATEFILE="$WORKDIR/.last_line"

mkdir -p "$WORKDIR"

if [ ! -f "$STATEFILE" ]; then
	echo 0 > "$STATEFILE"
fi

LAST_LINE=$(cat "$STATEFILE")
CURRENT_LINE=0

while read -r line; do
	CURRENT_LINE=$((CURRENT_LINE + 1))
	
	if [ "$CURRENT_LINE" -le "$LAST_LINE" ]; then
		continue
	fi
	
	DATE=$(echo "$line" | awk '{print $1" "$2}')
	ACTION=$(echo "$line" | awk '{print $3}')
	PACKAGE_RAW=$(echo "$line" | awk '{print $4}')
	PACKAGE=${PACKAGE_RAW%%:*}
	
	if [ -z "$PACKAGE" ]; then
		continue
	fi
	
	PKGDIR="$WORKDIR/$PACKAGE"
	mkdir -p "$PKGDIR"
	touch "$PKGDIR/history.log"
	
	if [ "$ACTION" = "install" ] && [ ! -f "$PKGDIR/first_install" ]; then
		echo "$DATE" > "$PKGDIR/first_install"
	fi
	
	case "$ACTION" in
		install)
			echo "$DATE install" >> "$PKGDIR/history.log"
			echo "installing" > "$PKGDIR/status"
			;;
		half-installed|unpacked)
			echo "$DATE partial-install" >> "$PKGDIR/history.log"
			echo "partial" > "$PKGDIR/status"
			;;
		configure)
			echo "$DATE install" >> "$PKGDIR/history.log"
			echo "installed" > "$PKGDIR/status"
			;;
		remove|purge)
			echo "$DATE remove" >> "$PKGDIR/history.log"
			echo  "removed" > "$PKGDIR/status"
			;;
	esac

done < "$LOG"

echo "$CURRENT_LINE" > "$STATEFILE"

exit 0
