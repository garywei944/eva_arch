#!/bin/zsh

spawn() {
  ($@ </dev/null &>/dev/null) &
  disown
}

# Shortcuts
alias c='clear' # use `clr` in systemadmin plugin
alias t='tmux'
alias xcopy='xclip -sel clip'
alias fdh='fd -H'
alias fdhi='fd -HI'
alias rgh='rg --hidden'
alias rghi='rg --hidden --no-ignore'
alias ftree='fd | as-tree'
alias ncore='grep -m 1 "cpu cores" /proc/cpuinfo | sed "s/[^0-9]*//g"'
alias s='neofetch'

# Time
#alias isodate='date +%F'
alias isotime='date +%Y-%m-%dT%H:%M:%S%z'
alias utctime='date -u +%FT%TZ'

# Public IP
alias myip="curl 'https://ifconfig.me'"
alias apiip="curl 'https://api.ipify.org'"
alias apiipv6="curl 'https://api64.ipify.org'"

# Chrome
alias startchrome='spawn google-chrome-stable --password-store=gnome --no-startup-window'

# Browser-sync
alias bsync='browser-sync'
alias bss='browser-sync start'
alias bsexpress='browser-sync start -p "localhost:5000" -f "public"'

# Cookiecutter
alias ccml='cookiecutter gh:garywei944/cookiecutter-machine-learning'
alias ccpypi='cookiecutter gh:garywei944/cookiecutter-pypackage'

# git
alias gcld='git clone --recurse-submodules --depth 1'
alias gaignore='git ls-files -ci --exclude-standard -z | xargs -0 git rm --cached'
alias gassh="ssh-keygen -R github.com; curl -L https://api.github.com/meta | jq -r '.ssh_keys | .[]' | sed -e 's/^/github.com /' >>~/.ssh/known_hosts"

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
