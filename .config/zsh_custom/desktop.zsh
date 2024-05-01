#!/bin/zsh

# Dolphin
dol() {
	spawn dolphin "$@"
}
alias dolt='dol .'

# PyCharm
pcm() {
	spawn pycharm-professional "$@"
}
alias pcmt='pcm .'
