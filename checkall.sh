#!/bin/bash

set -uf 
shopt -s failglob
source "$MDZ_DIR/functions.sh"

LOG=/tmp/xmlcheck.log
date > $LOG

note "Checking datasets in $MDZ_DATADIR"
echo

OK=0
WR=0
ER=0

set +e
for a in $(datasets); do
     bash "$MDZ_DIR/check.sh" "$a"
     RET=$?
     if [ $RET -eq "0" ]; then
         echo -n "$G$a$N " >> $LOG
	 ((OK++))
     elif [ $RET -eq "1" ]; then 
         echo -n "$Y$a$N " >> $LOG
	 ((WR++))
     else
         echo -n "$R$a$N " >> $LOG
	 ((ER++))
     fi
     echo '--------'
done
echo
echo SUMMARY:
cat $LOG
echo

mkdir -p "$MDZ_DATADIR/logs"
echo "$(date -I)       $OK     $WR     $ER" >> "$MDZ_DATADIR/logs/check_log"
