#!/bin/bash
set -euf -o pipefail

# Generate a skeleton meta.xml file
. "$MDZ_DIR/functions.sh"

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
	bam)	echo -n "application/x-bam" ;;
	bai)	echo -n "application/x-bamindex" ;;
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
echo '<meta name="'$NAME'">' > meta.xml
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
  #  sha1=`checksum "$a"` - add checksums on import
  fpath=`echo "$a" | cut -d/ -f2-`
  echo >> meta.xml '  <file path="'$fpath'"'
  # echo >> meta.xml '        sha1="'$sha1'"'
  echo -n >> meta.xml '        mimetype="'
  mimetype "$fpath" >> meta.xml
  echo >> meta.xml '">'
  echo >> meta.xml '        ...'
  echo >> meta.xml '  </file>'
  chmod ugo-w "$a"
done

cat >> meta.xml << EOF
</contents>
</meta>
EOF

# chmod -w .
