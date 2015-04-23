#!/bin/bash

# pack a list of data sets as a tar file to standard output

DIR=$(mktemp -d "./mdz_send_XXXX")

# list all files (by path) in a dataset
files_by_id(){
    D="$1"
    assert_is_dataset "$D"
    xmlstarlet sel -t -m //file -v "@sha1" -n "$(datafile "$D")" | grep .
}

cd "$DIR"
for d in "$@"; do
    is_valid_id "$d" || error "Invalid data ID: $d"
    if is_dataset "$d"; then
	for f in $(files_by_id "$d"); do
	    ln -s $(datafile "$f")
	done
    fi
    ln -s $(datafile "$d")
done

tar chzf - . && cd .. && rm -rf "$DIR"

