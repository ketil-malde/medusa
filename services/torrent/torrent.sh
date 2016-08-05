#!/bin/bash
set -euf -o pipefail
. "$MDZ_DIR/functions.sh"

set -x

# Create torrent files for all data sets, and lauch
# tracker and seeder.

path="$MDZ_WEBSITE_DIR"
torrentpath="$path/torrents/"
mkdir -p "$torrentpath"

tracker="http://$(hostname):8888"

for d in $(datasets); do
    if [ -f "$torrentpath/$d.torrent" ]; then
	echo "Torrent for $d exists, skipping"
    else
        mkdir -p "$torrentpath/$d"
        ln -fs "$(datafile "$d")" "$torrentpath/$d/"
        fileids "$d" | while read f; do
	    ln -fs "$(datafile $f)" "$torrentpath/$d/"
        done
        btmakemetafile "$tracker/announce" "$torrentpath/$d" --target "$torrentpath/$d.torrent"
    fi
done

btmakemetafile "$tracker/announce" "$MDZ_DATADIR" --target "$torrentpath/repository.torrent"

# bttrack.bittornado --port 8888 --dfile bt.state &
echo "Torrents ready, start/restart seeder, e.g.:"
echo "   btlaunchmany --super_seeder 1 \"$torrentpath\""
