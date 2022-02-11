#!/bin/zsh

spawn() {
	($@ </dev/null &>/dev/null) & disown
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

# Chrome
alias startchrome='spawn google-chrome-stable --password-store=gnome --no-startup-window'

# Browser-sync
alias bs='browser-sync'
alias bss='browser-sync start'
alias bsexpress='browser-sync start -p "localhost:5000" -f "public"'

# Cookiecutter
alias ckct='cookiecutter https://github.com/garywei944/cookiecutter-data-science.git'

# git
alias gcld='git clone --recurse-submodules --depth 1'
alias gaignore='git ls-files -ci --exclude-standard -z | xargs -0 git rm --cached'

# docker mysql
alias dmysql='docker run -it --rm --network host mysql mysql'
alias nasumls='docker run -it --rm --network host mysql mysql -h nas.oasis.eva -P 33060 -u root -p123456'

# Reload rc scripts
alias reload='. ~/.envrc; . ~/.zshrc'

# Shadowsocks
alias sssachiel='ss-local -c /etc/shadowsocks/sachiel.json & disown'
alias ss2hp='hpts -s 127.0.0.1:1080 -p 8080 & disown'
alias killss='killall ss-local'

# Maybe
alias lg='lazygit'
alias ra='ranger'
alias sra='sudo -E ranger'


# Check CUDA version
cudaver() {
	nvcc -V | sed -ne 's/.* V\(.*\..*\)\..*/\1/p'
}
