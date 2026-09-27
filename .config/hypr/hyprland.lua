-- Hyprland config (Lua, Hyprland >= 0.56): https://wiki.hypr.land/Configuring/Start/
-- Everything hand-written lives here. DMS rewrites dms/*.lua and dms-theme-sync.lua (required at the end);
-- it round-trips window rules through its own model, so hand-written rules stay in this file.

---------------
-- Autostart --
---------------

hl.env("TERMINAL", "kitty")

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("uwsm app -- dms run")
    hl.exec_cmd("~/bin/ensure-wallpaper-engine-control-dms --wait --restart-if-changed")
    hl.exec_cmd("~/bin/wallpaper-engine-login-start")
    hl.exec_cmd("kded6")
    hl.exec_cmd("fcitx5 -d --replace")
    hl.exec_cmd("insync start")
    hl.exec_cmd("google-chrome-stable --no-startup-window")
end)

-------------------
-- Look and feel --
-------------------

-- Gaps, borders and rounding come from dms/layout.lua; colors from dms/colors.lua.
hl.config({
    input = { numlock_by_default = true },
    xwayland = { force_zero_scaling = true },
    cursor = { no_hardware_cursors = false, default_monitor = "DP-1" },
    decoration = {
        shadow = { range = 30, render_power = 5, offset = "0 5", color = "rgba(00000070)" },
    },
    dwindle = { preserve_split = true },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
})

hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "default", style = "slidevert" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "default" })

-----------
-- Rules --
-----------

hl.window_rule({ match = { class = "^pavucontrol$" }, tile = true })
hl.window_rule({ match = { class = "^org\\.gnome\\.Nautilus$" }, float = true })
hl.window_rule({ match = { class = "^firefox$", title = "^Picture-in-Picture$" }, float = true })
hl.window_rule({ match = { class = "^steam$", title = "^notificationtoasts" }, no_initial_focus = true, pin = true })
hl.window_rule({ match = { class = "^steam_app_[0-9]+$" }, float = true, center = true, content = "game" })
hl.layer_rule({ match = { namespace = "^(quickshell|dms:.*)$" }, no_anim = true })

-- Open apps on their workspace of the right monitor (DP-3): 20 = Chat, 21 = Git, 25 = Music.
hl.window_rule({ match = { class = "^(discord|Discord|wechat|WeChat|lark|Lark)$" }, workspace = "20" })
hl.window_rule({ match = { class = "^(smerge|sublime_merge)$" }, workspace = "21" })
hl.window_rule({ match = { class = "^qqmusic$" }, workspace = "25" })

-- wallpaper-engine-control parks this hidden fullscreen helper so linux-wallpaperengine uses its
-- native fullscreen pause instead of SIGSTOP, which can crash it after queued DBus events.
hl.window_rule({
    match = { class = "^zenity$", title = "^EVA Wallpaper Pause Helper [0-9a-f]+$" },
    workspace = "special:eva-wallpaper-pause silent",
    fullscreen = true,
    no_focus = true,
    no_anim = true,
})

----------------
-- Workspaces --
----------------

-- Nine persistent workspaces per monitor: DP-1 = 1-9, DP-2 = 10-18, DP-3 = 19-27.
-- Binds reach them with "m~N" (the Nth workspace on the focused monitor), so no plugin is needed.
local workspaces = {
    { "DP-1", { "Code", "Web", "Folder", "Doc", "App", "Code", "Web", "Terminal", "Reserve" } },
    { "DP-2", { "Code", "Web", "Folder", "Doc", "App", "Code", "Web", "Terminal", "Reserve" } },
    { "DP-3", { "Web", "Chat", "Git", "Doc", "App", "Code", "Music", "Terminal", "Reserve" } },
}
for m, monitor in ipairs(workspaces) do
    for n, name in ipairs(monitor[2]) do
        hl.workspace_rule({
            workspace = tostring((m - 1) * 9 + n),
            monitor = monitor[1],
            default = n == 1,
            persistent = true,
            default_name = string.format("%d-%d | %s", m, n, name),
        })
    end
end

-----------
-- Binds --
-----------

local hyper = "CTRL + SHIFT + ALT + SUPER" -- Kanata's Hyper key
local locked = { locked = true }
local repeat_locked = { locked = true, repeating = true }

-- Apps
hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(hyper .. " + B", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(hyper .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind(hyper .. " + M", hl.dsp.exec_cmd("qqmusic"))
hl.bind(hyper .. " + W", hl.dsp.exec_cmd("wechat"))
hl.bind(hyper .. " + D", hl.dsp.exec_cmd("discord"))
hl.bind("SUPER + KP_Left", hl.dsp.exec_cmd("qqmusic"))
hl.bind("SUPER + KP_Home", hl.dsp.exec_cmd("wechat"))
hl.bind("SUPER + KP_Insert", hl.dsp.exec_cmd("discord"))

-- DMS shell and session
hl.bind("ALT + space", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))
hl.bind("SUPER + comma", hl.dsp.exec_cmd("dms ipc call settings focusOrToggle"))
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))
hl.bind("SUPER + X", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
hl.bind("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"))
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("dms ipc call window-rules toggle"))
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("dms ipc call wallpaperEngineControl next"))
hl.bind("CTRL + SHIFT + R", hl.dsp.exec_cmd("dms ipc call workspace-rename open"))
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"))

-- Media and brightness keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 2"), repeat_locked)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 2"), repeat_locked)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), locked)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"), locked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("dms ipc call mpris playPause"), locked)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("dms ipc call mpris playPause"), locked)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("dms ipc call mpris previous"), locked)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("dms ipc call mpris next"), locked)
hl.bind("CTRL + XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call mpris increment 2"), repeat_locked)
hl.bind("CTRL + XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call mpris decrement 2"), repeat_locked)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd('dms ipc call brightness increment 5 ""'), repeat_locked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd('dms ipc call brightness decrement 5 ""'), repeat_locked)

-- Screenshots
local function screenshot_focused_monitor()
    hl.exec_cmd("mark-shot --capture --fullscreen --display " .. hl.get_active_monitor().name)
end
hl.bind("Print", hl.dsp.exec_cmd("mark-shot --capture"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("mark-shot --capture"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("mark-shot --capture --all-outputs --fullscreen"))
hl.bind("CTRL + Print", screenshot_focused_monitor)

-- Window state and layout
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + up", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + down", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind("F11", hl.dsp.window.fullscreen())
hl.bind("SUPER + SHIFT + T", hl.dsp.window.float())
hl.bind("SUPER + W", hl.dsp.group.toggle())
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + bracketleft", hl.dsp.layout("preselect l"))
hl.bind("SUPER + bracketright", hl.dsp.layout("preselect r"))
hl.bind("SUPER + minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + equal", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Focus and move windows: Y/H/A/E = left/down/up/right on Gallium
hl.bind("SUPER + Y", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + H", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + A", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + E", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + SHIFT + Y", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + A", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + E", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.window.move({ direction = "r" }))

-- Monitors
hl.bind("SUPER + CTRL + Y", hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + CTRL + H", hl.dsp.focus({ monitor = "d" }))
hl.bind("SUPER + CTRL + A", hl.dsp.focus({ monitor = "u" }))
hl.bind("SUPER + CTRL + E", hl.dsp.focus({ monitor = "r" }))
hl.bind("SUPER + CTRL + left", hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + CTRL + right", hl.dsp.focus({ monitor = "r" }))
hl.bind("SUPER + CTRL + SHIFT + Y", hl.dsp.window.move({ monitor = "l" }))
hl.bind("SUPER + CTRL + SHIFT + H", hl.dsp.window.move({ monitor = "d" }))
hl.bind("SUPER + CTRL + SHIFT + A", hl.dsp.window.move({ monitor = "u" }))
hl.bind("SUPER + CTRL + SHIFT + E", hl.dsp.window.move({ monitor = "r" }))
hl.bind("SUPER + CTRL + SHIFT + left", hl.dsp.window.move({ monitor = "l" }))
hl.bind("SUPER + CTRL + SHIFT + down", hl.dsp.window.move({ monitor = "d" }))
hl.bind("SUPER + CTRL + SHIFT + up", hl.dsp.window.move({ monitor = "u" }))
hl.bind("SUPER + CTRL + SHIFT + right", hl.dsp.window.move({ monitor = "r" }))

-- Workspaces on the focused monitor; moving a window follows it
hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "m~1" }))
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "m~2" }))
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "m~3" }))
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "m~4" }))
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "m~5" }))
hl.bind("SUPER + 6", hl.dsp.focus({ workspace = "m~6" }))
hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "m~7" }))
hl.bind("SUPER + 8", hl.dsp.focus({ workspace = "m~8" }))
hl.bind("SUPER + 9", hl.dsp.focus({ workspace = "m~9" }))
hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "m~1" }))
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "m~2" }))
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "m~3" }))
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "m~4" }))
hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "m~5" }))
hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = "m~6" }))
hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "m~7" }))
hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = "m~8" }))
hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = "m~9" }))
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + N", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("SUPER + P", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind("SUPER + SHIFT + N", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind("SUPER + SHIFT + P", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind("SUPER + CTRL + down", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind("SUPER + CTRL + up", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind("SUPER + CTRL + N", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind("SUPER + CTRL + P", hl.dsp.window.move({ workspace = "m-1" }))
hl.bind("SUPER + CTRL + mouse_down", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind("SUPER + CTRL + mouse_up", hl.dsp.window.move({ workspace = "m-1" }))

-------------------------------------------
-- DMS-generated (edit via DMS Settings) --
-------------------------------------------

require("dms.colors")
require("dms.outputs")
require("dms.layout")
require("dms.cursor")
require("dms.windowrules")
require("dms-theme-sync")
