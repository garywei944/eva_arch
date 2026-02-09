-- config/autostart.lua

local awful = require("awful")

return function()
    -- Autostart
    -- awful.spawn.with_shell(
    --     "~/.config/autostart.sh </dev/null >/dev/null 2>&1 & disown")

    -- NOTE: awful.spawn.once() only works reliably for windowed clients (it matches
    -- on existing clients). For daemons like picom/fcitx5, use a pgrep gate.
    local function spawn_once(cmd, pgrep_pattern)
        local pat = pgrep_pattern or cmd
        awful.spawn.with_shell(string.format("pgrep -u $USER -f '%s' >/dev/null || (%s)", pat, cmd))
    end

    -- Only run autostarts on initial WM startup (avoid duplicating on awesome.restart())
    if awesome.startup then
        spawn_once("numlockx on", "numlockx")
        spawn_once("waw", "waw")
        spawn_once("picom -b", "picom")
        spawn_once("fcitx5", "fcitx5")
        spawn_once("albert", "albert")

        spawn_once("google-chrome-stable --password-store=gnome --no-startup-window", "google-chrome")
        spawn_once("insync start", "insync")
        spawn_once("betterbird", "betterbird")
    end
end
