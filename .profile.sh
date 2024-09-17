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

# set up local variables
__uname=$(uname)

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

  if [ -n "$BREW_LOCATION" ]; then
    # Only add Homebrew installation to PATH, MANPATH, and INFOPATH if brew is
    # not already on the path, to prevent duplicate entries. This aligns with
    # the behavior of the brew installer.sh post-install steps.
    eval "$("$BREW_LOCATION" shellenv)"
    unset BREW_LOCATION
  fi
fi

if [ -n "$(command -v brew)" ]; then
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
# if micromamba installed, add $HOME/.conda as base
[ -n "$(command -v micromamba)" ] && export MAMBA_ROOT_PREFIX="$HOME/.conda"

for CONDA in anaconda3 miniconda3 mambaforge miniforge3; do
  if [ -d "$HOME/$CONDA" ]; then
    export CONDA_PATH="$HOME/$CONDA"
    break
  elif [ -d "/opt/$CONDA" ]; then
    export CONDA_PATH="/opt/$CONDA"
    break
  # Fix install mamba from brew
  elif [ "$__uname" = "Darwin" ]; then
    # MacOS `brew install $CONDA`
    if [ -d "/usr/local/Caskroom/$CONDA/base" ]; then
      export CONDA_PATH="/usr/local/Caskroom/$CONDA/base"
      break
    elif [ -d "$HOMEBREW_PREFIX/Caskroom/$CONDA/base" ]; then
      export CONDA_PATH="$HOMEBREW_PREFIX/Caskroom/$CONDA/base"
      break
    elif [ -d "$HOMEBREW_PREFIX/$CONDA" ]; then
      export CONDA_PATH="$HOMEBREW_PREFIX/$CONDA"
      break
    fi
  fi
done
unset CONDA

# SDKMAN
[ -d "$HOME/.sdkman" ] && export SDKMAN_DIR="$HOME/.sdkman"

# Cargo
# rustup shell setup
# affix colons on either side of $PATH to simplify matching
[ -d "$HOME/.cargo/bin" ] && __prepend_path "$HOME/.cargo/bin"

# Ruby
# check if ruby is install by brew
if [ -n "$HOMEBREW_PREFIX" ] || [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  if [ -d "$HOMEBREW_PREFIX/opt/ruby" ]; then
    __prepend_path "$HOMEBREW_PREFIX/opt/ruby/bin"
    export LDFLAGS="-L$HOMEBREW_PREFIX/opt/ruby/lib"
    export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/ruby/include"
    export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/ruby/lib/pkgconfig"
  fi
fi
if [ -n "$(command -v gem)" ]; then
  # only gem 3.2.0 and above support GEM_HOME
  required_version="3.2.0"
  if [ "$(printf '%s\n' "$required_version" "$(gem --version)" | sort -V | head -n1)" = "$required_version" ]; then
    GEM_HOME="$(gem env user_gemhome)"
    export GEM_HOME
  else
    echo "[INFO] gem version $(gem --version) is lower than $required_version, GEM_HOME is set to $HOME/.gem"
    export GEM_HOME="$HOME/.gem"
  fi
  unset required_version
  __prepend_path "$GEM_HOME/bin"
fi

# wine
[ -n "$(command -v wine)" ] && export WINEDEBUG=fixme-font

# Cisco Anyconnect
[ -d /opt/cisco/anyconnect/bin ] && __prepend_path /opt/cisco/anyconnect/bin

# Set up ssh-agent, macOS is handled by keychain
if [ ! "$__uname" = "Darwin" ]; then
  # get number of ssh-agent running
  SSH_AGENT_COUNT=$(pgrep -u "$USER" ssh-agent | wc -l)
  # if no ssh-agent running, start one
  if [ "$SSH_AGENT_COUNT" -eq 0 ]; then
    eval "$(ssh-agent -s)" >/dev/null
  # else if only one ssh-agent running, use it
  elif [ "$SSH_AGENT_COUNT" -eq 1 ]; then
    SSH_AUTH_SOCK=$(find /tmp/ssh-*/ -user "$USER" -type s -name 'agent*' 2>/dev/null)
    SSH_AGENT_PID=$(pgrep -u "$USER" ssh-agent)
    export SSH_AUTH_SOCK SSH_AGENT_PID
  # if more than one ssh-agent running, kill all and start a new one
  else
    pkill -u "$USER" ssh-agent
    eval "$(ssh-agent -s)" >/dev/null
  fi
  unset SSH_AGENT_COUNT
fi

unset -f __remove_path
unset -f __prepend_path

unset __uname

export PATH

# variable to track history
export EVA_HISTORY="${EVA_HISTORY:+$EVA_HISTORY -> }~/.profile.sh"
