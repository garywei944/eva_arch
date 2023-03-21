#!/bin/zsh

spawn() {
  ($@ </dev/null &>/dev/null) &
  disown
}

# Shortcuts
alias c='clear'
alias t='tmux'
alias copy='xclip -sel clip'
alias fdh='fd -H'
alias fdhi='fd -HI'
alias rgh='rg --hidden'
alias rghi='rg --hidden --no-ignore'
alias ftree='fd | as-tree'
alias ncore='grep -m 1 "cpu cores" /proc/cpuinfo | sed "s/[^0-9]*//g"'
alias s='neofetch'

# Time
alias isodate='date +%F'
alias isotime='date +%Y-%m-%dT%H:%M:%S%z'
alias utctime='date -u +%FT%TZ'

# Public IP
alias myip="curl 'https://ifconfig.me'"
alias getip="curl 'https://api.ipify.org'"
alias getipv6="curl 'https://api64.ipify.org'"

# Chrome
alias startchrome='spawn google-chrome-stable --password-store=gnome --no-startup-window'

# Browser-sync
alias bs='browser-sync'
alias bss='browser-sync start'
alias bsexpress='browser-sync start -p "localhost:5000" -f "public"'

# Cookiecutter
alias ccml='cookiecutter gh:garywei944/cookiecutter-machine-learning'

# git
alias gcld='git clone --recurse-submodules --depth 1'
alias gaignore='git ls-files -ci --exclude-standard -z | xargs -0 git rm --cached'

# Reload rc scripts
alias reload='. ~/.env.sh; . ~/.zshrc'

# Maybe
alias lg='lazygit'
alias ra='ranger'
alias sra='sudo -E ranger'

# CentOS no `tree` workaround
[[ -z $(command -v tree) && -n $(command -v fd) && -n $(command -v as-tree) ]] && alias tree='fd -HI | as-tree'

# Check CUDA version
cudaver() {
  nvcc -V | sed -ne 's/.* V\(.*\..*\)\..*/\1/p'
}
