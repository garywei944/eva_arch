-- config/menu.lua

local awful = require("awful")
local beautiful = require("beautiful")
local freedesktop = require("freedesktop")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

return function(apps)
    local myawesomemenu = {
        { "hotkeys", function()
            return false, hotkeys_popup.show_help
        end },
        { "manual",      apps.terminal .. " -e 'man awesome'" },
        { "edit config", apps.editor_cmd .. " ~/.config/awesome/rc.lua" },
        { "restart",     awesome.restart },
        { "quit", function()
            awesome.quit()
        end },
    }

    local mainmenu = freedesktop.menu.build({
        icon_size = beautiful.menu_height or 16,
        before = {
            { "Awesome", myawesomemenu, beautiful.awesome_icon },
            -- other triads can be put here
        },
        after = {
            { "Terminal", apps.terminal },
            { "Log out", function()
                awesome.quit()
            end },
            { "Sleep",    "systemctl suspend" },
            { "Restart",  "systemctl reboot" },
            { "Exit",     "systemctl poweroff" },
            -- other triads can be put here
        },
    })

    local launcher = awful.widget.launcher({
        image = beautiful.awesome_icon,
        menu = mainmenu,
    })

    -- Menubar configuration
    menubar.utils.terminal = apps.terminal

    return {
        mainmenu = mainmenu,
        launcher = launcher,
    }
end
