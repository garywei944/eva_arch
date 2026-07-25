-- Workspace display names migrated from workspace.conf.

local names = {
    "1-1 | Code",
    "1-2 | Web",
    "1-3 | Folder",
    "1-4 | Doc",
    "1-5 | App",
    "1-6 | Code",
    "1-7 | Web",
    "1-8 | Terminal",
    "1-9 | Reserve",
    "2-1 | Code",
    "2-2 | Web",
    "2-3 | Folder",
    "2-4 | Doc",
    "2-5 | App",
    "2-6 | Code",
    "2-7 | Web",
    "2-8 | Terminal",
    "2-9 | Reserve",
    "3-1 | Web",
    "3-2 | Chat",
    "3-3 | Git",
    "3-4 | Doc",
    "3-5 | App",
    "3-6 | Code",
    "3-7 | Music",
    "3-8 | Terminal",
    "3-9 | Reserve",
}

for id, name in ipairs(names) do
    hl.workspace_rule({
        workspace = tostring(id),
        default_name = name,
    })
end
