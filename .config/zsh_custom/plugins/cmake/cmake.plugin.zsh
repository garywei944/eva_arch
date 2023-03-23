#!/bin/zsh

alias cmdb='cmake -DCMAKE_BUILD_TYPE=Debug ..'
alias cmdbm='cmake -DCMAKE_BUILD_TYPE=Debug .. && make -j$(nproc)'
alias cmdbmm='cmake -DCMAKE_BUILD_TYPE=Debug .. && make clean && make -j$(nproc)'
alias cmrl='cmake -DCMAKE_BUILD_TYPE=Release ..'
alias cmrlm='cmake -DCMAKE_BUILD_TYPE=Release .. && make -j$(nproc)'
alias cmrlmm='cmake -DCMAKE_BUILD_TYPE=Release .. && make clean && make -j$(nproc)'
