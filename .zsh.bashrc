#!/bin/bash

li_shell() {
    exec bash -l -c 'zsh -li'
}

i_shell() {
    exec bash -l -c 'zsh -i'
}

# https://unix.stackexchange.com/a/26782
spawn_shell() {
    if shopt -q login_shell; then
        li_shell
    else
        i_shell
    fi
}

# For servers that cannot change default login shell or changing default login
# shell to non-bash is not well-supported, this script replace the login shell
# to zsh

[[ -n $(command -v zsh) && $- == *i* ]] || return

# if this is a login shell and this is an interactive shell, and zsh available
# only replace shell when SHLVL=1
if [[ $SHLVL -le 5 ]]; then
    spawn_shell
fi

# # For Nersc and Perlmutter
# # if we are in a perlmutter computing node, exec zsh
# if [[ $NERSC_HOST == perlmutter && -n ${SLURM_NODELIST+x} ]]; then
#     exec zsh
# fi

# # Workaround for vscode start terminal in bash with inconsistent SHLVL
# if [[ $TERM_PROGRAM == vscode && -n ${VSCODE_TERM+x} ]]; then
#     unset VSCODE_TERM
#     spawn_shell
# fi
