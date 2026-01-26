#!/bin/zsh

# Dolphin
dol() {
	spawn dolphin "$@"
}
alias dolt='dol .'

# PyCharm
pcm() {
	if [[ -n $(command -v pycharm) ]]; then
		spawn pycharm "$@"
	elif [[ -n $(command -v pycharm-professional) ]]; then
		spawn pycharm-professional "$@"
	else
		echo "No pycharm command detected"
	fi
}
alias pcmt='pcm .'
