#!/usr/bin/python3
# Copyright (C) 2026 Qore Technologies, s.r.o.
# SPDX-License-Identifier: LGPL-2.1-or-later
"""Exercise manifest handling entirely inside a staged installation."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class UninstallTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="pdf uninstall ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.stage = self.root / "stage"
        self.stage.mkdir()
        template = Path(__file__).resolve().parents[1] / "cmake/cmake_uninstall.cmake.in"
        self.script = self.root / "uninstall.cmake"
        self.script.write_text(template.read_text().replace("@CMAKE_CURRENT_BINARY_DIR@", str(self.root)))

    def run_uninstall(self, entries=None):
        if entries is not None:
            (self.root / "install_manifest.txt").write_text("\n".join(entries) + "\n")
        return subprocess.run(["cmake", "-P", str(self.script)],
                              env=dict(os.environ, DESTDIR=str(self.stage)),
                              capture_output=True, text=True, check=False)

    def test_staged_files_spaces_and_symlinks(self):
        installed = self.stage / "usr/share/qore/with spaces.qm"
        installed.parent.mkdir(parents=True)
        installed.write_text("installed source")
        outside = self.root / "outside"
        outside.write_text("retain symlink target")
        link = installed.parent / "link.qm"
        link.symlink_to(outside)
        result = self.run_uninstall(["/usr/share/qore/with spaces.qm", "/usr/share/qore/link.qm",
                                     "/usr/share/qore/already-missing.qm"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(installed.exists())
        self.assertFalse(link.is_symlink())
        self.assertEqual(outside.read_text(), "retain symlink target")

    def test_missing_manifest_fails(self):
        result = self.run_uninstall()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Cannot find install manifest", result.stderr)

    def test_relative_path_fails_before_removal(self):
        installed = self.stage / "first"
        installed.write_text("retain")
        result = self.run_uninstall(["/first", "relative"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Refusing relative install path", result.stderr)
        self.assertEqual(installed.read_text(), "retain")

    def test_directory_fails_before_removal(self):
        installed = self.stage / "first"
        installed.write_text("retain")
        directory = self.stage / "directory"
        directory.mkdir()
        result = self.run_uninstall(["/first", "/directory"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Refusing directory", result.stderr)
        self.assertTrue(directory.is_dir())
        self.assertEqual(installed.read_text(), "retain")


if __name__ == "__main__":
    unittest.main()
