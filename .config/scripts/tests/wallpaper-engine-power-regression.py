#!/usr/bin/env python3
"""Live stop/start regression for the DMS Wallpaper Engine control."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

CONTROL = Path.home() / ".local/bin/wallpaper-engine-control"
PLUGIN = Path.home() / ".config/DankMaterialShell/plugins/wallpaperEngineControl/WallpaperEngineControl.qml"
ACTIVE_CONFIG = Path.home() / ".config/Linux Wallpaper Engine/active-wallpapers.json"
POWER_STATE = (
    Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "wallpaper-engine-control/power.json"
)
UX_ASAR = "/usr/lib/linux-wallpaper-engine-ux/app.asar"
RENDERER_NAME = "linux-wallpaperengine"


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


def main() -> int:
    errors: list[str] = []
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
            if durable_active_state() != active_before:
                errors.append("start did not preserve the durable active-wallpaper selection")
            try:
                restore_plan = json.loads(POWER_STATE.read_text()).get("active_config", {})
            except FileNotFoundError, json.JSONDecodeError:
                restore_plan = {}
            if {key: restore_plan.get(key) for key in active_before} != active_before:
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
        "preserves wallpaper selections, and start restores every output"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
