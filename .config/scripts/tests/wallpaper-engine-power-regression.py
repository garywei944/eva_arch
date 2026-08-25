#!/usr/bin/env python3
"""Live stop/start regression for the DMS Wallpaper Engine control."""

from __future__ import annotations

import json
import os
import runpy
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

CONTROL = Path.home() / ".local/bin/wallpaper-engine-control"
PLUGIN = Path.home() / ".config/DankMaterialShell/plugins/wallpaperEngineControl/WallpaperEngineControl.qml"
ACTIVE_CONFIG = Path.home() / ".config/Linux Wallpaper Engine/active-wallpapers.json"
CONTROL_MODULE = runpy.run_path(str(CONTROL))
POWER_STATE = (
    Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "wallpaper-engine-control/power.json"
)
UX_ASAR = "/usr/lib/linux-wallpaper-engine-ux/app.asar"
RENDERER_NAME = "linux-wallpaperengine"


def ux_selected_steam_config_path() -> Path:
    for library in CONTROL_MODULE["steam_library_paths"]():
        candidate = library / "steamapps/common/wallpaper_engine/config.json"
        if candidate.exists():
            return candidate.resolve()
    raise RuntimeError("Wallpaper Engine UX has no existing config.json candidate")


STEAM_CONFIG = ux_selected_steam_config_path()


def invoke(action: str) -> tuple[int, dict[str, Any], str]:
    result = subprocess.run(
        [str(CONTROL), action, "--json"],
        check=False,
        capture_output=True,
        text=True,
    )
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        payload = {"state": "invalid", "raw": result.stdout.strip()}
    return result.returncode, payload, result.stderr.strip()


def invoke_pill_power() -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["dms", "ipc", "call", "wallpaperEngineControl", "power"],
        check=False,
        capture_output=True,
        text=True,
    )


def invoke_pill_primary() -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["dms", "ipc", "call", "wallpaperEngineControl", "primary"],
        check=False,
        capture_output=True,
        text=True,
    )


def wait_for_state(expected: str, timeout: float = 40) -> dict[str, Any]:
    deadline = time.monotonic() + timeout
    latest: dict[str, Any] = {}
    while time.monotonic() < deadline:
        _, latest, _ = invoke("status")
        if latest.get("state") == expected:
            return latest
        time.sleep(0.1)
    return latest


def state_stays(expected: str, duration: float = 2) -> tuple[bool, dict[str, Any]]:
    deadline = time.monotonic() + duration
    latest: dict[str, Any] = {}
    while time.monotonic() < deadline:
        _, latest, _ = invoke("status")
        if latest.get("state") != expected:
            return False, latest
        time.sleep(0.1)
    return True, latest


def process_argv(pid: int) -> list[str]:
    return [os.fsdecode(value) for value in Path(f"/proc/{pid}/cmdline").read_bytes().split(b"\0") if value]


def wallpaper_processes() -> tuple[list[int], list[int]]:
    ux_roots: list[int] = []
    renderers: list[int] = []
    for process in Path("/proc").iterdir():
        if not process.name.isdigit():
            continue
        try:
            argv = process_argv(int(process.name))
        except OSError:
            continue
        if len(argv) >= 2 and argv[1] == UX_ASAR and not any(argument.startswith("--type=") for argument in argv[2:]):
            ux_roots.append(int(process.name))
        elif argv and Path(argv[0]).name == RENDERER_NAME:
            renderers.append(int(process.name))
    return sorted(ux_roots), sorted(renderers)


def gpu_memory_used_mib() -> int:
    output = subprocess.check_output(
        [
            "nvidia-smi",
            "--query-gpu=memory.used",
            "--format=csv,noheader,nounits",
        ],
        text=True,
    )
    return int(output.splitlines()[0].strip())


def durable_active_state() -> dict[str, Any]:
    data = json.loads(ACTIVE_CONFIG.read_text())
    return {key: data.get(key) for key in ("activeWallpapers", "activePlaylists", "activePlaylist")}


