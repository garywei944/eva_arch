spawn() {
	$@ </dev/null &>/dev/null & disown
}

# Shortcuts
alias c="clear"
alias fdh='fd -H'
alias fdhi='fd -HI'
alias rgh='rg --hidden'
alias rghi='rg --hidden --no-ignore'
alias s='neofetch'

# Time
alias isodate='date +%F'
alias isotime='date +%Y-%m-%dT%H:%M:%S%z'
alias utctime='date -u +%FT%TZ'

# Browser-sync
alias bs='browser-sync'
alias bss='browser-sync start'
alias bsexpress='browser-sync start -p "localhost:5000" -f "public"'

# Cookiecutter
alias ckct='cookiecutter https://github.com/garywei944/cookiecutter-data-science.git'

# gitignore
alias gaignore='git ls-files -ci --exclude-standard -z | xargs -0 git rm --cached'

# MetaMap Server
alias startmm='sudo /opt/metamap_2020/public_mm/bin/skrmedpostctl start
sudo /opt/metamap_2020/public_mm/bin/wsdserverctl start'
alias stopmm='sudo /opt/metamap_2020/public_mm/bin/skrmedpostctl stop
sudo /opt/metamap_2020/public_mm/bin/wsdserverctl stop'

# docker mysql
alias dmysql='docker run -it --rm --network host mysql mysql'
alias nasumls='docker run -it --rm --network host mysql mysql -h nas.oasis.eva -P 33060 -u root -p123456'

# Reload rc scripts
alias reload='. ~/.envrc; . ~/.zshrc'

# Servers
alias sachiel='ssh root@47.92.194.143'
alias shamshel='ssh ubuntu@100.25.13.185'

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
