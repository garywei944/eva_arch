-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")



local function log_debug(msg)
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = msg,
        timeout = 0
    })
end


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

local themes = {
    -- "copland",
    "dremora",
    "multicolor",
    "steamburn",
}

math.randomseed(os.time())
local chosen_theme = themes[math.random(3)]
-- beautiful.init(gears.filesystem.get_configuration_dir().."themes/"..chosen_theme.."/theme.lua")
beautiful.init(string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))

-- This is used later as the default terminal and editor to run.
-- terminal = "x-terminal-emulator"
-- editor = os.getenv("EDITOR") or "editor"
local terminal = "terminator"
local editor = "emacs"
local editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    -- awful.layout.suit.floating,
    -- awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
    { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after = { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = {
            menu_awesome,
            { "Debian", debian.menu.Debian_menu.Debian },
            menu_terminal,
        }
    })
end

mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = mymainmenu
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t) awful.tag.viewprev(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewnext(t.screen) end))

local tasklist_buttons = gears.table.join(awful.button({}, 1, function(c)
    if c == client.focus then
        c.minimized = true
    else
        c:emit_signal("request::activate",
            "tasklist",
            { raise = true })
    end
end),
    wibox.widget {
        widget = wibox.widget.separator
    },
    awful.button({}, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({}, 4, function()
        awful.client.focus.byidx(-1)
    end),
    awful.button({}, 5, function()
        awful.client.focus.byidx(1)
    end))

-- local function set_wallpaper(s)
-- 	-- Wallpaper
-- 	if beautiful.wallpaper then
-- 		local wallpaper = beautiful.wallpaper
-- 		-- If wallpaper is a function, call it with the screen
-- 		if type(wallpaper) == "function" then
-- 			wallpaper = wallpaper(s)
-- 		end
-- 		gears.wallpaper.maximized(wallpaper, s, true)
-- 	end
-- end

-- -- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
-- screen.connect_signal("property::geometry", set_wallpaper)

-- Load third-party widgets
local cpu_widget = require("widgets.cpu-widget.cpu-widget")
local ram_widget = require("widgets.ram-widget.ram-widget")
local calendar_widget = require("widgets.calendar-widget.calendar")

local cw = calendar_widget({
    theme = 'naughty',
    placement = 'top_right',
    radius = 8
})
mytextclock:connect_signal("button::press",
    function(_, _, _, button)
        if button == 1 then cw.toggle() end
    end)


awful.screen.connect_for_each_screen(function(s)
    -- -- Wallpaper
    -- set_wallpaper(s)

    -- Each screen has its own tag table.
    -- Hardcoded Primary screen.
    local tags
    if s.index == 2 then
        -- Support screen
        tags = { "1|Web", "2|Chat", "3|Smerge", "4|Doc", "5|App", "6|Code", "7|Music", "8|Terminal", "9|Reserve" }
    else
        -- Primary screen
        tags = { "1|Code", "2|Web", "3|Folder", "4|Doc", "5|App", "6|Code", "7|Web", "8|Terminal", "9|Reserve" }
    end
    awful.tag(tags, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        {
            -- Right widgets
            layout = wibox.layout.fixed.horizontal,

            -- Welcome message textbox
            wibox.widget {
                markup = "<span foreground=\"#ff66cc\">Welcome, ariseus.</span>",
                font = 'sans 8',
                screen = s,
                buttons = gears.table.join(awful.button({}, 1, function() awful.spawn.with_shell("waw &") end)),
                widget = wibox.widget.textbox
            },
            cpu_widget({
                enable_kill_button = true,
                timeout = 1
            }),
            ram_widget({
                timeout = 1
            }),
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(awful.button({}, 3, function() mymainmenu:toggle() end),
    awful.button({ modkey }, 4, awful.tag.viewprev),
    awful.button({ modkey }, 5, awful.tag.viewnext)))
-- }}}function

local last_tag = nil