def effective_active_playlist_entries(active_state: dict[str, Any]) -> dict[str, dict[str, Any]]:
    stored = active_state.get("activePlaylists")
    entries = (
        {str(screen): entry for screen, entry in stored.items() if isinstance(stored, dict) and isinstance(entry, dict)}
        if isinstance(stored, dict)
        else {}
    )
    legacy = active_state.get("activePlaylist")
    if isinstance(legacy, dict):
        screen = legacy.get("screen")
        if isinstance(screen, str) and screen and screen not in entries:
            entries[screen] = legacy
    return entries


def playlist_catalog() -> dict[str, dict[str, Any]]:
    config = json.loads(STEAM_CONFIG.read_text())
    playlists = config.get("steamuser", {}).get("general", {}).get("playlists", [])
    return {
        str(playlist["name"]): json.loads(json.dumps(playlist))
        for playlist in playlists
        if isinstance(playlist, dict) and isinstance(playlist.get("name"), str)
    }


def active_playlist_items(active_state: dict[str, Any]) -> dict[str, dict[str, Any]]:
    names = {
        str(entry.get("name"))
        for entry in effective_active_playlist_entries(active_state).values()
        if isinstance(entry.get("name"), str) and entry.get("name")
    }
    return {
        name: {
            "order": playlist.get("settings", {}).get("order"),
            "items": list(playlist.get("items", [])),
        }
        for name, playlist in playlist_catalog().items()
        if name in names
    }


def active_state_matches_shuffled_restart(
    before: dict[str, Any],
    after: dict[str, Any],
    shuffled_playlists: dict[str, dict[str, Any]],
) -> bool:
    if before.get("activePlaylists") != after.get("activePlaylists"):
        return False
    if before.get("activePlaylist") != after.get("activePlaylist"):
        return False

    before_wallpapers = before.get("activeWallpapers")
    after_wallpapers = after.get("activeWallpapers")
    active_playlists = before.get("activePlaylists")
    if (
        not isinstance(before_wallpapers, dict)
        or not isinstance(after_wallpapers, dict)
        or not isinstance(active_playlists, dict)
    ):
        return before_wallpapers == after_wallpapers
    if set(before_wallpapers) != set(after_wallpapers):
        return False

    for screen, before_entry in before_wallpapers.items():
        after_entry = after_wallpapers.get(screen)
        playlist_entry = active_playlists.get(screen)
        playlist_name = playlist_entry.get("name") if isinstance(playlist_entry, dict) else None
        playlist = shuffled_playlists.get(str(playlist_name)) if playlist_name else None
        if playlist is None or playlist.get("order") != "random" or len(playlist.get("items", [])) <= 1:
            if after_entry != before_entry:
                return False
            continue
        if not isinstance(before_entry, dict) or not isinstance(after_entry, dict):
            return False
        if {key: value for key, value in after_entry.items() if key != "backgroundId"} != {
            key: value for key, value in before_entry.items() if key != "backgroundId"
        }:
            return False
        if after_entry.get("backgroundId") != playlist["items"][0]:
            return False
    return True


