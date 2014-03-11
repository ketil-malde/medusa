#!/bin/bash
# based on recipe from Tomasz Furmanek

set -euf -o pipefail
. "$MDZ_DIR/functions.sh"

POP=/data/prosjekt/genom/src/popoolation2_1201/
TMP=/tmp

[ "$#" = "2" ] || error "Usage: snpcall <dataset>"

# REF=$(files_by_type "$2" text/x-fasta-nuc)
BAMS=$(files_by_type "$1" application/x-bam)
TARGET=$2
MPILE=$TMP/mpileup.out
SYNC=$TARGET/mpileup.sync

# todo: generate metadata..
mkdir -p "$TARGET" || error "Failed to create dataset dir '$TARGET'."

# do a mpileup of the mapped files (add -f reference)
samtools mpileup -B "$BAMS" > "$MPILE"

cd "$TARGET"
 
# run the (java tool) mpileup2sync.jar on the pileup file
java -ea -Xmx30g -jar "$POP/mpileup2sync.jar" --input "$MPILE" --output "$SYNC" --fastq-type sanger --min-qual 20 --threads 6

# this gives you the allele frequency differences
perl "$POP/snp-frequency-diff.pl" --input $MPILE.sync --output-prefix freqdiffs_ --min-count 3 --min-coverage 3 --max-coverage 100 &

# Fst-values: measure differentiation between populations
perl "$POP/fst-sliding.pl" --input "$SYNC" --output fst.csv --suppress-noninformative --min-count 3 --min-coverage 3 --max-coverage 100 --min-covered-fraction 1 --window-size 1 --step-size 1 --pool-size 15 &

# Calculate Fst values using a sliding window approach
perl $POP/fst-sliding.pl --input "$SYNC" --output fst-2k-window.csv --min-count 3 --min-coverage 3 --max-coverage 100 --min-covered-fraction 1 --window-size 2000 --step-size 1000 --pool-size 15 &

#Fisher's Exact Test: estimate the significance of allele frequency differences
perl "$POP/fisher-test.pl" --input "$SYNC" --output "fisher.txt" --min-count 3 --min-coverage 3 --max-coverage 100 --suppress-noninformative &

wait
cd -