-- DMS Window Rules — managed by DankMaterialShell
-- Do not edit manually; changes may be overwritten

-- DMS-RULE: id=dms_rule_0, name=
hl.window_rule({ match = { class = "^(discord|Discord|wechat|WeChat|lark|Lark)$" }, workspace = "20" })

-- DMS-RULE: id=dms_rule_1, name=
hl.window_rule({ match = { class = "^(qqmusic)$" }, workspace = "25" })

-- DMS-RULE: id=dms_rule_2, name=
hl.window_rule({ match = { class = "^(smerge|sublime_merge)$" }, workspace = "21" })

-- DMS-RULE: id=dms_rule_3, name=
hl.window_rule({ match = { class = "^zenity$", title = "^EVA Wallpaper Pause Helper [0-9a-f]+$" }, fullscreen = true, no_focus = true, no_anim = true, workspace = "special:eva-wallpaper-pause silent" })

-- DMS-RULE: id=dms-floating-windows, name=DMS Floating Windows
hl.window_rule({ match = { class = "^com.danklinux.dms$" }, float = true })
