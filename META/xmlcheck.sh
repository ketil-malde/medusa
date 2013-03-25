#!/bin/bash

META=META
ERROR=0

error(){
    echo ERROR: $*
    ERROR=1
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

# convert to RNG:
trang $META/meta.rnc $META/meta.rng

# validate the XML against schema
xmlstarlet val -e -r $META/meta.rng $M || error "$M failed to validate."

# Check files exist, checksums, file types
echo "Checking files:"
FILES=`xmlstarlet sel -t -m "//file" -v "@path" -n $M`
for f in $FILES; do
  [ -f $D/$f ] || error "File $f not found."
  md5=`xmlstarlet sel -t -m "//file[@path='$f']" -v "@md5" -n $M`
  cd $D; echo "$md5  $f" | md5sum -c 2> /dev/null || error "Checksum mismatch for $f"; cd -
  type=`xmlstarlet sel -t -m "//file[@path='$f']" -v "@mimetype" -n $M`
  grep -q "^$type\$" $META/mimetypes.txt || warn "$f has unknown mimetype $type"
done

for a in `cd $D && find . | sed -e 's/^\.\///g' | grep -v meta.xml`; do
    echo $FILES | grep -q $a || warn "File $a not mentioned in $M"
done

echo "Checking links:"
LINKS=`xmlstarlet sel -t -m "//dataset" -v "@id" -n $M`
for a in $LINKS; do
  [ -d $a ] || warn "Dataset $a referenced, but not found"
done

if [ $ERROR -eq "0" ]; then 
  echo "XMLcheck: $D is okay"
else
  echo "Errors occured"
  exit -1
fi