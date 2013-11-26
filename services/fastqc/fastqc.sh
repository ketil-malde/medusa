#!/bin/bash

set -euf -o pipefail

error(){
    echo "Error: $*"
    exit -1
}

[ "$#" = "2" ] || error "Usage: fastqc <dataset> <output>"

INPUT=$1
mkdir "$2" || error "Failed to make ouptut directory \"$2\""
cd "$2"
TARGET=$(pwd -P)
THREADS=`nproc`
cd -

# extract all fastq-files from input
cd "$INPUT" || error "Couldn't navigate to input dataset \"$INPUT\""
xmlstarlet sel -t -m "//file[@mimetype='text/x-fastq']" -v "@path" -n meta.xml | while read FILE; do
  # run fastq
  fastqc -t "$THREADS" -o "$TARGET" "$FILE"
done

# generate metadata
# link to dataset-id
# link to file names
# build summary page?

cd -

