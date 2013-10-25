#!/bin/bash

# Generate a skeleton meta.xml file

error(){
	echo >&2 ERROR: $*
	exit -1
}

mimetype(){
	SUF=`echo "$1" | sed -e 's/^.*\.\([^.]*\)$/\1/g'`
	# echo \"$1\" : suffix = $SUF
	case $SUF in
	fastq)	echo -n "text/x-fastq" ;;
	pdf)    echo -n "application/pdf" ;;
        [tc]sv)	echo -n "text/csv" ;;
	gff3|gff)
		echo -n "text/x-gff3" ;;
	sff)	echo -n "application/x-sff" ;;
	fasta|fa)
	        echo -n "text/x-fasta" ;;
	fna)	echo -n "text/x-fasta-dna-or-rna" ;;
	aa|faa)	echo -n "text/x-fasta-prot" ;;
	txt)	echo -n "text/plain" ;;
	html)	echo -n "text/html" ;;
	*)	echo >&2 "Unknown file type: $1"; echo -n "unknown" ;;	
	esac
}

if test -z "$*"; then
	echo "Usage: $0 dataset"
	exit -1
fi

DIR=$1

test -d $DIR || error "Data set $DIR not found"
test ! -e $DIR/meta.xml || error "$DIR/meta.xml already exists"

cd $DIR
NAME=`basename "$DIR"`
echo '<meta id="'$NAME'" version="1">' > meta.xml
cat >> meta.xml << EOF
<description>
  ...
</description>
<provenance>
  ...
</provenance>
<contents>
EOF

find . -type f | grep -v meta.xml | while read a; do
  x=`md5sum "$a"`
  md5=`echo "$x" | cut -c-32`
  fpath=`echo "$a" | cut -d/ -f2-`
  echo >> meta.xml '  <file path="'$fpath'"'
  echo >> meta.xml '        md5="'$md5'"'
  echo -n >> meta.xml '        mimetype="'
  mimetype "$fpath" >> meta.xml
  echo >> meta.xml '">'
  echo >> meta.xml '        ...'
  echo >> meta.xml '  </file>'
done

cat >> meta.xml << EOF
</contents>
</meta>
EOF