def controller_fixture_errors() -> list[str]:
    errors: list[str] = []

    def fixture_path(root: Path) -> Path:
        return root / "steamapps/common/wallpaper_engine/config.json"

    def write_fixture(root: Path, config: dict[str, Any], mode: int = 0o600) -> Path:
        path = fixture_path(root)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(config))
        os.chmod(path, mode)
        return path

    minimal: dict[str, Any] = {"steamuser": {"general": {"playlists": []}}}
    with TemporaryDirectory(prefix="wallpaper-playlist-path-") as directory:
        first = Path(directory) / "first"
        second = Path(directory) / "second"
        first_path = write_fixture(first, minimal, 0o400)
        write_fixture(second, minimal, 0o600)
        globals_ = CONTROL_MODULE["find_steam_config_path"].__globals__
        original_roots = globals_["STEAM_ROOT_PATHS"]
        globals_["STEAM_ROOT_PATHS"] = (first, second)
        try:
            try:
                selected = CONTROL_MODULE["find_steam_config_path"]()
            except CONTROL_MODULE["ControlError"]:
                selected = None
            if selected is not None:
                errors.append(
                    "controller must fail on the UX-selected first existing config "
                    "instead of choosing a later writable one: "
                    f"selected={selected}, expected refusal for {first_path.resolve()}"
                )
        finally:
            globals_["STEAM_ROOT_PATHS"] = original_roots

    shadowed_state = {
        "activePlaylists": {"DP-1": {"name": "current", "screen": "DP-1"}},
        "activePlaylist": {"name": "stale", "screen": "DP-1"},
    }
    if CONTROL_MODULE["active_playlist_names"](shadowed_state) != ["current"]:
        errors.append("a legacy playlist shadowed by activePlaylists is incorrectly treated as active")

    with TemporaryDirectory(prefix="wallpaper-playlist-scope-") as directory:
        root = Path(directory) / "Steam"
        original: dict[str, Any] = {
            "unrelated": {"keep": True},
            "steamuser": {
                "general": {
                    "playlists": [
                        {"name": "active-random", "items": ["a", "b", "c"], "settings": {"order": "random"}},
                        {
                            "name": "active-sequential",
                            "items": ["x", "y"],
                            "settings": {"order": "sequential"},
                        },
                        {"name": "inactive-random", "items": ["u", "v"], "settings": {"order": "random"}},
                    ]
                }
            },
        }
        path = write_fixture(root, original)
        globals_ = CONTROL_MODULE["shuffle_active_random_playlists"].__globals__
        original_roots = globals_["STEAM_ROOT_PATHS"]
        globals_["STEAM_ROOT_PATHS"] = (root,)
        active = {
            "activePlaylists": {
                "DP-1": {"name": "active-random", "screen": "DP-1"},
                "DP-2": {"name": "active-sequential", "screen": "DP-2"},
            },
            "activePlaylist": {"name": "inactive-random", "screen": "DP-1"},
        }
        try:
            shuffled = CONTROL_MODULE["shuffle_active_random_playlists"](active)
        finally:
            globals_["STEAM_ROOT_PATHS"] = original_roots
        after = json.loads(path.read_text())
        before_by_name = {playlist["name"]: playlist for playlist in original["steamuser"]["general"]["playlists"]}
        after_by_name = {playlist["name"]: playlist for playlist in after["steamuser"]["general"]["playlists"]}
        if shuffled != ["active-random"]:
            errors.append(f"shuffle scope included an inactive or non-random playlist: {shuffled}")
        if after_by_name["active-sequential"] != before_by_name["active-sequential"]:
            errors.append("active sequential playlist order changed")
        if after_by_name["inactive-random"] != before_by_name["inactive-random"]:
            errors.append("inactive random playlist changed")
        if Counter(after_by_name["active-random"]["items"]) != Counter(before_by_name["active-random"]["items"]):
            errors.append("active random playlist membership changed")

    with TemporaryDirectory(prefix="wallpaper-playlist-race-") as directory:
        root = Path(directory) / "Steam"
        original = {"steamuser": {"general": {"playlists": [{"name": "r", "items": ["a", "b"]}]}}}
        concurrent = {"steamuser": {"general": {"playlists": [{"name": "concurrent", "items": ["z"]}]}}}
        path = write_fixture(root, original)
        backup = path.with_name("config.json.eva-wallpaper-control.backup")
        backup.write_bytes(b"trusted-backup")
        module = runpy.run_path(str(CONTROL))
        exchange = module.get("_exchange_paths")
        if not callable(exchange):
            errors.append("playlist config commit lacks an atomic exchange primitive for race detection")
        else:
            parsed, *write_arguments = module["read_steam_config"](path)
            parsed["steamuser"]["general"]["playlists"][0]["items"] = ["b", "a"]
            globals_ = module["write_steam_config"].__globals__
            raced = False

            def racing_exchange(source: Path, target: Path) -> None:
                nonlocal raced
                if not raced and target == path:
                    path.write_text(json.dumps(concurrent))
                    raced = True
                exchange(source, target)

            globals_["_exchange_paths"] = racing_exchange
            try:
                try:
                    module["write_steam_config"](path, parsed, *write_arguments)
                except module["ControlError"]:
                    pass
                else:
                    errors.append("concurrent config replacement was silently overwritten")
            finally:
                globals_["_exchange_paths"] = exchange
            if json.loads(path.read_text()) != concurrent:
                errors.append("concurrent config replacement was not restored after a rejected commit")
            if backup.read_bytes() != b"trusted-backup":
                errors.append("a rejected concurrent commit replaced the last valid backup")

    with TemporaryDirectory(prefix="wallpaper-playlist-failure-") as directory:
        root = Path(directory) / "Steam"
        original = {"steamuser": {"general": {"playlists": [{"name": "r", "items": ["a", "b"]}]}}}
        path = write_fixture(root, original)
        module = runpy.run_path(str(CONTROL))
        parsed, *write_arguments = module["read_steam_config"](path)
        parsed["steamuser"]["general"]["playlists"][0]["items"] = ["b", "a"]
        module_os = module["write_steam_config"].__globals__["os"]
        original_chmod = module_os.chmod

        def fail_post_commit_chmod(target: str | os.PathLike[str], mode: int) -> None:
            if Path(target) == path:
                raise OSError("injected chmod failure")
            original_chmod(target, mode)

        module_os.chmod = fail_post_commit_chmod
        failed = False
        try:
            try:
                module["write_steam_config"](path, parsed, *write_arguments)
            except module["ControlError"]:
                failed = True
        finally:
            module_os.chmod = original_chmod
        if failed and json.loads(path.read_text()) != original:
            errors.append("playlist config changed even though the write reported failure")

    return errors


