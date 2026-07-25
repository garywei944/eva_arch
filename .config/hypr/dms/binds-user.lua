-- User keybind overrides migrated from the active dms/binds.conf.
-- DMS loads this after its generated defaults.

local function replace(keys, dispatcher, options)
    if type(keys) == "string" then
        keys = { keys }
    end
    for _, key in ipairs(keys) do
        hl.unbind(key)
        hl.bind(key, dispatcher, options)
    end
end

local function remove(keys)
    if type(keys) == "string" then
        keys = { keys }
    end
    for _, key in ipairs(keys) do
        hl.unbind(key)
    end
end

-- Remove generated shortcuts that were not active in the legacy config.
remove({
    "SUPER + space",
    "SUPER + O",
    "SUPER + Q",
    "SUPER + J",
    "SUPER + K",
    "SUPER + L",
    "SUPER + SHIFT + J",
    "SUPER + SHIFT + K",
    "SUPER + SHIFT + L",
    "SUPER + CTRL + J",
    "SUPER + CTRL + K",
    "SUPER + CTRL + L",
    "SUPER + SHIFT + CTRL + J",
    "SUPER + SHIFT + CTRL + K",
    "SUPER + SHIFT + CTRL + L",
    "SUPER + U",
    "SUPER + I",
    "SUPER + CTRL + U",
    "SUPER + CTRL + I",
    "SUPER + SHIFT + U",
    "SUPER + SHIFT + I",
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "unset" })

-- Application launchers and DMS UI.
replace("SUPER + T", hl.dsp.exec_cmd("kitty"))
replace("ALT + space", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
replace("SUPER + V", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
replace("SUPER + M", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))
replace("SUPER + comma", hl.dsp.exec_cmd("dms ipc call settings focusOrToggle"))
replace("SUPER + TAB", hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))
replace("SUPER + X", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
replace("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"))

-- Security and session controls.
replace("SUPER + ALT + L", hl.dsp.exec_cmd("dms ipc call lock lock"))
replace("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"))
replace("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))

-- Audio controls.
replace("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 2"), { locked = true, repeating = true })
replace("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 2"), { locked = true, repeating = true })
replace("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { locked = true })
replace("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"), { locked = true })
replace("XF86AudioPause", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { locked = true })
replace("XF86AudioPlay", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { locked = true })
replace("XF86AudioPrev", hl.dsp.exec_cmd("dms ipc call mpris previous"), { locked = true })
replace("XF86AudioNext", hl.dsp.exec_cmd("dms ipc call mpris next"), { locked = true })
replace(
    "CTRL + XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("dms ipc call mpris increment 2"),
    { locked = true, repeating = true }
)
replace(
    "CTRL + XF86AudioLowerVolume",
    hl.dsp.exec_cmd("dms ipc call mpris decrement 2"),
    { locked = true, repeating = true }
)

-- Brightness controls.
replace(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd([[dms ipc call brightness increment 5 ""]]),
    { locked = true, repeating = true }
)
replace(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd([[dms ipc call brightness decrement 5 ""]]),
    { locked = true, repeating = true }
)

