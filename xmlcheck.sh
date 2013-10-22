#!/bin/bash

[ -z "$MDZ_DIR" ]         && error "MDZ_DIR undefined"
[ -z "$MDZ_DATADIR" ]     && error "MDZ_DATADIR undefined"

set -euf -o pipefail

ERROR=0
WARN=0

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
    WARN=1
}

# Check a data set (directory) if it conforms to conventions
D=$1

echo "XMLcheck: checking $D"

M=$D/meta.xml

# check that directory exists and contains "meta.xml"
if [ ! -f $M ]; then
  error "Couldn't find 'meta.xml' in $D"
  exit -1
fi

# convert to RNG if RNC is newer:
test $MDZ_DIR/meta.rnc -nt $MDZ_DIR/meta.rng && (trang $MDZ_DIR/meta.rnc $MDZ_DIR/meta.rng || error "Can't update $MDZ_DIR/meta.rng")

# validate the XML against schema
xmlstarlet val -e -r $MDZ_DIR/meta.rng $M || error "$M failed to validate."

grep -q '^  *\.\.\.$' $M && warn "meta.xml seems incomplete - please fill in details"

if [ -f $M ]; then
   # Check that ID matches the directory name
   ID=`xmlstarlet sel -t -m "//meta" -v "@id" $M`
   if [ "$ID" \!= `basename $D` ]; then
	error "ID of $ID doesn't match "`basename $D`
   fi

  if [ "$(dirname $(readlink -e $D))" = "$MDZ_DATADIR" ]; then # only register if we are in the data dir
   # Check that metadata is unchanged if version is unchanged
   META_MD5=`md5sum $M | cut -f1 -d' '`
   VER=`xmlstarlet sel -t -m "//meta" -v "@version" $M`
   OLD=`grep "$ID	$VER	" "$MDZ_DIR/meta_checksums"` || echo -n
   if grep -q "$ID	" "$MDZ_DIR/meta_checksums"; then
      if [ -z "$OLD" ]; then
	echo "Registering new version: $ID $VER"
	echo "$ID	$VER	$META_MD5" >> $MDZ_DIR/meta_checksums
      else
	S_OLD=`echo "$OLD" | cut -f3`
	if [ "$META_MD5" \!= "$S_OLD" ]; then
	   error "$ID version $VER exists, but has different checksum! $META_MD5 vs $S_OLD"
        fi
      fi
   else # new dataset
        echo "Registering new dataset: $ID $VER"
        echo "$ID	$VER	$META_MD5" >> $MDZ_DIR/meta_checksums
   fi
  fi
 
  # Check files exist, checksums, file types
  echo -n "Checking files: "
  FILES=`xmlstarlet sel -t -m "//file" -v "@path" -n $M`
  for f in $FILES; do
    [ -f $D/$f ] || error "File $f not found."
    md5=`xmlstarlet sel -t -m "//file[@path='$f']" -v "@md5" -n $M`
    if [ -z ${QUICK+x} ]; then
       cd $D ; echo "$md5  $f" | md5sum -c 2> /dev/null || error "Checksum mismatch for $f"; cd - > /dev/null
    else
       echo -n . 
       # echo "quick mode: skipping checksumming for $f"
    fi
    type=`xmlstarlet sel -t -m "//file[@path='$f']" -v "@mimetype" -n $M`
    grep -q "^$type\$" $MDZ_DIR/mimetypes.txt || warn "$f has unknown mimetype \"$type\""
  done
  echo

  RFILES=`cd $D && find . | sed -e 's/^\.\///g' | grep -v '^.$' | tr ' ' '?' | grep -v meta.xml`
  for a in $RFILES; do
    f=`echo $a | tr '?' ' '`
    echo $FILES | grep -q "$f" || warn "File \"$f\" not mentioned in $M"
  done

  echo -n "Checking links: "
  LINKS=`xmlstarlet sel -t -m "//dataset" -v "@id" -n $M` || echo -n # failure is okay
  for a in $LINKS; do
    echo -n .
    [ -d $a ] || warn "Dataset $a referenced, but not found"
  done
  echo
fi

if [ ! $ERROR -eq "0" ]; then 
  echo "${R}XMLcheck: $D had errors${N}"
  exit -1
elif [ ! $WARN -eq "0" ]; then
  echo "${Y}XMLcheck: $D had warnings${N}"
  exit 1
else
  echo "${G}XMLcheck: $D is okay${N}"
  exit 0
fi