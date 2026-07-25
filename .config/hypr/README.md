# Hyprland config

This configuration is written in Lua and uses the
[hyprsplit](https://github.com/shezdy/hyprsplit) Lua library for per-monitor
workspaces (see `dms/hyprsplit.lua`). It requires Hyprland >= v0.55.0.

## Setup

`hyprsplit` is no longer vendored as a Git submodule. Clone it yourself:

```sh
git clone --depth=1 https://github.com/shezdy/hyprsplit.git ~/.config/hypr/hyprsplit
```

The clone is ignored by this repository, so local updates (`git -C
~/.config/hypr/hyprsplit pull`) never show up as untracked changes here.

Then reload Hyprland (`hyprctl reload`) — or restart your session — to pick up
the library.
