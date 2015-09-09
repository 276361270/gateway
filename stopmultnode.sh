#!/bin/bash

export RELX_REPLACE_OS_VARS=true

for i in `seq 0 9`;
do
    NODE_NAME=node_$i  _build/default/rel/gateway/bin/gateway stop &
    sleep 1
done