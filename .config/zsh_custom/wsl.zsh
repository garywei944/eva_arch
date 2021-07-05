#!/bin/zsh

if [[ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/ip') == microsoft ]]; then
	__cmd() {
		cmd.exe /c "$@" &>/dev/null
	}

	alias subl='__cmd subl.bat'
	alias smerge='__cmd smerge.bat'
fi
