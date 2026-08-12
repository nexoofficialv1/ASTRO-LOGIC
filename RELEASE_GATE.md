# ASTRO LOGIC — Final Flutter CI & Release Gate

Contract: `astro-logic-final-release-gate-v1`  
Preparation milestone: `v0.71.0+75`  
Pinned Flutter baseline: `3.44.7`

This document defines the evidence required before ASTRO LOGIC may be described
as a tested Android/Windows release. v075 prepares the gate only; it does not
claim that the current source has passed Flutter runtime CI or that the full
product scope is complete.

## 1. Commercial full-scope release remains blocked while modules are Coming Soon

The source-release gate has a `--require-full-scope` mode. A final `v*` release
tag invokes that mode automatically. As long as the dashboard still declares Vastu, Palmistry or Practice as `Coming Soon`, a full-scope commercial
release tag is expected to fail. This is deliberate and prevents CI success on
only the implemented subset from being mistaken for completion of the original
ASTRO LOGIC product scope.

Development `main` builds remain allowed while those modules are being built.

## 2. Dependency lock policy

ASTRO LOGIC is an application, so the final tested `pubspec.lock` must be kept in
source control. `.gitignore` must not exclude it.

Two-stage qualification:

1. After feature completion, push the private source baseline to `main`.
2. If no lock exists yet, Android/Windows development CI may run ordinary
   `flutter pub get` and each artifact will include the generated lock candidate.
3. Confirm the Android and Windows `pubspec.lock` SHA-256 values are identical.
4. Commit that exact tested `pubspec.lock` to `main`.
5. Re-run both platform workflows. Once a lock exists, the workflows use
   `flutter pub get --enforce-lockfile`.
6. Only after both locked builds pass may the exact tag `v<pubspec-version>` be
   created, for example `v0.71.0+75` for this preparation milestone.
7. Every tagged platform build again uses `--enforce-lockfile`.

Never hand-author a lock file and never copy a lock from an unrelated project.

## 3. Source release gate

`.github/workflows/release-source-gate.yml` is triggered by `v*` tags and can be
run manually after the tested lock is committed.

Tagged mode requires:

- `pubspec.yaml` version == top `CHANGELOG.md` version
- Git tag == `v<pubspec-version>`
- committed `pubspec.lock`
- lock file is not ignored
- full declared product scope has no `Coming Soon` modules
- all release scripts/workflows are present
- exact lock-enforced package resolution succeeds under Flutter `3.44.7`

The source gate is metadata/dependency evidence. It does not replace analyzer,
tests or platform builds.

## 4. Android release matrix

The Android workflow must pass, in order:

1. source readiness audit
2. tagged source/full-scope/lock gate when applicable
3. Java 17 setup
4. Flutter `3.44.7`
5. governed Android runner generation
6. lock-enforced package resolution when a lock exists; mandatory on release tag
7. dependency graph capture
8. `flutter analyze --no-fatal-infos`
9. `flutter test`
10. native Astronomy Engine C reference/ABI verification
11. release APK build with
    `ASTRO_LOGIC_EPHEMERIS_BACKEND=astronomy-engine`
12. governed platform evidence packaging

The evidence package contains a versioned APK, analyzer/test/native logs,
dependency graph, tested lock file, platform release manifest and SHA-256 sums.

## 5. Windows release matrix

The Windows workflow must pass, in order:

1. source readiness audit
2. tagged source/full-scope/lock gate when applicable
3. Flutter `3.44.7`
4. governed Windows runner generation
5. lock-enforced package resolution when a lock exists; mandatory on release tag
6. dependency graph capture
7. `flutter analyze --no-fatal-infos`
8. `flutter test`
9. release Windows build with Astronomy Engine backend
10. packaged `astro_logic_astronomy.dll` existence/hash evidence
11. governed Windows evidence packaging

The Windows Release directory is archived as a versioned ZIP with per-file
inventory hashes in its manifest.

## 6. Platform evidence contract

`tool/package_release_artifact.py` writes
`astro-logic-platform-release-evidence-v1`.

The manifest binds:

- platform
- app version
- exact release tag when tagged
- source commit
- workflow run id
- Flutter baseline
- Astronomy Engine backend
- platform artifact SHA-256
- `pubspec.lock` SHA-256
- analyzer log SHA-256
- Flutter test log SHA-256
- native-verification log SHA-256
- dependency-graph SHA-256

This is integrity evidence, not APK/EXE publisher signing and not PKI.

## 7. Final Android + Windows bundle

After the same final tag has passed Android and Windows CI, download both
platform evidence artifacts and run:

```bash
python tool/assemble_release_bundle.py \
  --android-manifest /path/to/android/ASTRO_LOGIC_Android_vX_RELEASE_MANIFEST.json \
  --windows-manifest /path/to/windows/ASTRO_LOGIC_Windows_vX_RELEASE_MANIFEST.json \
  --output-dir /path/to/final-release
```

The assembler rejects the bundle unless both platform manifests agree on:

- app version
- release tag
- source commit
- Flutter version
- `pubspec.lock` SHA-256
- ephemeris backend

It then verifies every artifact/evidence hash and emits
`astro-logic-final-release-bundle-v1` plus final SHA-256 sums.

## 8. Claims that remain forbidden until runtime CI actually passes

Do not claim any of the following from a source ZIP alone:

- Flutter compilation passed
- analyzer passed
- Flutter tests passed
- Android APK works on a real device
- Windows application launches on a real machine
- native Astronomy Engine loads correctly on both target platforms
- backup/restore or PDF/DOCX behavior passed end-to-end runtime testing

Those claims require actual CI/device evidence.

## 9. Final real-device acceptance before distribution

After CI passes, test at minimum:

- Android fresh install and upgrade path
- Windows fresh install/extracted bundle launch
- Bengali and English UI
- client + consultation lifecycle
- one verified Vedic calculation and one Numerology calculation
- immutable report creation, approval, PDF/DOCX export and signed QR verification
- encrypted backup create → preview → restore on clean workspace
- governed merge into non-empty workspace and receipt verification
- offline restart with no network
- database reopen/migration path
- share/export permissions on Android
- Windows file picker/export paths

Record failures as release blockers; do not bypass them by editing the final
manifest.
