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
files[".config/hypr/dms/*.lua"] = {
  globals = { "hl" },
}
