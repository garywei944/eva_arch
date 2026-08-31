local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Match the Linux Kitty geometry and typography.
config.font = wezterm.font_with_fallback {
  { family = 'JetBrains Mono', weight = 'Regular' },
  'Microsoft YaHei UI',
}
config.font_size = 11.0
config.line_height = 1.08
config.cell_width = 1.0
config.window_padding = {
  left = 12,
  right = 12,
  top = 12,
  bottom = 12,
}

-- Recreate Kitty's plain translucent, borderless window without backdrop blur.
config.window_background_opacity = 0.76
config.text_background_opacity = 0.92
config.win32_system_backdrop = 'Disable'
config.window_decorations = 'RESIZE'
config.window_frame = {
  border_left_width = '1px',
  border_right_width = '1px',
  border_bottom_height = '1px',
  border_top_height = '1px',
  border_left_color = '#20364a',
  border_right_color = '#20364a',
  border_bottom_color = '#20364a',
  border_top_color = '#20364a',
}

-- Stable dark blue-gray palette with the preferred #66CCFF accent.
config.colors = {
  foreground = '#dce7f3',
  background = '#0b1118',
  cursor_bg = '#66ccff',
  cursor_fg = '#071018',
  cursor_border = '#66ccff',
  selection_fg = '#f4faff',
  selection_bg = '#264f78',
  scrollbar_thumb = '#29445d',
  split = '#29445d',
  ansi = {
    '#17212b',
    '#ff6b81',
    '#8bd49c',
    '#e5c07b',
    '#66ccff',
    '#c792ea',
    '#5de4c7',
    '#c8d3e0',
  },
  brights = {
    '#526777',
    '#ff8297',
    '#a8e6b5',
    '#f2d28b',
    '#89ddff',
    '#d6a7ff',
    '#7ff0d4',
    '#ffffff',
  },
  tab_bar = {
    background = '#081018',
    active_tab = {
      bg_color = '#66ccff',
      fg_color = '#071018',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#142231',
      fg_color = '#8fa7bb',
    },
    inactive_tab_hover = {
      bg_color = '#20364a',
      fg_color = '#dce7f3',
      italic = true,
    },
    new_tab = {
      bg_color = '#081018',
      fg_color = '#66ccff',
    },
    new_tab_hover = {
      bg_color = '#20364a',
      fg_color = '#ffffff',
    },
  },
}

-- Use the terminal font and Powerline separators, matching Kitty's tab bar.
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 28

local left_arrow = wezterm.nerdfonts.pl_right_hard_divider
local right_arrow = wezterm.nerdfonts.pl_left_hard_divider

local function tab_title(tab)
  if tab.tab_title and #tab.tab_title > 0 then
    return tab.tab_title
  end
  return tab.active_pane.title
end

wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
  local background = '#142231'
  local foreground = '#8fa7bb'
  local intensity = 'Normal'

  if tab.is_active then
    background = '#66ccff'
    foreground = '#071018'
    intensity = 'Bold'
  elseif hover then
    background = '#20364a'
    foreground = '#dce7f3'
  end

  local title = wezterm.truncate_right(tab_title(tab), math.max(1, max_width - 4))
  return {
    { Background = { Color = '#081018' } },
    { Foreground = { Color = background } },
    { Text = left_arrow },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Attribute = { Intensity = intensity } },
    { Text = ' ' .. title .. ' ' },
    { Background = { Color = '#081018' } },
    { Foreground = { Color = background } },
    { Text = right_arrow },
  }
end)

-- Match Kitty's cursor and scrollback behavior.
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 1000
config.scrollback_lines = 3000
config.enable_scroll_bar = false
config.hide_mouse_cursor_when_typing = true
config.inactive_pane_hsb = {
  saturation = 0.85,
  brightness = 0.72,
}

-- Preserve the familiar Kitty shortcuts.
config.keys = {
  {
    key = 'n',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SpawnWindow,
  },
  {
    key = 't',
    mods = 'CTRL',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = '+',
    mods = 'CTRL',
    action = wezterm.action.IncreaseFontSize,
  },
  {
    key = '-',
    mods = 'CTRL',
    action = wezterm.action.DecreaseFontSize,
  },
  {
    key = '0',
    mods = 'CTRL',
    action = wezterm.action.ResetFontSize,
  },
}

return config
