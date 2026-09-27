std = "lua54"

globals = {
  "awesome",
  "client",
  "screen",
  "tag",
  "root",
  "mouse",
}

-- Hyprland Lua config runs with the `hl` API injected by Hyprland.
files[".config/hypr/hyprland.lua"] = {
  globals = { "hl" },
}

files[".config/hypr/dms/*.lua"] = {
  globals = { "hl" },
}

files[".config/hypr/dms-theme-sync.lua"] = {
  globals = { "hl" },
}
