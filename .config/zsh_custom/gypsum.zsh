gypsum() {
	if [[ $(hostname) == selenite.cs.umass.edu ]]; then
		ssh guanghaowei@gypsum.cs.umass.edu
	else
		ssh guanghaowei@gypsum-gateway.cs.umass.edu
	fi
}

alias cdw='/mnt/nfs/work1/hongyu/guanghaowei'
alias noteaid='cd /mnt/nfs/work1/hongyu/guanghaowei/'
