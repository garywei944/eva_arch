local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local logging = require("logging")

local logger = logging.get_logger("theme")

local THEMES = {
    "blackburn",
    -- "copland",
    "dremora",
    "holo",
    "multicolor",
    -- "powerarrow",
    -- "rainbow",
    "steamburn",
    -- "vertex"
}

local M = {}

function M.init()
    math.randomseed(os.time())
    local chosen_theme = THEMES[math.random(#THEMES)]
    -- local chosen_theme = "vertex"
    logger.info("Chosen theme: " .. chosen_theme)

    beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/" .. chosen_theme .. "/theme.lua")

    -- Theme overrides (must be set BEFORE constructing menus/wibars)
    -- beautiful.font = "Hack Nerd Font Mono 10"
    beautiful.font = "DejaVu Sans Mono 10"
    beautiful.useless_gap = dpi(5)
    beautiful.menu_height = dpi(15)

    M.chosen_theme = chosen_theme
    return M
end

return M
