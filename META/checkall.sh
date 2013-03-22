#!/bin/bash

LOG=/tmp/xmlcheck.log
date > $LOG

for a in *; do
  if echo $a | egrep -q -v _darcs\|lost\\+found\|META; then
     META/xmlcheck.sh $a || echo "FAILED:	$a" >> $LOG
  fi
done
echo
cat $LOG

