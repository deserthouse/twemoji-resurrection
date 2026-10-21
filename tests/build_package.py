"""Build the distributable module zip and gate release consistency.

Usage:
  tests/.venv/Scripts/python.exe tests/build_package.py [--out PATH]

Gates (all must pass before a zip is written; run before every release):
  * module.prop versionCode == update.json versionCode == build in the
    module.prop version string ("vX.Y.Z (N)")
  * update.json version string == module.prop version string
  * install.sh banner shows the same "vX.Y.Z (N)"
  * newest changelog.md build heading ("## vX.Y.Z · build N") matches
  * zipUrl asset filename in update.json matches the produced zip filename
    (the asset URL is a contract — renaming breaks every updater)
  * builds >= 60: immutable release identity — the asset name embeds the build
    number and zipUrl points at this build's own tag
    twemoji-<fontver>-build.<N> (approved 2026-10-21; legacy builds < 60 keep
    the rolling v17.0.3 URL so installed updaters never break)
  * zip contains exactly the git-tracked files under module/, '/'-separated

Build 58 shipped with versionCode 57 while update.json advertised 58 — every
user got an endless update prompt. This gate exists so that cannot recur.
"""
import argparse
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOD = ROOT / "module"


def fail(msg):
    print(f"GATE FAIL: {msg}")
    sys.exit(1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", help="output zip path (default: tests/.build/<zipUrl basename>)")
    args = ap.parse_args()

    prop = (MOD / "module.prop").read_text(encoding="utf-8")
    version = re.search(r"^version=(.+)$", prop, re.M).group(1).strip()
    vc_prop = int(re.search(r"^versionCode=(\d+)$", prop, re.M).group(1))
    upd = json.loads((MOD / "update.json").read_text(encoding="utf-8"))
    banner = re.search(r"Twemoji Resurrection (v[\d.]+ \((\d+)\))",
                       (MOD / "install.sh").read_text(encoding="utf-8"))
    head = re.search(r"^## (v[\d.]+) · build (\d+)",
                     (MOD / "changelog.md").read_text(encoding="utf-8"), re.M)

    m = re.fullmatch(r"(v[\d.]+) \((\d+)\)", version)
    if not m:
        fail(f'module.prop version is not "vX.Y.Z (N)": {version!r}')
    ver_num, ver_build = m.group(1), int(m.group(2))
    if not (vc_prop == int(upd["versionCode"]) == ver_build):
        fail(f"versionCode disagrees: module.prop={vc_prop} "
             f'update.json={upd["versionCode"]} version-build={ver_build}')
    if upd["version"] != version:
        fail(f'update.json version {upd["version"]!r} != module.prop {version!r}')
    if not banner or banner.group(1) != version:
        fail(f"install.sh banner does not show {version!r}")
    if not head or head.group(1) != ver_num or int(head.group(2)) != ver_build:
        fail(f"changelog.md top build heading does not show {ver_num} build {ver_build}")
    zip_name = Path(upd["zipUrl"]).name
    if ver_build < 60:
        expected_name = f"Twemoji-Resurrection-{ver_num.lstrip('v')}-ksu.zip"
        if zip_name != expected_name:
            fail(f"zipUrl asset name {zip_name!r} != expected {expected_name!r}")
    else:
        expected_name = f"Twemoji-Resurrection-{ver_num.lstrip('v')}-build.{ver_build}-ksu.zip"
        if zip_name != expected_name:
            fail(f"zipUrl asset name {zip_name!r} != immutable-build name {expected_name!r}")
        tag = f"twemoji-{ver_num.lstrip('v')}-build.{ver_build}"
        if f"/download/{tag}/" not in upd["zipUrl"]:
            fail(f"zipUrl must point at this build's own immutable tag {tag!r}: {upd['zipUrl']!r}")

    tracked = sorted(subprocess.check_output(
        ["git", "-C", str(MOD), "ls-files", "-z"]).decode().strip("\0").split("\0"))
    out = Path(args.out) if args.out else (ROOT / "tests" / ".build" / zip_name)
    if out.name != zip_name:
        fail(f"output name {out.name!r} != zipUrl asset {zip_name!r}")
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for name in tracked:  # zipfile writes '/' separators on every platform
            z.write(MOD / name, name)
    with zipfile.ZipFile(out) as z:
        assert z.testzip() is None, "CRC error in produced zip"
        assert z.namelist() == tracked, "zip contents != tracked files"

    print(f"GATE PASS: {version} versionCode={vc_prop} files={len(tracked)}")
    print(f"zip: {out}")


if __name__ == "__main__":
    main()
