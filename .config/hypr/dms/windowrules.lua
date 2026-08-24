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
