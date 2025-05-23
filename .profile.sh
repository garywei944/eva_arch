#!/bin/sh

# This script is sourced by all POSIX-compliant shells upon startup

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function: Remove duplicate paths, keep the first occurrence.
remove_duplicates() {
  # Usage: new_list=$(remove_duplicates "$list")
  old_IFS=$IFS
  IFS=:
  set -- $1
  IFS=$old_IFS
  unique=""
  for p in "$@"; do
    case ":$unique:" in
    *":$p:"*) ;; # already seen, skip
    *) unique=${unique:+$unique:}$p ;;
    esac
  done
  echo "$unique"
}

# Function: Prepend a path, removing any existing occurrences.
path_prepend() {
  # Usage: new_list=$(path_prepend "/new/path" "$list")
  target=$1
  list=$2
  old_IFS=$IFS
  IFS=:
  newlist=""
  for p in $list; do
    if [ "$p" = "$target" ]; then
      continue
    fi
    newlist=${newlist:+$newlist:}$p
  done
  IFS=$old_IFS
  echo "$target${newlist:+:$newlist}"
}

# Function: Append a path, if it doesn't already exist.
path_append() {
  # Usage: new_list=$(path_append "/new/path" "$list")
  target=$1
  list=$2
  old_IFS=$IFS
  IFS=:
  for p in $list; do
    if [ "$p" = "$target" ]; then
      IFS=$old_IFS
      echo "$list" # already exists, return unchanged
      return
    fi
  done
  IFS=$old_IFS
  echo "${list:+$list:}$target"
}

################################################################################
# Set up environment
################################################################################

PATH=$(remove_duplicates "$PATH")
LD_LIBRARY_PATH=$(remove_duplicates "$LD_LIBRARY_PATH")
CPATH=$(remove_duplicates "$CPATH")

for p in "$HOME/.local/bin" \
  "$HOME/bin" \
  /usr/local/go/bin \
  "$HOME/.local/opt/go/bin" \
  "$HOME/.cargo/bin" \
  /opt/cisco/anyconnect/bin; do
  [ -d "$p" ] && PATH=$(path_prepend "$p" "$PATH")
done

# Set up LD_LIBRARY_PATH
for p in "$HOME/.local/lib" \
  /usr/lib/x86_64-linux-gnu; do
  [ -d "$p" ] && LD_LIBRARY_PATH=$(path_append "$p" "$LD_LIBRARY_PATH")
done

# CUDA
for CUDA_HOME in /usr/local/cuda /opt/cuda; do
  if [ -d "$CUDA_HOME" ]; then
    export CUDA_HOME
    CPATH=$(path_prepend "$CUDA_HOME/include" "$CPATH")

    for SUBDIR in bin nsight_compute nsight_systems/bin; do
      [ -d "$CUDA_HOME/$SUBDIR" ] && PATH=$(path_prepend "$CUDA_HOME/$SUBDIR" "$PATH")
    done
    for SUBDIR in lib64 extras/CUPTI/lib64; do
      [ -d "$CUDA_HOME/$SUBDIR" ] &&
        LD_LIBRARY_PATH=$(path_append "$CUDA_HOME/$SUBDIR" "$LD_LIBRARY_PATH")
    done
    break
  fi
done

# Fix brew, copied from oh-my-zsh brew plugin
if ! command_exists brew; then
  for p in /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$p" ]; then
      BREW_LOCATION="$p"
      break
    fi
  done

  if [ -n "$BREW_LOCATION" ]; then
    # Only add Homebrew installation to PATH, MANPATH, and INFOPATH if brew is
    # not already on the path, to prevent duplicate entries. This aligns with
    # the behavior of the brew installer.sh post-install steps.
    eval "$("$BREW_LOCATION" shellenv)"
    unset BREW_LOCATION
  fi
fi

if command_exists brew; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  export HOMEBREW_PREFIX
fi

# SUDO
# https://superuser.com/a/1281228
# https://github.com/koalaman/shellcheck/wiki/SC2181
if __sudo="$(sudo -nv 2>&1)"; then
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

# JAVA
if [ -z "${JAVA_HOME+x}" ]; then
  for JAVA_HOME in /usr/lib/jvm/default \
    /usr/lib/jvm/default-java \
    /Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home; do
    if [ -d "$JAVA_HOME" ]; then
      export JAVA_HOME
      break
    fi
  done
fi

# Conda, anaconda, or mambaforge

# Fix miniconda OpenSSL 3.0 legacy provider failed to load issue
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

# if micromamba installed, add $HOME/.conda as base
command_exists micromamba && export MAMBA_ROOT_PREFIX="$HOME/.conda"

for CONDA in anaconda3 miniconda3 mambaforge miniforge3 miniforge; do
  for p in "$HOME/$CONDA" \
    "/opt/$CONDA" \
    /usr/local/Caskroom/$CONDA/base \
    "$HOMEBREW_PREFIX/Caskroom/$CONDA/base" \
    "$HOMEBREW_PREFIX/$CONDA"; do
    if [ -d "$p" ]; then
      export CONDA_PATH="$p"
      break 2
    fi
  done
done
unset CONDA

# pyenv
for p in "$HOME/.pyenv" \
  "/usr/local/pyenv"; do
  if [ -d "$p" ]; then
    export PYENV_ROOT="$p"
    PATH=$(path_prepend "$PYENV_ROOT/bin" "$PATH")
    break
  fi
done

# fzf and fd
export FZF_DEFAULT_COMMAND=fd

# SDKMAN
[ -d "$HOME/.sdkman" ] && export SDKMAN_DIR="$HOME/.sdkman"

# Ruby
# check if ruby is install by brew
if [ -n "$HOMEBREW_PREFIX" ] || [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  if [ -d "$HOMEBREW_PREFIX/opt/ruby" ]; then
    PATH=$(path_prepend "$HOMEBREW_PREFIX/opt/ruby/bin" "$PATH")
    export LDFLAGS="-L$HOMEBREW_PREFIX/opt/ruby/lib"
    export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/ruby/include"
    export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/ruby/lib/pkgconfig"
  fi
fi
if command_exists gem; then
  if ! GEM_HOME="$(gem env user_gemhome 2>/dev/null)" || [ -z "$GEM_HOME" ]; then
    [ -d "$HOME/.gem" ] && export GEM_HOME="$HOME/.gem"
  else
    export GEM_HOME
  fi
  [ -n "$GEM_HOME" ] && PATH=$(path_prepend "$GEM_HOME/bin" "$PATH")
fi

# wine
command_exists wine && export WINEDEBUG=fixme-font

# Set up ssh-agent, macOS is handled by keychain
if [ ! "$(uname)" = "Darwin" ] && [ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
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

export PATH LD_LIBRARY_PATH CPATH

# Always assume vim is installed
EDITOR="$(command -v vim)"
# if we have code, not in an SSH term, and the X11 display number is under 10
if command_exists code &&
  [ "$SSH_TTY$DISPLAY" = "${DISPLAY#*:[1-9][0-9]}" ]; then
  VISUAL="$(command -v code) --wait"
  SUDO_EDITOR="$VISUAL"
else
  VISUAL="$EDITOR"
  SUDO_EDITOR="$EDITOR"
fi
export EDITOR VISUAL SUDO_EDITOR

export LANG=en_US.UTF-8

unset -f command_exists remove_duplicates path_prepend path_append

# variable to track history
export EVA_HISTORY="${EVA_HISTORY:+$EVA_HISTORY -> }~/.profile.sh"
