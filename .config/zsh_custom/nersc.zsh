#!/bin/zsh

alias gennersckey='sshproxy -u garywei'
alias perlmutter='ssh -i ~/.ssh/nersc garywei@perlmutter-p1.nersc.gov'

# The rest is only for perlmutter servers
[[ $NERSC_HOST == perlmutter ]] || return

export GLOBAL_COMMON=/global/common/software/m4341/garywei
export CONDA_PATH="$GLOBAL_COMMON/mambaforge"

alias pcpunode='salloc -N 1 -q interactive -t 01:00:00 -C cpu -A m4341'

[[ -n ${SLURM_NODELIST+x} ]] && export NODENAME=$SLURM_NODELIST

# module workaround
# https://github.com/ACAD-UofA/Bioinformatics-Wiki/wiki/Modules#module-is-a-shell-function
module () 
{ 
    if [ -z "${LMOD_SH_DBG_ON+x}" ]; then
        case "$-" in 
            *v*x*)
                __lmod_sh_dbg='vx'
            ;;
            *v*)
                __lmod_sh_dbg='v'
            ;;
            *x*)
                __lmod_sh_dbg='x'
            ;;
        esac;
    fi;
    if [ -n "${__lmod_sh_dbg:-}" ]; then
        set +$__lmod_sh_dbg;
        echo "Shell debugging temporarily silenced: export LMOD_SH_DBG_ON=1 for Lmod's output" 1>&2;
    fi;
    eval "$($LMOD_CMD $LMOD_SHELL_PRGM "$@")" && eval "$(${LMOD_SETTARG_CMD:-:} -s sh)";
    __lmod_my_status=$?;
    if [ -n "${__lmod_sh_dbg:-}" ]; then
        echo "Shell debugging restarted" 1>&2;
        set -$__lmod_sh_dbg;
    fi;
    unset __lmod_sh_dbg;
    return $__lmod_my_status
}
