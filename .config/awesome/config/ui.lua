-- config/ui.lua
-- Screen tags + wibar construction

local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

return function(apps, menu, widgets, screenmap)
    -- Table of layouts to cover with awful.layout.inc, order matters.
    awful.layout.layouts = {
        -- awful.layout.suit.floating,
        -- awful.layout.suit.tile,
        awful.layout.suit.tile.left,
        awful.layout.suit.fair,
        awful.layout.suit.spiral.dwindle,
        -- awful.layout.suit.max,
    }

    local taglist_buttons = gears.table.join(
        awful.button({}, 1, function(t)
            t:view_only()
        end),
        awful.button({ apps.modkey }, 1, function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end),
        awful.button({}, 3, awful.tag.viewtoggle),
        awful.button({ apps.modkey }, 3, function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end),
        awful.button({}, 4, function(t)
            awful.tag.viewprev(t.screen)
        end),
        awful.button({}, 5, function(t)
            awful.tag.viewnext(t.screen)
        end)
    )

    local tasklist_buttons = gears.table.join(
        awful.button({}, 1, function(c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal("request::activate", "tasklist", { raise = true })
            end
        end),
        awful.button({}, 3, function()
            awful.menu.client_list({ theme = { width = 250 } })
        end),
        awful.button({}, 4, function()
            awful.client.focus.byidx(-1)
        end),
        awful.button({}, 5, function()
            awful.client.focus.byidx(1)
        end)
    )

    awful.screen.connect_for_each_screen(function(s)
        -- Each screen has its own tag table.
        -- Only the screen to the RIGHT of primary uses the "support" tag set.
        -- Primary and left screens use the "primary" tag set.
        local tags
        if screenmap.is_support_screen(s) then
            -- Support (right) screen
            tags = {
                "1|Web",
                "2|Chat",
                "3|Git",
                "4|Doc",
                "5|App",
                "6|Code",
                "7|Music",
                "8|Terminal",
                "9|Reserve",
            }
        else
            -- Primary layout
            tags = {
                "1|Code",
                "2|Web",
                "3|Folder",
                "4|Doc",
                "5|App",
                "6|Code",
                "7|Web",
                "8|Terminal",
                "9|Reserve",
            }
        end

        awful.tag(tags, s, awful.layout.layouts[1])

        -- Per-screen widgets
        s.mypromptbox = awful.widget.prompt()

        s.mylayoutbox = awful.widget.layoutbox(s)
        s.mylayoutbox:buttons(gears.table.join(
            awful.button({}, 1, function()
                awful.layout.inc(1)
            end),
            awful.button({}, 3, function()
                awful.layout.inc(-1)
            end),
            awful.button({}, 4, function()
                awful.layout.inc(1)
            end),
            awful.button({}, 5, function()
                awful.layout.inc(-1)
            end)
        ))

        s.mytaglist = awful.widget.taglist({
            screen = s,
            filter = awful.widget.taglist.filter.all,
            buttons = taglist_buttons,
        })

        s.mytasklist = awful.widget.tasklist({
            screen = s,
            filter = awful.widget.tasklist.filter.currenttags,
            buttons = tasklist_buttons,
        })

        -- Wibar
        s.mywibox = awful.wibar({ position = "top", screen = s })

        s.mywibox:setup({
            layout = wibox.layout.align.horizontal,
            {
                -- Left widgets
                layout = wibox.layout.fixed.horizontal,
                menu.launcher,
                s.mytaglist,
                s.mypromptbox,
            },
            s.mytasklist, -- Middle widget
            {
                -- Right widgets
                layout = wibox.layout.fixed.horizontal,

                -- Welcome message textbox
                wibox.widget({
                    markup = '<span foreground="#ff66cc">Welcome, ariseus.</span>',
                    font = "DejaVu Sans Mono 10",
                    screen = s,
                    buttons = gears.table.join(awful.button({}, 1, function()
                        awful.spawn.with_shell("waw &")
                    end)),
                    widget = wibox.widget.textbox,
                }),
                widgets.cpu_widget({ enable_kill_button = true, timeout = 1 }),
                widgets.ram_widget({ timeout = 1 }),
                -- widgets.volume_widget(),
                (s == screen.primary and widgets.volume_widget() or wibox.widget.textbox()),
                widgets.keyboardlayout,
                (s == screen.primary and wibox.widget.systray() or wibox.widget.textbox()),
                widgets.textclock,
                s.mylayoutbox,
            },
        })
    end)

    -- {{{ Signals
    -- Signal function to execute when a new client appears.
    client.connect_signal("manage", function(c)
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        if not awesome.startup then
            awful.client.setslave(c)
        end

        if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
            -- Prevent clients from being unreachable after screen count changes.
            awful.placement.no_offscreen(c)
        end
    end)

    -- Add a titlebar if titlebars_enabled is set to true in the rules.
    client.connect_signal("request::titlebars", function(c)
        -- buttons for the titlebar
        local buttons = gears.table.join(
            awful.button({}, 1, function()
                c:emit_signal("request::activate", "titlebar", { raise = true })
                awful.mouse.client.move(c)
            end),
            awful.button({}, 3, function()
                c:emit_signal("request::activate", "titlebar", { raise = true })
                awful.mouse.client.resize(c)
            end)
        )

        awful.titlebar(c):setup({
            {
                -- Left
                awful.titlebar.widget.iconwidget(c),
                buttons = buttons,
                layout = wibox.layout.fixed.horizontal,
            },
            {
                -- Middle
                {
                    -- Title
                    align = "center",
                    widget = awful.titlebar.widget.titlewidget(c),
                },
                buttons = buttons,
                layout = wibox.layout.flex.horizontal,
            },
            {
                -- Right
                awful.titlebar.widget.floatingbutton(c),
                awful.titlebar.widget.maximizedbutton(c),
                awful.titlebar.widget.stickybutton(c),
                awful.titlebar.widget.ontopbutton(c),
                awful.titlebar.widget.closebutton(c),
                layout = wibox.layout.fixed.horizontal(),
            },
            layout = wibox.layout.align.horizontal,
        })
    end)

    -- -- Enable sloppy focus, so that focus follows mouse.
    -- client.connect_signal("mouse::enter", function(c)
    -- 	c:emit_signal("request::activate", "mouse_enter", { raise = false })
    -- end)

    client.connect_signal("focus", function(c)
        c.border_color = beautiful.border_focus
    end)
    client.connect_signal("unfocus", function(c)
        c.border_color = beautiful.border_normal
    end)

    -- Smart borders: remove borders when there is only one tiled client visible.
    -- (Does not affect floating/maximized/fullscreen clients.)
    screen.connect_signal("arrange", function(s)
        local only_one = #s.tiled_clients == 1

        -- Smart gaps: remove gaps when there is only one tiled client.
        local t = s.selected_tag
        if t then
            local base_gap = beautiful.useless_gap or 0
            t.gap = only_one and 0 or base_gap
        end

        -- Smart borders: remove borders when there is only one tiled client visible.
        -- (Does not affect floating/maximized/fullscreen clients.)
        for _, c in pairs(s.clients) do
            if only_one and not c.floating and not c.maximized and not c.fullscreen then
                c.border_width = 0
            else
                c.border_width = beautiful.border_width
            end
        end
    end)
    -- }}}
end
