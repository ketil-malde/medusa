#!/bin/bash

# Generate a skeleton meta.xml file

error(){
	echo ERROR: $*
	exit -1
}

if test -z "$*"; then
	echo "Usage: $0 dataset"
	exit -1
fi

DIR=$1

test -d $DIR || error "Data set $DIR not found"
test ! -e $DIR/meta.xml || error "$DIR/meta.xml already exists"

cd $DIR
echo '<meta id="'$DIR'" version="1">' > meta.xml
cat >> meta.xml << EOF
<description>
  ...
</description>
<provenance>
  ...
</provenance>
<contents>
EOF

for a in `find . -type f | grep -v meta.xml`; do
  x=`md5sum $a`
  md5=`echo $x | cut -c-32`
  fpath=`echo $x | cut -c36-`
  echo >> meta.xml '  <file path="'$fpath'"'
  echo >> meta.xml '        md5="'$md5'"'
  echo >> meta.xml '        mimetype="unknown">'
  echo >> meta.xml '        ...'
  echo >> meta.xml '  </file>'
done

cat >> meta.xml << EOF
</contents>
</meta>
EOF

