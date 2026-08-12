#!/usr/bin/env python3
"""Assemble qualified Android + Windows ASTRO LOGIC evidence into one bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def load_manifest(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("contract") != "astro-logic-platform-release-evidence-v1":
        raise RuntimeError(f"Unsupported manifest contract: {path}")
    return data


def verify_platform(manifest_path: Path, data: dict) -> Path:
    artifact = manifest_path.parent / data["artifact"]["file"]
    if not artifact.exists():
        raise RuntimeError(f"Artifact missing next to manifest: {artifact}")
    actual = sha256_file(artifact)
    if actual != data["artifact"]["sha256"]:
        raise RuntimeError(f"Artifact hash mismatch: {artifact}")
    for ev in data.get("evidence", []):
        p = manifest_path.parent / ev["file"]
        if not p.exists() or sha256_file(p) != ev["sha256"]:
            raise RuntimeError(f"Evidence hash mismatch: {p}")
    if not data.get("releaseEligible") or not data.get("releaseTag"):
        raise RuntimeError(f"Manifest is CI-only, not release-qualified: {manifest_path}")
    return artifact


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--android-manifest", required=True)
    parser.add_argument("--windows-manifest", required=True)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()

    android_path = Path(args.android_manifest).resolve()
    windows_path = Path(args.windows_manifest).resolve()
    android = load_manifest(android_path)
    windows = load_manifest(windows_path)

    if android.get("platform") != "android" or windows.get("platform") != "windows":
        raise RuntimeError("Platform manifests were supplied in the wrong slots")

    shared_fields = ["appVersion", "releaseTag", "sourceCommit", "pubspecLockSha256", "flutterVersion", "ephemerisBackend"]
    mismatches = [field for field in shared_fields if android.get(field) != windows.get(field)]
    if mismatches:
        raise RuntimeError(f"Android/Windows release evidence mismatch: {', '.join(mismatches)}")

    android_artifact = verify_platform(android_path, android)
    windows_artifact = verify_platform(windows_path, windows)

    out = Path(args.output_dir).resolve()
    out.mkdir(parents=True, exist_ok=True)
    copied_android = out / android_artifact.name
    copied_windows = out / windows_artifact.name
    shutil.copy2(android_artifact, copied_android)
    shutil.copy2(windows_artifact, copied_windows)

    version = android["appVersion"]
    final = {
        "contract": "astro-logic-final-release-bundle-v1",
        "appVersion": version,
        "releaseTag": android["releaseTag"],
        "sourceCommit": android.get("sourceCommit"),
        "flutterVersion": android["flutterVersion"],
        "pubspecLockSha256": android["pubspecLockSha256"],
        "ephemerisBackend": android["ephemerisBackend"],
        "platformArtifacts": [
            {"platform": "android", "file": copied_android.name, "sha256": sha256_file(copied_android)},
            {"platform": "windows", "file": copied_windows.name, "sha256": sha256_file(copied_windows)},
        ],
        "sourceManifests": [
            {"platform": "android", "sha256": sha256_file(android_path)},
            {"platform": "windows", "sha256": sha256_file(windows_path)},
        ],
        "releaseGate": "Both platform manifests must share version/tag/commit/lock/toolchain/backend and verify all evidence hashes.",
        "codeSigningClaimed": False,
    }
    manifest = out / f"ASTRO_LOGIC_v{version}_FINAL_RELEASE_MANIFEST.json"
    manifest.write_text(json.dumps(final, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    sums = out / "SHA256SUMS.txt"
    lines = [
        f"{sha256_file(copied_android)}  {copied_android.name}",
        f"{sha256_file(copied_windows)}  {copied_windows.name}",
        f"{sha256_file(manifest)}  {manifest.name}",
    ]
    sums.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({"manifest": str(manifest), "sha256s": str(sums)}, indent=2))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
