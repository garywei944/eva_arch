#!/bin/bash

__spawn() {
	([[ $(pgrep $1) ]] || ${@:2}) </dev/null >/dev/null 2>&1 & disown
}

__spawn picom picom -b
__spawn chrome google-chrome-stable --password-store=gnome --no-startup-window
__spawn insync insync start
__spawn albert albert
__spawn fcitx fcitx -d
# __spawn krunner krunner -d
numlockx on
waw
