#!/bin/bash

export RELX_REPLACE_OS_VARS=true
make rm
make clean
make debug

NODE_NAME=gateway PORT=8080 _build/default/rel/gateway/bin/gateway console
