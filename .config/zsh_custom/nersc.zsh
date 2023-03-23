#!/bin/zsh

alias gennersckey='sshproxy -u garywei'
alias perlmutter='ssh -i ~/.ssh/nersc garywei@perlmutter-p1.nersc.gov'

# The rest is only for perlmutter servers
[[ $NERSC_HOST == perlmutter ]] || return

export GLOBAL_COMMON=/global/common/software/m4341/garywei
export CONDA_PATH="$GLOBAL_COMMON/mambaforge"

alias pcpunode='salloc -q interactive -t 01:00:00 -C cpu -A m4341 -N 1'
alias pcpunoden='salloc -q interactive -t 01:00:00 -C cpu -A m4341 -N'

[[ -n ${SLURM_NODELIST+x} ]] && export NODENAME=$SLURM_NODELIST

# Workaround for sourcing module
. /etc/profile.d/zz-cray-pe.sh
