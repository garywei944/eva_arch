local config_root = "/home/aris/.config/hypr"
package.path = config_root .. "/?.lua;" .. config_root .. "/?/init.lua;" .. package.path

local binds = {}
local unbinds = {}
local callbacks = {}
local workspace_rules = {}

hl = {
    bind = function(key, dispatcher)
        assert(type(key) == "string")
        assert(type(dispatcher) == "function" or type(dispatcher) == "table")
        table.insert(binds, key)
    end,
    unbind = function(key)
        assert(type(key) == "string")
        table.insert(unbinds, key)
    end,
    on = function(event, callback)
        assert(type(event) == "string")
        assert(type(callback) == "function")
        callbacks[event] = callback
    end,
    workspace_rule = function(spec)
        assert(type(spec.workspace) == "string")
        table.insert(workspace_rules, spec)
    end,
    notification = {
        create = function() end,
    },
    dsp = {
        focus = function()
            return function() end
        end,
        window = {
            move = function()
                return function() end
            end,
        },
    },
}

dofile(config_root .. "/dms/hyprsplit.lua")
local hs = require("hyprsplit")
assert(hs.get_config("num_workspaces") == 9)
assert(hs.get_config("persistent_workspaces") == true)
assert(#binds == 34, "expected 34 hyprsplit binds, got " .. #binds)
assert(callbacks["config.reloaded"] ~= nil)
assert(callbacks["monitor.added"] ~= nil)
assert(callbacks["monitor.removed"] ~= nil)

dofile(config_root .. "/dms/workspaces.lua")
assert(#workspace_rules == 27, "expected 27 workspace-name rules, got " .. #workspace_rules)
assert(workspace_rules[1].default_name == "1-1 | Code")
assert(workspace_rules[27].default_name == "3-9 | Reserve")

print("hyprsplit_config=ok")
print("hyprsplit_binds=" .. #binds)
print("hyprsplit_unbinds=" .. #unbinds)
print("workspace_name_rules=" .. #workspace_rules)
