#!/bin/zsh

# Welcome message
if [[ -n $(command -v figlet) && -n $(command -v lolcat) ]]; then
    echo "$(echo "ariseus" | figlet)\nWelcome back, ariseus." | lolcat
elif is-at-least 5.8; then
    if [[ -n $(command -v lolcat) ]]; then
        box_out "Welcome back, ariseus." | lolcat
    else
        box_out "Welcome back, ariseus."
    fi
else
    echo " ------------------------
|                        |
| Welcome back, ariseus. |
|                        |
 ------------------------"
fi
