#!/usr/bin/env python3
"""Validate that source-required platform bridge files survive .gitignore rules."""
from __future__ import annotations
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "native/platform/android/CMakeLists.txt",
    "native/platform/windows/astro_logic_windows.cmake",
]

def main() -> int:
    missing = [p for p in REQUIRED if not (ROOT / p).is_file()]
    if missing:
        print("FAIL REQUIRED_PLATFORM_BRIDGES: Missing: " + ", ".join(missing))
        return 1

    # git check-ignore works once the source is in a repository; the CI checkout is one.
    proc = subprocess.run(
        ["git", "check-ignore", "-v", *REQUIRED],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode == 0 and proc.stdout.strip():
        print("FAIL PLATFORM_BRIDGES_TRACKABILITY: required files are ignored")
        print(proc.stdout.rstrip())
        return 1
    if proc.returncode not in (0, 1):
        print("FAIL GIT_CHECK_IGNORE: " + (proc.stderr.strip() or f"exit={proc.returncode}"))
        return 1

    print("PASS REQUIRED_PLATFORM_BRIDGES: files exist")
    print("PASS PLATFORM_BRIDGES_TRACKABILITY: files are not ignored")
    return 0

if __name__ == "__main__":
    sys.exit(main())
