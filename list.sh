#!/bin/bash
set -u -o pipefail

# List data sets in a repository
# Uses: MDZ_REPO_METHOD MDZ_REPOSITORY

[ -z "$MDZ_REPO_METHOD" ] && error "MDZ_REPO_METHOD undefined"
[ -z "$MDZ_REPOSITORY" ]  && error "MDZ_REPOSITORY undefined"

case "$MDZ_REPO_METHOD" in
       scp)
	   SRV=$(echo "$MDZ_REPOSITORY" | cut -d: -f1)
	   PTH=$(echo "$MDZ_REPOSITORY" | cut -d: -f2)
	   ssh "$SRV" "ls $PTH"
	   ;; 
       *)
	   error "Unknown repository access method $MDZ_REPO_METHOD"
	   ;;
esac

