std = "lua54"

globals = {
  "awesome",
  "client",
  "screen",
  "tag",
  "root",
  "mouse",
}

-- DMS-generated Hyprland Lua runs with the `hl` API injected by Hyprland.
files[".config/hypr/hyprland.lua"] = {
  globals = { "hl" },
}

files[".config/hypr/dms/*.lua"] = {
  globals = { "hl" },
}

files[".config/hypr-backups/*/config/dms/*.lua"] = {
  globals = { "hl" },
}

files[".config/hypr-backups/*/validation/*.lua"] = {
  globals = { "hl" },
}
