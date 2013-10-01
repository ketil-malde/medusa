#!/bin/bash

DIR=/data/genomdata
CONF=$DIR/META/services/sync/CONFIG

egrep -v '^#|^$' $CONF | while read line; do
    target=`echo "$line" | cut -f1`
    source=`echo "$line" | cut -f2-`
    for a in $source; do
        rsync -azuv $DIR/$a $target
    done
done

