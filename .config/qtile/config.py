# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from typing import List  # noqa: F401

from libqtile import bar, layout, widget, qtile, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy

import os
import subprocess


def window_to_previous_screen(_qtile):
    _screen_index = _qtile.screens.index(_qtile.current_screen)
    if _screen_index != 0:
        _group = _qtile.screens[_screen_index - 1].group.name
        _qtile.current_window.togroup(_group)
        _qtile.focus_screen(_screen_index - 1)


def window_to_next_screen(_qtile):
    _screen_index = _qtile.screens.index(_qtile.current_screen)
    if _screen_index + 1 != len(_qtile.screens):
        _group = _qtile.screens[_screen_index + 1].group.name
        _qtile.current_window.togroup(_group)
        _qtile.focus_screen(_screen_index + 1)


mod = "mod4"
terminal = "terminator"

keys = [
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key(["mod1"], "Tab", lazy.layout.next(),
        desc="Move window focus to other window"),

    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(),
        desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(),
        desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(),
        desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod], "Left", lazy.layout.shuffle_left(),
        desc="Move window to the left"),
    Key([mod], "Right", lazy.layout.shuffle_right(),
        desc="Move window to the right"),
    Key([mod], "Up", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod], "Down", lazy.layout.shuffle_down(),
        desc="Move window down"),

    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(),
        desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(),
        desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(),
        desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),

    # xmonadtall
    Key([mod, "control"], "h", lazy.layout.shrink(), desc="Shrink window"),
    Key([mod, "control"], "l", lazy.layout.grow(), desc="Grow window"),
    Key([mod, "control"], "j", lazy.layout.shrink(), desc="Shrink window"),
    Key([mod, "control"], "k", lazy.layout.grow(), desc="Grow window"),

    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod, "control"], "space", lazy.window.toggle_floating(),
        desc="Toggle floating"),

    # Switch between monitors
    Key([mod, "shift"], "Left", lazy.function(window_to_next_screen),
        desc="Move window to the next monitor"),
    Key([mod, "shift"], "Right", lazy.function(window_to_previous_screen),
        desc="Move window to the previous monitor"),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack"),
    Key([mod], "t", lazy.spawn(terminal), desc="Launch terminal"),

    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key(["mod1"], "F4", lazy.window.kill(), desc="Kill focused window"),

    Key([mod, "control"], "r", lazy.restart(), desc="Restart Qtile"),
    Key(["control", 'mod1'], 'Delete', lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(),
        desc="Spawn a command using a prompt widget"),

    # Control Qtile
    Key([mod], 'semicolon', lazy.spawn('lock'), desc="Lock Qtile"),
    Key([mod], 'd', lazy.screen.toggle_group('Desktop'), desc="Show Desktop"),
    Key(["control", "shift"], "Escape", lazy.spawn("gnome-system-monitor"),
        desc="Launch system monitor"),

    # Launch applications
    Key(["control"], "space", lazy.spawn("dmenu_run", shell=True),
        desc="Launch dmenu"),
    Key([mod], "e", lazy.spawn("nautilus"), desc="Launch nautilus"),
    Key([mod], "b", lazy.spawn("google-chrome"), desc="Launch google chrome"),
    Key([mod], "KP_Left", lazy.spawn("netease-cloud-music"),
        desc="Launch netease cloud music"),

    # Just for test
    Key([mod], "a", lazy.group['Desktop'].toscreen(0))
]
_group_names = [
    ("Major", {'layout': ['xmonadtall', 'max']}),
    ("Minor", {'layout': ['columns', 'max']}),
    ("Desktop", {'layout': 'columns'})
]

groups = [Group(name, **kwargs) for name, kwargs in _group_names]

for i, (name, kwargs) in enumerate(_group_names, 1):
    keys.append(Key([mod], str(i),
                    lazy.group[name].toscreen()))  # Switch to another group
    keys.append(Key([mod, "shift"], str(i), lazy.window.togroup(
        name)))  # Send current window to another group

_layout_theme = {
    "border_width": 1,
    "margin": 5,
    "border_focus": "#ff66cc",
    "border_normal": "#66ccff"
}

