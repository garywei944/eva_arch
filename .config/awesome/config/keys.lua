-- config/keys.lua

local gears = require("gears")
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")

return function(apps, menu, widgets)
    -- {{{ Mouse bindings
    root.buttons(
        gears.table.join(
            awful.button({}, 3, function()
                menu.mainmenu:toggle()
            end),
            awful.button({ apps.modkey }, 4, awful.tag.viewprev),
            awful.button({ apps.modkey }, 5, awful.tag.viewnext)
        )
    )
    -- }}}

    local last_tag = nil

    -- {{{ Key bindings
    local globalkeys = gears.table.join(
    -- awesome features
        awful.key({ apps.modkey }, "s", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),
        awful.key({ apps.modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
        awful.key({ "Control", "Mod1" }, "Delete", awesome.quit, { description = "quit awesome", group = "awesome" }),
        awful.key({ apps.modkey }, "x", function()
            awful.prompt.run({
                prompt = "Run Lua code: ",
                textbox = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval",
            })
        end, { description = "lua execute prompt", group = "awesome" }),
        awful.key({ "Control", "Mod1" }, "l", function()
            awful.spawn.with_shell("lock")
        end, { description = "lock screen", group = "awesome" }),

        -- Change focus
        awful.key({ apps.modkey }, "j", function()
            awful.client.focus.global_bydirection("down")
            if client.focus then
                client.focus:raise()
            end
        end, { description = "focus down", group = "client" }),
        awful.key({ apps.modkey }, "k", function()
            awful.client.focus.global_bydirection("up")
            if client.focus then
                client.focus:raise()
            end
        end, { description = "focus up", group = "client" }),
        awful.key({ apps.modkey }, "h", function()
            awful.client.focus.global_bydirection("left")
            if client.focus then
                client.focus:raise()
            end
        end, { description = "focus left", group = "client" }),
        awful.key({ apps.modkey }, "l", function()
            awful.client.focus.global_bydirection("right")
            if client.focus then
                client.focus:raise()
            end
        end, { description = "focus right", group = "client" }),
        awful.key({ "Mod1" }, "Tab", function()
            awful.client.focus.byidx(-1)
            if client.focus then
                client.focus:raise()
            end
        end, { description = "focus with next client by index", group = "client" }),
        awful.key({ apps.modkey }, "comma", function()
            awful.screen.focus_bydirection("right")
        end, { description = "focus the next screen", group = "screen" }),
        awful.key({ apps.modkey }, "m", function()
            awful.screen.focus_bydirection("left")
        end, { description = "focus the previous screen", group = "screen" }),

        -- view tags
        awful.key({ apps.modkey }, "p", awful.tag.viewprev, { description = "view previous", group = "tag" }),
        awful.key({ apps.modkey }, "n", awful.tag.viewnext, { description = "view next", group = "tag" }),
        awful.key({ apps.modkey }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),
        awful.key({ apps.modkey }, "u", awful.client.urgent.jumpto,
            { description = "jump to urgent client", group = "client" }),
        awful.key({ "Mod1", "Shift" }, "Tab", function()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end, { description = "go back", group = "client" }),

        -- Layout manipulation
        awful.key({ apps.modkey, "Control" }, "h", function()
            awful.tag.incmwfact(0.05)
        end, { description = "increase master width factor", group = "layout" }),
        awful.key({ apps.modkey, "Control" }, "l", function()
            awful.tag.incmwfact(-0.05)
        end, { description = "decrease master width factor", group = "layout" }),
        awful.key({ apps.modkey, "Control", "Shift" }, "j", function()
            awful.tag.incnmaster(1, nil, true)
        end, { description = "increase the number of master clients", group = "layout" }),
        awful.key({ apps.modkey, "Control", "Shift" }, "k", function()
            awful.tag.incnmaster(-1, nil, true)
        end, { description = "decrease the number of master clients", group = "layout" }),
        awful.key({ apps.modkey, "Control", "Shift" }, "h", function()
            awful.tag.incncol(1, nil, true)
        end, { description = "increase the number of columns", group = "layout" }),
        awful.key({ apps.modkey, "Control", "Shift" }, "l", function()
            awful.tag.incncol(-1, nil, true)
        end, { description = "decrease the number of columns", group = "layout" }),
        awful.key({ apps.modkey }, "Tab", function()
            awful.layout.inc(1)
        end, { description = "select next", group = "layout" }),

        -- Prompt
        awful.key({ apps.modkey }, "r", function()
            awful.screen.focused().mypromptbox:run()
        end, { description = "run prompt", group = "launcher" }),

        -- Show Desktop
        awful.key({ apps.modkey }, "d", function()
            local s = awful.screen.focused()
            local t = s.selected_tags[1]
            if t then
                last_tag = t
                t.selected = false
            else
                last_tag.selected = true
            end
        end, { description = "Show Desktop", group = "launcher" }),

        -- Launcher
        awful.key({ apps.modkey }, "t", function()
            awful.spawn(apps.terminal)
        end, { description = "open a terminal", group = "launcher" }),
        awful.key({ "Control" }, "space", function()
            awful.spawn("dmenu_run")
        end, { description = "run dmenu", group = "launcher" }),
        awful.key({ "Control", "Shift" }, "Escape", function()
            awful.spawn("plasma-systemmonitor")
        end, { description = "launch system monitor", group = "launcher" }),
        awful.key({ apps.modkey }, "b", function()
            awful.spawn("google-chrome-stable --password-store=gnome")
        end, { description = "launch google chrome", group = "launcher" }),
        awful.key({ apps.modkey }, "e", function()
            -- Check KDE shortcut settings if the dolphin doesn't show theme!!!
            awful.spawn("dolphin")
        end, { description = "launch dolphin", group = "launcher" }),
        awful.key({ apps.modkey }, "KP_Left", function()
            awful.spawn("qqmusic")
        end, { description = "launch QQ Music", group = "launcher" }),
        awful.key({ apps.modkey }, "KP_Home", function()
            awful.spawn("wechat")
        end, { description = "launch wechat", group = "launcher" }),
        awful.key({ apps.modkey }, "KP_Insert", function()
            awful.spawn("discord")
        end, { description = "launch discord", group = "launcher" }),

        -- Screenshots
        awful.key({ apps.modkey }, "Print", function()
            awful.util.spawn(
                "scrot 'ArcoLinuxD-%Y-%m-%d-%s_screenshot_$wx$h.jpg' -e 'mv $f $$(xdg-user-dir PICTURES)'"
            )
        end, { description = "scrot screenshot", group = "screenshots" }),
        awful.key({}, "Print", function()
            awful.util.spawn("flameshot gui")
        end, { description = "flameshot screenshot", group = "screenshots" })
    )

    local clientkeys = gears.table.join(
        awful.key({ apps.modkey }, "f", function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end, { description = "toggle fullscreen", group = "client" }),
        awful.key({ apps.modkey }, "q", function(c)
            c:kill()
        end, { description = "close", group = "client" }),
        awful.key({ "Mod1" }, "F4", function(c)
            c:kill()
        end, { description = "close", group = "client" }),
        awful.key({ apps.modkey }, "w", function(c)
            c:kill()
        end, { description = "close", group = "client" }),
        awful.key({ apps.modkey, "Control" }, "space", awful.client.floating.toggle,
            { description = "toggle floating", group = "client" }),
        awful.key({ apps.modkey }, "Return", function(c)
            c:swap(awful.client.getmaster())
        end, { description = "move to master", group = "client" }),

        awful.key({ apps.modkey, "Shift" }, "j", function()
            awful.client.swap.global_bydirection("down")
        end, { description = "swap with down", group = "client" }),
        awful.key({ apps.modkey, "Shift" }, "k", function()
            awful.client.swap.global_bydirection("up")
        end, { description = "swap with up", group = "client" }),
        awful.key({ apps.modkey, "Shift" }, "h", function()
            awful.client.swap.global_bydirection("left")
        end, { description = "swap with left", group = "client" }),
        awful.key({ apps.modkey, "Shift" }, "l", function()
            awful.client.swap.global_bydirection("right")
        end, { description = "swap with right", group = "client" }),

        awful.key({ apps.modkey }, "Up", function(c)
            if not c.maximized then
                c.maximized = not c.maximized
                c:raise()
            end
        end, { description = "maximize", group = "client" }),
        awful.key({ apps.modkey }, "Down", function(c)
            if c.maximized then
                c.maximized = not c.maximized
                c:raise()
            else
                c.minimized = true
            end
        end, { description = "minimize", group = "client" }),

        awful.key({ apps.modkey }, "Left", function()
            awful.client.swap.global_bydirection("left")
        end, { description = "swap with left", group = "client" }),
        awful.key({ apps.modkey }, "Right", function()
            awful.client.swap.global_bydirection("right")
        end, { description = "swap with right", group = "client" }),

        -- move client to tag
        awful.key({ apps.modkey, "Control" }, "p", function()
            local t = client.focus and client.focus.first_tag or nil
            if t then
                local tag = client.focus.screen.tags[(t.index - 2) % 9 + 1]
                awful.client.movetotag(tag)
            end
        end, { description = "move focused client to previous tag", group = "tag" }),
        awful.key({ apps.modkey, "Control" }, "n", function()
            local t = client.focus and client.focus.first_tag or nil
            if t then
                local tag = client.focus.screen.tags[t.index % 9 + 1]
                awful.client.movetotag(tag)
            end
        end, { description = "move focused client to next tag", group = "tag" }),
        awful.key({ apps.modkey, "Shift" }, "p", function()
            local t = client.focus and client.focus.first_tag or nil
            if t then
                local tag = client.focus.screen.tags[(t.index - 2) % 9 + 1]
                awful.client.movetotag(tag)
                awful.tag.viewprev()
            end
        end, { description = "send focused client to previous tag", group = "tag" }),
        awful.key({ apps.modkey, "Shift" }, "n", function()
            local t = client.focus and client.focus.first_tag or nil
            if t then
                local tag = client.focus.screen.tags[t.index % 9 + 1]
                awful.client.movetotag(tag)
                awful.tag.viewnext()
            end
        end, { description = "send focused client to next tag", group = "tag" }),

        -- move client to screen
        awful.key({ apps.modkey, "Shift" }, "comma", function(c)
            c:move_to_screen(c.screen.index - 1)
        end, { description = "move to the next screen", group = "screen" }),
        awful.key({ apps.modkey, "Shift" }, "m", function(c)
            c:move_to_screen(c.screen.index + 1)
        end, { description = "move to the previous screen", group = "screen" }),
        awful.key({}, "XF86AudioRaiseVolume", function()
            widgets.volume_widget:inc(2)
        end),
        awful.key({}, "XF86AudioLowerVolume", function()
            widgets.volume_widget:dec(2)
        end),
        awful.key({}, "XF86AudioMute", function()
            widgets.volume_widget:toggle(2)
        end),

        -- Media Keys
        awful.key({}, "XF86AudioPlay", function()
            awful.util.spawn("playerctl play-pause", false)
        end),
        awful.key({}, "XF86AudioNext", function()
            awful.util.spawn("playerctl next", false)
        end),
        awful.key({}, "XF86AudioPrev", function()
            awful.util.spawn("playerctl previous", false)
        end),
        awful.key({}, "XF86AudioStop", function()
            awful.util.spawn("playerctl stop", false)
        end),
        awful.key({ apps.modkey }, "KP_Next", function()
            awful.util.spawn("playerctl next", false)
        end),
        awful.key({ apps.modkey }, "KP_End", function()
            awful.util.spawn("playerctl previous", false)
        end),
        awful.key({ apps.modkey }, "KP_Down", function()
            awful.util.spawn("playerctl play-pause", false)
        end)
    )

    -- Bind all key numbers to tags.
    for i = 1, 9 do
        local descr_view, descr_toggle, descr_move, descr_toggle_focus
        if i == 1 or i == 9 then
            descr_view = { description = "view tag #", group = "tag" }
            descr_toggle = { description = "toggle tag #", group = "tag" }
            descr_move = { description = "move focused client to tag #", group = "tag" }
            descr_toggle_focus = { description = "toggle focused client on tag #", group = "tag" }
        end

        globalkeys = gears.table.join(
            globalkeys,
            awful.key({ apps.modkey }, "#" .. i + 9, function()
                local s = awful.screen.focused()
                local tag = s.tags[i]
                if tag then
                    tag:view_only()
                end
            end, descr_view),
            awful.key({ apps.modkey, "Control" }, "#" .. i + 9, function()
                local s = awful.screen.focused()
                local tag = s.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end, descr_toggle),
            awful.key({ apps.modkey, "Shift" }, "#" .. i + 9, function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end, descr_move),
            awful.key({ apps.modkey, "Control", "Shift" }, "#" .. i + 9, function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end, descr_toggle_focus)
        )
    end

    local clientbuttons = gears.table.join(
        awful.button({}, 1, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
        end),
        awful.button({ apps.modkey }, 1, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({ apps.modkey }, 3, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.resize(c)
        end),
        awful.button({ apps.modkey }, 4, function()
            awful.tag.viewprev()
        end),
        awful.button({ apps.modkey }, 5, function()
            awful.tag.viewnext()
        end)
    )

    -- Set keys
    root.keys(globalkeys)

    return {
        globalkeys = globalkeys,
        clientkeys = clientkeys,
        clientbuttons = clientbuttons,
    }
end
