#!/bin/bash

DATA_DIR=/data/genomdata
META=META
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

# check that directory exists and contains "meta.xml"
if [ ! -f $D/meta.xml ]; then
  error "Couldn't find $D/meta.xml"
  exit -1
fi

M=$D/meta.xml

# convert to RNG if RNC is newer:
test $META/meta.rnc -nt $META/meta.rng && (trang $META/meta.rnc $META/meta.rng || error "Can't update $META/meta.rng")

# validate the XML against schema
xmlstarlet val -e -r $META/meta.rng $M || error "$M failed to validate."

grep -q '^  *\.\.\.$' $M && warn "meta.xml seems incomplete - please fill in details"

if [ -f $M ]; then
   # Check that ID matches the directory name
   ID=`xmlstarlet sel -t -m "//meta" -v "@id" $M`
   if [ "$ID" \!= `basename $D` ]; then
	error "ID of $ID doesn't match "`basename $D`
   fi

   # Check that metadata is unchanged if version is unchanged
   META_MD5=`md5sum $M | cut -f1 -d' '`
   VER=`xmlstarlet sel -t -m "//meta" -v "@version" $M`
   OLD=`grep "$ID	$VER	" "$DATA_DIR/META/meta_checksums"`
   if grep -q "$ID	" "$DATA_DIR/META/meta_checksums"; then
      if [ -z "$OLD" ]; then
	echo "Registering new version: $ID $VER"
	echo "$ID	$VER	$META_MD5" >> $DATA_DIR/META/meta_checksums
      else
	S_OLD=`echo "$OLD" | cut -f3`
	if [ "$META_MD5" \!= "$S_OLD" ]; then
	   error "$ID version $VER exists, but has different checksum! $META_MD5 vs $S_OLD"
        fi
      fi
   else # new dataset
        echo "Registering new dataset: $ID $VER"
        echo "$ID	$VER	$META_MD5" >> $DATA_DIR/META/meta_checksums
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
    grep -q "^$type\$" $META/mimetypes.txt || warn "$f has unknown mimetype \"$type\""
  done
  echo

  RFILES=`cd $D && find . | sed -e 's/^\.\///g' | grep -v '^.$' | tr ' ' '?' | grep -v meta.xml`
  for a in $RFILES; do
    f=`echo $a | tr '?' ' '`
    echo $FILES | grep -q "$f" || warn "File \"$f\" not mentioned in $M"
  done

  echo -n "Checking links: "
  LINKS=`xmlstarlet sel -t -m "//dataset" -v "@id" -n $M`
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
