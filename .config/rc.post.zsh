#!/bin/zsh

# Conda init
if [[ -n ${CONDA_PATH+x} ]]; then
  __conda_setup="$("$CONDA_PATH/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
  if [[ $? -eq 0 ]]; then
    eval "$__conda_setup"
  else
    if [[ -f "$CONDA_PATH/etc/profile.d/conda.sh" ]]; then
      . "$CONDA_PATH/etc/profile.d/conda.sh"
    else
      export PATH="$CONDA_PATH/bin:$PATH"
    fi
  fi
  unset __conda_setup
fi

# SDKMAN init
if [[ -n ${SDKMAN_DIR+x} ]]; then
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && . "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