-- {{{ Key bindings
globalkeys = gears.table.join(-- awesome features
    awful.key({ modkey }, "s", hotkeys_popup.show_help,
        { description = "show help", group = "awesome" }),
    awful.key({ modkey }, "w", function() mymainmenu:show() end,
        { description = "show main menu", group = "awesome" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
        { description = "reload awesome", group = "awesome" }),
    awful.key({ "Control", "Mod1" }, "Delete", awesome.quit,
        { description = "quit awesome", group = "awesome" }),
    awful.key({ modkey }, "x",
        function()
            awful.prompt.run {
                prompt = "Run Lua code: ",
                textbox = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval"
            }
        end,
        { description = "lua execute prompt", group = "awesome" }),
    awful.key({ modkey, "Mod1" }, "l", function() awful.spawn.with_shell("lock") end,
        { description = "lock screen", group = "awesome" }),

    -- Change focus
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.global_bydirection("down")
            if client.focus then client.focus:raise() end
        end,
        { description = "focus down", group = "client" }),
    awful.key({ modkey }, "k",
        function()
            awful.client.focus.global_bydirection("up")
            if client.focus then client.focus:raise() end
        end,
        { description = "focus up", group = "client" }),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.global_bydirection("left")
            if client.focus then client.focus:raise() end
        end,
        { description = "focus left", group = "client" }),
    awful.key({ modkey }, "l",
        function()
            awful.client.focus.global_bydirection("right")
            if client.focus then client.focus:raise() end
        end,
        { description = "focus right", group = "client" }),
    awful.key({ "Mod1" }, "Tab",
        function()
            awful.client.focus.byidx(-1)
            if client.focus then
                client.focus:raise()
            end
        end,
        { description = "focus with next client by index", group = "client" }),

    awful.key({ modkey }, "comma", function() awful.screen.focus_bydirection("right") end,
        { description = "focus the next screen", group = "screen" }),
    awful.key({ modkey }, "m", function() awful.screen.focus_bydirection("left") end,
        { description = "focus the previous screen", group = "screen" }),

    -- view tags
    awful.key({ modkey }, "p", awful.tag.viewprev,
        { description = "view previous", group = "tag" }),
    awful.key({ modkey }, "n", awful.tag.viewnext,
        { description = "view next", group = "tag" }),
    awful.key({ modkey }, "Escape", awful.tag.history.restore,
        { description = "go back", group = "tag" }),

    awful.key({ modkey }, "u", awful.client.urgent.jumpto,
        { description = "jump to urgent client", group = "client" }),
    awful.key({ "Mod1", "Shift" }, "Tab",
        function()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        { description = "go back", group = "client" }),

    -- Layout manipulation
    awful.key({ modkey, "Control" }, "h", function() awful.tag.incmwfact(0.05) end,
        { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey, "Control" }, "l", function() awful.tag.incmwfact(-0.05) end,
        { description = "decrease master width factor", group = "layout" }),
    awful.key({ modkey, "Control", "Shift" }, "j", function() awful.tag.incnmaster(1, nil, true) end,
        { description = "increase the number of master clients", group = "layout" }),
    awful.key({ modkey, "Control", "Shift" }, "k", function() awful.tag.incnmaster(-1, nil, true) end,
        { description = "decrease the number of master clients", group = "layout" }),
    awful.key({ modkey, "Control", "Shift" }, "h", function() awful.tag.incncol(1, nil, true) end,
        { description = "increase the number of columns", group = "layout" }),
    awful.key({ modkey, "Control", "Shift" }, "l", function() awful.tag.incncol(-1, nil, true) end,
        { description = "decrease the number of columns", group = "layout" }),
    awful.key({ modkey }, "Tab", function() awful.layout.inc(1) end,
        { description = "select next", group = "layout" }),
    -- awful.key({ modkey, "Shift" }, "space", function() awful.layout.inc(-1) end,
    -- 		{ description = "select previous", group = "layout" }),

    -- awful.key({ modkey, "Control" }, "n",
    -- 		function()
    -- 			local c = awful.client.restore()
    -- 			-- Focus restored client
    -- 			if c then
    -- 				c:emit_signal(
    -- 						"request::activate", "key.unminimize", { raise = true }
    -- 				)
    -- 			end
    -- 		end,
    -- 		{ description = "restore minimized", group = "client" }),

    -- Prompt
    awful.key({ modkey }, "r", function() awful.screen.focused().mypromptbox:run() end,
        { description = "run prompt", group = "launcher" }),

    -- -- Menubar
    -- awful.key({ modkey }, "p", function() menubar.show() end,
    -- 		{ description = "show the menubar", group = "launcher" }),

    -- Show Desktop
    awful.key({ modkey }, "d", function()
        local s = awful.screen.focused()
        local t = s.selected_tags[1]
        if t then
            last_tag = t
            t.selected = false
        else
            last_tag.selected = true
        end
    end,
        { description = "open a terminal", group = "launcher" }),

    -- Launcher
    awful.key({ modkey }, "t", function() awful.spawn(terminal) end,
        { description = "open a terminal", group = "launcher" }),
    awful.key({ "Control" }, "space", function() awful.spawn("dmenu_run") end,
        { description = "run dmenu", group = "launcher" }),
    awful.key({ "Control", "Shift" }, "Escape", function() awful.spawn("gnome-system-monitor") end,
        { description = "launch system monitor", group = "launcher" }),
    awful.key({ modkey }, "b", function() awful.spawn("google-chrome --password-store=gnome") end,
        { description = "launch google chrome", group = "launcher" }),
    awful.key({ modkey }, "e", function() awful.spawn("nautilus") end,
        { description = "launch nautilus", group = "launcher" }),
    awful.key({ modkey }, "KP_Left", function() awful.spawn("netease-cloud-music") end,
        { description = "launch netease cloud music", group = "launcher" }),
    awful.key({ modkey }, "KP_Home", function() awful.spawn("/opt/apps/com.qq.weixin.deepin/files/run.sh -u") end,
        { description = "launch wechat", group = "launcher" }),
    awful.key({ modkey }, "KP_Insert", function() awful.spawn("discord") end,
        { description = "launch discord", group = "launcher" }),

    -- Screenshots
    awful.key({ modkey }, "Print", function() awful.util.spawn("scrot 'ArcoLinuxD-%Y-%m-%d-%s_screenshot_$wx$h.jpg' -e 'mv $f $$(xdg-user-dir PICTURES)'") end,
        { description = "scrot screenshot", group = "screenshots" }),
    awful.key({}, "Print", function() awful.util.spawn("flameshot gui") end,
        { description = "flameshot screenshot", group = "screenshots" }))

clientkeys = gears.table.join(awful.key({ modkey }, "f",
    function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end,
    { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey }, "q", function(c) c:kill() end,
        { description = "close", group = "client" }),
    awful.key({ "Mod1" }, "F4", function(c) c:kill() end,
        { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle,
        { description = "toggle floating", group = "client" }),
    awful.key({ modkey }, "Return", function(c) c:swap(awful.client.getmaster()) end,
        { description = "move to master", group = "client" }),
    -- awful.key({ modkey }, "t", function(c) c.ontop = not c.ontop end,
    -- 		{ description = "toggle keep on top", group = "client" }),
    -- awful.key({ modkey }, "n",
    -- 		function(c)
    -- 			-- The client currently has the input focus, so it cannot be
    -- 			-- minimized, since minimized clients can't have the focus.
    -- 			c.minimized = true
    -- 		end,
    -- 		{ description = "minimize", group = "client" }),
    -- awful.key({ modkey }, "m",
    -- 		function(c)
    -- 			c.maximized = not c.maximized
    -- 			c:raise()
    -- 		end,
    -- 		{ description = "(un)maximize", group = "client" }),
    -- awful.key({ modkey, "Control" }, "m",
    -- 		function(c)
    -- 			c.maximized_vertical = not c.maximized_vertical
    -- 			c:raise()
    -- 		end,
    -- 		{ description = "(un)maximize vertically", group = "client" }),
    -- awful.key({ modkey, "Shift" }, "m",
    -- 		function(c)
    -- 			c.maximized_horizontal = not c.maximized_horizontal
    -- 			c:raise()
    -- 		end,
    -- 		{ description = "(un)maximize horizontally", group = "client" }),

    awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.global_bydirection("down") end,
        { description = "swap with down", group = "client" }),
    awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.global_bydirection("up") end,
        { description = "swap with up", group = "client" }),
    awful.key({ modkey, "Shift" }, "h", function() awful.client.swap.global_bydirection("left") end,
        { description = "swap with left", group = "client" }),
    awful.key({ modkey, "Shift" }, "l", function() awful.client.swap.global_bydirection("right") end,
        { description = "swap with right", group = "client" }),

    awful.key({ modkey }, "Up",
        function(c)
            if not c.maximized then
                c.maximized = not c.maximized
                c:raise()
            end
        end,
        { description = "maximize", group = "client" }),
    awful.key({ modkey }, "Down",
        function(c)
            if c.maximized then
                c.maximized = not c.maximized
                c:raise()
            else
                c.minimized = true
            end
        end,
        { description = "minimize", group = "client" }),
    awful.key({ modkey }, "Left", function() awful.client.swap.global_bydirection("left") end,
        { description = "swap with left", group = "client" }),
    awful.key({ modkey }, "Right", function() awful.client.swap.global_bydirection("right") end,
        { description = "swap with right", group = "client" }),

    -- move client to tag
    awful.key({ modkey, "Control" }, "p",
        function()
            local t = client.focus and client.focus.first_tag or nil
            if t then
                local tag = client.focus.screen.tags[(t.index - 2) % 9 + 1]
                awful.client.movetotag(tag)
            end
        end,
        { description = "move focused client to previous tag", group = "tag" }),
    awful.key({ modkey, "Control" }, "n",
        function()
            local t = client.focus and client.focus.first_tag or nil
            if t then
                local tag = client.focus.screen.tags[t.index % 9 + 1]
                awful.client.movetotag(tag)
            end
        end,
        { description = "move focused client to next tag", group = "tag" }),
    awful.key({ modkey, "Shift" }, "p",
        function()
            local t = client.focus and client.focus.first_tag or nil
            if t then
                local tag = client.focus.screen.tags[(t.index - 2) % 9 + 1]
                awful.client.movetotag(tag)
                awful.tag.viewprev()
            end
        end,
        { description = "send focused client to previous tag", group = "tag" }),
    awful.key({ modkey, "Shift" }, "n",
        function()
            local t = client.focus and client.focus.first_tag or nil
            if t then
                local tag = client.focus.screen.tags[t.index % 9 + 1]
                awful.client.movetotag(tag)
                awful.tag.viewnext()
            end
        end,
        { description = "send focused client to next tag", group = "tag" }),

    -- move client to screen
    awful.key({ modkey, "Shift" }, "comma",
        function(c)
            -- if c.screen.index < screen.count() then
                c:move_to_screen(c.screen.index + 1)
            -- end
        end,
        { description = "move to the next screen", group = "screen" }),
    awful.key({ modkey, "Shift" }, "m",
        function(c)
            -- if c.screen.index > 1 then
                c:move_to_screen(c.screen.index - 1)
            -- end
        end,
        { description = "move to the previous screen", group = "screen" }))

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    local descr_view, descr_toggle, descr_move, descr_toggle_focus
    if i == 1 or i == 9 then
        descr_view = {description = "view tag #", group = "tag"}
        descr_toggle = {description = "toggle tag #", group = "tag"}
        descr_move = {description = "move focused client to tag #", group = "tag"}
        descr_toggle_focus = {description = "toggle focused client on tag #", group = "tag"}
    end
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            -- { description = "view tag #" .. i, group = "tag" }),
            descr_view),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            -- { description = "toggle tag #" .. i, group = "tag" }),
            descr_toggle),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            -- { description = "move focused client to tag #" .. i, group = "tag" }),
            descr_move),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            -- { description = "toggle focused client on tag #" .. i, group = "tag" }))
            descr_toggle_focus))
