#!/bin/bash

set -u -o pipefail
shopt -s failglob
. "$MDZ_DIR/functions.sh"

LOG=/tmp/xmlcheck.log
date > $LOG

if [ "$#" = "0" ]; then
   DIR="$MDZ_DATADIR"
elif [ -d "$1" ]; then
   DIR="$1"
else
   error "checkall: $1 is not a directory"
fi

for a in $DIR/*; do
  if echo $a | egrep -q -v _darcs\|lost\\+found; then
     $MDZ_DIR/xmlcheck.sh $a
     RET=$?
     if [ $RET -eq "0" ]; then
        echo -n "$G$a$N " >> $LOG 
     elif [ $RET -eq "1" ]; then 
        echo -n "$Y$a$N " >> $LOG
     else
        echo -n "$R$a$N " >> $LOG
     fi
     echo '--------'
  fi
done
echo
echo SUMMARY:
cat $LOG
echo
