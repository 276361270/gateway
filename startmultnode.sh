#!/bin/bash

export RELX_REPLACE_OS_VARS=true

for i in `seq 1 9`;
do
    NODE_NAME=node_$i PORT=808$i _build/default/rel/gateway/bin/gateway foreground &
    sleep 4
done