def main() -> int:
    errors = controller_fixture_errors()
    if errors:
        print("\n".join(f"FAIL: {error}" for error in errors))
        return 1
    source = PLUGIN.read_text()
    for required in (
        'command: [root.controlPath, "power-toggle", "--json"]',
        'pillRightClickAction: () => root.requestAction("power")',
        'pillClickAction: () => root.requestAction("primary")',
        "property string pendingAction",
    ):
        if required not in source:
            errors.append(f"DMS power-control path is missing: {required}")

    initial_code, initial, initial_stderr = invoke("status")
    if initial_code != 0 or initial.get("state") != "running":
        errors.append(f"precondition failed: status rc={initial_code}, payload={initial}, stderr={initial_stderr!r}")
        print("\n".join(f"FAIL: {error}" for error in errors))
        return 1

    active_before = durable_active_state()
    playlists_before = active_playlist_items(active_before)
    active_playlist_entries = active_before.get("activePlaylists")
    expected_playlist_names = (
        {
            str(entry.get("name"))
            for entry in active_playlist_entries.values()
            if isinstance(entry, dict) and entry.get("name")
        }
        if isinstance(active_playlist_entries, dict)
        else set()
    )
    if set(playlists_before) != expected_playlist_names:
        errors.append(
            "precondition failed: active playlists are missing from the Steam config; "
            f"active={sorted(expected_playlist_names)}, found={sorted(playlists_before)}"
        )
    random_restart_names = {
        name
        for name, playlist in playlists_before.items()
        if playlist.get("order") == "random"
        and len(playlist.get("items", [])) > 1
        and any(item != playlist["items"][0] for item in playlist["items"][1:])
    }
    if not random_restart_names:
        errors.append("precondition failed: no active randomized playlist has a distinct alternative start item")
    expected_screens: set[str] = set()
    for key in ("activeWallpapers", "activePlaylists"):
        section = active_before.get(key)
        if isinstance(section, dict):
            expected_screens.update(str(screen) for screen in section if screen)
    if not expected_screens:
        expected_screens = set(initial.get("screens", []))
    if not expected_screens or not expected_screens.issubset(set(initial.get("screens", []))):
        errors.append(
            "precondition failed: configured outputs are not all running; "
            f"configured={sorted(expected_screens)}, running={initial.get('screens', [])}"
        )
    if errors:
        print("\n".join(f"FAIL: {error}" for error in errors))
        return 1
    gpu_before = gpu_memory_used_mib()

    try:
        stop_click = invoke_pill_power()
        stopped_state = wait_for_state("stopped")
        if stop_click.returncode != 0 or "queued" not in stop_click.stdout or stopped_state.get("state") != "stopped":
            errors.append(
                f"live DMS power callback did not stop: rc={stop_click.returncode}, "
                f"payload={stopped_state}, stderr={stop_click.stderr!r}"
            )
        else:
            ux_roots, renderers = wallpaper_processes()
            if ux_roots or renderers:
                errors.append(f"Wallpaper Engine processes survived stop: ux={ux_roots}, renderers={renderers}")
            if stopped_state.get("ux_running") is not False:
                errors.append(f"stopped payload still reports UX running: {stopped_state}")
            if durable_active_state() != active_before:
                errors.append("stop changed the durable active-wallpaper selection")

            gpu_stopped = gpu_memory_used_mib()
            released = gpu_before - gpu_stopped
            if released < 1000:
                errors.append(
                    f"stop released only {released} MiB of GPU memory " f"({gpu_before} -> {gpu_stopped} MiB)"
                )

            primary_click = invoke_pill_primary()
            stayed_stopped, after_primary = state_stays("stopped")
            if primary_click.returncode != 0 or "ignored" not in primary_click.stdout or not stayed_stopped:
                errors.append(
                    "left click must be a no-op while stopped; only right click may restart the UX: "
                    f"rc={primary_click.returncode}, payload={after_primary}, stderr={primary_click.stderr!r}"
                )

        start_click = invoke_pill_power()
        started_state = wait_for_state("running")
        if start_click.returncode != 0 or "queued" not in start_click.stdout or started_state.get("state") != "running":
            errors.append(
                f"live DMS power callback did not restore running state: rc={start_click.returncode}, "
                f"payload={started_state}, stderr={start_click.stderr!r}"
            )
        else:
            restored_screens = set(started_state.get("screens", []))
            if not expected_screens.issubset(restored_screens):
                errors.append(
                    f"start did not restore all outputs: expected={sorted(expected_screens)}, "
                    f"actual={sorted(restored_screens)}"
                )
            ux_roots, renderers = wallpaper_processes()
            if len(ux_roots) != 1 or not renderers:
                errors.append(f"start restored an invalid process topology: ux={ux_roots}, renderers={renderers}")
            stayed_running, stable_state = state_stays("running", duration=3)
            if not stayed_running:
                errors.append(f"restored rendering did not remain stable: {stable_state}")
            active_after = durable_active_state()
            playlists_after = active_playlist_items(active_after)
            if set(playlists_after) != set(playlists_before):
                errors.append(
                    "start changed the active playlist set: "
                    f"before={sorted(playlists_before)}, after={sorted(playlists_after)}"
                )
            for name, before_playlist in playlists_before.items():
                after_playlist = playlists_after.get(name)
                if after_playlist is None:
                    continue
                before_items = before_playlist.get("items", [])
                after_items = after_playlist.get("items", [])
                if Counter(before_items) != Counter(after_items):
                    errors.append(f"start changed playlist membership for {name}")
                if (
                    before_playlist.get("order") == "random"
                    and len(before_items) > 1
                    and any(item != before_items[0] for item in before_items[1:])
                    and after_items
                    and after_items[0] == before_items[0]
                ):
                    errors.append(f"random playlist {name} replayed its pre-stop first item")
            if not active_state_matches_shuffled_restart(active_before, active_after, playlists_after):
                errors.append("start did not preserve playlist assignments and non-playlist wallpaper selections")
            try:
                restore_plan = json.loads(POWER_STATE.read_text()).get("active_config", {})
            except FileNotFoundError, json.JSONDecodeError:
                restore_plan = {}
            if {key: restore_plan.get(key) for key in active_after} != active_after:
                errors.append("start did not retain a matching last-known restore plan for repeated power cycles")
    finally:
        _, cleanup_state, _ = invoke("status")
        cleanup_screens = set(cleanup_state.get("screens", []))
        if cleanup_state.get("state") != "running" or not expected_screens.issubset(cleanup_screens):
            invoke("stop")
            invoke("start")

    if errors:
        print("\n".join(f"FAIL: {error}" for error in errors))
        return 1

    print(
        "PASS: manual stop removes the UX and all renderers, releases GPU memory, "
        "preserves playlist assignments, reshuffles random starts, and restores every output"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
