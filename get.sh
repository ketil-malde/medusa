#!/bin/bash
set -u -o pipefail

# Get a data set from repository
# Uses: MDZ_REPO_METHOD MDZ_REPOSITORY

TARGET="$1"

error(){
    echo "Error: $*"
    # clean up
    [ -z "$CLEANUP" ] && rm -rf "$TARGET"
    exit -1
}

# create the target data dir
mkdatadir(){
    mkdir "$TARGET" || CLEANUP=no error "Could not create directory $TARGET"
}

# extract list of files from meta.xml
getfiles(){
    xmlstarlet sel -t -m "//file" -v "@path" -n "$1"
}

CLEANUP=no
[ -z "$1" ]               && error "Usage: $0 <dataset>"
[ -e "$TARGET" ]          && "$TARGET already exists"
[ -z "$MDZ_REPO_METHOD" ] && error "MDZ_REPO_METHOD undefined"
[ -z "$MDZ_REPOSITORY" ]  && error "MDZ_REPOSITORY undefined"
CLEANUP=

case "$MDZ_REPO_METHOD" in
    scp)
        mkdatadir
	scp "$MDZ_REPOSITORY/$1/meta.xml" "$TARGET/"   || error "Failed to download $MDZ_REPOSITORY/$1/meta.xml"
	for path in `getfiles $TARGET/meta.xml`; do
	    scp "$MDZ_REPOSITORY/$1/$path" "$TARGET/$path"
        done
    ;;

    *)
    error "Unknown repository access method $MDZ_REPO_METHOD"
    ;;
esac
