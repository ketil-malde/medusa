#!/bin/bash

DIR=/data/genomdata

for a in `find $DIR -name meta.xml`; do 
  echo url=`dirname $a`
  xmlstarlet sel -t -m "//species" -o "species= " -v "@sciname" -o "     " -v "@tsn" -o "        " -v "." -n $a | grep -v "^$"
  xmlstarlet sel -t -m "//file" -o "filetype=" -v "@path" -o "   " -v "@mimetype" -n $a  | grep -v "^$"
  echo "sample= "`cat $a`
  echo
done | scriptindex -v --overwrite $DIR/META/metadb $DIR/META/index.def

rm -rf /var/lib/xapian-omega/data/default                     
cp -a $DIR/META/metadb /var/lib/xapian-omega/data/default       
