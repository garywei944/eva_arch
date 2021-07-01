#!/bin/bash

__spawn() {
	([[ -z $(pgrep $1) ]] && ${@:2} </dev/null >/dev/null 2>&1) & disown
}

numlockx on
waw
__spawn picom picom -b
__spawn fcitx fcitx -d
__spawn albert albert

sleep 1

__spawn chrome google-chrome-stable --password-store=gnome --no-startup-window
__spawn insync insync start
__spawn deja-dup deja-dup --gapplication-service
# __spawn krunner krunner -d
