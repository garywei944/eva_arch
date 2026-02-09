-- config/widgets.lua

local awful = require("awful")
local wibox = require("wibox")

return function()
    local textclock = wibox.widget.textclock()
    local keyboardlayout = awful.widget.keyboardlayout()

    -- Third-party widgets (vendored)
    local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
    local ram_widget = require("awesome-wm-widgets.ram-widget.ram-widget")
    local volume_widget = require("awesome-wm-widgets.pactl-widget.volume")
    local calendar_widget = require("awesome-wm-widgets.calendar-widget.calendar")

    local cw = calendar_widget({
        theme = "naughty",
        placement = "top_right",
        radius = 8,
    })

    textclock:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            cw.toggle()
        end
    end)

    return {
        textclock = textclock,
        keyboardlayout = keyboardlayout,
        cpu_widget = cpu_widget,
        ram_widget = ram_widget,
        volume_widget = volume_widget,
    }
end
