#!/bin/zsh

# WSL alias
if [[ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/ip') == microsoft ]]; then
  __cmd() {
    cmd.exe /c "$@" &>/dev/null
  }

  alias subl='__cmd subl.bat'
  alias smerge='__cmd smerge.bat'
  alias nvidia-smi='nvidia-smi.exe'
fi
