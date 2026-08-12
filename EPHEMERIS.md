# Offline astronomical engine policy

## Product decision

ASTRO LOGIC is proprietary commercial software, but it will not use Swiss
Ephemeris. No Swiss source, wrapper, native binary, data file, entitlement or
commercial licence is required by this codebase.

The selected upstream astronomical base is **Astronomy Engine** by Don Cross:

- upstream: https://github.com/cosinekitty/astronomy
- licence: MIT
- pinned tag: `v2.1.19`
- pinned source-archive SHA-256:
  `ee466bca06c18bb0c54b30c0617c22a119c9ad9cf1fb8ae6f315824f49205fbe`

The reviewed upstream C source, header and full MIT licence are bundled under
`third_party/astronomy_engine`. Per-file SHA-256 verification and licence-notice
checks are release gates.

## Integration boundary

`AstronomyEngineEphemerisProvider` is the vendor-specific adapter behind the
existing interchangeable `EphemerisProvider` contract. The stable native C ABI
under `native/` builds the same shared calculation core for Android and Windows.

The provider:

- refuses to run until the audited backend is explicitly included;
- validates UTC, latitude and longitude before native execution;
- initializes the native library once per provider instance;
- records the upstream library version in calculation metadata;
- never fabricates missing positions.

`AstronomyEngineFfiBridge` now binds the stable ABI directly with `dart:ffi`.
It opens `libastro_logic_astronomy.so` on Android and
`astro_logic_astronomy.dll` on Windows. `createProductionVedicEngine()` is the
single composition point for the packaged native provider and the pure Dart
Vedic derivation layer.

The intended build flag is:

`ASTRO_LOGIC_EPHEMERIS_BACKEND=astronomy-engine`

The flag must only be set in builds that actually package the corresponding
native library. A missing library, unconfigured backend or unsupported platform
fails explicitly; there is no approximate fallback.

Platform integration templates live under `native/platform`. Android's Gradle
external-native-build path compiles `libastro_logic_astronomy.so` from the
pinned source. The Windows CMake include compiles the same target and installs
`astro_logic_astronomy.dll` beside the packaged executable. The host verification
script checks both the astronomical regression test and all three exported ABI
symbols without leaving compiled files in the source tree.

## External accuracy fixture

The native wrapper is checked against NASA/JPL Horizons DE441 geocentric,
apparent ecliptic-of-date longitudes for 1984-03-12 18:42 UTC. Sun, Moon,
Mercury, Venus, Mars, Jupiter and Saturn must each remain within 0.01 degree.
The reviewed wrapper's maximum observed difference is about 0.00172 degree.

## Vedic frame supplements

Astronomy Engine supplies the astronomical planetary base. ASTRO LOGIC's
deterministic native layer now supplies:

- Lahiri/Chitrapaksha ayanamsha, anchored to the apparent tropical longitude
  of Spica minus 180 degrees;
- true lunar node from the instantaneous lunar orbital plane;
- mean lunar node from the standard mean-node polynomial;
- tropical ascendant from local apparent sidereal time and true obliquity;
- daily longitude speed from centred one-hour samples;
- observer-specific apparent Sun hour angle in [0,24), where 0h is local apparent upper transit/noon and 12h is apparent midnight.

Native ABI v6 retains the apparent Sun hour angle and bracketing rise/set search from ABI v4 and adds the prior observer sunrise plus prior sidereal solar-ingress contexts used by the governed Varsha/Masa/Dina/Hora profile and adds geocentric ecliptic latitude for each physical planet so planetary-war review does not have to reconstruct latitude. The Dart derivation layer persists available UTC audit instants, astrological weekday lords and seasonal Hora identity; optional event-search failures remain gated rather than failing the whole chart.

The Dart derivation layer selects true or mean Rahu from settings, derives Ketu
exactly 180 degrees opposite, subtracts ayanamsha for sidereal longitude, and
then derives:

- sidereal ascendant;
- D1 sign, Nakshatra, Pada and D9/Navamsha;
- an explicit `vedic-chart-v9.divisionalCharts.d9` chart for the ascendant and
  all calculated bodies, while preserving the per-planet Navamsha fields;
