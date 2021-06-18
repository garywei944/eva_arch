#!/bin/bash

__spawn() {
	([[ $(pgrep $1) ]] || ${@:2}) </dev/null >/dev/null 2>&1 & disown
}

numlockx on
waw
__spawn picom picom -b
__spawn fcitx fcitx -d

sleep 3

__spawn chrome google-chrome-stable --password-store=gnome --no-startup-window
__spawn insync insync start
__spawn albert albert
__spawn deja-dup deja-dup --gapplication-service
# __spawn krunner krunner -d