-- Window management.
replace("ALT + F4", hl.dsp.window.close())
replace("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
replace("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
replace("F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
replace({ "SUPER + up", "SUPER + down" }, hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
replace("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))
replace("SUPER + W", hl.dsp.group.toggle())
replace("SUPER + SHIFT + W", hl.dsp.exec_cmd("dms ipc call window-rules toggle"))

-- Focus navigation.
replace("SUPER + Y", hl.dsp.focus({ direction = "l" }))
replace("SUPER + H", hl.dsp.focus({ direction = "d" }))
replace("SUPER + A", hl.dsp.focus({ direction = "u" }))
replace("SUPER + E", hl.dsp.focus({ direction = "r" }))

-- Window movement.
replace("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
replace("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))
replace("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
replace("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
replace("SUPER + left", hl.dsp.window.move({ direction = "l" }))
replace("SUPER + right", hl.dsp.window.move({ direction = "r" }))
replace("SUPER + SHIFT + Y", hl.dsp.window.move({ direction = "l" }))
replace("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "d" }))
replace("SUPER + SHIFT + A", hl.dsp.window.move({ direction = "u" }))
replace("SUPER + SHIFT + E", hl.dsp.window.move({ direction = "r" }))

-- Column navigation.
replace("SUPER + Home", hl.dsp.focus({ window = "first" }))
replace("SUPER + End", hl.dsp.focus({ window = "last" }))

-- Monitor navigation.
replace("SUPER + CTRL + left", hl.dsp.focus({ monitor = "l" }))
replace("SUPER + CTRL + right", hl.dsp.focus({ monitor = "r" }))
replace("SUPER + CTRL + Y", hl.dsp.focus({ monitor = "l" }))
replace("SUPER + CTRL + H", hl.dsp.focus({ monitor = "d" }))
replace("SUPER + CTRL + A", hl.dsp.focus({ monitor = "u" }))
replace("SUPER + CTRL + E", hl.dsp.focus({ monitor = "r" }))

-- Move windows between monitors.
replace("SUPER + SHIFT + CTRL + left", hl.dsp.window.move({ monitor = "l" }))
replace("SUPER + SHIFT + CTRL + down", hl.dsp.window.move({ monitor = "d" }))
replace("SUPER + SHIFT + CTRL + up", hl.dsp.window.move({ monitor = "u" }))
replace("SUPER + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "r" }))
replace("SUPER + SHIFT + CTRL + Y", hl.dsp.window.move({ monitor = "l" }))
replace("SUPER + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "d" }))
replace("SUPER + SHIFT + CTRL + A", hl.dsp.window.move({ monitor = "u" }))
replace("SUPER + SHIFT + CTRL + E", hl.dsp.window.move({ monitor = "r" }))

-- Workspace renaming; hyprsplit workspace movement is loaded afterwards.
replace("CTRL + SHIFT + R", hl.dsp.exec_cmd("dms ipc call workspace-rename open"))

-- Layout controls.
replace("SUPER + bracketleft", hl.dsp.layout("preselect l"))
replace("SUPER + bracketright", hl.dsp.layout("preselect r"))
replace("SUPER + R", hl.dsp.layout("togglesplit"))

local function resize_to_full_width()
    return function()
        local window = hl.get_active_window()
        local monitor = hl.get_active_monitor()
        if window == nil or monitor == nil or type(window.size) ~= "table" then
            return
        end
        local height = window.size.y or window.size[2]
        if height == nil then
            return
        end
        hl.dispatch(hl.dsp.window.resize({ x = monitor.width, y = height, relative = false }))
    end
end

local function resize_by_monitor_fraction(x_fraction, y_fraction)
    return function()
        local monitor = hl.get_active_monitor()
        if monitor == nil then
            return
        end
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(monitor.width * x_fraction),
            y = math.floor(monitor.height * y_fraction),
            relative = true,
        }))
    end
end

replace("SUPER + CTRL + F", resize_to_full_width())
replace("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
replace("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
replace(
    "SUPER + code:20",
    hl.dsp.window.resize({ x = -100, y = 0, relative = true }),
    { description = "Expand window left" }
)
replace(
    "SUPER + code:21",
    hl.dsp.window.resize({ x = 100, y = 0, relative = true }),
    { description = "Shrink window left" }
)
replace("SUPER + minus", resize_by_monitor_fraction(-0.10, 0), { repeating = true })
replace("SUPER + equal", resize_by_monitor_fraction(0.10, 0), { repeating = true })
replace("SUPER + SHIFT + minus", resize_by_monitor_fraction(0, -0.10), { repeating = true })
replace("SUPER + SHIFT + equal", resize_by_monitor_fraction(0, 0.10), { repeating = true })

-- Screenshots.
replace("Print", hl.dsp.exec_cmd("grimblast --notify --freeze save area /tmp/ss.png && satty --filename /tmp/ss.png"))
replace(
    "SHIFT + Print",
    hl.dsp.exec_cmd("grimblast --notify --freeze save screen /tmp/ss.png && satty --filename /tmp/ss.png")
)
replace("CTRL + Print", hl.dsp.exec_cmd("dms screenshot full"))
replace("ALT + Print", hl.dsp.exec_cmd("dms screenshot window"))

-- Display power.
replace("SUPER + SHIFT + P", hl.dsp.dpms({ action = "toggle" }))

-- Application shortcuts.
local hyper = "CTRL + SHIFT + ALT + SUPER"
replace(hyper .. " + B", hl.dsp.exec_cmd("google-chrome-stable"))
replace(hyper .. " + E", hl.dsp.exec_cmd("dolphin"))
replace(hyper .. " + M", hl.dsp.exec_cmd("qqmusic"))
replace(hyper .. " + W", hl.dsp.exec_cmd("wechat"))
replace(hyper .. " + D", hl.dsp.exec_cmd("discord"))
replace("SUPER + B", hl.dsp.exec_cmd("google-chrome-stable"))
replace("SUPER + KP_Left", hl.dsp.exec_cmd("qqmusic"))
replace("SUPER + KP_Home", hl.dsp.exec_cmd("wechat"))
replace("SUPER + KP_Insert", hl.dsp.exec_cmd("discord"))
