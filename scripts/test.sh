#!/usr/bin/env bash
# 
# ---------------------------------------------------------------- #
# Script Name:   test.sh 
# Description:   Run the tests of distributed-logger project
# Author:        Gabriel Oliveira
# Github:        oliveigah
# Created At:    2020-10-28
# ---------------------------------------------------------------- #
# Requirements: Erlang/OTP 23 | Elixir 1.11.1 
# Command:      bash ./test.sh
# ---------------------------------------------------------------- #
epmd -daemon
mix test