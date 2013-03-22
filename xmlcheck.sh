#!/bin/bash

error(){
    echo ERROR: $*
    exit -1
}

warn(){
    echo WARNING: $*
}

# Check a data set (directory) if it conforms to conventions
D=$1

echo "XMLcheck: checking $D"

# check that directory exists and contains "meta.xml"
[ -f $D/meta.xml ] || error "Couldn't find $D/meta.xml"
M=$D/meta.xml

# validate the XML against schema
xmlstarlet val -r meta.rng $M

# Check files exist, checksums, file types
echo "Checking files:"
FILES=`xmlstarlet sel -t -m "//file" -v "@path" -n $M`
for f in $FILES; do
  [ -f $f ] || error "File $f not found."
  md5=`xmlstarlet sel -t -m "//file[@path='$f']" -v "@md5" -n $M`
  echo "$md5  $f" | md5sum -c 2> /dev/null || error "Checksum mismatch for $f"
  type=`xmlstarlet sel -t -m "//file[@path='$f']" -v "@mimetype" -n $M`
  grep -q '^\$type$' mimetypes.txt || warn "$f has unknown mimetype $type"
done

echo "XMLcheck: $D is okay"