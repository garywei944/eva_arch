# Hyprland config

`hyprland.lua` is the whole hand-written config (Lua provider, Hyprland >= 0.56).
The files it `require`s at the end belong to DankMaterialShell: `dms/*.lua` are
written by DMS Settings and `dms-theme-sync.lua` by the Theme Sync plugin. Change
those through DMS, not by hand; DMS rewrites them.

Per-monitor workspaces need no plugin. Persistent workspace rules pin 1-9, 10-18
and 19-27 to DP-1, DP-2 and DP-3, and the binds use the `m~N` selector (the Nth
workspace on the focused monitor) plus `m+1`/`m-1`, which wrap within a monitor.
