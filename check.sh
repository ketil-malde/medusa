#!/bin/bash

[ -z "$MDZ_DIR" ]         && error "MDZ_DIR undefined"
[ -z "$MDZ_DATADIR" ]     && error "MDZ_DATADIR undefined"

set -euf -o pipefail
. "$MDZ_DIR/functions.sh"
. "$MDZ_DIR/formats.sh"

# Override warn() to track return value
ERROR=0
WARN=0
warn(){
    echo "${Y}WARNING:${N} $@"
    WARN=1
}

# convert to RNG if RNC is newer:
test $MDZ_DIR/meta.rnc -nt $MDZ_DIR/meta.rng && (trang $MDZ_DIR/meta.rnc $MDZ_DIR/meta.rng || error "Can't update $MDZ_DIR/meta.rng")

# Iterate over data sets specified on command line
for D in "$@"; do
    is_valid_id "$D" || error "$D is not a valid ID"
    note "Checking dataset $D:"
    is_dataset "$D" || error "$D is not a valid dataset"
    M=$(datafile "$D")
    [ "$(checksum "$M")" = "$D" ] || error "$D checksum mismatch!"
    # validate the XML against schema
    xmlstarlet val -e -r "$MDZ_DIR/meta.rng" "$M" || error "$D failed to validate."
    echo -n "Name: "
    xmlstarlet sel -t -m "/meta" -v "@name" -n "$M"
    echo    

    echo "Checking files..."
    while read f; do
      sha1=$(xmlstarlet sel -t -m "//file[@path='$f']" -v "@sha1" -n "$M")
      [ -f "$(datafile $sha1)" ] || error "File '$f' (object $sha1) does not exist."
      type=$(xmlstarlet sel -t -m "//file[@path='$f']" -v "@mimetype" -n "$M")
      grep -q "^$type\$" $MDZ_DIR/mimetypes.txt || warn "File '$f' has unknown mimetype \"$type\""
      # check format
      if [ "${MDZ_QUICK_MODE}" = "0" ]; then
	  check_format "$(datafile "$sha1")" "$type"
      fi
    done < <(files "$D")

    echo "Checking links..."
    while read a; do
	[ -f "$(datafile "$a")" ] || warn "Dataset '$a' referenced, but not found"
    done < <(xmlstarlet sel -t -m "//dataset" -v "@id" -n "$M")
    echo
done

if [ ! $ERROR -eq "0" ]; then 
  echo "${R}$D had errors${N}"
  exit -1
elif [ ! $WARN -eq "0" ]; then
  echo "${Y}$D had warnings${N}"
  exit 1
else
  echo "${G}$D is okay${N}"
  exit 0
fi
