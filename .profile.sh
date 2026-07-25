#!/bin/sh

# Shared environment setup for POSIX-compatible shell startup files.
# Keep this file safe to source repeatedly and avoid interactive output.

_eva_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Deduplicate a colon-delimited path while preserving the first occurrence.
_eva_dedupe_path() {
  awk -v path="${1-}" 'BEGIN {
    count = split(path, entries, ":")
    output = ""
    for (i = 1; i <= count; i++) {
      if (entries[i] != "" && !seen[entries[i]]++) {
        output = output (output == "" ? "" : ":") entries[i]
      }
    }
    print output
  }'
}

_eva_prepend_path() {
  [ -n "${1-}" ] || {
    printf '%s' "${2-}"
    return
  }
  printf '%s%s' "$1" "${2:+:$2}"
}

_eva_append_path() {
  [ -n "${1-}" ] || {
    printf '%s' "${2-}"
    return
  }
  printf '%s%s' "${2-}" "${2:+:}$1"
}

_eva_ssh_agent_is_usable() {
  [ -n "${SSH_AUTH_SOCK-}" ] && [ -S "${SSH_AUTH_SOCK}" ] || return 1

  # ssh-add returns 1 when the agent is reachable but has no identities.
  _eva_command_exists ssh-add || return 0
  ssh-add -l >/dev/null 2>&1
  case $? in
    0 | 1) return 0 ;;
    *) return 1 ;;
  esac
}

################################################################################
# Base paths
################################################################################

# Iterate from lowest to highest priority because each entry is prepended.
for _eva_dir in \
  /opt/cisco/anyconnect/bin \
  /usr/local/go/bin \
  "${HOME}/.local/opt/go/bin" \
  "${HOME}/.cargo/bin" \
  "${HOME}/bin" \
  "${HOME}/.local/bin"; do
  [ -d "${_eva_dir}" ] && PATH=$(_eva_prepend_path "${_eva_dir}" "${PATH-}")
done

for _eva_dir in \
  /usr/lib/x86_64-linux-gnu \
  /usr/local/lib64 \
  "${HOME}/.local/lib"; do
  [ -d "${_eva_dir}" ] &&
    LD_LIBRARY_PATH=$(_eva_prepend_path "${_eva_dir}" "${LD_LIBRARY_PATH-}")
done

################################################################################
# Toolchains
################################################################################

# CUDA: respect a valid explicit CUDA_HOME, then try common locations.
_eva_cuda_home=
if [ -n "${CUDA_HOME-}" ] && [ -d "${CUDA_HOME}" ]; then
  _eva_cuda_home=${CUDA_HOME}
else
  for _eva_candidate in /usr/local/cuda /opt/cuda; do
    if [ -d "${_eva_candidate}" ]; then
      _eva_cuda_home=${_eva_candidate}
      break
    fi
  done
fi

if [ -n "${_eva_cuda_home}" ]; then
  CUDA_HOME=${_eva_cuda_home}
  export CUDA_HOME

  [ -d "${CUDA_HOME}/include" ] &&
    CPATH=$(_eva_prepend_path "${CUDA_HOME}/include" "${CPATH-}")

  for _eva_subdir in bin nsight_compute nsight_systems/bin; do
    [ -d "${CUDA_HOME}/${_eva_subdir}" ] &&
      PATH=$(_eva_prepend_path "${CUDA_HOME}/${_eva_subdir}" "${PATH-}")
  done

  for _eva_subdir in lib64 extras/CUPTI/lib64; do
    [ -d "${CUDA_HOME}/${_eva_subdir}" ] &&
      LD_LIBRARY_PATH=$(_eva_append_path "${CUDA_HOME}/${_eva_subdir}" "${LD_LIBRARY_PATH-}")
  done
fi

# Homebrew. shellenv is evaluated only from a discovered executable and only
# when it returns successfully.
if ! _eva_command_exists brew; then
  _eva_brew=
  for _eva_candidate in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "${HOME}/.linuxbrew/bin/brew"; do
    if [ -x "${_eva_candidate}" ]; then
      _eva_brew=${_eva_candidate}
      break
    fi
  done

  if [ -n "${_eva_brew}" ]; then
    _eva_brew_shellenv=$("${_eva_brew}" shellenv 2>/dev/null) || _eva_brew_shellenv=
    [ -n "${_eva_brew_shellenv}" ] && eval "${_eva_brew_shellenv}"
  fi
fi

_eva_homebrew_prefix=
if [ -n "${HOMEBREW_PREFIX-}" ] && [ -d "${HOMEBREW_PREFIX}" ]; then
  _eva_homebrew_prefix=${HOMEBREW_PREFIX}
elif _eva_command_exists brew; then
  _eva_homebrew_prefix=$(brew --prefix 2>/dev/null) || _eva_homebrew_prefix=
  [ -d "${_eva_homebrew_prefix}" ] || _eva_homebrew_prefix=
fi

