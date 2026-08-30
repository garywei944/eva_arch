#!/usr/bin/env python3
"""Regression tests for readiness-gated Wallpaper Engine login startup."""

from __future__ import annotations

import json
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path
from typing import Any

HOME = Path.home()
HELPER = HOME / ".local/bin/wallpaper-engine-login-start"
DESKTOP = HOME / ".config/autostart/wallpaper-engine-ready.desktop"
OLD_DESKTOP = HOME / ".config/autostart/Linux Wallpaper Engine.desktop"
SETTINGS = HOME / ".config/Linux Wallpaper Engine/settings.json"
EXPECTED_SCREENS = ["DP-1", "DP-2", "DP-3"]


def write_executable(path: Path, content: str) -> None:
    path.write_text(textwrap.dedent(content).lstrip())
    path.chmod(0o755)


class Fixture:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.runtime = root / "runtime"
        self.runtime.mkdir()
        (self.runtime / "wayland-test").touch()

        self.assets = root / "assets"
        self.assets.mkdir()
        self.wallpapers = root / "wallpapers"
        self.wallpapers.mkdir()
        for screen in EXPECTED_SCREENS:
            (self.wallpapers / screen).mkdir()

        self.active_config = root / "active-wallpapers.json"
        self.active_config.write_text(
            json.dumps(
                {
                    "activeWallpapers": {
                        screen: {
                            "backgroundId": str(self.wallpapers / screen),
                            "screen": screen,
                        }
                        for screen in EXPECTED_SCREENS
                    },
                    "activePlaylists": {screen: {"name": screen, "screen": screen} for screen in EXPECTED_SCREENS},
                }
            )
        )

        self.bin = root / "bin"
        self.bin.mkdir()
        self.hyprctl = self.bin / "hyprctl"
        write_executable(
            self.hyprctl,
            """
            #!/usr/bin/env python3
            import json
            import os

            screens = os.environ.get("FAKE_MONITORS", "DP-1,DP-2,DP-3").split(",")
            print(json.dumps([{"name": screen, "disabled": False} for screen in screens if screen]))
            """,
        )

        self.systemctl = self.bin / "systemctl"
        write_executable(
            self.systemctl,
            """
            #!/usr/bin/env python3
            import os
            import sys

            service = sys.argv[-1]
            inactive = {name for name in os.environ.get("FAKE_INACTIVE_AUDIO", "").split(",") if name}
            if service in inactive:
                print("inactive")
                raise SystemExit(3)
            print("active")
            """,
        )

        self.renderer = self.bin / "linux-wallpaperengine"
        write_executable(
            self.renderer,
            """
            #!/usr/bin/env python3
            import os
            import sys

            error = os.environ.get("FAKE_RENDERER_ERROR")
            if error:
                print(error, file=sys.stderr)
                raise SystemExit(127)
            print("Usage: linux-wallpaperengine [--help]")
            """,
        )

        self.control_log = root / "control-actions.jsonl"
        self.control_state = root / "control-state"
        self.control = self.bin / "wallpaper-engine-control"
        write_executable(
            self.control,
            """
            #!/usr/bin/env python3
            import json
            import os
            import sys
            from pathlib import Path

            action = sys.argv[1]
            log = Path(os.environ["FAKE_CONTROL_LOG"])
            with log.open("a") as handle:
                handle.write(json.dumps(action) + "\\n")

            state_path = Path(os.environ["FAKE_CONTROL_STATE"])
            attempt = int(state_path.read_text()) if state_path.exists() else 0
            screens = [screen for screen in os.environ["FAKE_EXPECTED_SCREENS"].split(",") if screen]

            if action == "start":
                state_path.write_text(str(attempt + 1))
                if os.environ.get("FAKE_FAIL_FIRST") == "1" and attempt == 0:
                    print(json.dumps({
                        "state": "idle",
                        "count": 0,
                        "screen_count": 0,
                        "screens": [],
                        "ux_running": True,
                        "error": "simulated first-start failure",
                    }))
                    sys.exit(3)
                print(json.dumps({
                    "state": "running",
                    "count": len(screens),
                    "screen_count": len(screens),
                    "screens": screens,
                    "running": len(screens),
                    "paused": 0,
                    "pids": list(range(100, 100 + len(screens))),
                    "ux_running": True,
                }))
                sys.exit(0)

            if action == "stop":
                print(json.dumps({
                    "state": "stopped",
                    "count": 0,
                    "screen_count": 0,
                    "screens": [],
                    "ux_running": False,
                }))
                sys.exit(0)

            raise SystemExit(2)
            """,
        )

    def environment(self, **updates: str) -> dict[str, str]:
        environment = os.environ.copy()
        environment.update(
            {
                "XDG_RUNTIME_DIR": str(self.runtime),
                "WAYLAND_DISPLAY": "wayland-test",
                "WALLPAPER_ENGINE_ACTIVE_CONFIG": str(self.active_config),
                "WALLPAPER_ENGINE_ASSETS_DIR": str(self.assets),
                "WALLPAPER_ENGINE_CONTROL": str(self.control),
                "WALLPAPER_ENGINE_HYPRCTL": str(self.hyprctl),
                "WALLPAPER_ENGINE_RENDERER": str(self.renderer),
                "WALLPAPER_ENGINE_SYSTEMCTL": str(self.systemctl),
                "WALLPAPER_ENGINE_READY_TIMEOUT": "0.2",
                "WALLPAPER_ENGINE_READY_POLL_INTERVAL": "0.01",
                "WALLPAPER_ENGINE_RETRY_DELAY": "0.01",
                "FAKE_CONTROL_LOG": str(self.control_log),
                "FAKE_CONTROL_STATE": str(self.control_state),
                "FAKE_EXPECTED_SCREENS": ",".join(EXPECTED_SCREENS),
            }
        )
        environment.update(updates)
        return environment

    def actions(self) -> list[str]:
        if not self.control_log.exists():
            return []
        return [json.loads(line) for line in self.control_log.read_text().splitlines()]


