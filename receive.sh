#!/bin/bash

DIR=$(mktemp -d "$MDZ_DATADIR/mdz_recv_XXXX")

cd "$DIR"
tar zxf -

# check contents
for f in $(ls); do
    is_valid_id "$f" || error "Not a valid data id: $f"
    tgt="$(datafile "$f")"
    [ -f "$tgt" ] && warn "Object $f is already present - ignoring"
    if test "$(head -c 5 "$f")" = "<?xml" && test "$(tail -n +2 "$f" | head -c 5)" = "<meta"; then
	# is a metadata object
	echo "Received dataset: $f"
	[ "$(checksum "$f")" = "$f" ] || error "Checksum failed for $f"	
	xmlstarlet val -e -r "$MDZ_DIR/meta.rng" "$f" || error "$f failed to validate."
	echo -n "Contents: "
	xmlstarlet sel -t -m //file -v "@sha1" -n "$f" | grep . | \
	    while read x; do
		echo -n " $x"
		[ -f "$x" ] || error "Dataset $f refers object $x, but it is not present"
		[ -f "$tgt" ] || [ "$(checksum "$x")" = "$x" ] || error "Checksum failed for $x"
	    done
	echo "."
    fi
done

## ask for confirmation - only if non-interactive
echo -n "Importing..."
# import into repository
for f in $(ls); do
    t="$(datafile "$f")"
    [ -d "$(dirname "$t")" ] || mkdir -p "$(dirname "$t")"
    [ -f "$t" ] || mv "$f" "$t"
done
cd .. && rm -rf "$DIR"
echo "done!"
