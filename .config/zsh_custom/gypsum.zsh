alias gypsum='ssh guanghaowei@gypsum.cs.umass.edu'
alias ggypsum='ssh guanghaowei@gypsum-gateway.cs.umass.edu'

alias gpnoteaid='cd /mnt/nfs/work1/hongyu/guanghaowei/NoteAid-Annotation && conda activate noteaid'
alias gpcd='/mnt/nfs/work1/hongyu/guanghaowei'

alias gpb='sbatch'
alias gpsh='srun --pty /bin/zsh'
alias gpshg='srun --pty --gres=gpu:1 /bin/zsh'
alias gpshgl='srun --pty --gres=gpu:1 --partition=titanx-long /bin/zsh'
alias gpq='squeue | grep'
alias gpps='squeue | grep guanghaowei'
alias gpc='scancel'
alias gpi='sinfo'
