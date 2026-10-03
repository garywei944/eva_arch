# Windows 11 desktop

komorebi tiles windows, YASB draws the bar on every monitor, whkd maps hotkeys to
`komorebic` commands, kanata provides the Gallium layout, masir makes focus follow the mouse,
and WezTerm opens Arch WSL. All of them are configured from this directory.

## Files and deployment

This directory mirrors `%USERPROFILE%\.config` on Windows. Edit it in WSL, run `./install.sh`
to copy it there (together with `../kanata/gallium.kbd`), check the result, then commit.
Windows programs only read that copy; there is no Windows checkout of this repo.

| File | Read by | After a change |
| --- | --- | --- |
| `komorebi/komorebi.json` | komorebi, via `KOMOREBI_CONFIG_HOME` | reloads itself |
| `yasb/config.yaml`, `yasb/styles.css` | YASB, from its default path | reloads itself |
| `komorebi/komorebi.bar*.json` | komorebi-bar, no longer started (see below) | — |
| `whkdrc` | whkd, from its default path | Ctrl+Alt+Shift+R |
| `../kanata/gallium.kbd` | kanata, shared with Linux | Ctrl+Alt+Shift+R |
| `wezterm/wezterm.lua` | WezTerm, from its default path | reloads itself |

`komorebi/applications.json` holds komorebi's community rules for applications that need
special handling. `install.sh` downloads it once; refresh it with `komorebic fetch-asc`.

In `komorebi.json`, `monitors` lists the nine workspaces of each monitor, and
`display_index_preferences` pins monitor indices to the three displays' hardware IDs so they
survive reconnects. `global_work_area_offset` keeps the top 60 px (the bar's 48 px at 125 %
scaling) free of tiles. The rest is appearance: `theme`, borders, padding, `animation`.

## Bar

YASB shows the same bar on every monitor. Each copy lists that monitor's nine workspaces by
name: dim when empty, with app icons when populated, and filled light blue when active. The
layout widget turns into "Paused" in game mode. Change the look in `yasb/styles.css`; the
workspace label colours are in `config.yaml`, because YASB does not restyle a label when its
workspace changes state.

The bar is not a Windows app bar. komorebi does not reliably notice app bars that appear on the
side monitors and then tiles under them, so komorebi reserves the space itself. If the bar
height or display scaling changes, update `global_work_area_offset` to match.

The old komorebi-bar configs stay for rollback: `yasbc stop`, then `komorebic start --bar`.

## Startup

`komorebi/setup.ps1` (run once, elevated) registers two scheduled tasks:

- `komorebi` runs `start-komorebi.ps1` at logon as you: it starts komorebi, whkd, masir and
  YASB, then starts the `kanata` task.
- `kanata` runs elevated. Starting the task while it is running replaces the running instance.

There are two tasks because the two halves need different privileges: kanata runs elevated, and
whkd must not be, or everything it launches would be elevated too. kanata is started after whkd,
at logon and by Ctrl+Alt+Shift+R; see [kanata](#kanata) for when that matters.

If the hotkeys are dead, restart everything the way logon does, from PowerShell (or WSL via
`powershell.exe -c '...'`): `yasbc stop; komorebic stop --whkd --masir; sleep 3; Start-ScheduledTask komorebi`.
Going through the task matters: a whkd started from WSL inherits WSL's stale environment.

## kanata

kanata is the Interception (`wintercept`) build of 1.12.0 with
`../kanata/windows/wintercept-output-device.patch`, built by `../kanata/windows/build.sh` into
`D:\opt\kanata-1.12.0-outdev`. It reads and writes keys through the Interception driver, below
every keyboard hook, so its output enters Windows through the keyboard's own device like a
physical key press: Doubao IME accepts a remapped Ctrl, and whkd sees the Gallium layout no matter
which of the two starts first.

Upstream kanata sends all of its output to Interception keyboard 1 (mouse output to mouse 11).
The driver numbers devices as they appear and drops strokes sent to an empty number; here number
1 is empty and the K100 is number 2, so upstream silently drops every remapped key. The patch
sends output to the device the last intercepted key came from, or else to the first device that
accepts it.

- Reconnecting keyboards and mice uses up the driver's fixed pool of device numbers. After enough
  reconnects, newly connected devices stop working until a reboot; this is an Interception bug
  and happens without kanata too.
- kanata sits in the input path: if it hangs, keys stop. Press physical LCtrl+Space+Esc or end it
  from Task Manager; once it exits, the driver passes keys through again.

The hook-based `winIOv2` release build (`setup.ps1 -Kanata <exe>`) remains the fallback. It needs
the elevation to remap admin windows and must start after whkd, because the low-level hook
installed last sees a key first. Its output is flagged as injected, which Doubao IME ignores for
its hotkeys; that is why `gallium.kbd` leaves Right Ctrl, Doubao's voice-input key, alone.

## Keys

| Keys | Action |
| --- | --- |
| Ctrl+Alt+Shift+P | game mode: pause whkd and komorebi together; the bar shows "Paused" |
| Ctrl+Alt+Shift+R | restart whkd, then kanata |
| Ctrl+Alt+Shift+D | wallpaper mode: hide the bar and minimise windows, or restore |
| Win+T / Win+B | Arch WSL in WezTerm / new Chrome window, on the monitor under the mouse |
| Win+Y/H/A/E | focus left/down/up/right (physical H/J/K/L on Gallium) |
| Win+Shift+Y/H/A/E, Win+Shift+arrows, Win+Left/Right | move the window |
| Win+1..9 | focus workspace; with Shift, move the window there and follow it |
| Win+PgUp/PgDn | previous/next workspace; with Shift, send the window there |
| Win+Ctrl+Y/E | previous/next monitor; with Shift, send the window there |
| Win+F, Win+Up/Down | monocle; Win+Shift+T toggles floating |
| Win+= / Win+- (+Shift) | grow/shrink horizontally (vertically) |

WezTerm follows Kitty: Ctrl+T new tab, Ctrl+Tab / Ctrl+Shift+Tab or Ctrl+Shift+Left/Right to
switch tabs, Ctrl+Shift+1..9 to jump to a tab, Ctrl+Shift+W to close it, Ctrl+Shift+N for a new
window.

## New machine

1. `winget install LGUG2Z.komorebi LGUG2Z.whkd LGUG2Z.masir AmN.yasb wez.wezterm`, and install the
   Interception driver: `install-interception.exe /install` from its release, elevated, then reboot.
2. In WSL: `~/.config/kanata/windows/build.sh`, then `~/.config/win11/install.sh`.
3. In an elevated PowerShell: `& "$env:USERPROFILE\.config\komorebi\setup.ps1"`, then sign out
   and back in.
