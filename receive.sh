#!/bin/bash

DIR=$(mktemp -d "./mdz_recv_XXXX")

cd "$DIR"
tar zxf -

# check contents
for f in $(ls); do
    is_valid_id "$f" || error "Not a valid data id: $f"
    [ -f "$(datafile "$f")" ] && warn "Data object $f is already present - ignoring"
    if test "$(head -c 5 "$f")" = "<?xml" && test "$(tail -n +2 "$f" | head -c 5)" = "<meta"; then
	# is a metadata object
	echo "Received dataset: $f"
	[ "$(checksum "$f")" = "$f" ] || error "Checksum failed for $f"	
	echo -n "Contents: "
	xmlstarlet sel -t -m //file -v "@sha1" -n "$f" | grep . | \
	    while read x; do
		echo -n " $x"
		[ -f "$x" ] || error "Dataset $f refers object $x, but it is not present"
		[ "$(checksum "$x")" = "$x" ] || error "Checksum failed for $x"
	    done
	echo "."
    fi
done

## ask for confirmation - only if non-interactive
echo "Importing..."
# import into repository
for f in $(ls); do
    echo "Importing object $f..."
    t="$(datafile "$f")"
    [ -f "$t" ] || mv "$f" "$t"
done
cd .. && rm -rf "$DIR"
