#!/bin/bash

# For servers that cannot change default login shell or changing default login
# shell to non-bash is not well-supported, this script replace the login shell
# to zsh

[[ -n $(command -v zsh) && $- == *i* ]] || return

# if this is a login shell and this is an interactive shell, and zsh available
# only replace shell when SHLVL=1
# https://unix.stackexchange.com/a/26782
if [[ $SHLVL == 1 ]]; then
  if shopt -q login_shell; then
    exec zsh -li
  else
    exec zsh
  fi
fi

# Workaround for vscode start terminal in bash with inconsistent SHLVL
if [[ $TERM_PROGRAM == vscode && -n ${VSCODE_TERM+x} ]]; then
  unset VSCODE_TERM; exec bash -l -c 'zsh -li'
fi

# For Nersc and Perlmutter
# if we are in a perlmutter computing node, exec zsh
if [[ $NERSC_HOST == perlmutter && -n ${SLURM_NODELIST+x} ]]; then
  exec zsh
fi
