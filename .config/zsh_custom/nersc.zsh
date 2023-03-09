#!/bin/zsh

alias gennersckey='sshproxy -u garywei'
alias perlmutter='ssh -i ~/.ssh/nersc garywei@perlmutter-p1.nersc.gov -t "zsh --login"'
alias pcpunode='salloc --nodes 1 --qos interactive --time 01:00:00 --constraint cpu --account=m4341 zsh --login'
