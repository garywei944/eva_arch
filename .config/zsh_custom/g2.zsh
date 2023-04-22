#!/bin/zsh

alias g2login='ssh gw338@g2-login.coecis.cornell.edu'
alias gcpulow='srun -p default_partition-interactive --pty -n 4 --mem=8g /bin/zsh -li'
alias gcpunode='srun -p desa-interactive /bin/zsh -li'

alias cuvpn='/opt/cisco/anyconnect/bin/vpn -s connect cuvpn.cuvpn.cornell.edu'
alias cudisc='/opt/cisco/anyconnect/bin/vpn -s disconnect'
alias custate='/opt/cisco/anyconnect/bin/vpn -s state'
