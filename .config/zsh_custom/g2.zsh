#!/bin/zsh

alias g2login='ssh gw338@g2-login.coecis.cornell.edu'
alias gcpulow='srun -p default_partition-interactive --pty -n 4 --mem=8g /bin/zsh'
alias gcpunode='srun -p desa_partition-interactive /bin/zsh'
