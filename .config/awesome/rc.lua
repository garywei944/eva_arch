-- ~/.config/awesome/rc.lua
-- Modularized AwesomeWM configuration

pcall(require, "luarocks.loader")

-- Core libs (kept here so side-effect requires are explicit)
local awful = require("awful")
require("awful.autofocus")

local beautiful = require("beautiful")
local naughty = require("naughty")

local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- Error handling
require("config.errors")(naughty)

-- Layouts
require("config.layouts")

-- Theme
require("config.theme").init()

-- Basic apps / key modifier
local apps = require("config.apps")

-- Menu / launcher
local menu = require("config.menu")(apps)

-- Widgets
local widgets = require("config.widgets")()

-- Screen mapping
local monitors = require("config.monitors")

-- Keys + mouse bindings
local keys = require("config.keys")(apps, menu, widgets)

-- UI (tags + wibars)
require("config.ui")(apps, menu, widgets, monitors)

-- Rules
require("config.rules")(keys, monitors)

-- Signals
require("config.display")()

-- Autostart
require("config.autostart")()
