#!/bin/bash
set -u -o pipefail
shopt -s failglob
. "$MDZ_DIR/functions.sh"

TARGET_DIR="$MDZ_VIROBLAST_DIR"

[ -d "$TARGET_DIR" ] || mkdir -p "$TARGET_DIR" || error "Viroblast target dir '$TARGET_DIR' does not exist"

mkdir -p "$TARGET_DIR/db/nucleotide"
mkdir -p "$TARGET_DIR/db/protein" 
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
    sha1="$1"
    fpath="$2"
    fdesc="$3"
    dset="$4"
    ftype="$5"
    echo "Adding nucleotide file $sha1 as [$dset] $fdesc"
    if [ -f "$TARGET_DIR/db/nucleotide/$sha1" ]; then
	echo -n
    else
	(cd $TARGET_DIR/db/nucleotide/ && ln -fs "$(datafile "$sha1")" . && formatdb "$sha1" nucl)
    fi
    echo "$sha1 => [$dset] $fdesc ($ftype)" >> /tmp/nucleotide
}

add_prot(){
    sha1="$1"
    fpath="$2"
    fdesc="$3"
    dset="$4"
    echo "Adding protein file $sha1 as [$dset] $fdesc"
    if [ -f "$TARGET_DIR/db/protein/$fname" ]; then
	echo -n
    else
	(cd "$TARGET_DIR/db/protein/" && ln -fs "$(datafile "$sha1")" . && formatdb "$sha1" prot)
    fi
    echo "$sha1 => [$dset] $fdesc (Prot)" >> /tmp/protein
}

filter(){
  grep -v '^[ 	]*$' |  sed 'N;s/	\n[ 	]*/	/g'
}

datasets | while read x; do
  a="$(datafile "$x")"
  dataset="$(xmlstarlet sel -t -m /meta -v "@name" -n "$a")"

  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-dna']" -v @sha1 -o "	" -v @path -o "	" -v "." -n "$a" | filter | while read cs path desc; do
    add_nuc "$cs" "$path" "$desc" "$dataset" "DNA"
  done

  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-rna']" -v @sha1 -o "	" -v @path -o "	" -v "." -n "$a" | filter | while read cs path desc; do
    add_nuc "$cs" "$path" "$desc" "$dataset" "DNA"
  done

  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-prot']" -v @sha1 -o "	" -v @path -o "	" -v "." -n "$a" | filter | while read cs path desc; do
    add_prot "$cs" "$path" "$desc" "$dataset" 
  done
done

set -f
echo > $TARGET_DIR/viroblast.ini "blast+: $TARGET_DIR/blast+/bin/"
for a in blastn tblastn tblastx; do
  echo >> $TARGET_DIR/viroblast.ini "$a: $(tr '\n' , < /tmp/nucleotide)"
done
for a in blastp blastx; do
  echo >> $TARGET_DIR/viroblast.ini "$a: $(tr '\n' , < /tmp/protein)"
done

