#!/bin/bash

# [[ $(pgrep compton) ]] || compton -b --backend glx --vsync opengl-swc
[[ $(pgrep picom) ]] || picom -b
[[ $(pgrep chrome) ]] || google-chrome-stable --password-store=gnome --no-startup-window &
# [[ $(pgrep albert) ]] || (unset XDG_CURRENT_DESKTOP; albert) &
# [[ $(pgrep albert) ]] || albert &
[[ $(pgrep krunner) ]] || krunner -d
numlockx on
waw
