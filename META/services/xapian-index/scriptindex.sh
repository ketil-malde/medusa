#!/bin/bash

DIR=/data/genomdata

for a in `find $DIR -name meta.xml`; do 
  name=`dirname $a`
  echo url="http://nmdbio"$name
  echo name=`basename $name`
  xmlstarlet sel -t -m "//species" -o "species= " -v "@sciname" -o "     " -v "@tsn" -o "        " -v "." -n $a | grep -v "^$"
  xmlstarlet sel -t -m "//file" -o "filetype=" -v "@path" -o "   " -v "@mimetype" -n $a  | grep -v "^$"
  echo "sample= "`xmlstarlet sel -t -m "//description" -v "." $a`
  echo
done | scriptindex -v --overwrite $DIR/META/metadb/default $DIR/META/index.def

# rm -rf /var/lib/xapian-omega/data/default                     
# cp -a $DIR/META/metadb /var/lib/xapian-omega/data/default       

# When using sshfs, the allow_other option must be set, like so:
# sshfs -o allow_other zeus:/data/genomdata /data/genomdata