def invoke_helper(environment: dict[str, str], *arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(HELPER), *arguments],
        check=False,
        capture_output=True,
        text=True,
        env=environment,
        timeout=5,
    )


def parse_payload(result: subprocess.CompletedProcess[str]) -> dict[str, Any]:
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise AssertionError(f"invalid helper JSON: stdout={result.stdout!r}, stderr={result.stderr!r}") from error


class WallpaperEngineLoginStartTests(unittest.TestCase):
    def test_ready_check_reports_configured_outputs_without_starting(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(Path(directory))
            result = invoke_helper(fixture.environment(), "--check")
            payload = parse_payload(result)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(payload["ready"])
            self.assertEqual(payload["expected_screens"], EXPECTED_SCREENS)
            self.assertEqual(payload["missing_screens"], [])
            self.assertEqual(fixture.actions(), [])

    def test_check_fails_closed_when_one_output_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(Path(directory))
            result = invoke_helper(
                fixture.environment(FAKE_MONITORS="DP-1,DP-2"),
                "--check",
            )
            payload = parse_payload(result)

            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(payload["ready"])
            self.assertEqual(payload["missing_screens"], ["DP-3"])
            self.assertEqual(fixture.actions(), [])

    def test_check_fails_closed_until_every_audio_service_is_active(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(Path(directory))
            result = invoke_helper(
                fixture.environment(FAKE_INACTIVE_AUDIO="pipewire-pulse.service"),
                "--check",
            )
            payload = parse_payload(result)

            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(payload["ready"])
            self.assertFalse(payload["audio_ready"])
            self.assertEqual(payload["audio_services"]["pipewire-pulse.service"], "inactive")
            self.assertEqual(fixture.actions(), [])

    def test_check_fails_closed_when_renderer_cannot_load(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(Path(directory))
            result = invoke_helper(
                fixture.environment(
                    FAKE_RENDERER_ERROR=(
                        "error while loading shared libraries: " "libcdio.so.19: cannot open shared object file"
                    )
                ),
                "--check",
            )
            payload = parse_payload(result)

            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(payload["ready"])
            self.assertFalse(payload["renderer_ready"])
            self.assertIn("libcdio.so.19", payload["renderer_error"])
            self.assertEqual(fixture.actions(), [])

    def test_login_start_uses_one_bounded_safe_retry(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(Path(directory))
            result = invoke_helper(fixture.environment(FAKE_FAIL_FIRST="1"))
            payload = parse_payload(result)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(payload["state"], "running")
            self.assertEqual(payload["attempts"], 2)
            self.assertEqual(payload["screens"], EXPECTED_SCREENS)
            self.assertEqual(fixture.actions(), ["start", "stop", "start"])

    def test_login_start_times_out_without_touching_the_controller(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(Path(directory))
            result = invoke_helper(
                fixture.environment(FAKE_MONITORS="DP-1"),
            )
            payload = parse_payload(result)

            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(payload["state"], "error")
            self.assertEqual(payload["step"], "readiness")
            self.assertEqual(fixture.actions(), [])

    def test_invalid_numeric_overrides_fail_with_one_json_payload(self) -> None:
        bad_values = ("not-a-number", "-1", "nan", "inf")
        for value in bad_values:
            with self.subTest(value=value), tempfile.TemporaryDirectory() as directory:
                fixture = Fixture(Path(directory))
                result = invoke_helper(fixture.environment(WALLPAPER_ENGINE_READY_TIMEOUT=value))
                payload = parse_payload(result)

                self.assertEqual(result.returncode, 3)
                self.assertEqual(payload["state"], "error")
                self.assertEqual(payload["step"], "setup")
                self.assertIn("WALLPAPER_ENGINE_READY_TIMEOUT", payload["error"])
                self.assertEqual(fixture.actions(), [])

    def test_owned_autostart_replaces_the_generated_entry(self) -> None:
        desktop = DESKTOP.read_text()
        settings = json.loads(SETTINGS.read_text())

        self.assertIn("Type=Application", desktop)
        self.assertIn(f"TryExec={HELPER}", desktop)
        self.assertIn(f"Exec={HELPER}", desktop)
        self.assertFalse(settings["launchOnLogin"])
        self.assertFalse(OLD_DESKTOP.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
