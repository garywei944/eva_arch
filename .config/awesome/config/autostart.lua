-- config/autostart.lua

local awful = require("awful")

return function()
    -- Fallback to the classic approach: run a shell script.
    -- This avoids Awesome-specific spawn.once semantics (which only really works for windowed clients)
    -- and keeps everything debuggable in plain bash.
    awful.spawn.with_shell("$HOME/.config/autostart.sh </dev/null >/dev/null 2>&1 & disown")
end
