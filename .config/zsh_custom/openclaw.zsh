#!/bin/zsh

if [[ -f "${HOME}/.npm-global/bin/openclaw" ]]; then
    alias openclaw="${HOME}/.npm-global/bin/openclaw"
else
    alias openclaw="openclaw"
fi
alias oca='openclaw agent'
alias ocas='openclaw agents'
alias ocg='openclaw gateway'
alias ocgrs='openclaw gateway restart'
alias oct='openclaw tui'
alias ocmsg='openclaw message'
