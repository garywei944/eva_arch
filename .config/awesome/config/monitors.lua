-- config/screenmap.lua
-- Compute stable screen assignments based on screen.primary + geometry.

local M = {
    dis_main = (screen.primary and screen.primary.index) or 1,
    dis_left = (screen.primary and screen.primary.index) or 1,
    dis_right = (screen.primary and screen.primary.index) or 1,
    dis_right_exists = false,
}

function M.recompute()
    local screens = {}
    for s in screen do
        table.insert(screens, s)
    end
    if #screens == 0 then
        M.dis_main, M.dis_left, M.dis_right = 1, 1, 1
        M.dis_right_exists = false
        return
    end

    local primary = screen.primary or screens[1]
    M.dis_main = primary.index

    table.sort(screens, function(a, b)
        return a.geometry.x < b.geometry.x
    end)

    -- Support screen is the one immediately to the RIGHT of primary.
    -- If there is no right screen, we do NOT assign any support layout.
    local right, left = nil, nil
    for _, s in ipairs(screens) do
        if s.geometry.x > primary.geometry.x then
            if (not right) or (s.geometry.x < right.geometry.x) then
                right = s
            end
        elseif s.geometry.x < primary.geometry.x then
            if (not left) or (s.geometry.x > left.geometry.x) then
                left = s
            end
        end
    end

    M.dis_right_exists = (right ~= nil)
    M.dis_right = (right and right.index) or M.dis_main
    M.dis_left = (left and left.index) or M.dis_main
end

function M.is_support_screen(s)
    return M.dis_right_exists and s.index == M.dis_right
end

M.recompute()

-- Best-effort: keep indices fresh on hotplug / layout changes.
screen.connect_signal("added", function()
    M.recompute()
end)

screen.connect_signal("removed", function()
    M.recompute()
end)

screen.connect_signal("property::geometry", function()
    M.recompute()
end)

return M
