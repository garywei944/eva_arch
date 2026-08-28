#!/usr/bin/env python3
"""Unit tests for wallpaper-engine-control (no live processes or Hyprland needed)."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import json
import random
import sys
import tempfile
import unittest
from pathlib import Path
from types import ModuleType
from typing import Any
from unittest import mock

CONTROL = Path.home() / ".local/bin/wallpaper-engine-control"


def load_control() -> ModuleType:
    loader = importlib.machinery.SourceFileLoader("wallpaper_engine_control", str(CONTROL))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[loader.name] = module  # dataclasses resolve postponed annotations through sys.modules
    loader.exec_module(module)
    return module


wec = load_control()


def renderer(pid: int, argv: list[str], replaced: bool = False) -> Any:
    screens, playlists, backgrounds, default_playlist = wec.parse_renderer_argv(argv)
    return wec.Renderer(
        pid,
        argv,
        wec.RENDERER_EXECUTABLE,
        replaced,
        1000 + pid,
        screens,
        playlists,
        backgrounds,
        default_playlist,
    )


def process(pid: int, argv: list[str], exe: str, start_time: int = 1000) -> Any:
    return wec.Proc(pid, argv, exe, False, start_time)


class ArgvParsingTests(unittest.TestCase):
    def test_one_playlist_per_screen(self) -> None:
        screens, playlists, backgrounds, default_playlist = wec.parse_renderer_argv(
            ["./linux-wallpaperengine", "--screen-root", "DP-2", "--playlist", "DP-2", "--fps", "160"]
        )
        self.assertEqual(screens, ["DP-2"])
        self.assertEqual(playlists, {"DP-2": "DP-2"})
        self.assertEqual(backgrounds, {})
        self.assertIsNone(default_playlist)

    def test_one_process_serving_several_screens(self) -> None:
        screens, playlists, backgrounds, default_playlist = wec.parse_renderer_argv(
            ["x", "--screen-root", "DP-1", "--screen-root", "DP-2", "--playlist", "all", "--bg", "123"]
        )
        self.assertEqual(screens, ["DP-1", "DP-2"])
        # --playlist / --bg apply to the most recent --screen-root, matching the renderer's own parser
        self.assertEqual(playlists, {"DP-2": "all"})
        self.assertEqual(backgrounds, {"DP-2": "123"})
        self.assertIsNone(default_playlist)

    def test_screen_span(self) -> None:
        screens, playlists, _, default_playlist = wec.parse_renderer_argv(
            ["x", "--screen-span", "DP-1,DP-3", "--playlist", "wide"]
        )
        self.assertEqual(screens, ["DP-1", "DP-3"])
        self.assertEqual(playlists, {"DP-1": "wide", "DP-3": "wide"})
        self.assertIsNone(default_playlist)

    def test_window_mode_playlist_is_still_an_eligible_target(self) -> None:
        screens, playlists, backgrounds, default_playlist = wec.parse_renderer_argv(["x", "--playlist", "window-list"])
        self.assertEqual(screens, [])
        self.assertEqual(playlists, {})
        self.assertEqual(backgrounds, {})
        self.assertEqual(default_playlist, "window-list")


class SelectionTests(unittest.TestCase):
    def test_empty_selection(self) -> None:
        self.assertTrue(wec.selection_is_empty({}))
        self.assertTrue(wec.selection_is_empty({"activeWallpapers": {}, "activePlaylists": {}, "activePlaylist": None}))
        self.assertEqual(wec.active_playlist_names({"activePlaylist": {"name": "old", "screen": "DP-1"}}), {"old"})

    def test_shadowed_legacy_playlist_is_not_effectively_active(self) -> None:
        config = {
            "activePlaylists": {"DP-1": {"name": "current", "screen": "DP-1"}},
            "activePlaylist": {"name": "stale", "screen": "DP-1"},
        }
        self.assertEqual(wec.active_playlist_names(config), {"current"})

    def test_empty_live_store_requires_matching_full_saved_plan(self) -> None:
        live = [renderer(10, ["x", "--screen-root", "DP-2", "--playlist", "DP-2"])]
        with mock.patch.object(wec, "read_power_state", return_value=None):
            with self.assertRaisesRegex(wec.ControlError, "trustworthy restore plan"):
                wec.restore_config_for_stop(live, {})

        stale = {
            "expected_screens": ["DP-1"],
            "active_config": {
                "activeWallpapers": {"DP-1": {"backgroundId": "/wp/1", "screen": "DP-1"}},
                "appliedHistory": {"keep": True},
            },
        }
        with mock.patch.object(wec, "read_power_state", return_value=stale):
            with self.assertRaisesRegex(wec.ControlError, "does not match live outputs"):
                wec.restore_config_for_stop(live, {})

        full = {
            "activeWallpapers": {"DP-2": {"backgroundId": "/wp/2", "screen": "DP-2"}},
            "activePlaylists": {"DP-2": {"name": "DP-2", "screen": "DP-2"}},
            "appliedHistory": {"keep": True},
        }
        with mock.patch.object(
            wec,
            "read_power_state",
            return_value={"expected_screens": ["DP-2"], "active_config": full},
        ):
            self.assertIs(wec.restore_config_for_stop(live, {}), full)


class ShuffleTests(unittest.TestCase):
    def test_shuffle_is_a_permutation_that_changes_the_first_item(self) -> None:
        items = [f"/wp/{index}" for index in range(20)]
        for seed in range(50):
            shuffled = wec.shuffled_items(items, random.Random(seed))
            self.assertEqual(sorted(shuffled), sorted(items))
            self.assertNotEqual(shuffled[0], items[0])

    def test_duplicates_still_change_the_visible_first_item(self) -> None:
        items = ["a", "a", "a", "b"]
        for seed in range(20):
            self.assertEqual(wec.shuffled_items(items, random.Random(seed))[0], "b")

    def test_only_active_random_playlists_are_rewritten(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            config = {
                "steamuser": {
                    "general": {
                        "playlists": [
                            {"name": "DP-1", "settings": {"order": "random"}, "items": ["a", "b", "c"]},
                            {"name": "DP-2", "settings": {"order": "sequential"}, "items": ["a", "b", "c"]},
                            {"name": "idle", "settings": {"order": "random"}, "items": ["a", "b", "c"]},
                            {"name": "single", "settings": {"order": "random"}, "items": ["a", "a"]},
                        ]
                    }
                }
            }
            path.write_text(json.dumps(config))
            with mock.patch.object(wec, "steam_config_path", return_value=path):
                shuffled = wec.shuffle_random_playlists({"DP-1", "DP-2", "single"}, random.Random(1))
            self.assertEqual(shuffled, ["DP-1"])
            saved = json.loads(path.read_text())["steamuser"]["general"]["playlists"]
            self.assertNotEqual(saved[0]["items"][0], "a")
            self.assertEqual(sorted(saved[0]["items"]), ["a", "b", "c"])
            self.assertEqual(saved[1]["items"], ["a", "b", "c"])
            self.assertEqual(saved[2]["items"], ["a", "b", "c"])

    def test_no_active_playlists_means_no_file_access(self) -> None:
        with mock.patch.object(wec, "steam_config_path", side_effect=AssertionError("must not be called")):
            self.assertEqual(wec.shuffle_random_playlists(set()), [])

    def test_atomic_writer_refuses_destination_symlinks(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            victim = root / "victim.json"
            victim.write_text('{"safe":true}\n')
            destination = root / "config.json"
            destination.symlink_to(victim)
            with self.assertRaises(wec.ControlError):
                wec.write_json_atomic(destination, {"unsafe": True}, indent=2)
            self.assertTrue(destination.is_symlink())
            self.assertEqual(victim.read_text(), '{"safe":true}\n')

    def test_steam_config_compare_and_swap_rejects_concurrent_writer(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            path.write_text('{"version":1}\n')
            config, raw, identity, mode = wec.read_steam_config(path)
            path.write_text('{"version":2}\n')
            with self.assertRaisesRegex(wec.ControlError, "changed"):
                wec.write_steam_config(path, config, raw, identity, mode)
            self.assertEqual(json.loads(path.read_text()), {"version": 2})


class SnapshotTests(unittest.TestCase):
    def snapshot(self, records: list[Any], ux: list[int], helpers: list[dict[str, Any]]) -> dict[str, Any]:
        with (
            mock.patch.object(wec, "renderers", return_value=records),
            mock.patch.object(wec, "ux_pids", return_value=ux),
            mock.patch.object(wec, "helper_windows", return_value=helpers),
            mock.patch.object(wec, "read_power_state", return_value=None),
        ):
            return wec.snapshot()

    def test_states(self) -> None:
        live = [renderer(10, ["x", "--screen-root", "DP-1", "--playlist", "DP-1"])]
        helper = {"pid": 5, "title": "t", "argv": ["zenity"], "native_pause": True}
        self.assertEqual(self.snapshot([], [], [])["state"], "stopped")
        self.assertEqual(self.snapshot([], [7], [])["state"], "idle")
        self.assertEqual(self.snapshot(live, [7], [])["state"], "running")
        self.assertEqual(self.snapshot(live, [7], [helper])["state"], "paused")
        self.assertEqual(self.snapshot(live, [7], [{**helper, "native_pause": False}])["state"], "error")
        self.assertEqual(self.snapshot([], [7], [helper])["state"], "error")
        disabled = [renderer(11, ["x", "--screen-root", "DP-1", "--no-fullscreen-pause"])]
        self.assertEqual(self.snapshot(disabled, [7], [helper])["state"], "error")

    def test_payload_fields_the_bar_widget_reads(self) -> None:
        live = [renderer(10, ["x", "--screen-root", "DP-1", "--screen-root", "DP-2", "--playlist", "all"])]
        payload = self.snapshot(live, [7], [])
        self.assertEqual(payload["count"], 1)
        self.assertEqual(payload["screen_count"], 2)
        self.assertEqual(payload["screens"], ["DP-1", "DP-2"])
        self.assertEqual(payload["running"], 1)
        self.assertTrue(payload["ux_running"])
        self.assertIsNone(payload["helper_pid"])
        self.assertIn("next_supported", payload)

    def test_next_is_unavailable_without_an_eligible_playlist(self) -> None:
        static = [renderer(10, ["x", "--screen-root", "DP-1", "--bg", "/wp/1"])]
        with mock.patch.object(wec, "NEXT_SUPPORT_MARKER", Path("/")):
            self.assertFalse(self.snapshot(static, [7], [])["next_supported"])


class ProcessIdentityTests(unittest.TestCase):
    def test_ux_discovery_requires_the_expected_executable(self) -> None:
        spoof = process(42, [wec.UX_EXECUTABLE, wec.UX_ASAR], "/usr/bin/yes")
        real = process(43, [wec.UX_EXECUTABLE, wec.UX_ASAR], wec.UX_EXECUTABLE)
        with mock.patch.object(wec, "own_processes", return_value=iter([spoof, real])):
            self.assertEqual([record.pid for record in wec.ux_processes()], [43])

    def test_signal_is_sent_through_a_revalidated_pidfd(self) -> None:
        target = process(77, ["renderer"], wec.RENDERER_EXECUTABLE)
        with (
            mock.patch.object(wec.os, "pidfd_open", return_value=9) as pidfd_open,
            mock.patch.object(wec, "process_identity_live", return_value=True),
            mock.patch.object(wec.signal, "pidfd_send_signal") as pidfd_send,
            mock.patch.object(wec.os, "close") as close,
        ):
            self.assertTrue(wec.signal_process(target, wec.signal.SIGUSR1))
        pidfd_open.assert_called_once_with(77)
        pidfd_send.assert_called_once_with(9, wec.signal.SIGUSR1)
        close.assert_called_once_with(9)

    def test_scope_validation_rejects_non_app_slice(self) -> None:
        target = process(42, [wec.UX_EXECUTABLE, wec.UX_ASAR], wec.UX_EXECUTABLE)
        with (
            mock.patch.object(wec, "process_identity_live", return_value=True),
            mock.patch.object(wec, "proc_cgroup", return_value="/user.slice/unrelated-42.scope"),
        ):
            with self.assertRaisesRegex(wec.ControlError, "unexpected Wallpaper Engine cgroup"):
                wec.validated_ux_scope(target)


class NextTests(unittest.TestCase):
    def test_next_refuses_unpatched_or_upgraded_renderers(self) -> None:
        live = [renderer(10, ["x", "--screen-root", "DP-1", "--playlist", "DP-1"], replaced=True)]
        with (
            mock.patch.object(wec, "renderers", return_value=live),
            mock.patch.object(wec, "helper_windows", return_value=[]),
            mock.patch.object(wec, "fullscreen_windows", return_value=[]),
            mock.patch.object(wec, "NEXT_SUPPORT_MARKER", Path("/")),
            mock.patch.object(wec.os, "kill") as kill,
        ):
            with self.assertRaises(wec.ControlError):
                wec.next_wallpaper()
            kill.assert_not_called()

    def test_next_signals_only_playlist_renderers(self) -> None:
        live = [
            renderer(10, ["x", "--screen-root", "DP-1", "--playlist", "DP-1"]),
            renderer(11, ["x", "--screen-root", "DP-2", "--bg", "/wp/1"]),
        ]
        with (
            mock.patch.object(wec, "renderers", return_value=live),
            mock.patch.object(wec, "ux_pids", return_value=[7]),
            mock.patch.object(wec, "helper_windows", return_value=[]),
            mock.patch.object(wec, "fullscreen_windows", return_value=[]),
            mock.patch.object(wec, "read_power_state", return_value=None),
            mock.patch.object(wec, "NEXT_SUPPORT_MARKER", Path("/")),
            mock.patch.object(wec, "renderer_next_ready", return_value=True),
            mock.patch.object(wec, "signal_process", return_value=True) as send,
        ):
            result = wec.next_wallpaper()
        send.assert_called_once_with(live[0], wec.signal.SIGUSR1)
        self.assertEqual(result["requested_pids"], [10])
        self.assertEqual(result["requested_screens"], ["DP-1"])
        self.assertNotIn("advanced_pids", result)

    def test_next_does_not_report_a_vanished_renderer(self) -> None:
        live = [renderer(10, ["x", "--screen-root", "DP-1", "--playlist", "DP-1"])]
        with (
            mock.patch.object(wec, "renderers", return_value=live),
            mock.patch.object(wec, "ux_pids", return_value=[7]),
            mock.patch.object(wec, "helper_windows", return_value=[]),
            mock.patch.object(wec, "fullscreen_windows", return_value=[]),
            mock.patch.object(wec, "read_power_state", return_value=None),
            mock.patch.object(wec, "NEXT_SUPPORT_MARKER", Path("/")),
            mock.patch.object(wec, "renderer_next_ready", return_value=True),
            mock.patch.object(wec, "signal_process", return_value=False),
        ):
            with self.assertRaisesRegex(wec.ControlError, "vanished"):
                wec.next_wallpaper()

    def test_next_refuses_while_paused(self) -> None:
        live = [renderer(10, ["x", "--screen-root", "DP-1", "--playlist", "DP-1"])]
        with (
            mock.patch.object(wec, "renderers", return_value=live),
            mock.patch.object(wec, "helper_windows", return_value=[{"pid": 1, "native_pause": True}]),
            mock.patch.object(wec.os, "kill") as kill,
        ):
            with self.assertRaises(wec.ControlError):
                wec.next_wallpaper()
            kill.assert_not_called()


if __name__ == "__main__":
    unittest.main(verbosity=2)
