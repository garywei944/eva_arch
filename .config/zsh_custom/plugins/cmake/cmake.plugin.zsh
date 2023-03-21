#!/bin/zsh

alias cmd='cmake -DCMAKE_BUILD_TYPE=Debug ..'
alias cmdm='cmake -DCMAKE_BUILD_TYPE=Debug .. && make'
alias cmdmm='cmake -DCMAKE_BUILD_TYPE=Debug .. && make clean && make'
alias cmr='cmake -DCMAKE_BUILD_TYPE=Release ..'
alias cmrm='cmake -DCMAKE_BUILD_TYPE=Release .. && make'
alias cmrmm='cmake -DCMAKE_BUILD_TYPE=Release .. && make clean && make'
