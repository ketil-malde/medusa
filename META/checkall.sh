#!/bin/bash

R="$(tput setaf 1)"
G="$(tput setaf 2)"

LOG=/tmp/xmlcheck.log
date > $LOG

for a in *; do
  if echo $a | egrep -q -v _darcs\|lost\\+found\|META; then
     META/xmlcheck.sh $a && echo -n "$G$a " >> $LOG || echo -n "$R$a " >> $LOG
     echo '--------'
  fi
done
echo
echo SUMMARY:
cat $LOG

