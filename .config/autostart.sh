#!/bin/bash

__spawn() {
  ([[ -z $(pgrep "$1") ]] && "${@:2}" </dev/null >/dev/null 2>&1) &
  disown
}

__nokde_spawn() {
  (
    unset KDE_FULL_SESSION XDG_CURRENT_DESKTOP
    __spawn "$@"
  ) &
  disown
}

numlockx on
waw
__spawn picom picom -b
__spawn fcitx fcitx -d
__spawn albert albert

# sleep 1

#__spawn qv2ray qv2ray
__spawn chrome google-chrome-stable --password-store=gnome --no-startup-window
__spawn insync insync start
# __spawn deja-dup deja-dup --gapplication-service
# __nokde_spawn birdtrap birdtray
__spawn betterbird betterbird
