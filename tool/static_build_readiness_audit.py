#!/usr/bin/env python3
"""Source-only build-readiness checks for ASTRO LOGIC.

This script deliberately does not claim Flutter compilation. It verifies the
repository contracts that can be checked before a Flutter SDK is available.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def result(code: str, severity: str, passed: bool, detail: str) -> dict:
    return {
        "code": code,
        "severity": severity,
        "passed": passed,
        "detail": detail,
    }


def relative_imports() -> list[dict]:
    findings: list[dict] = []
    pattern = re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]")
    for dart in sorted((ROOT / "lib").rglob("*.dart")):
        for lineno, line in enumerate(dart.read_text(encoding="utf-8").splitlines(), 1):
            match = pattern.match(line)
            if not match:
                continue
            target = match.group(1)
            if target.startswith(("dart:", "package:")):
                continue
            resolved = (dart.parent / target).resolve()
            if not resolved.exists():
                findings.append(
                    result(
                        "RELATIVE_IMPORT_MISSING",
                        "error",
                        False,
                        f"{dart.relative_to(ROOT)}:{lineno} -> {target}",
                    )
                )
    if not findings:
        findings.append(
            result(
                "RELATIVE_IMPORTS",
                "error",
                True,
                "All relative Dart imports resolve to local files.",
            )
        )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", default="BUILD_READINESS_AUDIT.json")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    findings: list[dict] = []

    required = [
        "pubspec.yaml",
        "lib/main.dart",
        "tool/bootstrap_android_runner.dart",
        "tool/bootstrap_windows_runner.dart",
        "tool/verify_native_packaging.sh",
        "tool/final_release_gate.py",
        "tool/package_release_artifact.py",
        "tool/assemble_release_bundle.py",
        "RELEASE_GATE.md",
        ".github/workflows/android-apk.yml",
        ".github/workflows/windows-desktop.yml",
        ".github/workflows/release-source-gate.yml",
        "native/platform/android/CMakeLists.txt",
        "native/platform/windows/astro_logic_windows.cmake",
    ]
    missing = [path for path in required if not (ROOT / path).exists()]
    findings.append(
        result(
            "REQUIRED_BUILD_FILES",
            "error",
            not missing,
            "All required build/bootstrap files are present."
            if not missing
            else f"Missing: {', '.join(missing)}",
        )
    )

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    version_match = re.search(r"^version:\s*([^\s]+)", pubspec, re.M)
    version = version_match.group(1) if version_match else ""
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    top_change = re.search(r"^##\s+([^\s]+)", changelog, re.M)
    top_change_version = top_change.group(1) if top_change else ""
    findings.append(
        result(
            "VERSION_ALIGNMENT",
            "error",
            bool(version) and version == top_change_version,
            f"pubspec={version or 'missing'}, changelog={top_change_version or 'missing'}",
        )
    )

    workflow_text = "\n".join(
        p.read_text(encoding="utf-8")
        for p in [
            ROOT / ".github/workflows/android-apk.yml",
            ROOT / ".github/workflows/windows-desktop.yml",
            ROOT / ".github/workflows/release-source-gate.yml",
        ]
        if p.exists()
    )
    expected_flutter = "3.44.7"
    findings.append(
        result(
            "CI_FLUTTER_PIN",
            "error",
            workflow_text.count(f"flutter-version: \"{expected_flutter}\"") >= 3,
            f"Android, Windows and release-source CI must pin Flutter {expected_flutter}.",
        )
    )

    findings.append(
        result(
            "CI_ANALYZE_TEST_GATES",
            "error",
            workflow_text.count("flutter analyze --no-fatal-infos") >= 2
            and workflow_text.count("flutter test") >= 2,
            "Both platform workflows include analyzer and test gates.",
        )
    )

    findings.append(
        result(
            "CI_RELEASE_TAG_GATES",
            "error",
            workflow_text.count("tags:") >= 3
            and workflow_text.count("'v*'") >= 3
            and workflow_text.count("--enforce-lockfile") >= 3,
            "Android, Windows and source release workflows enforce tagged-release lock resolution.",
        )
    )

    findings.append(
        result(
            "CI_RELEASE_EVIDENCE_PACKAGING",
            "error",
            workflow_text.count("package_release_artifact.py") >= 2,
            "Android and Windows workflows package governed release evidence.",
        )
    )

    generated_dirs = [name for name in ("android", "windows") if (ROOT / name).exists()]
    findings.append(
        result(
            "GENERATED_RUNNERS_NOT_COMMITTED",
            "warning",
            not generated_dirs,
            "Platform runners remain generated-at-build-time."
            if not generated_dirs
            else f"Generated runner directories present: {generated_dirs}",
        )
    )

    fonts = [
        p.relative_to(ROOT).as_posix()
        for p in ROOT.rglob("*")
        if p.is_file() and p.suffix.lower() in {".ttf", ".otf", ".woff", ".woff2"}
    ]
    findings.append(
        result(
            "NO_BUNDLED_FONTS",
            "error",
            not fonts,
            "No font binaries are bundled." if not fonts else f"Font binaries: {fonts}",
        )
    )

    markers = []
    for base in (ROOT / "lib", ROOT / "test", ROOT / "tool", ROOT / "native"):
        if not base.exists():
            continue
        for p in base.rglob("*"):
            if p.resolve() == Path(__file__).resolve():
                continue
            if not p.is_file() or p.suffix.lower() not in {".dart", ".py", ".sh", ".c", ".h", ".cmake"}:
                continue
            text = p.read_text(encoding="utf-8", errors="ignore")
            if re.search(r"\b(TODO|FIXME|HACK|XXX)\b", text):
                markers.append(p.relative_to(ROOT).as_posix())
    findings.append(
        result(
            "NO_UNRESOLVED_MARKERS",
            "warning",
            not markers,
            "No TODO/FIXME/HACK/XXX markers found."
            if not markers
            else f"Markers found in: {', '.join(markers[:12])}",
        )
    )

    findings.extend(relative_imports())

    large_files = []
    for p in (ROOT / "lib").rglob("*.dart"):
        lines = sum(1 for _ in p.open(encoding="utf-8"))
        if lines >= 1000:
            large_files.append((lines, p.relative_to(ROOT).as_posix()))
    large_files.sort(reverse=True)
    findings.append(
        result(
            "LARGE_DART_FILES",
            "warning",
            not any(lines >= 2500 for lines, _ in large_files),
            "Large-file watchlist: "
            + (", ".join(f"{path}={lines}" for lines, path in large_files[:8]) or "none"),
        )
    )

    gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
    lock_ignored = any(
        line.strip() in {"pubspec.lock", "/pubspec.lock"}
        for line in gitignore.splitlines()
        if line.strip() and not line.strip().startswith("#")
    )
    findings.append(
        result(
            "PUBSPEC_LOCK_COMMITTABLE",
            "error",
            not lock_ignored,
            "pubspec.lock is not ignored and can be committed for final release qualification."
            if not lock_ignored
            else "pubspec.lock is still ignored by .gitignore.",
        )
    )

    lock_exists = (ROOT / "pubspec.lock").exists()
    findings.append(
        result(
            "PUBSPEC_LOCK_RELEASE_GATE",
            "warning",
            lock_exists,
            "pubspec.lock is present."
            if lock_exists
            else "pubspec.lock is not present; generate and retain it at the final Flutter build checkpoint for reproducible resolution.",
        )
    )

    dashboard = (ROOT / "lib/src/screens/dashboard_screen.dart").read_text(encoding="utf-8")
    modules = (ROOT / "lib/src/models/astro_module.dart").read_text(encoding="utf-8")
    findings.append(
        result(
            "DASHBOARD_PLACEHOLDER_GOVERNANCE",
            "error",
            "AstroModuleAvailability.comingSoon" in modules
            and "module.availability == AstroModuleAvailability.comingSoon" in dashboard,
            "Unimplemented dashboard modules are explicitly marked Coming Soon.",
        )
    )
    findings.append(
        result(
            "NEW_CONSULTATION_CONTROL",
            "error",
            "_openClients(context)" in dashboard and "onStart: () => _openClients(context)" in dashboard,
            "Dashboard New Consultation control routes into the client/consultation workflow.",
        )
    )

    report = {
        "auditVersion": "build-readiness-audit-v2",
        "appVersion": version,
        "scope": "source-only; does not claim Flutter runtime compilation",
        "findings": findings,
        "summary": {
            "errorsFailed": sum(1 for f in findings if f["severity"] == "error" and not f["passed"]),
            "warningsFailed": sum(1 for f in findings if f["severity"] == "warning" and not f["passed"]),
            "passed": sum(1 for f in findings if f["passed"]),
        },
    }
    output = ROOT / args.json
    output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    for f in findings:
        status = "PASS" if f["passed"] else "WARN" if f["severity"] == "warning" else "FAIL"
        print(f"{status:4} {f['code']}: {f['detail']}")
    print(json.dumps(report["summary"], sort_keys=True))

    if report["summary"]["errorsFailed"]:
        return 1
    if args.strict and report["summary"]["warningsFailed"]:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
