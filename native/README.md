# Native astronomical core

This directory exposes the pinned Astronomy Engine C source through the stable
`astro_logic_astronomy` ABI. The same ABI is intended for Android NDK and
Windows DLL builds.

## Shared library

From the project root, a CMake-capable toolchain can run:

```text
cmake -S native -B build/native -DCMAKE_BUILD_TYPE=Release
cmake --build build/native --config Release
```

## Reference check

The strict wrapper and fixture can be compiled with a C99 compiler. Compile the
upstream object without `-Werror` so its byte-for-byte pinned source does not
need local warning edits. Compile ASTRO LOGIC's wrapper and test with
`-Werror`, link the three objects with the platform math library, and run
`reference_accuracy_test`.

The test compares seven geocentric apparent ecliptic-of-date longitudes against
the committed NASA/JPL Horizons DE441 fixture. Every angular error must be at
most 0.01 degree.

The same test also regression-locks ABI version 6 frame supplements: the
Spica-anchored Lahiri/Chitrapaksha ayanamsha, tropical ascendant, true Rahu, mean Rahu and observer-specific apparent Sun hour angle, the exact sunrise/sunset-bracketed Tribhaga day/night third, prior observer sunrise, and prior sidereal Aries/current-sign solar-ingress audit offsets used by Varsha/Masa/Dina/Hora, and finite geocentric ecliptic latitude for each physical planet used by Yuddha Bala. It checks finite/range status and expected retrograde speed for the
committed sample. Ketu and all sidereal positions are derived in Dart.

No generated `.so`, `.dll`, object or executable is committed. Android and
Windows release projects must package a locally built library with the exact
names expected by `AstronomyEngineFfiBridge`.

Flutter runner integration is defined in `platform/README.md`. On a POSIX host,
`tool/verify_native_packaging.sh` compiles the reviewed sources in a temporary
directory, runs the strict reference test and confirms every FFI ABI symbol is
exported.

## ABI v7 — KP native chart frame

`al_calculate_kp_frame` adds the governed classic Krishnamurti ayanamsha reconstruction and native Placidus 12-cusp calculation. It returns both tropical and sidereal cusps plus Asc/MC and node longitudes. Unsupported polar Placidus geometry returns a non-zero status; callers must not substitute another house system silently.

`native/tests/kp_reference_fixtures.json` contains development-only external numeric reference values. No Swiss Ephemeris source/library is built, linked or required at runtime.

## ABI v8 — Western tropical frame

`al_calculate_western_frame` exposes tropical Ascendant, MC, true/mean node longitudes and a separate Placidus status. Unlike the KP frame, a Placidus polar failure does not invalidate the core tropical frame, so Whole Sign or Equal houses can still be calculated when the user explicitly selected them. The Placidus cusp array is populated only when `placidus_status == 0`; no silent house-system fallback is performed.
