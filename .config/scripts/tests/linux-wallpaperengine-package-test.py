#!/usr/bin/env python3
"""Static package regressions for the pinned linux-wallpaperengine build."""

from __future__ import annotations

import hashlib
import re
import unittest
from pathlib import Path

PACKAGE = Path.home() / ".config/linux-wallpaperengine-pkg"
PATCH = PACKAGE / "0002-sigusr1-advance-playlist.patch"
PKGBUILD = PACKAGE / "PKGBUILD"


class SignalPatchTests(unittest.TestCase):
    def test_sigusr1_is_blocked_before_application_construction_and_unblocked_after_handler(self) -> None:
        patch = PATCH.read_text()
        blocked = patch.index("pthread_sigmask (SIG_BLOCK")
        handler = patch.index("std::signal (SIGUSR1, signalhandler)")
        unblocked = patch.index("pthread_sigmask (SIG_UNBLOCK")
        self.assertLess(blocked, handler)
        self.assertLess(handler, unblocked)
        self.assertIn("static_assert(std::atomic<bool>::is_always_lock_free)", patch)

    def test_recipe_pins_cef_and_every_local_patch(self) -> None:
        recipe = PKGBUILD.read_text()
        self.assertIn("_cef_version='135.0.17+gcbc1c5b+chromium-135.0.7049.52'", recipe)
        self.assertIn('"${_cef_archive}::https://cef-builds.spotifycdn.com/${_cef_archive}"', recipe)
        self.assertIn('cp "$srcdir/${_cef_archive}" "build/cef/${_cef_archive}"', recipe)

        sums_match = re.search(r"sha256sums=\((.*?)\)\n", recipe, re.DOTALL)
        if sums_match is None:
            self.fail("PKGBUILD sha256sums array is missing")
        sums = re.findall(r"'([0-9a-f]{64}|SKIP)'", sums_match.group(1))
        self.assertGreaterEqual(len(sums), 4)
        self.assertNotEqual(sums[-1], "SKIP", "CEF payload must have a fixed SHA-256")
        for filename, expected in zip(
            ("0001-disable-unsafe-script-album-art-callback.patch", "0002-sigusr1-advance-playlist.patch"),
            sums[1:3],
            strict=True,
        ):
            actual = hashlib.sha256((PACKAGE / filename).read_bytes()).hexdigest()
            self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main(verbosity=2)
