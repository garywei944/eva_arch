Hyprland Lua migration record
=============================

Created: 2026-07-25 01:21:21 local time
Original configuration: /home/aris/.config/hypr

Backups
-------
- Original config tree: config/
- Original HyprPM cache/state: hyprpm-cache/
- DMS migration backup: /home/aris/.config/hypr/.dms-backups/2026-07-25_01-25-43/

Migration
---------
- Main provider config: /home/aris/.config/hypr/hyprland.lua
- DMS Lua fragments: /home/aris/.config/hypr/dms/*.lua
- Lua hyprsplit checkout: /home/aris/.config/hypr/hyprsplit
- Lua hyprsplit pinned commit: 6b00b677d8905fb38779c91e12d6294e0e586a44
- C++ HyprPM repositories removed: hyprsplit, hyprland-easymotion
- Legacy active .conf files archived; none remain in the active config tree.

Validation
----------
- luac syntax check: passed
- Hyprland --verify-config: config ok
- Lua hyprsplit construction test: 34 binds
- Workspace-name construction test: 27 rules
- Legacy-to-Lua effective key-set audit: 122/122 binds preserved, 0 missing, 0 additional
- HyprPM repository list: empty
- Active Lua config contains no easymotion, hyprpm, or split:* dispatcher references

Activation
----------
The existing graphical session remains on configProvider=hyprlang. Do not run
`hyprctl reload` to switch providers. Log out and start a fresh Hyprland session;
Hyprland will discover ~/.config/hypr/hyprland.lua.

After login, verify with:

    hyprctl status
    hyprctl plugin list
    hyprctl monitors
    hyprctl workspaces

Expected: configProvider=lua and no C++ plugins loaded.

Rollback
--------
Do this from a TTY or another desktop session, not from the running Hyprland session:

    mv /home/aris/.config/hypr /home/aris/.config/hypr.lua-migration-failed
    cp -a /home/aris/.config/hypr-backups/lua-migration-20260725-012121/config /home/aris/.config/hypr

The original C++ plugin repositories were incompatible with Hyprland 0.56. Their
state/cache is retained under hyprpm-cache/ for forensic rollback, but restoring
it will not make those plugins ABI-compatible.
