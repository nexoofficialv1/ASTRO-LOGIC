#!/usr/bin/env python3
"""ASTRO LOGIC final release source-contract gate.

This gate is intentionally usable before Flutter is installed. It validates the
release metadata contract and can optionally enforce the committed dependency
lock and full product-scope completion required for a commercial release tag.
It does not claim that Flutter compilation or tests passed.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def item(code: str, passed: bool, detail: str, *, blocking: bool = True) -> dict:
    return {"code": code, "passed": passed, "blocking": blocking, "detail": detail}


def pubspec_version() -> str:
    m = re.search(r"^version:\s*([^\s]+)", read("pubspec.yaml"), re.M)
    return m.group(1) if m else ""


def changelog_version() -> str:
    m = re.search(r"^##\s+([^\s]+)", read("CHANGELOG.md"), re.M)
    return m.group(1) if m else ""


def coming_soon_modules() -> list[str]:
    text = read("lib/src/models/astro_module.dart")
    pending: list[str] = []
    token = "AstroModule("
    cursor = 0
    while True:
        start = text.find(token, cursor)
        if start < 0:
            break
        i = start + len("AstroModule")
        depth = 0
        quote = None
        escaped = False
        end = len(text)
        while i < len(text):
            ch = text[i]
            if quote is not None:
                if escaped:
                    escaped = False
                elif ch == "\\":
                    escaped = True
                elif ch == quote:
                    quote = None
            else:
                if ch in {"'", '"'}:
                    quote = ch
                elif ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        end = i + 1
                        break
            i += 1
        block = text[start:end]
        if "AstroModuleAvailability.comingSoon" in block:
            key = re.search(r"copyKey:\s*'([^']+)'", block)
            if key:
                pending.append(key.group(1))
        cursor = max(end, start + len(token))
    return pending


def lock_ignored() -> bool:
    gitignore = read(".gitignore")
    for raw in gitignore.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line in {"pubspec.lock", "/pubspec.lock"}:
            return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", default="build/release/FINAL_RELEASE_SOURCE_GATE.json")
    parser.add_argument("--require-lock", action="store_true")
    parser.add_argument("--require-full-scope", action="store_true")
    parser.add_argument("--tag", default="")
    args = parser.parse_args()

    version = pubspec_version()
    change = changelog_version()
    expected_tag = f"v{version}" if version else ""
    lock = ROOT / "pubspec.lock"
    pending = coming_soon_modules()

    checks: list[dict] = []
    checks.append(item(
        "VERSION_ALIGNMENT",
        bool(version) and version == change,
        f"pubspec={version or 'missing'}, changelog={change or 'missing'}",
    ))
    checks.append(item(
        "RELEASE_TAG_MATCH",
        not args.tag or args.tag == expected_tag,
        f"expected={expected_tag or 'missing'}, supplied={args.tag or 'not supplied'}",
    ))
    checks.append(item(
        "LOCKFILE_COMMITTABLE",
        not lock_ignored(),
        "pubspec.lock is not ignored and can be committed for release qualification."
        if not lock_ignored()
        else "pubspec.lock is still ignored by .gitignore.",
    ))
    checks.append(item(
        "LOCKFILE_PRESENT",
        lock.exists() if args.require_lock else True,
        (
            f"pubspec.lock present sha256={sha256_file(lock)}"
            if lock.exists()
            else "pubspec.lock absent; allowed for source-preparation, forbidden when --require-lock is set."
        ),
    ))

    required_release_files = [
        "RELEASE_GATE.md",
        "tool/final_release_gate.py",
        "tool/package_release_artifact.py",
        "tool/assemble_release_bundle.py",
        ".github/workflows/release-source-gate.yml",
        ".github/workflows/android-apk.yml",
        ".github/workflows/windows-desktop.yml",
    ]
    missing = [p for p in required_release_files if not (ROOT / p).exists()]
    checks.append(item(
        "RELEASE_CONTRACT_FILES",
        not missing,
        "Release gate scripts/workflows are present." if not missing else f"Missing: {', '.join(missing)}",
    ))

    workflows = "\n".join(
        read(path)
        for path in [
            ".github/workflows/android-apk.yml",
            ".github/workflows/windows-desktop.yml",
            ".github/workflows/release-source-gate.yml",
        ]
        if (ROOT / path).exists()
    )
    checks.append(item(
        "ENFORCED_LOCK_RESOLUTION",
        workflows.count("--enforce-lockfile") >= 3,
        "Release workflows use lock-enforced package resolution.",
    ))
    checks.append(item(
        "TAG_TRIGGER_COVERAGE",
        workflows.count("tags:") >= 3 and workflows.count("'v*'") >= 3,
        "Android, Windows and source-release workflows all declare v* tag triggers.",
    ))
    checks.append(item(
        "RELEASE_EVIDENCE_PACKAGING",
        workflows.count("package_release_artifact.py") >= 2,
        "Both platform workflows package versioned release evidence.",
    ))

    full_scope_ok = not pending
    checks.append(item(
        "FULL_PRODUCT_SCOPE",
        full_scope_ok if args.require_full_scope else True,
        (
            "No dashboard modules remain Coming Soon."
            if full_scope_ok
            else f"Coming Soon modules: {', '.join(pending)}. Source preparation may continue; a full-scope commercial release tag must remain blocked."
        ),
    ))

    blocking_failures = [c for c in checks if c["blocking"] and not c["passed"]]
    report = {
        "contract": "astro-logic-final-release-source-gate-v1",
        "appVersion": version,
        "expectedTag": expected_tag,
        "suppliedTag": args.tag or None,
        "requiresLock": args.require_lock,
        "requiresFullScope": args.require_full_scope,
        "pendingModules": pending,
        "scope": "source/release metadata only; does not claim Flutter analyze/test/build success",
        "checks": checks,
        "summary": {
            "passed": sum(1 for c in checks if c["passed"]),
            "failed": len(blocking_failures),
            "releaseSourceGatePassed": not blocking_failures,
        },
    }

    out = ROOT / args.json
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    for c in checks:
        print(f"{'PASS' if c['passed'] else 'FAIL'} {c['code']}: {c['detail']}")
    print(json.dumps(report["summary"], sort_keys=True))
    return 1 if blocking_failures else 0


if __name__ == "__main__":
    sys.exit(main())
