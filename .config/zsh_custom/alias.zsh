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


alias reload='. ~/.zshrc'

# Servers
alias sachiel='ssh root@47.92.194.143'
alias shamshel='ssh ubuntu@3.83.202.176'

# Maybe
alias lg='lazygit'
alias ra='ranger'
alias sra='sudo -E ranger'
