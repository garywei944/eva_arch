-- Load after DMS's generated and user keybinds.
local hs = require("hyprsplit")

hs.config({
    num_workspaces = 9,
    persistent_workspaces = true,
})

hs.monitor_priority({ "DP-1", "DP-2", "DP-3" })

local function replace(keys, dispatcher)
    for _, key in ipairs(keys) do
        hl.unbind(key)
        hl.bind(key, dispatcher)
    end
end

replace({ "SUPER + Page_Down", "SUPER + N", "SUPER + mouse_down" }, hs.dsp.focus({ workspace = "e+1" }))
replace({ "SUPER + Page_Up", "SUPER + P", "SUPER + mouse_up" }, hs.dsp.focus({ workspace = "e-1" }))

replace(
    { "SUPER + CTRL + down", "SUPER + CTRL + N", "SUPER + CTRL + mouse_down" },
    hs.dsp.window.move({ workspace = "e+1", follow = false })
)
replace(
    { "SUPER + CTRL + up", "SUPER + CTRL + P", "SUPER + CTRL + mouse_up" },
    hs.dsp.window.move({ workspace = "e-1", follow = false })
)

replace({ "SUPER + SHIFT + Page_Down", "SUPER + SHIFT + N" }, hs.dsp.window.move({ workspace = "e+1", follow = false }))
replace({ "SUPER + SHIFT + Page_Up", "SUPER + SHIFT + P" }, hs.dsp.window.move({ workspace = "e-1", follow = false }))

for i = 1, 9 do
    local workspace = tostring(i)
    replace({ "SUPER + " .. workspace }, hs.dsp.focus({ workspace = workspace }))
    replace({ "SUPER + SHIFT + " .. workspace }, hs.dsp.window.move({ workspace = workspace, follow = false }))
end
