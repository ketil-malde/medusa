#!/bin/bash
set -uf -o pipefail

for name in $(ls "$MDZ_DATADIR"); do 
  path="$MDZ_DATADIR/$name"
  a="$path/meta.xml"
  echo url="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX/$name"
  echo name=$name
  xmlstarlet sel -t -m "//species" -o "species= " -v "@sciname" -o "     " -v "@tsn" -o "        " -v "." -n $a | grep -v "^$"
  xmlstarlet sel -t -m "//file" -o "filetype=" -v "@path" -o "   " -v "@mimetype" -n $a  | grep -v "^$"
  echo "sample="`xmlstarlet sel -t -m "//description" -v "." $a`
  echo
done | scriptindex -v --overwrite $MDZ_XAPIAN_DIR/$MDZ_XAPIAN_DB $MDZ_DIR/services/xapian-index/index.def

# When using sshfs, the allow_other option must be set, like so:
# sshfs -o allow_other zeus:/data/genomdata /data/genomdata
