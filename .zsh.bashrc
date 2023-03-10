#!/bin/bash

# For servers that cannot change default login shell or changing default login
# shell to non-bash is not well-supported, this script replace the login shell
# to zsh

# if this is a login shell and an interactive shell
# https://unix.stackexchange.com/a/26782
if shopt -q login_shell && [[ $- == *i* && -n $(command -v zsh) ]]; then
  exec zsh --login
fi
