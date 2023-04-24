#!/bin/bash

# For servers that cannot change default login shell or changing default login
# shell to non-bash is not well-supported, this script replace the login shell
# to zsh

# if this is a login shell and this is an interactive shell, and zsh available
# only replace shell when SHLVL=1
# https://unix.stackexchange.com/a/26782
if [[ $- == *i* && $SHLVL == 1 && -n $(command -v zsh) ]]; then
  if shopt -q login_shell; then
    exec zsh -li
  else
    exec zsh
  fi
fi

# For Nersc and Perlmutter
# if we are in a perlmutter computing node, exec zsh
if [[ $NERSC_HOST == perlmutter && -n ${SLURM_NODELIST+x} ]]; then
  exec zsh
fi

# Workaround for vscode start terminal with SHLVL=4
if [[ $NERSC_HOST == perlmutter && $TERM_PROGRAM == vscode && $SHLVL == 4 ]]; then
  exec zsh
fi
