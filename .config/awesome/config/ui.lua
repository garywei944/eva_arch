-- config/ui.lua
-- Screen tags + wibar construction

local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

return function(apps, menu, widgets, screenmap)
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
        s.mylayoutbox:buttons(
            gears.table.join(
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
            )
        )

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
                    buttons = gears.table.join(
                        awful.button({}, 1, function()
                            awful.spawn.with_shell("waw &")
                        end)
                    ),
                    widget = wibox.widget.textbox,
                }),
                widgets.cpu_widget({ enable_kill_button = true, timeout = 1 }),
                widgets.ram_widget({ timeout = 1 }),
                widgets.volume_widget(),
                widgets.keyboardlayout,
                (s == screen.primary and wibox.widget.systray() or wibox.widget.textbox()),
                widgets.textclock,
                s.mylayoutbox,
            },
        })
    end)
end
