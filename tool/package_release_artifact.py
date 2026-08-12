#!/usr/bin/env python3
"""Package one ASTRO LOGIC platform build with release evidence.

The script does not perform code signing. It copies/archives an already-built
artifact, hashes it and the required CI evidence, and writes a platform manifest.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def version() -> str:
    text = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    m = re.search(r"^version:\s*([^\s]+)", text, re.M)
    if not m:
        raise RuntimeError("pubspec version is missing")
    return m.group(1)


def nonempty(path: Path, label: str) -> None:
    if not path.exists() or not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError(f"Missing/empty {label}: {path}")


def zip_directory(source: Path, destination: Path) -> list[dict]:
    inventory: list[dict] = []
    files = sorted(p for p in source.rglob("*") if p.is_file())
    if not files:
        raise RuntimeError(f"Windows release directory is empty: {source}")
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in files:
            rel = path.relative_to(source).as_posix()
            data = path.read_bytes()
            info = zipfile.ZipInfo(rel)
            info.date_time = (1980, 1, 1, 0, 0, 0)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            zf.writestr(info, data)
            inventory.append({"path": rel, "size": len(data), "sha256": hashlib.sha256(data).hexdigest()})
    return inventory


def copy_evidence(src: Path, evidence_dir: Path, name: str) -> dict:
    nonempty(src, name)
    dst = evidence_dir / name
    shutil.copy2(src, dst)
    return {"file": f"evidence/{name}", "size": dst.stat().st_size, "sha256": sha256_file(dst)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", choices=["android", "windows"], required=True)
    parser.add_argument("--input-file")
    parser.add_argument("--input-dir")
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--analyze-log", required=True)
    parser.add_argument("--test-log", required=True)
    parser.add_argument("--native-log", required=True)
    parser.add_argument("--dependency-graph", required=True)
    parser.add_argument("--lock-file", default="pubspec.lock")
    parser.add_argument("--release-tag", default="")
    parser.add_argument("--source-commit", default="")
    parser.add_argument("--run-id", default="")
    args = parser.parse_args()

    app_version = version()
    expected_tag = f"v{app_version}"
    if args.release_tag and args.release_tag != expected_tag:
        raise RuntimeError(f"Release tag mismatch: expected {expected_tag}, got {args.release_tag}")

    out = Path(args.output_dir)
    if not out.is_absolute():
        out = ROOT / out
    out.mkdir(parents=True, exist_ok=True)
    evidence_dir = out / "evidence"
    evidence_dir.mkdir(exist_ok=True)

    lock_path = Path(args.lock_file)
    if not lock_path.is_absolute():
        lock_path = ROOT / lock_path
    nonempty(lock_path, "pubspec.lock")

    platform_label = "Android" if args.platform == "android" else "Windows"
    inventory: list[dict] = []

    if args.platform == "android":
        if not args.input_file:
            raise RuntimeError("--input-file is required for Android")
        source = Path(args.input_file)
        if not source.is_absolute():
            source = ROOT / source
        nonempty(source, "Android APK")
        artifact_name = f"ASTRO_LOGIC_Android_v{app_version}.apk"
        artifact = out / artifact_name
        shutil.copy2(source, artifact)
    else:
        if not args.input_dir:
            raise RuntimeError("--input-dir is required for Windows")
        source_dir = Path(args.input_dir)
        if not source_dir.is_absolute():
            source_dir = ROOT / source_dir
        if not source_dir.exists() or not source_dir.is_dir():
            raise RuntimeError(f"Windows release directory missing: {source_dir}")
        dlls = list(source_dir.rglob("astro_logic_astronomy.dll"))
        if not dlls:
            raise RuntimeError("astro_logic_astronomy.dll is missing from Windows release bundle")
        artifact_name = f"ASTRO_LOGIC_Windows_v{app_version}.zip"
        artifact = out / artifact_name
        inventory = zip_directory(source_dir, artifact)

    evidence = []
    evidence.append(copy_evidence(Path(args.analyze_log), evidence_dir, "flutter_analyze.log"))
    evidence.append(copy_evidence(Path(args.test_log), evidence_dir, "flutter_test.log"))
    evidence.append(copy_evidence(Path(args.native_log), evidence_dir, "native_verification.log"))
    evidence.append(copy_evidence(Path(args.dependency_graph), evidence_dir, "DEPENDENCY_GRAPH.txt"))
    evidence.append(copy_evidence(lock_path, evidence_dir, "pubspec.lock"))

    artifact_hash = sha256_file(artifact)
    lock_hash = sha256_file(lock_path)
    manifest = {
        "contract": "astro-logic-platform-release-evidence-v1",
        "platform": args.platform,
        "appVersion": app_version,
        "expectedReleaseTag": expected_tag,
        "releaseTag": args.release_tag or None,
        "channel": "release" if args.release_tag else "ci",
        "sourceCommit": args.source_commit or os.environ.get("GITHUB_SHA") or None,
        "workflowRunId": args.run_id or os.environ.get("GITHUB_RUN_ID") or None,
        "flutterVersion": "3.44.7",
        "ephemerisBackend": "astronomy-engine",
        "artifact": {
            "file": artifact.name,
            "size": artifact.stat().st_size,
            "sha256": artifact_hash,
        },
        "windowsBundleInventory": inventory if args.platform == "windows" else None,
        "pubspecLockSha256": lock_hash,
        "evidence": evidence,
        "releaseEligible": bool(args.release_tag),
        "codeSigningClaimed": False,
        "notes": "Evidence manifest binds CI outputs; it is not a PKI/code-signing signature.",
    }
    manifest_name = f"ASTRO_LOGIC_{platform_label}_v{app_version}_RELEASE_MANIFEST.json"
    manifest_path = out / manifest_name
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    sums = out / "SHA256SUMS.txt"
    sums.write_text(
        f"{artifact_hash}  {artifact.name}\n{sha256_file(manifest_path)}  {manifest_path.name}\n",
        encoding="utf-8",
    )
    print(json.dumps({"artifact": str(artifact), "manifest": str(manifest_path), "sha256": artifact_hash}, indent=2))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
