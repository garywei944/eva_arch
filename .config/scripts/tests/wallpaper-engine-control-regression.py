#!/usr/bin/env python3
"""Live regression check for the DMS Wallpaper Engine pill."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

CONTROL = Path.home() / ".local/bin/wallpaper-engine-control"
PLUGIN = Path.home() / ".config/DankMaterialShell/plugins/wallpaperEngineControl/WallpaperEngineControl.qml"
HELPER_TITLE_PREFIX = "EVA Wallpaper Pause Helper"


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


def invoke_pill_primary() -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["dms", "ipc", "call", "wallpaperEngineControl", "primary"],
        check=False,
        capture_output=True,
        text=True,
    )


def wait_for_state(expected: str, timeout: float = 8) -> dict[str, Any]:
    deadline = time.monotonic() + timeout
    latest: dict[str, Any] = {}
    while time.monotonic() < deadline:
        _, latest, _ = invoke("status")
        if latest.get("state") == expected:
            return latest
        time.sleep(0.1)
    return latest


def helper_clients() -> list[dict[str, Any]]:
    result = subprocess.run(
        ["hyprctl", "clients", "-j"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [
        client for client in json.loads(result.stdout) if str(client.get("title", "")).startswith(HELPER_TITLE_PREFIX)
    ]


def process_state(pid: int) -> str:
    return Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].strip().split()[0]


def main() -> int:
    errors: list[str] = []
    source = PLUGIN.read_text()
    for required in (
        'pillClickAction: () => root.requestAction("primary")',
        'pillRightClickAction: () => root.requestAction("power")',
        "property string pendingAction",
        "Qt.callLater(root.flushPendingAction)",
        'if (action === "primary" && !root.primaryActionEligible()) return false',
        'return root.engineState === "running" || root.engineState === "paused"',
        'return root.requestAction("primary") ? "queued" : "ignored"',
    ):
        if required not in source:
            errors.append(f"DMS canonical pill path is missing: {required}")
    for forbidden in ("MouseArea {", "HoverHandler {", "DankTooltipV2 {"):
        if forbidden in source:
            errors.append(
                f"bar content must not own pointer/tooltip handling that can compete with DMS BasePill: {forbidden}"
            )
    request_block = source.split("function requestAction(action)", 1)[-1].split("function flushPendingAction()", 1)[0]
    guard = 'if (action === "primary" && !root.primaryActionEligible()) return false'
    assignment = "root.pendingAction = action"
    if (
        guard not in request_block
        or assignment not in request_block
        or request_block.index(guard) > request_block.index(assignment)
    ):
        errors.append("primary eligibility must be rejected at click time before the action is queued")

    with tempfile.TemporaryDirectory() as runtime_dir:
        runtime_root = Path(runtime_dir) / "wallpaper-engine-control"
        runtime_root.mkdir()
        (runtime_root / "power.json").mkdir()
        failure = subprocess.run(
            [str(CONTROL), "status", "--json"],
            check=False,
            capture_output=True,
            text=True,
            env={**os.environ, "XDG_RUNTIME_DIR": runtime_dir},
        )
        try:
            failure_payload = json.loads(failure.stdout)
        except json.JSONDecodeError:
            failure_payload = {}
        if failure.returncode != 3 or failure_payload.get("state") != "error":
            errors.append(
                "controller did not preserve its structured JSON contract for a wrong-type runtime state: "
                f"rc={failure.returncode}, stdout={failure.stdout!r}, stderr={failure.stderr!r}"
            )

    initial_code, initial, initial_stderr = invoke("status")
    if initial_code != 0 or initial.get("state") != "running":
        errors.append(f"precondition failed: status rc={initial_code}, payload={initial}, stderr={initial_stderr!r}")
        print("\n".join(f"FAIL: {error}" for error in errors))
        return 1

    initial_screens = initial.get("screens")
    pause_attempted = False
    try:
        click = invoke_pill_primary()
        pause_attempted = True
        if click.returncode != 0 or "queued" not in click.stdout:
            errors.append(
                f"live DMS primary callback failed: rc={click.returncode}, "
                f"stdout={click.stdout!r}, stderr={click.stderr!r}"
            )
        paused = wait_for_state("paused")
        if paused.get("state") != "paused":
            errors.append(f"live DMS primary callback did not pause: {paused}")
        else:
            if paused.get("screens") != initial_screens:
                errors.append(
                    f"pause changed the active output set: before={initial_screens}, after={paused.get('screens')}"
                )
            stopped = [
                int(pid)
                for pid in paused.get("pids", [])
                if Path(f"/proc/{pid}").exists() and process_state(int(pid)) in {"T", "t"}
            ]
            if stopped:
                errors.append(f"pause used unsafe process freezing for PIDs {stopped}")
            clients = helper_clients()
            if len(clients) != 1:
                errors.append(f"expected one native-pause helper window, found {len(clients)}")
            elif (
                clients[0].get("workspace", {}).get("name") != "special:eva-wallpaper-pause"
                or int(clients[0].get("fullscreen", 0)) == 0
            ):
                errors.append(f"native-pause helper is not hidden and fullscreen: {clients[0]}")

        click = invoke_pill_primary()
        if click.returncode != 0 or "queued" not in click.stdout:
            errors.append(f"second live DMS primary callback failed: {click.stderr!r}")
        resumed = wait_for_state("running")
        if resumed.get("state") != "running":
            errors.append(f"second live DMS primary callback did not resume: {resumed}")
    finally:
        if pause_attempted:
            invoke("resume")
        final = wait_for_state("running", timeout=3)
        if final.get("state") != "running" or helper_clients():
            errors.append(f"cleanup failed to leave rendering resumed: {final}")

    if errors:
        print("\n".join(f"FAIL: {error}" for error in errors))
        return 1

    print(
        "PASS: the live DMS whole-pill callback queues through status polling, toggles native "
        "pause/resume, and never SIGSTOPs renderers"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
