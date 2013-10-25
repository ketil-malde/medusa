#!/bin/bash

# Put a data set (by path) from repository
# Uses: MDZ_REPO_METHOD MDZ_REPOSITORY

error(){
    echo "Error: $*"
    exit -1
}

SOURCE="$1"

[ -z "$1" ]               && error "Usage: $0 <dataset>"
[ ! -e "$SOURCE" ]        && error "$SOURCE doesn't exist"
[ -z "$MDZ_REPO_METHOD" ] && error "MDZ_REPO_METHOD undefined"
[ -z "$MDZ_REPOSITORY" ]  && error "MDZ_REPOSITORY undefined"

set -euf -o pipefail

error(){
    echo "Error: $*"
    set +u
    [ -d "$STAGE" ] && rm -rf "$STAGE"
    exit -1
}

# extract list of files from meta.xml
getfiles(){
    xmlstarlet sel -t -m "//file" -v "@path" -n "$1"
}

case "$MDZ_REPO_METHOD" in
    scp)
	RPATH=$(echo $MDZ_REPOSITORY | cut -d: -f2)
	RHOST=$(echo $MDZ_REPOSITORY | cut -d: -f1)
	NAME=`basename "$1"`
	E=$(ssh $RHOST "ls -d \"$RPATH/$NAME\" 2> /dev/null; echo -n") || error "$0: Failed to connect to host $RHOST."
        # BUG: Will also copy irrelevant directories, don't cleanup on remote side.
	[ -z "$E" ] || error "$1 already exists in $MDZ_REPOSITORY"
	STAGE="/tmp/$NAME"
	mkdir "$STAGE"
	cp -a "$SOURCE/meta.xml" "$STAGE" || error "Couldn't stage in /tmp, is this a real dataset?"
	cd $SOURCE
        find . -type d | while read dir; do
	    mkdir -p "$STAGE/$dir"
	done
	cd -
	scp -rp "$STAGE" "$MDZ_REPOSITORY/" || error "Failed to transfer $1 to $MDZ_REPOSITORY"
	for path in `getfiles $SOURCE/meta.xml`; do
	    scp "$SOURCE/$path" "$MDZ_REPOSITORY/$NAME/$path" 
        done
	rm -rf "$STAGE"
    ;;

    *)
    error "Unknown repository access method $MDZ_REPO_METHOD"
    ;;
esac