if [ -n "${_eva_homebrew_prefix}" ]; then
  HOMEBREW_PREFIX=${_eva_homebrew_prefix}
  export HOMEBREW_PREFIX
  [ -d "${HOMEBREW_PREFIX}/sbin" ] &&
    PATH=$(_eva_prepend_path "${HOMEBREW_PREFIX}/sbin" "${PATH-}")
  [ -d "${HOMEBREW_PREFIX}/bin" ] &&
    PATH=$(_eva_prepend_path "${HOMEBREW_PREFIX}/bin" "${PATH-}")
fi

# Mark hosts where sudo is unavailable or the user is definitively denied.
# Password-required responses still mean sudo is usable interactively.
if [ -z "${NOSUDO+x}" ]; then
  if ! _eva_command_exists sudo; then
    NOSUDO=1
    export NOSUDO
  elif _eva_sudo_output=$(LC_ALL=C sudo -n -v 2>&1); then
    :
  else
    case ${_eva_sudo_output} in
      *"not in the sudoers"* | *"not allowed to execute"* | *"not allowed to run sudo"* | *"may not run sudo"*)
        NOSUDO=1
        export NOSUDO
        ;;
    esac
  fi
fi

# Java: preserve an explicit JAVA_HOME, otherwise use common platform defaults.
if [ -z "${JAVA_HOME+x}" ]; then
  _eva_java_home=
  for _eva_candidate in \
    /usr/lib/jvm/default \
    /usr/lib/jvm/default-java \
    /Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home; do
    if [ -d "${_eva_candidate}" ]; then
      _eva_java_home=${_eva_candidate}
      break
    fi
  done

  if [ -z "${_eva_java_home}" ] && [ -x /usr/libexec/java_home ]; then
    _eva_java_home=$(/usr/libexec/java_home 2>/dev/null) || _eva_java_home=
  fi

  if [ -n "${_eva_java_home}" ]; then
    JAVA_HOME=${_eva_java_home}
    export JAVA_HOME
  fi
fi

# Conda, Anaconda, Miniforge, or Mambaforge.
# Work around the Miniconda OpenSSL 3 legacy-provider loading issue.
: "${CRYPTOGRAPHY_OPENSSL_NO_LEGACY:=1}"
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY

if _eva_command_exists micromamba; then
  : "${MAMBA_ROOT_PREFIX:=${HOME}/.conda}"
  export MAMBA_ROOT_PREFIX
fi

if [ -z "${CONDA_PATH+x}" ]; then
  _eva_conda_path=
  for _eva_conda in anaconda3 miniconda3 mambaforge miniforge3 miniforge; do
    for _eva_candidate in \
      "${HOME}/${_eva_conda}" \
      "/opt/${_eva_conda}" \
      "/usr/local/Caskroom/${_eva_conda}/base"; do
      if [ -d "${_eva_candidate}" ]; then
        _eva_conda_path=${_eva_candidate}
        break 2
      fi
    done

    if [ -n "${_eva_homebrew_prefix}" ]; then
      for _eva_candidate in \
        "${_eva_homebrew_prefix}/Caskroom/${_eva_conda}/base" \
        "${_eva_homebrew_prefix}/${_eva_conda}"; do
        if [ -d "${_eva_candidate}" ]; then
          _eva_conda_path=${_eva_candidate}
          break 2
        fi
      done
    fi
  done

  if [ -n "${_eva_conda_path}" ]; then
    CONDA_PATH=${_eva_conda_path}
    export CONDA_PATH
  fi
fi

# fzf and fd: keep an explicit command and avoid configuring a missing binary.
if [ -z "${FZF_DEFAULT_COMMAND-}" ]; then
  if _eva_command_exists fd; then
    FZF_DEFAULT_COMMAND=fd
  elif _eva_command_exists fdfind; then
    FZF_DEFAULT_COMMAND=fdfind
  fi
  [ -n "${FZF_DEFAULT_COMMAND-}" ] && export FZF_DEFAULT_COMMAND
fi

# SDKMAN.
if [ -z "${SDKMAN_DIR+x}" ] && [ -d "${HOME}/.sdkman" ]; then
  SDKMAN_DIR=${HOME}/.sdkman
  export SDKMAN_DIR
fi

# Homebrew Ruby.
_eva_ruby_prefix=
if [ -n "${_eva_homebrew_prefix}" ] && [ -d "${_eva_homebrew_prefix}/opt/ruby" ]; then
  _eva_ruby_prefix=${_eva_homebrew_prefix}/opt/ruby
  PATH=$(_eva_prepend_path "${_eva_ruby_prefix}/bin" "${PATH-}")

  case " ${LDFLAGS-} " in
    *" -L${_eva_ruby_prefix}/lib "*) ;;
    *) LDFLAGS="-L${_eva_ruby_prefix}/lib${LDFLAGS:+ ${LDFLAGS}}" ;;
  esac
  case " ${CPPFLAGS-} " in
    *" -I${_eva_ruby_prefix}/include "*) ;;
    *) CPPFLAGS="-I${_eva_ruby_prefix}/include${CPPFLAGS:+ ${CPPFLAGS}}" ;;
  esac
  PKG_CONFIG_PATH=$(_eva_prepend_path "${_eva_ruby_prefix}/lib/pkgconfig" "${PKG_CONFIG_PATH-}")
  export LDFLAGS CPPFLAGS PKG_CONFIG_PATH
