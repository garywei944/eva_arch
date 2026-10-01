#!/usr/bin/env bash
# Copy the Windows desktop configs from this directory (plus the shared kanata layout) to
# %USERPROFILE%\.config, which mirrors it. Windows reads only that copy; there is no Windows
# checkout of this repo. komorebi, YASB and WezTerm reload changed files by themselves;
# after changing whkdrc or gallium.kbd press Ctrl+Alt+Shift+R to restart whkd and kanata.
set -euo pipefail

src=$(dirname "$(realpath "$0")")
dst=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")/.config

mkdir -p "$dst/komorebi" "$dst/kanata" "$dst/wezterm" "$dst/yasb"
cp "$src"/komorebi/*.json "$src"/komorebi/*.ps1 "$dst/komorebi/"
cp "$src/wezterm/wezterm.lua" "$dst/wezterm/"
cp "$src/yasb/config.yaml" "$src/yasb/styles.css" "$dst/yasb/"
cp "$src/whkdrc" "$dst/"
cp "$src/../kanata/gallium.kbd" "$dst/kanata/"

# komorebi's community rules for known applications; refresh with `komorebic fetch-asc`.
asc=$dst/komorebi/applications.json
[[ -f $asc ]] || curl -fsSL -o "$asc" \
    https://raw.githubusercontent.com/LGUG2Z/komorebi-application-specific-configuration/master/applications.json

echo "Deployed to $dst"
