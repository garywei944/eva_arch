local config_root = "/home/aris/.config/hypr"
package.path = config_root .. "/?.lua;" .. config_root .. "/?/init.lua;" .. package.path

local effective = {}

local function proxy(path)
    return setmetatable({}, {
        __index = function(_, key)
            return proxy(path .. "." .. key)
        end,
        __call = function()
            return function() end
        end,
    })
end

hl = {
    bind = function(key)
        effective[key] = true
    end,
    unbind = function(key)
        effective[key] = nil
    end,
    gesture = function() end,
    on = function() end,
    define_submap = function() end,
    dsp = proxy("dsp"),
    notification = {
        create = function() end,
    },
}

dofile(config_root .. "/dms/binds.lua")
dofile(config_root .. "/dms/binds-user.lua")
dofile(config_root .. "/dms/hyprsplit.lua")

local keys = {}
for key in pairs(effective) do
    table.insert(keys, key)
end
table.sort(keys)
print("effective_bind_count=" .. #keys)
for _, key in ipairs(keys) do
    print(key)
end
