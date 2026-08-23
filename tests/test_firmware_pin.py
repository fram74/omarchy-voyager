#!/usr/bin/env python3
"""Firmware pinning / digest checks for voyager-layout (no USB, no network)."""

from __future__ import annotations

import importlib.machinery
import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
_LOADER = importlib.machinery.SourceFileLoader(
    "voyager_layout", str(ROOT / "bin" / "voyager-layout")
)
_SPEC = importlib.util.spec_from_loader(_LOADER.name, _LOADER)
assert _SPEC and _SPEC.loader
vl = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(vl)


class ParseTests(unittest.TestCase):
    def test_parse_oryx_url_latest(self) -> None:
        layout_id, revision = vl.parse_oryx_url(
            "https://configure.zsa.io/voyager/layouts/xPOwx/latest"
        )
        self.assertEqual(layout_id, "xPOwx")
        self.assertIsNone(revision)

    def test_parse_oryx_url_revision(self) -> None:
        layout_id, revision = vl.parse_oryx_url(
            "https://configure.zsa.io/voyager/layouts/xPOwx/abc123def"
        )
        self.assertEqual(layout_id, "xPOwx")
        self.assertEqual(revision, "abc123def")

    def test_parse_oryx_url_rejects_other_geometry(self) -> None:
        with self.assertRaises(SystemExit):
            vl.parse_oryx_url(
                "https://configure.zsa.io/moonlander/layouts/xPOwx/latest"
            )

    def test_sha256_normalizes(self) -> None:
        digest = "A" * 64
        self.assertEqual(vl.parse_sha256(digest), "a" * 64)

    def test_sha256_rejects_short(self) -> None:
        with self.assertRaises(SystemExit):
            vl.parse_sha256("abc")

    def test_download_refuses_latest_revision_id(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp) / "fw.bin"
            with self.assertRaises(SystemExit):
                vl.download_firmware_bytes("latest", dest)

    def test_latest_revision_url_for_stock_default(self) -> None:
        self.assertEqual(
            vl.latest_revision_url("default"),
            "https://oryx.zsa.io/firmware/latest/voyager/default",
        )
        self.assertNotEqual(
            vl.latest_revision_url("default"),
            "https://oryx.zsa.io/firmware/latest/default",
        )
        self.assertEqual(
            vl.latest_revision_url("4RbWm"),
            "https://oryx.zsa.io/firmware/latest/4RbWm",
        )
        self.assertEqual(
            vl.parse_oryx_geometry(
                "https://configure.zsa.io/voyager/layouts/default/latest/0"
            ),
            "voyager",
        )

    def test_oryx_url_allowlist(self) -> None:
        vl.assert_oryx_api_url("https://oryx.zsa.io/firmware/abc123")
        vl.assert_oryx_api_url("https://oryx.zsa.io/graphql")
        with self.assertRaises(SystemExit):
            vl.assert_oryx_api_url("http://oryx.zsa.io/firmware/abc123")
        with self.assertRaises(SystemExit):
            vl.assert_oryx_api_url("https://evil.example/firmware/abc123")
        with self.assertRaises(SystemExit):
            vl.assert_oryx_api_url("https://oryx.zsa.io/etc/passwd")


class LocalFilePinTests(unittest.TestCase):
    def _firmware(self, directory: Path, payload: bytes | None = None) -> Path:
        path = directory / "layout.bin"
        data = payload if payload is not None else (b"\x00" * vl.MIN_FIRMWARE_BYTES)
        path.write_bytes(data)
        return path

    def test_pin_and_verify_local_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = self._firmware(Path(tmp))
            layout = {"id": "daily", "file": str(path)}
            vl.pin_layout(layout)
            self.assertEqual(layout["sha256"], vl.sha256_file(path))
            verified = vl.verified_firmware_file(layout)
            self.assertEqual(verified, path)

    def test_flash_refuses_unpinned_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = self._firmware(Path(tmp))
            layout = {"id": "daily", "file": str(path)}
            with self.assertRaises(SystemExit):
                vl.verified_firmware_file(layout)

    def test_flash_refuses_digest_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = self._firmware(Path(tmp))
            layout = {
                "id": "daily",
                "file": str(path),
                "sha256": "0" * 64,
            }
            with self.assertRaises(SystemExit):
                vl.verified_firmware_file(layout)

    def test_expected_sha256_must_match_on_pin(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = self._firmware(Path(tmp))
            layout = {"id": "daily", "file": str(path)}
            with self.assertRaises(SystemExit):
                vl.pin_layout(layout, expected_sha256="0" * 64)
            vl.pin_layout(layout, expected_sha256=vl.sha256_file(path))
            self.assertTrue(vl.layout_is_pinned(layout))

    def test_tiny_file_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tiny.bin"
            path.write_bytes(b"too-small")
            layout = {"id": "daily", "file": str(path)}
            with self.assertRaises(SystemExit):
                vl.pin_layout(layout)

    def test_load_config_rejects_unsafe_id(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "layouts.toml"
            path.write_text(
                '[settings]\nnotify = true\n\n[[layouts]]\nid = "daily;rm"\nname = "x"\n',
                encoding="utf-8",
            )
            previous = vl.CONFIG_PATH
            vl.CONFIG_PATH = path
            try:
                with self.assertRaises(SystemExit):
                    vl.load_config()
            finally:
                vl.CONFIG_PATH = previous


if __name__ == "__main__":
    unittest.main()
