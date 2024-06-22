#!/bin/sh

# This file should support both bash and zsh

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
  export PATH
}

__prepend_path() {
  case ":${PATH}:" in
  *:"$1":*)
    __remove_path "$1"
    export PATH="$1:$PATH"
    ;;
  *)
    export PATH="$1:$PATH"
    ;;
  esac
}

__prepend_path "$HOME/bin"
__prepend_path "$HOME/.local/bin"

[ -d /opt/cuda/lib64 ] &&
  export LD_LIBRARY_PATH="/opt/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
[ -d "$HOME/.local/lib" ] &&
  export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# Fix brew
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

[ -n "$(command -v brew)" ] && __prepend_path /usr/local/sbin

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
for CONDA in anaconda3 miniconda3 mambaforge; do
  if [ -d "$HOME/$CONDA" ]; then
    export CONDA_PATH="$HOME/$CONDA"
  elif [ -d "/opt/$CONDA" ]; then
    export CONDA_PATH="/opt/$CONDA"
  fi
done
unset CONDA
# MacOS `brew install mambaforge`
if [ -d /usr/local/Caskroom/mambaforge/base ]; then
  export CONDA_PATH=/usr/local/Caskroom/mambaforge/base
elif [ -d /opt/homebrew/Caskroom/mambaforge/base ]; then
  export CONDA_PATH=/opt/homebrew/Caskroom/mambaforge/base
fi

# SDKMAN
[ -d "$HOME/.sdkman" ] && export SDKMAN_DIR="$HOME/.sdkman"

# Cargo
# rustup shell setup
# affix colons on either side of $PATH to simplify matching
[ -d "$HOME/.cargo/bin" ] && __prepend_path "$HOME/.cargo/bin"

# Ruby
if [ -n "$(command -v gem)" ]; then
  export GEM_HOME="$(gem env user_gemhome)"
  __prepend_path "$GEM_HOME/bin"
fi

# wine
[ -n "$(command -v wine)" ] && export WINEDEBUG=fixme-font

# Cisco Anyconnect
[ -d /opt/cisco/anyconnect/bin ] && __prepend_path /opt/cisco/anyconnect/bin

# Custom environment variable
export EVA=ariseus

unset __remove_path
unset __prepend_path
