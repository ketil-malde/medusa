#!/bin/bash

DIR=/data/genomdata
TARGET_DIR=/tmp/viroblast

mkdir -p $TARGET_DIR/db/nucleotide 
mkdir -p $TARGET_DIR/db/protein 
echo -n > /tmp/nucleotide
echo -n > /tmp/protein

# Find all files of type text/x-fasta-*
# link them to target_dir
# add them (with description) to viroblast.ini

for a in `find $DIR -name meta.xml`; do
  name=`dirname $a`
  dataset=`basename $name`

  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-dna']" -v @path -o "	" -v "." -n $a | grep -v '^$' | while read rec; do
    fpath=`echo "$rec" | cut -d '	' -f1`
    fdesc=`echo "$rec" | cut -d '	' -f2 | tr , \;`
    ln -fs $DIR/$dataset/$fpath $TARGET_DIR/db/nucleotide/
    echo "`basename $fpath` => [$dataset]: $fdesc (DNA)" >> /tmp/nucleotide
  done

  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-rna']" -v @path -o "	" -v "." -n $a | grep -v '^$' | while read rec; do
    fpath=`echo "$rec" | cut -d '	' -f1`
    fdesc=`echo "$rec" | cut -d '	' -f2 | tr , \;`
    ln -fs $DIR/$dataset/$fpath $TARGET_DIR/db/nucleotide/
    echo "`basename $fpath` => [$dataset]: $fdesc (RNA)" >> /tmp/nucleotide
  done
  xmlstarlet sel -t -m "//file[@mimetype='text/x-fasta-prot']" -v @path -o "	" -v "." -n $a | grep -v '^$' | while read rec; do
    fpath=`echo "$rec" | cut -d '	' -f1`
    fdesc=`echo "$rec" | cut -d '	' -f2 | tr , \;`
    ln -fs $DIR/$dataset/$fpath $TARGET_DIR/db/protein/
    echo "`basename $fpath` => [$dataset]: $fdesc (Prot)" >> /tmp/protein
  done

done

echo > $TARGET_DIR/viroblast.ini "blast+: $TARGET_DIR/blast+/bin/"
for a in blastn tblastn tblastx; do
  echo >> $TARGET_DIR/viroblast.ini "$a: "`cat /tmp/nucleotide | tr '\n' ,`
done
for a in blastp blastx; do
  echo >> $TARGET_DIR/viroblast.ini "$a: "`cat /tmp/protein | tr '\n' ,`
done

