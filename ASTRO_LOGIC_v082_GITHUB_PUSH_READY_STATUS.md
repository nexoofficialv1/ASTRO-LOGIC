# ASTRO LOGIC v082 — GitHub Push-Ready Android CI Status

App version: `0.78.0+82`

This package is a CI/push-readiness amendment of the completed v082 source milestone; it is not a new astrology-engine milestone and does not change SQLite schema 12 or native ABI `al-abi-9`.

## Android main-branch checkpoint

`.github/workflows/android-apk.yml` runs on `main` push or manual dispatch and performs:

1. source-only readiness audit;
2. v082 Western modern source/native validator;
3. Java 17 and Flutter `3.44.7` setup;
4. governed Android runner generation;
5. dependency resolution (generating a CI lock candidate when no committed lock exists);
6. dependency graph capture;
7. `flutter analyze`;
8. `flutter test`;
9. native astronomy compile/run regression;
10. `flutter build apk --release` with the Astronomy Engine backend;
11. governed APK/evidence packaging and GitHub artifact upload;
12. always-run diagnostic artifact upload for troubleshooting.

No APK PASS claim is made by this source package. The first GitHub Actions run is the runtime/build checkpoint.

## Windows governance

Windows is deliberately **not** triggered by a `main` push in this checkpoint. It remains available via manual dispatch and governed `v*` tag. This preserves the instruction not to perform a Windows final build while the immediate objective is Android APK validation.

## Dependency lock governance

`pubspec.lock` remains absent from this package. Main Android CI may generate it and upload it as evidence. It is not a final committed tested lock until the governed cross-platform release process accepts it.

## First push into the already-created repository

Use `TERMUX_PUSH_EXISTING_REPO.sh`. The script refuses to overwrite a non-empty remote repository and runs both source gates before the first push.
