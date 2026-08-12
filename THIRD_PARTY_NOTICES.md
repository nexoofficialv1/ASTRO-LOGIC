# Third-party notices

## Bundled source

### Astronomy Engine

- Copyright: Don Cross and contributors
- Upstream: https://github.com/cosinekitty/astronomy
- Licence: MIT
- Intended use: offline Sun, Moon and planetary astronomical calculations

Reviewed C source and header version 2.1.19 are bundled under
`third_party/astronomy_engine`, together with the complete upstream MIT licence,
per-file checksums and source-archive provenance. Android and Windows release
packages must preserve the licence notice.

## Explicit exclusion

Swiss Ephemeris is not a dependency of ASTRO LOGIC. No Swiss source, binary,
wrapper or data file may be added without a new documented product decision and
licence review.

## Runtime package dependencies

Professional Report Export Engine v1 adds package dependencies resolved through `pubspec.yaml`: `pdf` (Apache-2.0), `archive` (MIT), `share_plus` (BSD-3-Clause) and `cross_file` (BSD-3-Clause), `qr` 4.0.0 (BSD-3-Clause), `cryptography` 2.9.0 (Apache-2.0) and `file_picker` 11.0.3 (MIT). These packages are not vendored into this source ZIP; release builds must preserve their applicable licence notices through the normal Flutter dependency-distribution process. No third-party font binary is bundled for report export.