fi

if _eva_command_exists gem; then
  if [ -z "${GEM_HOME-}" ]; then
    _eva_gem_home=$(gem env user_gemhome 2>/dev/null) || _eva_gem_home=
    if [ -n "${_eva_gem_home}" ]; then
      GEM_HOME=${_eva_gem_home}
    elif [ -d "${HOME}/.gem" ]; then
      GEM_HOME=${HOME}/.gem
    fi
  fi

  if [ -n "${GEM_HOME-}" ]; then
    export GEM_HOME
    PATH=$(_eva_prepend_path "${GEM_HOME}/bin" "${PATH-}")
  fi
fi

# Wine.
if _eva_command_exists wine; then
  : "${WINEDEBUG:=fixme-font}"
  export WINEDEBUG
fi

# npm global packages.
[ -d "${HOME}/.npm-global/bin" ] &&
  PATH=$(_eva_prepend_path "${HOME}/.npm-global/bin" "${PATH-}")

################################################################################
# SSH agent
################################################################################

_eva_uname=$(uname -s 2>/dev/null) || _eva_uname=unknown
case $- in
  *i*)
    if [ "${_eva_uname}" != Darwin ] && [ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
      if ! _eva_ssh_agent_is_usable && _eva_command_exists ssh-agent; then
        _eva_agent_dir=${XDG_RUNTIME_DIR:-${HOME}/.cache}/eva
        _eva_agent_env=${_eva_agent_dir}/ssh-agent.env

        # Reuse only an environment file whose socket still answers ssh-add.
        if [ -r "${_eva_agent_env}" ]; then
          # This file is generated exclusively from `ssh-agent -s` below.
          # shellcheck disable=SC1090
          . "${_eva_agent_env}" >/dev/null 2>&1
        fi

        if ! _eva_ssh_agent_is_usable && mkdir -p "${_eva_agent_dir}" 2>/dev/null; then
          chmod 700 "${_eva_agent_dir}" 2>/dev/null || :
          _eva_agent_tmp=${_eva_agent_env}.$$
          if (umask 077 && ssh-agent -s >"${_eva_agent_tmp}"); then
            # shellcheck disable=SC1090
            . "${_eva_agent_tmp}" >/dev/null 2>&1
            if _eva_ssh_agent_is_usable; then
              mv -f "${_eva_agent_tmp}" "${_eva_agent_env}"
            else
              rm -f "${_eva_agent_tmp}"
            fi
          else
            rm -f "${_eva_agent_tmp}"
          fi
        fi
      fi
    fi
    ;;
esac

################################################################################
# Finalize exported environment
################################################################################

PATH=$(_eva_dedupe_path "${PATH-}")
LD_LIBRARY_PATH=$(_eva_dedupe_path "${LD_LIBRARY_PATH-}")
CPATH=$(_eva_dedupe_path "${CPATH-}")
export PATH LD_LIBRARY_PATH CPATH

if [ -n "${PKG_CONFIG_PATH-}" ]; then
  PKG_CONFIG_PATH=$(_eva_dedupe_path "${PKG_CONFIG_PATH}")
  export PKG_CONFIG_PATH
fi

# Preserve explicit editor choices. Prefer VS Code only for local graphical
# sessions; remote shells should keep a terminal editor.
if [ -z "${EDITOR-}" ]; then
  for _eva_editor in vim vi; do
    if _eva_command_exists "${_eva_editor}"; then
      EDITOR=$(command -v "${_eva_editor}")
      break
    fi
  done
  : "${EDITOR:=vi}"
fi

if [ -z "${VISUAL-}" ]; then
  if _eva_command_exists code &&
    [ -z "${SSH_TTY-}${SSH_CONNECTION-}" ] &&
    { [ "${_eva_uname}" = Darwin ] || [ -n "${DISPLAY-}${WAYLAND_DISPLAY-}" ]; }; then
    VISUAL="$(command -v code) --wait"
  else
    VISUAL=${EDITOR}
  fi
fi

: "${SUDO_EDITOR:=${VISUAL}}"
export EDITOR VISUAL SUDO_EDITOR

: "${LANG:=en_US.UTF-8}"
export LANG

case ${EVA_HISTORY-} in
  *"~/.profile.sh"*) ;;
  *)
    EVA_HISTORY="${EVA_HISTORY:+${EVA_HISTORY} -> }~/.profile.sh"
    export EVA_HISTORY
    ;;
esac

unset _eva_agent_dir _eva_agent_env _eva_agent_tmp _eva_brew _eva_brew_shellenv
unset _eva_candidate _eva_conda _eva_conda_path _eva_cuda_home _eva_dir _eva_editor
unset _eva_gem_home _eva_homebrew_prefix _eva_java_home _eva_ruby_prefix _eva_subdir
unset _eva_sudo_output _eva_uname
unset -f _eva_append_path _eva_command_exists _eva_dedupe_path
unset -f _eva_prepend_path _eva_ssh_agent_is_usable
