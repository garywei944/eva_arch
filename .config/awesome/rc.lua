-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- logging
local logging = require("logging")

logging.set_level(logging.DEBUG)
logging.setup_error_handling()

local logger = logging.root

-- Initialization
local _ = require("awful")
require("awful.autofocus")
require("config.theme").init()

local apps = require("config.apps")
local menu = require("config.menu")(apps)
local widgets = require("config.widgets")()
local monitors = require("config.monitors")
local keys = require("config.keys")(apps, menu, widgets)
require("config.ui")(apps, menu, widgets, monitors)
require("config.rules")(keys, monitors)

logger.info("Awesome config loaded")

require("autostart")()