end

clientbuttons = gears.table.join(awful.button({}, 1, function(c)
    c:emit_signal("request::activate", "mouse_click", { raise = true })
end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end),
    awful.button({ modkey }, 4, function()
        awful.tag.viewprev()
    end),
    awful.button({ modkey }, 5, function()
        awful.tag.viewnext()
    end))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    },

    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA", -- Firefox addon DownThemAll.
                "copyq", -- Includes session name in class.
                "pinentry",
            },
            class = {
                "Arandr",
                "Blueman-manager",
                "Gpick",
                "Kruler",
                "MessageWin", -- kalarm.
                "Sxiv",
                "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
                "Wpa_gui",
                "veromix",
                "xtightvncviewer"
            },

            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
                "Event Tester", -- xev.
            },
            role = {
                "AlarmWindow", -- Thunderbird's calendar.
                "ConfigManager", -- Thunderbird's about:config.
                "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
                "setup",
            }
        },
        properties = { floating = true }
    },

    -- Add titlebars to normal clients and dialogs
    {
        rule_any = {
            type = { "normal", "dialog" }
        },
        properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },

    {
        rule = {
            instance = "sublime_text"
        },
        properties = { tag = screen[1].tags[6] }
    },
    {
        rule = {
            name = "WeChat"
        },
        properties = { tag = screen[2].tags[2] }
    },
    {
        rule = {
            name = "Discord"
        },
        properties = { tag = screen[2].tags[2] }
    },
    {
        rule = {
            instance = "sublime_merge"
        },
        properties = { tag = screen[2].tags[3] }
    },
    {
        rule = {
            instance = "netease-cloud-music"
        },
        properties = { tag = screen[2].tags[7] }
    },
    {
        rule = {
            instance = "gnome-system-monitor"
        },
        properties = { tag = screen[2].tags[8] }
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
            and not c.size_hints.user_position
            and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(awful.button({}, 1, function()
        c:emit_signal("request::activate", "titlebar", { raise = true })
        awful.mouse.client.move(c)
    end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end))

    awful.titlebar(c):setup {
        {
            -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal
        },
        {
            -- Middle
            {
                -- Title
                align = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal
        },
        {
            -- Right
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- -- Enable sloppy focus, so that focus follows mouse.
-- client.connect_signal("mouse::enter", function(c)
-- 	c:emit_signal("request::activate", "mouse_enter", { raise = false })
-- end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- -- Theme
local dpi = require("beautiful.xresources").apply_dpi
beautiful.font = "sans 8"
beautiful.useless_gap = dpi(5)
beautiful.menu_height = dpi(15)

-- Autostart
awful.spawn.with_shell("~/.config/autostart.sh &")
