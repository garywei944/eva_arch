-- config/apps.lua

local M = {
    terminal = "terminator",
    editor = "vim",
    modkey = "Mod4",
}

M.editor_cmd = M.terminal .. " -e " .. M.editor

return M
