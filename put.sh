#!/bin/bash

# Put a data set (by path) from repository
# Uses: MDZ_REPO_METHOD MDZ_REPOSITORY

SOURCE="$MDZ_DATADIR/$1"

[ -z "$1" ]               && error "Usage: $0 <dataset>"
[ ! -e "$SOURCE" ]        && "$SOURCE doesn't exist"
[ -z "$MDZ_REPO_METHOD" ] && error "MDZ_REPO_METHOD undefined"
[ -z "$MDZ_REPOSITORY" ]  && error "MDZ_REPOSITORY undefined"
[ -z "$MDZ_DATADIR" ]     && error "MDZ_DATADIR undefined"

set -euf -o pipefail

error(){
    echo "Error: $*"
    exit -1
}

case "$MDZ_REPO_METHOD" in
    scp)
	RPATH=$(echo $MDZ_REPOSITORY | cut -d: -f2)
	RHOST=$(echo $MDZ_REPOSITORY | cut -d: -f1)
	E=$(ssh $RHOST "ls -d $RPATH/$1 2> /dev/null; echo -n") || error "$0: Failed to connect to host $RHOST"
        # BUG: Will also copy irrelevant files and incorrect (e.g. empty) datasets!
	[ -z "$E" ] || error "$1 already exists in $MDZ_REPOSITORY"
	scp -rp "$SOURCE" "$MDZ_REPOSITORY/" || error "Failed to transfer $1 to $MDZ_REPOSITORY"
    ;;

    *)
    error "Unknown repository access method $MDZ_REPO_METHOD"
    ;;
esac
