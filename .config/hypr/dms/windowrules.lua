-- Window rules. Deploy writes ~/.config/hypr/dms/windowrules.lua

-- Route communication apps to the right monitor's Chat workspace on creation.
hl.window_rule({
    name = "route-chat-apps",
    match = { class = "^(discord|Discord|wechat|WeChat|lark|Lark)$" },
    workspace = "20",
})

-- Route QQ Music to the right monitor's Music workspace on creation.
hl.window_rule({
    name = "route-qqmusic",
    match = { class = "^(qqmusic)$" },
    workspace = "25",
})

-- Route Sublime Merge to the right monitor's Git workspace on creation.
hl.window_rule({
    name = "route-sublime-merge",
    match = { class = "^(smerge|sublime_merge)$" },
    workspace = "21",
})

-- A hidden fullscreen toplevel lets linux-wallpaperengine use its native pause
-- path without SIGSTOPing renderers (which can crash after queued DBus events).
hl.window_rule({
    name = "native-wallpaper-pause-helper",
    match = {
        class = "^zenity$",
        title = "^EVA Wallpaper Pause Helper [0-9a-f]+$",
    },
    workspace = "special:eva-wallpaper-pause silent",
    fullscreen = true,
    no_focus = true,
    no_anim = true,
})
