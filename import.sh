#!/bin/bash

# Import a directory as a dataset
# calculate checksums and store in database

[ -z "$MDZ_DIR" ]         && error "MDZ_DIR undefined"
[ -z "$MDZ_DATADIR" ]     && error "MDZ_DATADIR undefined"

set -euf -o pipefail
. "$MDZ_DIR/functions.sh"
. "$MDZ_DIR/formats.sh"

# Override to track warnings
WARN=0
warn(){
    echo "${Y}WARNING:${N} $@"
    ((WARN+=1))
}

D="$1"
M="$D/meta.xml"

# convert to RNG if RNC is newer:
test $MDZ_DIR/meta.rnc -nt $MDZ_DIR/meta.rng && (trang $MDZ_DIR/meta.rnc $MDZ_DIR/meta.rng || error "Can't update $MDZ_DIR/meta.rng")

# Plan: Check meta.xml, add checksums, store in DB

[ -d "$D" ] || error "$D is not a directory"
[ -f "$M" ] || error "$M does not exist"

grep -q '^  *\.\.\.$' "$M" && warn "meta.xml seems incomplete - please fill in details"

# check file formats
cp "$M" tmp.xml
while read f t; do
    echo "Processing file $f"
    echo "  ...calculating hash"
    sha1="$(checksum "$D/$f")"
    xmlstarlet ed -i "//file[@path='$f']" -t attr -n "sha1" -v "$sha1" tmp.xml > tmp2.xml
    mv tmp2.xml tmp.xml
    if [ -f "$(datafile "$sha1")" ]; then
	warn "$sha1 already exists - possible SHA1 collision?"
    fi
    echo "  ...checking format"
    grep -q "^$t\$" "$MDZ_DIR/mimetypes.txt" || warn "$f has unknown mimetype \"$t\""
    check_format "$D/$f" "$t"
done < <(xmlstarlet sel -t -m "//file" -v "@path" -o "	" -v "@mimetype" -n "$M")

# check references
while read a; do
    [ -f "$(datafile "$a")" ] || warn "Dataset '$a' is referenced, but does not exist"
done < <(xmlstarlet sel -t -m "//dataset" -v "@id" -n "$M")

# Check for dataset with same name (and no parentage)

# Populate xml with sha1 checksums, then:
xmlstarlet val -e -r "$MDZ_DIR/meta.rng" tmp.xml || error "$D failed to validate."

# Abort if metadata already exists
sha1="$(checksum tmp.xml)"
[ -f "$(datafile "$sha1")" ] && error "$sha1 already exists - aborting!"

# Done: on warning, ask for confirmation
if [ ! "$WARN" -eq "0" ]; then
    echo -n "Warnings occurred, still proceed with import (y/n)? "
    read a
    if [ ! "$a" = "y" ]; then
	echo "OK, aborting!"
	exit 0
    fi
fi

echo "Importing..."
# for each file, copy it to its checksum id
while read f s; do
    echo "Importing $f"
    if [ -f "$(datafile "$s")" ]; then
	warn "$s already exists - ignoring import of $f"
    else
	tgt="$(datafile "$s")"
	[ -d "$(dirname "$tgt")" ] || mkdir -p "$(dirname "$tgt")"
	cp "$D/$f" "$tgt"
	chmod 0444 "$tgt"
    fi
done < <(xmlstarlet sel -t -m "//file" -v "@path" -o "	" -v "@sha1" -n tmp.xml)

# Finally copy the metadata file to its checksum ID
echo "Importing metadata file"
tgt="$(datafile "$sha1")"
[ -d "$(dirname "$tgt")" ] || mkdir -p "$(dirname "$tgt")"
mv tmp.xml "$tgt"
echo "done!"

