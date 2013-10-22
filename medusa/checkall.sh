#!/bin/bash

[ -z "$MDZ_DATADIR" ]     && error "MDZ_DATADIR undefined"

set -uf -o pipefail

R="$(tput setaf 1)"
G="$(tput setaf 2)"
Y="$(tput setaf 3)"
N="$(tput sgr0)"

LOG=/tmp/xmlcheck.log
date > $LOG

for a in $(ls $MDZ_DATADIR); do
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
