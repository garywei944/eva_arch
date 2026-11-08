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
| `komorebi/*.cs` | built into `*.exe` next to it by `install.sh` | next keypress |

Hotkey helpers that whkd runs on every press are C#, not PowerShell scripts: a cold PowerShell
costs ~0.4 s before the first line runs, a .NET Framework program ~30 ms. `install.sh` compiles
them with the `csc.exe` that ships with Windows (C# 5, .NET Framework 4.8), so nothing extra is
installed.

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

- `komorebi` runs `start-komorebi.cmd` at logon as you: it starts komorebi, whkd, masir and
  YASB, then starts the `kanata` task. Everything is running about half a second after the task
  starts.
- `kanata` runs elevated. Starting the task while it is running replaces the running instance.

There are two tasks because the two halves need different privileges: kanata runs elevated, and
whkd must not be, or everything it launches would be elevated too.

The `komorebi` task runs `conhost.exe --headless cmd.exe /c start-komorebi.cmd`. A task that
starts PowerShell (or any console program) directly gets a window, because Windows 11 hands new
consoles to Windows Terminal, which ignores `-WindowStyle Hidden`; a headless conhost never
shows one. That conhost stays alive as the console of komorebi, whkd and masir, so the task shows
as Running and has no time limit. The script launches the programs directly instead of through
`komorebic start --whkd --masir`, which starts one PowerShell per program and then sleeps 3 s.

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
accepts it. It is proposed upstream as [kanata#2206](https://github.com/jtroo/kanata/pull/2206)
(fixing #2193); once a release includes it, switch back to the release binary and drop the patch.

- Reconnecting keyboards and mice uses up the driver's fixed pool of device numbers. After enough
  reconnects, newly connected devices stop working until a reboot; this is an Interception bug
  and happens without kanata too.
- kanata sits in the input path: if it hangs, keys stop. Press physical LCtrl+Space+Esc or end it
  from Task Manager; once it exits, the driver passes keys through again.

The hook-based `winIOv2` release build (`setup.ps1 -Kanata <exe>`) remains the fallback. It needs
the elevation to remap admin windows and must start after whkd, because the low-level hook
installed last sees a key first. Ctrl+Alt+Shift+R waits a second for that; the logon script does
not wait, so with this build press Ctrl+Alt+Shift+R once after logon if the layout is wrong. Its output is flagged as injected, which Doubao IME ignores for
its hotkeys; that is why `gallium.kbd` leaves Right Ctrl, Doubao's voice-input key, alone.

## Where new windows open

komorebi tiles a new window on the monitor where it first appears, and the program decides where
that is. Programs that remember their last position (Chrome, Explorer, most Electron apps) return
there. The rest let Windows choose, which means the primary monitor, unless the launcher names a
monitor; the Start menu and taskbar name the one they are on.

`launch-on-cursor-monitor.exe <program> [args]`, behind Win+T, Win+B and Hyper+E, starts the
program with the monitor under the mouse named, then moves the new window there with
`komorebic move-to-monitor` if it appeared elsewhere. Starting the program takes ~0.1 s; a move
adds the time komorebi needs to manage the window plus 0.5 s for the retile. While komorebi is
paused it only launches.

## Keys

| Keys | Action |
| --- | --- |
| Ctrl+Alt+Shift+P | game mode: pause whkd and komorebi together; the bar shows "Paused" |
| Ctrl+Alt+Shift+R | restart whkd, then kanata |
| Ctrl+Alt+Shift+D | wallpaper mode: hide the bar and minimise windows, or restore |
| Win+T / Win+B / Hyper+E | Arch WSL in WezTerm / new Chrome window / File Explorer, on the monitor under the mouse |
| Hyper+M / Hyper+W / Hyper+D / Hyper+Y | QQ Music / WeChat / Discord / Youdao Dict, as on Hyprland; mouse side buttons send Win+Numpad 4/7/0/1 for the same apps |
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

## komorebi nightly

komorebi runs the winget package `LGUG2Z.komorebi.Nightly`, because the last tagged release
(v0.1.41, May 2026) lacks months of focus, monitor and resize fixes. The package's manifest has a
stale ProductCode, so `winget list` shows the install as the stable `LGUG2Z.komorebi`; the pin
`winget pin add --id LGUG2Z.komorebi --blocking` keeps `winget upgrade --all` from replacing it
with a stable release.

The nightly manifest always says 0.1.42, so `winget upgrade` never offers a new build, and every
build has the same MSI ProductCode, so it cannot be installed over the previous one. To update:

1. Stop the stack: `yasbc stop; komorebic stop --whkd --masir`.
2. `winget uninstall --id LGUG2Z.komorebi --exact`, then
   `winget install --id LGUG2Z.komorebi.Nightly --exact`.
3. `Start-ScheduledTask komorebi`.

If winget reports a hash mismatch, GitHub has rebuilt `nightly` since the winget manifest was last
updated (about every two weeks): wait, or install `komorebi-nightly-x86_64.msi` from the release
with `msiexec`, from a folder Windows created such as `%TEMP%` (elevated msiexec fails with 1622 on
a folder created from WSL). To go back to stable: `winget pin remove --id LGUG2Z.komorebi`,
uninstall, then `winget install LGUG2Z.komorebi`.
