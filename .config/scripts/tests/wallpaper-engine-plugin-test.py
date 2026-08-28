#!/usr/bin/env python3
"""Packaging and ownership regressions for the DMS Wallpaper Engine plugin."""

from __future__ import annotations

import re
import unittest
from pathlib import Path

PLUGIN = Path.home() / ".config/DankMaterialShell/plugins/wallpaperEngineControl"
VIEW = PLUGIN / "WallpaperEngineControl.qml"
SERVICE = PLUGIN / "WallpaperEngineControlService.qml"
QMLDIR = PLUGIN / "qmldir"


class SharedControllerTests(unittest.TestCase):
    def test_exactly_one_singleton_owns_global_controller_state(self) -> None:
        self.assertTrue(SERVICE.is_file(), "shared controller singleton is missing")
        self.assertTrue(QMLDIR.is_file(), "plugin qmldir is missing")
        service = SERVICE.read_text()
        view = VIEW.read_text()
        qmldir = QMLDIR.read_text()

        self.assertRegex(service, r"(?m)^pragma Singleton$")
        self.assertIn("singleton WallpaperEngineControlService 1.0 WallpaperEngineControlService.qml", qmldir)
        self.assertEqual(service.count("IpcHandler {"), 1)
        self.assertEqual(service.count("Process {"), 1)
        self.assertEqual(service.count("Timer {"), 1)
        self.assertNotIn("IpcHandler {", view)
        self.assertNotIn("Process {", view)
        self.assertNotIn("Timer {", view)
        self.assertIn("WallpaperEngineControlService", view)

    def test_intents_are_revalidated_and_global_next_uses_the_capability_gate(self) -> None:
        service = SERVICE.read_text()
        self.assertIn('intent === "next"', service)
        self.assertRegex(
            service,
            re.compile(r'intent === "next"[^\n]*engineState === "running"[^\n]*nextSupported', re.MULTILINE),
        )
        self.assertIn("currentIntent", service)
        self.assertIn("resolveIntent(intent)", service)
        self.assertIn("requestIntent", service)

    def test_busy_and_keyboard_accessibility_are_visible(self) -> None:
        view = VIEW.read_text()
        self.assertIn("activeFocusOnTab: enabled", view)
        self.assertIn("Accessible.role: Accessible.Button", view)
        self.assertIn("Keys.onPressed", view)
        self.assertRegex(view, r"enabled:\s*[^\n]*!root\.busy")
        self.assertIn("actionSentence", view)


if __name__ == "__main__":
    unittest.main(verbosity=2)
