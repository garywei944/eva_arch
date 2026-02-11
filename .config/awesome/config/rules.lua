-- config/rules.lua

local awful = require("awful")
local beautiful = require("beautiful")

return function(keys, screenmap)
    -- Workaround Thunderbird show a windows at start up
    local __tb_started = false

    -- Helpers for rules
    local function get_tag(screen_index, tag_index)
        local s = screen[screen_index]
        return (s and s.tags and s.tags[tag_index]) or nil
    end

    -- Be gentle: always place the window on the desired tag, but only switch the
    -- *view* when you're already focused on that screen and this isn't startup.
    local function maybe_view_only(t)
        if not t then
            return
        end
        if awesome.startup then
            return
        end
        if awful.screen.focused() ~= t.screen then
            return
        end
        if t.selected then
            return
        end
        t:view_only()
    end

    local function place_on_tag(c, screen_index, tag_index)
        local t = get_tag(screen_index, tag_index)
        if not t then
            return
        end
        c:move_to_tag(t)
        maybe_view_only(t)
    end

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
                keys = keys.clientkeys,
                buttons = keys.clientbuttons,
                screen = awful.screen.preferred,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            },
        },

        { rule = { instance = "krunner" }, properties = { floating = true } },

        -- Floating clients.
        {
            rule_any = {
                instance = {
                    "DTA",   -- Firefox addon DownThemAll.
                    "copyq", -- Includes session name in class.
                    "pinentry",
                },
                class = {
                    "Arandr",
                    "Blueman-manager",
                    "Gpick",
                    "Kruler",
                    "MessageWin",  -- kalarm.
                    "Sxiv",
                    "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
                    "Wpa_gui",
                    "veromix",
                    "xtightvncviewer",
                },
                name = {
                    "Event Tester", -- xev.
                },
                role = {
                    "AlarmWindow",   -- Thunderbird's calendar.
                    "ConfigManager", -- Thunderbird's about:config.
                    "pop-up",        -- e.g. Google Chrome's (detached) Developer Tools.
                    "setup",
                },
            },
            properties = { floating = true },
        },

        -- Add titlebars to normal clients and dialogs
        {
            rule_any = { type = { "normal", "dialog" } },
            properties = { titlebars_enabled = true },
        },

        -- App placement rules (gentle view switching)
        {
            rule = { instance = "Msgcompose", class = "betterbird" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_main, 4)
            end,
        },
        {
            rule = { instance = "Mail", class = "betterbird" },
            callback = function(c)
                local t = get_tag(screenmap.dis_main, 5)
                if not t then
                    return
                end

                c:move_to_tag(t)

                -- Don't steal focus during startup; also avoid switching on the very
                -- first Thunderbird window (old workaround).
                if __tb_started then
                    maybe_view_only(t)
                else
                    __tb_started = true
                end
            end,
        },
        {
            rule = { instance = "filezilla" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_main, 5)
            end,
        },

        -- Common apps (more robust matching by class/name)
        {
            rule_any = { class = { "discord", "Discord" }, instance = { "discord" } },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 2)
            end,
        },
        {
            rule = { instance = "wechat.exe" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 2)
            end,
        },
        {
            rule = { instance = "discord" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 2)
            end,
        },
        {
            rule = { instance = "sublime_merge" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 3)
            end,
        },
        {
            rule = { instance = "youdao-dict" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 5)
            end,
        },
        {
            rule = { instance = "jetbrains-pycharm", name = "SciView - " },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 6)
            end,
        },
        {
            rule = { instance = "jetbrains-pycharm", name = "Run - " },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 6)
            end,
        },
        {
            rule = { instance = "jetbrains-pycharm", name = "Jupyter - " },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 6)
            end,
        },
        {
            rule = { instance = "jetbrains-pycharm", name = "Documentation - " },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 6)
            end,
        },
        {
            rule = { instance = "qqmusic" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 7)
            end,
        },
        {
            rule = { instance = "netease-cloud-music" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 7)
            end,
        },
        {
            rule = { instance = "plasma-systemmonitor" },
            callback = function(c)
                place_on_tag(c, screenmap.dis_right, 8)
            end,
        },
    }
    -- }}}
end
