#!/usr/bin/env python3
"""Build the GitHub Pages console manifest from exact firmware assets.

No synthesis or FPGA programming. Binaries must already be downloaded from
published, reviewed GitHub Releases. The output only declares a profile
remotely available when file size + SHA-256 match the pinned profile.
"""
import argparse
import datetime as dt
import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPECTED_IDS = {"pong", "breakout", "kblocks", "lightcycles", "spacepatrol", "mazechase", "minitd"}
BASELINE = {"pong", "breakout"}

def validate_catalog(profiles):
    catalog = json.loads((ROOT / "catalog" / "games.json").read_text("utf-8"))
    by_id = {x["id"]: x for x in catalog["games"]}
    names = {"pong": "pikosol-pong-rgb-v1-2", "breakout": "konsol-breakout-rgb-v0-1-0"}
    for key, catalog_id in names.items():
        p = profiles[key]
        q = by_id[catalog_id]["distribution"]
        if (p["sha256"] != q["sha256"].lower() or
                p["filename"] != q["file"] or
                p["size_bytes"] != q["size_bytes"] or
                p["release_url"] != q["release_url"]):
            raise ValueError(f"CONSOLE_CATALOG_MISMATCH: {key}")


def build(site, require_baseline):
    profile_file = ROOT / "docs" / "console" / "profiles.json"
    config = json.loads(profile_file.read_text("utf-8"))
    assert config["schema_version"] == 1
    entries = config["profiles"]
    profiles = {p["id"]: p for p in entries}
    if set(profiles) != EXPECTED_IDS or len(entries) != 7:
        raise ValueError("Expected exactly pong, breakout, kblocks, lightcycles, spacepatrol, mazechase, minitd profiles")
    validate_catalog(profiles)
    fw_dir = site / "console" / "firmware"
    fw_dir.mkdir(parents=True, exist_ok=True)
    result = {"schema_version": 1, "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "board": "tangnano9k", "programming": "volatile SRAM only", "profiles": []}
    for p in entries:
        filename = p["filename"]
        if pathlib.PurePath(filename).name != filename or not filename.endswith(".fs"):
            raise ValueError("Unsafe filename in profile")
        sha = p["sha256"]
        if len(sha) != 64 or any(c not in "0123456789abcdef" for c in sha):
            raise ValueError("Malformed SHA-256")
        binary = fw_dir / filename
        published = binary.is_file()
        if published:
            size = binary.stat().st_size
            if size != p["size_bytes"]:
                raise ValueError(f"CONSOLE_SIZE_FAIL {p['id']}: {size} != {p['size_bytes']}")
            digest = hashlib.sha256(binary.read_bytes()).hexdigest()
            if digest != sha:
                raise ValueError(f"CONSOLE_SHA256_FAIL {p['id']}: {digest} != {sha}")
        elif require_baseline and p["id"] in BASELINE:
            raise ValueError(f"CONSOLE_BASELINE_MISSING: {p['id']}")
        result["profiles"].append({
            "id": p["id"], "filename": filename, "sha256": sha,
            "size_bytes": p["size_bytes"], "published": published
        })
        print(f"CONSOLE_PROFILE_{p['id'].upper()}={'REMOTE_READY' if published else 'LOCAL_ONLY'} {sha}")
    known = {x["filename"] for x in entries}
    extra = sorted(x.name for x in fw_dir.glob("*.fs") if x.name not in known)
    if extra:
        raise ValueError(f"Unexpected firmware assets not in pinned profiles: {extra}")
    (fw_dir / "manifest.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", "utf-8")
    print(f"CONSOLE_MANIFEST_PASS {fw_dir / 'manifest.json'}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--site", type=pathlib.Path, required=True)
    ap.add_argument("--require-baseline", action="store_true")
    args = ap.parse_args()
    try:
        build(args.site, args.require_baseline)
    except (AssertionError, ValueError, OSError, KeyError) as exc:
        sys.exit(f"CONSOLE_BUILD_FAIL: {exc}")
