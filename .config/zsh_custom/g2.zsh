#!/bin/zsh

alias g2login='ssh gw338@g2-login.coecis.cornell.edu'
alias g2login2='ssh gw338@g2-login-05.coecis.cornell.edu'
alias g2login5='ssh gw338@g2-login-05.coecis.cornell.edu'
alias gcpulow='srun -p default_partition-interactive --pty -n 4 --mem=8g /bin/zsh -li'
alias gcpunode='srun -p desa-interactive /bin/zsh -li'
alias gacct='sacct -a -X -o "User, Partition, JobID, State%-10, JobName%-30, Elapsed, Timelimit, AllocTRES%-42, Priority" -s R,PD'
alias gacctd='sacct -a -X -o "User, Partition, JobID, State%-10, JobName%-30, Elapsed, Timelimit, AllocTRES%-42, Priority" -s R,PD -r desa'
alias gacctgd='sacct -a -X -o "User, Partition, JobID, State%-10, JobName%-30, Elapsed, Timelimit, AllocTRES%-42, Priority" -s R,PD -r gpu,desa'

# anyconnect has been failed on arch linux
# alias cuvpn='/opt/cisco/anyconnect/bin/vpn -s connect cuvpn.cuvpn.cornell.edu'
# alias cudisc='/opt/cisco/anyconnect/bin/vpn -s disconnect'
# alias custate='/opt/cisco/anyconnect/bin/vpn -s state'

alias cuvpn="tmux new -s cuvpn 'sudo openconnect cuvpn.cuvpn.cornell.edu -u gw338'"
alias tcuvpn="tmux a -t cuvpn"