layouts = [
    layout.MonadTall(
        align=1,
        **_layout_theme
    ),
    layout.Max(),
    layout.Columns(
        # fair=True,
        insert_position=1,
        **_layout_theme
    ),
    # layout.Bsp(
    #     grow_amount=2,
    #     **_layout_theme
    # ),
    # Try more layouts by unleashing below layouts.
    # layout.Tile(),
    # layout.Stack(num_stacks=2),
    # layout.Slice(),
    # layout.Matrix(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

colors = [["#282c34", "#282c34"],  # panel background
          ["#434758", "#434758"],  # background for current screen tab
          ["#ffffff", "#ffffff"],  # font color for group names
          ["#ff5555", "#ff5555"],  # border line color for current tab
          ["#8d62a9", "#8d62a9"],
          # border line color for other tab and odd widgets
          ["#668bd7", "#668bd7"],  # color for the even widgets
          ["#e1acff", "#e1acff"]]  # window name

widget_defaults = dict(
    font='sans',
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayout(),
                widget.GroupBox(),
                widget.WindowName(),
            ],
            24
        ),
    ),
    Screen(
        top=bar.Bar(
            [
                widget.Sep(
                    linewidth=0,
                    padding=6,
                    foreground=colors[2],
                    background=colors[0]
                ),
                widget.Image(
                    filename="~/.config/qtile/logo.png",
                    mouse_callbacks={
                        "Button1": lambda: qtile.cmd_spawn("dmenu_run")}
                ),
                widget.CurrentLayout(),
                widget.GroupBox(),
                # widget.Prompt(),
                widget.WindowName(),
                # widget.Chord(
                #     chords_colors={
                #         'launch': ("#ff0000", "#ffffff"),
                #     },
                #     name_transform=lambda name: name.upper(),
                # ),
                widget.TextBox(
                    "Welcome, ariseus.",
                    foreground="#ff66cc",
                    mouse_callbacks={"Button1": lambda: qtile.cmd_spawn("waw")}
                ),
                widget.TextBox(
                    text=" 🌡",
                    padding=2,
                    fontsize=11
                ),
                widget.ThermalSensor(
                    threshold=90,
                    padding=5
                ),
                widget.TextBox(
                    text=" 🖬",
                    padding=0,
                    fontsize=14
                ),
                widget.Memory(
                    mouse_callbacks={'Button1': lambda: qtile.cmd_spawn(
                        terminal + ' -e bashtop')},
                    measure_mem='G',
                    padding=5
                ),
                widget.TextBox(
                    text='Network:',
                ),
                widget.Net(
                    interface="enp6s0",
                    format='{down} ↓↑ {up}'
                ),
                # widget.TextBox(
                #     text=" Vol:",
                #     padding=0
                # ),
                # widget.Volume(
                #     padding=5
                # ),
                widget.Systray(),
                widget.Clock(format='%Y/%m/%d %a %I:%M %p'),
                # widget.QuickExit(),
            ],
            24,
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    # Drag([mod], "Button3", lazy.window.set_size_floating(),
    #      start=lazy.window.get_size()),
    # Click([mod], "Button2", lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
main = None  # WARNING: this is deprecated and will be removed soon
follow_mouse_focus = False
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(float_rules=[
    # Run the utility of `xprop` to see the wm class and name of an X client.
    *layout.Floating.default_float_rules,
    Match(wm_class='confirmreset'),  # gitk
    Match(wm_class='makebranch'),  # gitk
    Match(wm_class='maketag'),  # gitk
    Match(wm_class='ssh-askpass'),  # ssh-askpass
    Match(title='branchdialog'),  # gitk
    Match(title='pinentry'),  # GPG key password entry
])
auto_fullscreen = True
focus_on_window_activation = "smart"

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"


@hook.subscribe.startup_once
def start_once():
    _home = os.path.expanduser('~')
    subprocess.call([_home + '/.config/autostart.sh'])


@hook.subscribe.startup_complete
def start():
    lazy.group['Major'].toscreen(1)
