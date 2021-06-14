#!/bin/bash

# [[ $(pgrep compton) ]] || compton -b --backend glx --vsync opengl-swc
[[ $(pgrep picom) ]] || picom -b
[[ $(pgrep chrome) ]] || google-chrome --no-startup-window --password-store=gnome &
# [[ $(pgrep albert) ]] || albert &
numlockx on
waw
