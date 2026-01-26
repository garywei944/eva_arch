#!/bin/zsh

alias selenite='ssh guanghaowei@gypsum-gateway.cs.umass.edu'
alias gypsum='ssh guanghaowei@gypsum.cs.umass.edu'

# net-tools depracated hostname
# https://bbs.archlinux.org/viewtopic.php?id=125308
if [[ $(hostname) == node* ]]; then
	alias gpcd='cd /mnt/nfs/work1/hongyu/guanghaowei'

	alias gpb='sbatch'

	alias gpsh='srun --pty /bin/zsh'
	alias gpshg='srun --pty --gres=gpu:1 /bin/zsh'
	alias gpshgl='srun --pty --gres=gpu:1 --partition=titanx-long /bin/zsh'

	alias gpq='squeue'
	alias gpqn='squeue -n'
	alias gpps='squeue -u guanghaowei'

	alias gpc='scancel'

	alias gpi='sinfo'
fi


alias noteaid='cd ~/projects/NoteAid-Annotation; conda activate noteaid'
