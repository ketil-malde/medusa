#!/bin/bash

[ -z "$MDZ_DIR" ]         && error "MDZ_DIR undefined"
[ -z "$MDZ_DATADIR" ]     && error "MDZ_DATADIR undefined"

set -euf -o pipefail
. "$MDZ_DIR/functions.sh"
. "$MDZ_DIR/formats.sh"

# Export a dataset

CP="ln -s"

for D in "$@"; do
    assert_is_dataset "$D"
    note "Exporting $D:"
    M="$(datafile "$D")"
    NAME=$(xmlstarlet sel -t -m "/meta" -v "@name" -n "$M")
    mkdir "$NAME" || error "Can't make directory '$NAME'"
    $CP "$M" "$NAME/meta.xml"
    xmlstarlet sel -t -m "//file" -v "@path" -o "	" -v "@sha1" -n "$M" | \
	while read p s; do
	    DIR="$(dirname "$NAME/$p")"
	    mkdir -p "$DIR" || error "Failed to create target dir '$DIR'"
	    $CP "$(datafile "$s")" "$NAME/$p"
	done
done
