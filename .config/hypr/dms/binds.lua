-- Hyprland keybinds (DMS, Hyprland 0.55+ Lua)

-- Application launchers and DMS UI.
hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty"))
hl.bind("ALT + space", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))
hl.bind("SUPER + comma", hl.dsp.exec_cmd("dms ipc call settings focusOrToggle"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("dms ipc call notifications toggle"))
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("dms ipc call notepad toggle"))
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))
hl.bind("SUPER + X", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
hl.bind("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"))

-- Security and session controls.
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"))
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))

-- Audio controls.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 2"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 2"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("dms ipc call mpris previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("dms ipc call mpris next"), { locked = true })
hl.bind(
    "CTRL + XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("dms ipc call mpris increment 2"),
    { locked = true, repeating = true }
)
hl.bind(
    "CTRL + XF86AudioLowerVolume",
    hl.dsp.exec_cmd("dms ipc call mpris decrement 2"),
    { locked = true, repeating = true }
)

-- Brightness controls.
hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd([[dms ipc call brightness increment 5 ""]]),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd([[dms ipc call brightness decrement 5 ""]]),
    { locked = true, repeating = true }
)

-- Window management.
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + up", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + down", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + W", hl.dsp.group.toggle())
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("dms ipc call window-rules toggle"))
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("dms ipc call wallpaperEngineControl next"))

-- Focus and window movement.
for key, direction in pairs({ Y = "l", H = "d", A = "u", E = "r" }) do
    hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end
for key, direction in pairs({ left = "l", down = "d", up = "u", right = "r" }) do
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end
hl.bind("SUPER + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + Home", hl.dsp.focus({ window = "first" }))
hl.bind("SUPER + End", hl.dsp.focus({ window = "last" }))

-- Monitor navigation and window movement between monitors.
for key, direction in pairs({ Y = "l", H = "d", A = "u", E = "r" }) do
    hl.bind("SUPER + CTRL + " .. key, hl.dsp.focus({ monitor = direction }))
    hl.bind("SUPER + SHIFT + CTRL + " .. key, hl.dsp.window.move({ monitor = direction }))
end
hl.bind("SUPER + CTRL + left", hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + CTRL + right", hl.dsp.focus({ monitor = "r" }))
for key, direction in pairs({ left = "l", down = "d", up = "u", right = "r" }) do
    hl.bind("SUPER + SHIFT + CTRL + " .. key, hl.dsp.window.move({ monitor = direction }))
end

-- Workspaces.
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + up", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + mouse_down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + mouse_up", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("CTRL + SHIFT + R", hl.dsp.exec_cmd("dms ipc call workspace-rename open"))

for workspace = 1, 9 do
    local number = tostring(workspace)
    hl.bind("SUPER + " .. number, hl.dsp.focus({ workspace = number }))
    hl.bind("SUPER + SHIFT + " .. number, hl.dsp.window.move({ workspace = number }))
end

-- Layout and sizing.
hl.bind("SUPER + bracketleft", hl.dsp.layout("preselect l"))
hl.bind("SUPER + bracketright", hl.dsp.layout("preselect r"))
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"))

local function resize_to_full_width()
    return function()
        local window = hl.get_active_window()
        local monitor = hl.get_active_monitor()
        if window == nil or monitor == nil or type(window.size) ~= "table" then
            return
        end
        local height = window.size.y or window.size[2]
        if height ~= nil then
            hl.dispatch(hl.dsp.window.resize({ x = monitor.width, y = height, relative = false }))
        end
    end
end

local function resize_by_monitor_fraction(x_fraction, y_fraction)
    return function()
        local monitor = hl.get_active_monitor()
        if monitor ~= nil then
            hl.dispatch(hl.dsp.window.resize({
                x = math.floor(monitor.width * x_fraction),
                y = math.floor(monitor.height * y_fraction),
                relative = true,
            }))
        end
    end
end

hl.bind("SUPER + CTRL + F", resize_to_full_width())
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
hl.bind(
    "SUPER + code:20",
    hl.dsp.window.resize({ x = -100, y = 0, relative = true }),
    { description = "Expand window left" }
)
hl.bind(
    "SUPER + code:21",
    hl.dsp.window.resize({ x = 100, y = 0, relative = true }),
    { description = "Shrink window left" }
)
hl.bind("SUPER + minus", resize_by_monitor_fraction(-0.10, 0), { repeating = true })
hl.bind("SUPER + equal", resize_by_monitor_fraction(0.10, 0), { repeating = true })
hl.bind("SUPER + SHIFT + minus", resize_by_monitor_fraction(0, -0.10), { repeating = true })
hl.bind("SUPER + SHIFT + equal", resize_by_monitor_fraction(0, 0.10), { repeating = true })

-- Screenshots and display controls.
hl.bind("Print", hl.dsp.exec_cmd("mark-shot --capture"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("mark-shot --capture --all-outputs --fullscreen"))
hl.bind("CTRL + Print", function()
    local monitor = hl.get_active_monitor()
    local command = "mark-shot --capture --fullscreen"
    if monitor ~= nil and monitor.name ~= nil then
        command = command .. " --display " .. string.format("%q", monitor.name)
    end
    hl.exec_cmd(command)
end)
hl.bind("ALT + Print", hl.dsp.exec_cmd("mark-shot --capture"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("dms ipc outputs cycleProfile"))
hl.bind("SUPER + SHIFT + P", hl.dsp.dpms({ action = "toggle" }))

-- Application shortcuts.
local hyper = "CTRL + SHIFT + ALT + SUPER"
hl.bind(hyper .. " + B", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(hyper .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind(hyper .. " + M", hl.dsp.exec_cmd("qqmusic"))
hl.bind(hyper .. " + W", hl.dsp.exec_cmd("wechat"))
hl.bind(hyper .. " + D", hl.dsp.exec_cmd("discord"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind("SUPER + KP_Left", hl.dsp.exec_cmd("qqmusic"))
hl.bind("SUPER + KP_Home", hl.dsp.exec_cmd("wechat"))
hl.bind("SUPER + KP_Insert", hl.dsp.exec_cmd("discord"))
