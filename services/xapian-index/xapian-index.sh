#!/bin/bash
set -uf -o pipefail

. "$MDZ_DIR/functions.sh"

datasets | while read name; do
  echo url="/$MDZ_WEBSITE_DATA_PREFIX/$name"
  echo name="$name"
  a="$(datafile "$name")"
  xmlstarlet sel -t -m "//species" -o "species= " -v "@sciname" -o "     " -v "@tsn" -o "        " -v "." -n "$a" | grep -v '^$'
  xmlstarlet sel -t -m "//file" -o "filetype=" -v "@path" -o "   " -v "@mimetype" -n "$a"  | grep -v '^$'
  echo "sample=$(xmlstarlet sel -t -m "//description" -v "." "$a")"
  echo
done | scriptindex -v --overwrite "$MDZ_XAPIAN_DIR/$MDZ_XAPIAN_DB" "$MDZ_DIR/services/xapian-index/index.def"

# When using sshfs, the allow_other option must be set, like so:
# sshfs -o allow_other zeus:/data/genomdata /data/genomdata
