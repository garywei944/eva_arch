-- config/theme.lua
-- Theme selection + beautiful initialization

local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

function M.init()
    local themes = {
        "blackburn",
        "copland",
        "dremora",
        "holo",
        "multicolor",
        -- "powerarrow",
        -- "rainbow",
        "steamburn",
        -- "vertex"
    }

    math.randomseed(os.time())
    local chosen_theme = themes[math.random(#themes)]
    -- local chosen_theme = "vertex"

    beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/" .. chosen_theme .. "/theme.lua")

    -- Theme overrides (must be set BEFORE constructing menus/wibars)
    beautiful.font = "Hack Nerd Font Mono 10"
    beautiful.useless_gap = dpi(5)
    beautiful.menu_height = dpi(15)

    M.chosen_theme = chosen_theme
    return M
end

return M