- exact `longitudeSpeedPerDay` for every calculated body in the `vedic-chart-v9` planet payload, so governed motional-strength logic does not need to reconstruct speed from a retrograde flag;
- exact geocentric `eclipticLatitude` for physical planets in current v9 output, used by the governed Yuddha Bala audit;
- a Moon-longitude-based Vimshottari Mahadasha, Antardasha and
  Pratyantardasha calendar;
- Tithi, Paksha and Yoga.

Each D9 sign is calculated deterministically from sidereal longitude using
3 degrees 20 minutes per Navamsha. The judgment layer independently verifies
any supplied per-planet D9 sign against that longitude before interpretation.

Only Lahiri is enabled in the FFI bridge. Raman and Krishnamurti settings fail
explicitly until their separate methods and fixtures are reviewed. The
committed `vedic_frame_1984_03_12.json` regression fixture locks the complete
frame for 1984-03-12 18:42 UTC at 23.22 N, 88.37 E. It yields Lahiri
23.6212396 degrees and sidereal ascendant 236.2117930 degrees (Scorpio).

This fixture is a deterministic regression reference, not an independent
external certification of the ayanamsha or ascendant method. External JPL
evidence continues to cover the seven planetary longitudes.

## KP native profile — v0.71.0+75

- Native wrapper ABI: `al-abi-8`.
- KP ayanamsha profile: `kp-krishnamurti-classic-j1900-newcomb-v1`. It independently implements the classic Reader-1 J1900 value with Newcomb/Kinoshita precession and is explicitly versioned because the original KP source is historically ambiguous at higher precision.
- KP house profile: `kp-placidus-time-division-native-v1`. Twelve tropical cusps are solved natively and projected to sidereal cusps by the governed KP ayanamsha. Unsupported polar geometry is an error; there is no Porphyry fallback.
- Numeric external fixtures are retained in `native/tests/kp_reference_fixtures.json`. Swiss Ephemeris is not linked, bundled, called or distributed by ASTRO LOGIC; only numeric development fixtures are used for independent comparison.
- Validated profile range for this milestone: 1840–2100.

## Western native profile — v0.77.0+81

- Native wrapper ABI: `al-abi-8`.
- `al_calculate_western_frame` returns tropical Ascendant, MC, true/mean node longitudes and a separate Placidus status. Core tropical geometry remains available even when Placidus is mathematically unsupported, allowing Whole Sign or Equal houses only when explicitly selected.
- Placidus uses the same independently implemented time-division solver and never silently substitutes Porphyry or another house system.
- Seven traditional geocentric tropical planetary longitudes and longitude speeds reuse `al_geocentric_position`; lunar nodes are chart points but v081 excludes them from the major-aspect matrix.
- Western Foundation v1 is a practitioner-review astrology layer, not a scientific validation of astrological interpretation.


## Western modern native profile — v0.78.0+82

- Native wrapper ABI: `al-abi-9`. Existing Sun/Moon/Mars/Mercury/Jupiter/Venus/Saturn body codes `0–6` are unchanged; Uranus/Neptune/Pluto are appended as `7/8/9`. Existing native function signatures remain stable.
- `al_geocentric_position` maps the new codes directly to Astronomy Engine `BODY_URANUS`, `BODY_NEPTUNE` and `BODY_PLUTO`; no ASTRO LOGIC polynomial, interpolation or fabricated longitude fallback is introduced.
- Astronomy Engine `v2.1.19` is the pinned MIT astronomical implementation and documents geocentric support for Uranus, Neptune and Pluto plus validation against NOVAS/JPL Horizons. NASA/JPL Horizons remains the authoritative ephemeris reference path for future fixture refreshes.
- `native/tests/western_modern_reference_fixtures.json` adds a separate independent rounded public-ephemeris spot-check at `2026-08-12T17:19:00Z`. The tolerance is intentionally `0.02°` because the independent published values are rounded; this fixture is not presented as a replacement for JPL-grade validation.
- v081's existing 1984 JPL seven-planet fixtures, KP classic ayanamsha/Placidus fixtures and Western frame/polar-gate regression continue to run in the same native verification script.
