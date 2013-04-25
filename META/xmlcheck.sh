#!/bin/bash

META=META
ERROR=0

# Colors
R="$(tput setaf 1)"
G="$(tput setaf 2)"
Y="$(tput setaf 3)"
N="$(tput sgr0)"

error(){
    echo
    echo ${R}ERROR:${N} $*
    ERROR=1
}

warn(){
    echo
    echo ${Y}WARNING:${N} $*
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
echo -n "Checking files: "
FILES=`xmlstarlet sel -t -m "//file" -v "@path" -n $M`
for f in $FILES; do
  echo -n .
  [ -f $D/$f ] || error "File $f not found."
  md5=`xmlstarlet sel -t -m "//file[@path='$f']" -v "@md5" -n $M`
  if [ -z ${QUICK+x} ]; then
     cd $D; echo "$md5  $f" | md5sum -c 2> /dev/null || error "Checksum mismatch for $f"; cd -
  # else
     # echo "quick mode: skipping checksumming for $f"
  fi
  type=`xmlstarlet sel -t -m "//file[@path='$f']" -v "@mimetype" -n $M`
  grep -q "^$type\$" $META/mimetypes.txt || warn "$f has unknown mimetype $type"
done
echo

if [ -f $M ]; then
  RFILES=`cd $D && find . | sed -e 's/^\.\///g' | grep -v '^.$' | grep -v meta.xml`
  for a in $RFILES; do
    echo $FILES | grep -q $a || warn "File $a not mentioned in $M"
  done

  echo -n "Checking links: "
  LINKS=`xmlstarlet sel -t -m "//dataset" -v "@id" -n $M`
  for a in $LINKS; do
    echo -n .
    [ -d $a ] || warn "Dataset $a referenced, but not found"
  done
  echo
fi

if [ $ERROR -eq "0" ]; then 
  echo "${G}XMLcheck: $D is okay${N}"
else
  echo "${R}Errors occured${N}"
  exit -1
fi
