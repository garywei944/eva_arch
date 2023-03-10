#!/bin/zsh

alias gennersckey='sshproxy -u garywei'
alias perlmutter='ssh -i ~/.ssh/nersc garywei@perlmutter-p1.nersc.gov'

# The rest is only for perlmutter servers
[[ $NERSC_HOST == perlmutter ]] || return

export GLOBAL_COMMON=/global/common/software/m4341/garywei
export CONDA_PATH="$GLOBAL_COMMON/mambaforge"

alias pcpunode='salloc -N 1 -q interactive -t 01:00:00 -C cpu -A m4341'

# module workaround
# https://github.com/ACAD-UofA/Bioinformatics-Wiki/wiki/Modules#module-is-a-shell-function
module() {
  eval $($LMOD_CMD bash "$@") && eval $(${LMOD_SETTARG_CMD:-:} -s sh)
}
