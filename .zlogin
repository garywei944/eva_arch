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

# Conda init
if [[ -n ${CONDA_PATH+x} ]]; then
  __conda_setup="$("$CONDA_PATH/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
  if [[ $? -eq 0 ]]; then
    eval "$__conda_setup"
  else
    if [[ -f "$CONDA_PATH/etc/profile.d/conda.sh" ]]; then
      source "$CONDA_PATH/etc/profile.d/conda.sh"
    else
      export PATH="$CONDA_PATH/bin:$PATH"
    fi
  fi
  unset __conda_setup
fi

# SDKMAN init
if [[ -n ${SDKMAN_DIR+x} ]]; then
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi
