#!/bin/sh

# WINDOWS MANAGER AND DESKTOP ENVIRONMENT:
# -- Window manager
export XDG_CURRENT_DESKTOP="kde"
# -- Desktop Environment
export DESKTOP_SESSION="kde"
export DE="kde"

export KDE_FULL_SESSION=true
export QT_QPA_PLATFORMTHEME="kde"

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"

source $HOME/.envrc
