#!/usr/bin/env python3
"""No-hardware regression for the browser console configuration."""
import pathlib
import json
import tempfile
import subprocess

root = pathlib.Path(__file__).resolve().parents[1]
profiles = json.loads((root / "docs/console/profiles.json").read_text("utf-8"))["profiles"]
assert [p["id"] for p in profiles] == ["pong", "breakout", "kblocks"]
assert all(p["size_bytes"] == 2070601 for p in profiles)
assert len({p["sha256"] for p in profiles}) == 3
app = (root / "docs/console/app.js").read_text("utf-8")
assert "FIXED_PROGRAM_ARGS" in app
assert '["-c", "ft2232", "-b", "tangnano9k", "game.fs"]' in app
assert 'crypto.subtle.digest("SHA-256", buffer)' in app
assert 'navigator.usb.requestDevice' in app
assert 'navigator.serial.requestPort' in app
assert '!window.crossOriginIsolated' in app
assert 'openFPGALoader' in app
assert 'loaded.profileId !== current.id' in app
assert not any(flag in app for flag in ['"--flash"', '"--erase"', '"-f"', "--write-flash"])
html = (root / "docs/console/index.html").read_text("utf-8")
for uid in ["game-grid", "selected-game", "download-button", "connect-jtag", "program-button", "gamepad", "connect-serial", "log"]:
    assert f'id="{uid}"' in html, uid
with tempfile.TemporaryDirectory() as d:
    page = pathlib.Path(d)
    (page / "console/firmware").mkdir(parents=True)
    result = subprocess.run(["python3", str(root / "tools/build_console_site.py"), "--site", str(page)], capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr
    x = json.loads((page / "console/firmware/manifest.json").read_text("utf-8"))
    assert len(x["profiles"]) == 3
    assert not any(p["published"] for p in x["profiles"])
print("KONSOL_CONSOLE_STATIC_TEST_PASS: profiles=3, pinned-hash-only, SRAM-only, both browser transports")
