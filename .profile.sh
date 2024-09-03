#!/bin/sh

# This file should support all the shell you use(bash, zsh, etc)

# No idea why but if this is presented tmux won't correctly load variables.
# # return if EVA is set
# [ -n "${EVA+x}" ] && return

# inspired from https://unix.stackexchange.com/a/108933
# WARNING: only remove path that fully match
__remove_path() {
  PATH=":$PATH:"
  #  PATH=${PATH//":"/"::"}
  #  PATH=${PATH//":$1:"/}
  #  PATH=${PATH//"::"/":"}
  PATH=$(echo "$PATH" | sed 's/:/::/g')
  PATH=$(echo "$PATH" | sed "s|:$1:||g")
  PATH=$(echo "$PATH" | sed 's/::/:/g')
  PATH=${PATH#:}
  PATH=${PATH%:}
}

__prepend_path() {
  case ":${PATH}:" in
  *:"$1":*)
    __remove_path "$1"
    PATH="$1:$PATH"
    ;;
  *)
    PATH="$1:$PATH"
    ;;
  esac
}

__prepend_path "$HOME/bin"
__prepend_path "$HOME/.local/bin"

[ -d /opt/cuda/lib64 ] &&
  export LD_LIBRARY_PATH="/opt/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
[ -d "$HOME/.local/lib" ] &&
  export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# Fix brew, copied from oh-my-zsh brew plugin
if [ -z "$(command -v brew)" ]; then
  if [ -x /opt/homebrew/bin/brew ]; then
    BREW_LOCATION="/opt/homebrew/bin/brew"
  elif [ -x /usr/local/bin/brew ]; then
    BREW_LOCATION="/usr/local/bin/brew"
  elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    BREW_LOCATION="/home/linuxbrew/.linuxbrew/bin/brew"
  elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    BREW_LOCATION="$HOME/.linuxbrew/bin/brew"
  fi

  # Only add Homebrew installation to PATH, MANPATH, and INFOPATH if brew is
  # not already on the path, to prevent duplicate entries. This aligns with
  # the behavior of the brew installer.sh post-install steps.
  eval "$("$BREW_LOCATION" shellenv)"
  unset BREW_LOCATION

  HOMEBREW_PREFIX="$(brew --prefix)"
  export HOMEBREW_PREFIX
fi

# go
[ -d /usr/local/go/bin ] && __prepend_path /usr/local/go/bin

# SUDO
# https://superuser.com/a/1281228
# https://github.com/koalaman/shellcheck/wiki/SC2181
if __sudo=$(sudo -nv 2>&1); then
  # has sudo access w/o password
  :
elif echo "$__sudo" | grep -q '^sudo:'; then
  # has sudo access need password
  :
else
  # no sudo access
  export NOSUDO=1
fi
unset __sudo

# Preferred editor for local and remote sessions
if [ -n "${SSH_CONNECTION+x}" ]; then
  export EDITOR=vim
else
  export EDITOR=code
fi

# JAVA
if [ -z "${JAVA_HOME+x}" ]; then
  if [ -d /usr/lib/jvm/default ]; then
    export JAVA_HOME=/usr/lib/jvm/default
  elif [ -d /usr/lib/jvm/default-java ]; then
    export JAVA_HOME=/usr/lib/jvm/default-java
  # MacOS `brew install java`
  elif [ -d /Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home ]; then
    export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home
  fi
fi

# Conda, anaconda, or mambaforge
for CONDA in anaconda3 miniconda3 mambaforge miniforge3; do
  if [ -d "$HOME/$CONDA" ]; then
    export CONDA_PATH="$HOME/$CONDA"
    break
  elif [ -d "/opt/$CONDA" ]; then
    export CONDA_PATH="/opt/$CONDA"
    break
  fi
done
# Fix install mamba from brew
if [ "$(uname)" = "Darwin" ]; then
  for CONDA in miniforge mambaforge; do
    # MacOS `brew install $CONDA`
    if [ -d "/usr/local/Caskroom/$CONDA/base" ]; then
      export CONDA_PATH="/usr/local/Caskroom/$CONDA/base"
      break
    elif [ -d "$HOMEBREW_PREFIX/Caskroom/$CONDA/base" ]; then
      export CONDA_PATH="$HOMEBREW_PREFIX/Caskroom/$CONDA/base"
      break
    fi
  done
fi
unset CONDA

# SDKMAN
[ -d "$HOME/.sdkman" ] && export SDKMAN_DIR="$HOME/.sdkman"

# Cargo
# rustup shell setup
# affix colons on either side of $PATH to simplify matching
[ -d "$HOME/.cargo/bin" ] && __prepend_path "$HOME/.cargo/bin"

# Ruby
if [ -d "$HOMEBREW_PREFIX/lib/ruby/gems/3.3.0/bin" ]; then
  __prepend_path "$HOMEBREW_PREFIX/lib/ruby/gems/3.3.0/bin"
fi
if [ -n "$(command -v gem)" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    export GEM_HOME="$HOME/.gem"
  else
    GEM_HOME="$(gem env user_gemhome)"
    export GEM_HOME
  fi
  __prepend_path "$GEM_HOME/bin"
fi

# wine
[ -n "$(command -v wine)" ] && export WINEDEBUG=fixme-font

# Cisco Anyconnect
[ -d /opt/cisco/anyconnect/bin ] && __prepend_path /opt/cisco/anyconnect/bin

unset -f __remove_path
unset -f __prepend_path

export PATH

# variable to track history
export EVA_HISTORY="${EVA_HISTORY:+$EVA_HISTORY -> }~/.profile.sh"
