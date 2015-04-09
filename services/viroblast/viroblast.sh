#!/bin/bash
set -u -o pipefail
shopt -s failglob
. "$MDZ_DIR/functions.sh"

DIR=$MDZ_DATADIR
TARGET_DIR=$MDZ_VIROBLAST_DIR

[ -d "$TARGET_DIR" ] || mkdir -p "$TARGET_DIR" || error "Viroblast target dir '$TARGET_DIR' does not exist"

mkdir -p $TARGET_DIR/db/nucleotide 
mkdir -p $TARGET_DIR/db/protein 
echo -n > /tmp/nucleotide
echo -n > /tmp/protein

# Use BLAST+ included with Viroblst
formatdb(){
   "$MDZ_VIROBLAST_DIR/blast+/bin/makeblastdb" -in "$1" -dbtype "$2"
}

# Find all files of type text/x-fasta-*
# link them to target_dir
# add them (with description) to viroblast.ini

add_nuc(){
    fpath=`echo "$1" | cut -d '	' -f1`
    fdesc=`echo "$1" | cut -d '	' -f2 | tr , \;`
    fname=`basename $fpath`
    echo "Adding nucleotide file $fpath as [$2] $fdesc"
    if [ -f $TARGET_DIR/db/nucleotide/$fname ]; then
	echo -n
    else
	(cd $TARGET_DIR/db/nucleotide/ && ln -fs $DIR/$dataset/$fpath . && formatdb $fname nucl)
    fi
    echo "`basename $fpath` => [$2] $fdesc ($3)" >> /tmp/nucleotide
}

add_prot(){
    fpath=`echo "$1" | cut -d '	' -f1`
    fdesc=`echo "$1" | cut -d '	' -f2 | tr , \;`
    fname=`basename $fpath`
    echo "Adding protein file $fpath as [$2] $fdesc"
    if [ -f $TARGET_DIR/db/protein/$fname ]; then
	echo -n
    else
	(cd $TARGET_DIR/db/protein/ && ln -fs $DIR/$dataset/$fpath . && formatdb $fname prot)
    fi
    echo "`basename $fpath` => [$2] $fdesc (Prot)" >> /tmp/protein
}

filter(){
  grep -v '^[ 	]*$' |  sed 'N;s/	\n[ 	]*/	/g'
}

for x in "$(datasets)"; do
  a="$(datafile "$x")"
  dataset="$(xmlstarlet sel -t -m /meta -v "@name" -n "$a")"

  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-dna']" -v @path -o "	" -v "." -n $a | filter | while read rec; do
    add_nuc "$rec" "$dataset" "DNA"
  done

  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-rna']" -v @path -o "	" -v "." -n $a | filter | while read rec; do
    add_nuc "$rec" "$dataset" "RNA"
  done

  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-prot']" -v @path -o "	" -v "." -n $a | filter | while read rec; do
    add_prot "$rec" "$dataset" 
  done
done

set -f
echo > $TARGET_DIR/viroblast.ini "blast+: $TARGET_DIR/blast+/bin/"
for a in blastn tblastn tblastx; do
  echo >> $TARGET_DIR/viroblast.ini "$a: "`cat /tmp/nucleotide | tr '\n' ,`
done
for a in blastp blastx; do
  echo >> $TARGET_DIR/viroblast.ini "$a: "`cat /tmp/protein | tr '\n' ,`
done

