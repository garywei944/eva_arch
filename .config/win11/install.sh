#!/usr/bin/env bash
# Copy the Windows desktop configs from this directory (plus the shared kanata layout) to
# %USERPROFILE%\.config, which mirrors it. Windows reads only that copy; there is no Windows
# checkout of this repo. komorebi, YASB and WezTerm reload changed files by themselves;
# after changing whkdrc or gallium.kbd press Ctrl+Alt+Shift+R to restart whkd and kanata.
set -euo pipefail

src=$(dirname "$(realpath "$0")")
dst=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")/.config

mkdir -p "$dst/komorebi" "$dst/kanata" "$dst/wezterm" "$dst/yasb"
cp "$src"/komorebi/*.json "$src"/komorebi/*.ps1 "$src"/komorebi/*.cmd "$src"/komorebi/*.cs "$dst/komorebi/"
# cmd.exe can miss a goto label in a file with bare LF line endings; the repo keeps LF.
sed -i 's/\r*$/\r/' "$dst"/komorebi/*.cmd
cp "$src/wezterm/wezterm.lua" "$dst/wezterm/"
cp "$src/yasb/config.yaml" "$src/yasb/styles.css" "$dst/yasb/"
cp "$src/whkdrc" "$dst/"
cp "$src/../kanata/gallium.kbd" "$dst/kanata/"

# Hotkey helpers are C#, built with the .NET Framework compiler that ships with Windows, because
# a cold PowerShell costs ~0.6 s per keypress.
csc=/mnt/c/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe
for cs in "$dst"/komorebi/*.cs; do
    win=$(wslpath -w "$cs")
    "$csc" /nologo /target:winexe /optimize /r:System.Web.Extensions.dll /out:"${win%.cs}.exe" "$win"
done

# komorebi's community rules for known applications; refresh with `komorebic fetch-asc`.
asc=$dst/komorebi/applications.json
[[ -f $asc ]] || curl -fsSL -o "$asc" \
    https://raw.githubusercontent.com/LGUG2Z/komorebi-application-specific-configuration/master/applications.json

echo "Deployed to $dst"
