#!/usr/bin/env bash
# 
# ---------------------------------------------------------------- #
# Script Name:   run.sh 
# Description:   Run 3 instances of the distributed-logger system on ports 5555,5556 and 5557
# Author:        Gabriel Oliveira
# Github:        oliveigah
# Created At:    2020-10-28
# ---------------------------------------------------------------- #
# Requirements: Erlang/OTP 23 | Elixir 1.11.1 
# Command:      bash ./run.sh
# ---------------------------------------------------------------- #

elixir --name node1@127.0.0.1 --erl "-detached -distributed_logger port 5555 -distributed_logger nodes []" -S mix run --no-halt

echo "Node 1 running on port 5555 | POST localhost:5555/event to interact"

elixir --name node2@127.0.0.1 --erl "-detached -distributed_logger port 5556 -distributed_logger nodes [node1]" -S mix run --no-halt

echo "Node 2 running on port 5556 | POST localhost:5556/event to interact"

elixir --name node3@127.0.0.1 --erl "-detached -distributed_logger port 5557 -distributed_logger nodes [node1,node2]" -S mix run --no-halt

echo "Node 3 running on port 5557 | POST localhost:5557/event to interact"