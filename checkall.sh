#!/bin/bash

set -u -o pipefail
shopt -s failglob
. "$MDZ_DIR/functions.sh"

LOG=/tmp/xmlcheck.log
date > $LOG

note "Checking datasets in $MDZ_DATADIR"
echo
for a in $(datasets); do
     $MDZ_DIR/check.sh "$a"
     RET=$?
     if [ $RET -eq "0" ]; then
        echo -n "$G$a$N " >> $LOG 
     elif [ $RET -eq "1" ]; then 
        echo -n "$Y$a$N " >> $LOG
     else
        echo -n "$R$a$N " >> $LOG
     fi
     echo '--------'
done
echo
echo SUMMARY:
cat $LOG
echo
