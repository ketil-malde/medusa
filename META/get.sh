#!/bin/bash

# get a data set

# MDZ_REPO_METHOD
# MDZ_REPOSITORY
# MDZ_DATADIR

TARGET="$MDZ_DATADIR/$1"

error(){
    echo "Error: $*"
    exit -1
}

# create the target data dir
mkdatadir(){
    mkdir "$TARGET" || error "Could not create directory $TARGET"
}

# extract list of files from meta.xml
getfiles(){
    xmlstarlet sel -t -m "//file" -v "@path" -n "$1"
}

case "$MDZ_REPO_METHOD" in
    scp)
        mkdatadir
	scp "$MDZ_REPOSITORY/$1/meta.xml" "$TARGET/"
	for path in `getfiles $TARGET/meta.xml`; do
	    scp "$MDZ_REPOSITORY/$1/$path" "$TARGET/$path"
        done
    ;;

    *)
    error "Unknown repository access method $MDZ_REPO_METHOD"
    ;;
esac
