#!/usr/bin/env bash
# 
# ---------------------------------------------------------------- #
# Script Name:   kill.sh 
# Description:   Kills the processes that are running on ports 5555,5556 and 5557
# Author:        Gabriel Oliveira
# Github:        oliveigah
# Created At:    2020-10-28
# ---------------------------------------------------------------- #

fuser -k 5555/tcp
echo "Node 1 is down"
fuser -k 5556/tcp
echo "Node 2 is down"
fuser -k 5557/tcp
echo "Node 3 is down"

