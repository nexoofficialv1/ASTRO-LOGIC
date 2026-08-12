#!/usr/bin/env python3
"""Source/native validation for ASTRO LOGIC v082 Western Modern Expansion v1.

This is deliberately a source/native gate. It never claims Flutter analyzer,
Flutter tests, APK, Windows Flutter build, or device runtime success when those
SDK/toolchains are absent.
"""
from __future__ import annotations

import itertools
import json
import math
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKS: list[dict] = []


def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def add(code: str, ok: bool, detail: str) -> None:
    CHECKS.append({"code": code, "passed": bool(ok), "detail": detail})


def has(src: str, *parts: str) -> bool:
    return all(part in src for part in parts)


pub = text("pubspec.yaml")
change = text("CHANGELOG.md")
engine = text("lib/src/western/western_chart_engine.dart")
gov = text("lib/src/western/western_governance.dart")
bridge = text("lib/src/western/western_native_ffi_bridge.dart")
bridge_contract = text("lib/src/western/western_native_bridge.dart")
kp_bridge = text("lib/src/kp/kp_native_ffi_bridge.dart")
eph_bridge = text("lib/src/ephemeris/astronomy_engine_ffi_bridge.dart")
store = text("lib/src/data/client_store.dart")
orch = text("lib/src/services/western_chart_orchestrator.dart")
workspace = text("lib/src/screens/western_workspace_screen.dart")
copy = text("lib/src/localization/app_copy.dart")
modules = text("lib/src/models/astro_module.dart")
dashboard = text("lib/src/screens/dashboard_screen.dart")
header = text("native/astro_logic_astronomy.h")
native = text("native/astro_logic_astronomy.c")
native_test = text("native/tests/reference_accuracy_test.c")
western_test = text("test/western_chart_engine_test.dart")
db = text("lib/src/data/app_database.dart")
backup = text("lib/src/services/encrypted_backup_service.dart")
sources = text("WESTERN_RULE_SOURCES.md")

add("VERSION", "version: 0.78.0+82" in pub, "pubspec v082")
add("CHANGELOG_TOP", change.startswith("## 0.78.0+82"), "changelog v082 first")
add("DB_SCHEMA_12", "static const schemaVersion = 12;" in db, "SQLite remains schema 12")
add("BACKUP_ENGINE_14", "engineVersion = '1.4.0'" in backup, "backup engine remains 1.4.0")
add("NO_PUBSPEC_LOCK", not (ROOT / "pubspec.lock").exists(), "no untested lockfile fabricated")

add(
    "ENGINE_CONTRACT",
    has(
        engine,
        "engineVersion = '1.1.0'",
        "outputSchemaVersion = 'western-natal-chart-v2'",
        "inputSchemaVersion = 'western-input-schema-v2'",
    ),
    "Western v2 engine/input/output contracts",
)
add(
    "GOVERNANCE_CONTRACT",
    has(
        gov,
        "profileVersion = 'western-modern-aspect-v1'",
        "modernPlanetProfile = 'western-modern-planets-v1'",
        "patternProfile = 'western-aspect-pattern-v1'",
        "traditionalRulershipProfile = 'western-rulership-traditional-v1'",
        "modernRulershipProfile = 'western-rulership-modern-v1'",
    ),
    "Western v082 governance profiles",
)
add(
    "RULERSHIP_MAPPING",
    has(
        gov,
        "'venus', 'mars', 'jupiter', 'saturn', 'saturn', 'jupiter'",
        "'venus', 'pluto', 'jupiter', 'saturn', 'uranus', 'neptune'",
    ),
    "traditional and modern Scorpio/Aquarius/Pisces mappings are separate",
)
add(
    "DIGNITY_SEPARATION",
    has(engine, "_traditionalBodies", "dignities: List.unmodifiable(_buildDignities(traditional))")
    and all(f"WesternBody.{p}: _WesternDignitySigns" not in engine for p in ("uranus", "neptune", "pluto"))
    and "'modernRulersInjectedIntoTraditionalDignity': false" in engine,
    "traditional seven-planet dignity remains authoritative",
)

# Native ABI/body compatibility.
legacy = {
    "AL_BODY_SUN": 0,
    "AL_BODY_MOON": 1,
    "AL_BODY_MARS": 2,
    "AL_BODY_MERCURY": 3,
    "AL_BODY_JUPITER": 4,
    "AL_BODY_VENUS": 5,
    "AL_BODY_SATURN": 6,
    "AL_BODY_URANUS": 7,
    "AL_BODY_NEPTUNE": 8,
    "AL_BODY_PLUTO": 9,
}
body_ok = all(re.search(rf"\b{name}\s*=\s*{code}\b", header) for name, code in legacy.items())
add("NATIVE_BODY_CODES", body_ok, "legacy 0–6 preserved; modern bodies appended 7–9")
add(
    "NATIVE_MODERN_MAPPING",
    has(
        native,
        "case AL_BODY_URANUS: return BODY_URANUS;",
        "case AL_BODY_NEPTUNE: return BODY_NEPTUNE;",
        "case AL_BODY_PLUTO: return BODY_PLUTO;",
    ),
    "outer planets map directly to Astronomy Engine bodies",
)
add(
    "ABI_9_METADATA",
    all("al-abi-9" in src for src in (bridge, kp_bridge, eph_bridge)),
    "all native FFI metadata reports al-abi-9",
)
add(
    "WESTERN_BODY_DECOUPLED_FROM_KP",
    "enum WesternNativeBody" in bridge_contract
    and "KpNativeBody" not in bridge_contract
    and "KpNativeBody" not in bridge,
    "Western modern body enumeration does not mutate KP body contract",
)

# Aspects and defaults.
angle_tokens = {
    "semisextile": "WesternAspectType.semisextile: 30.0",
    "semisquare": "WesternAspectType.semisquare: 45.0",
    "quintile": "WesternAspectType.quintile: 72.0",
    "sesquiquadrate": "WesternAspectType.sesquiquadrate: 135.0",
    "quincunx": "WesternAspectType.quincunx: 150.0",
}
add("MINOR_ANGLES", all(v in engine for v in angle_tokens.values()), "five governed minor exact angles")
add(
    "MINOR_ORBS",
    all(
        t in engine
        for t in (
            "WesternAspectType.semisextile: 2.0",
            "WesternAspectType.semisquare: 2.0",
            "WesternAspectType.quintile: 2.0",
            "WesternAspectType.sesquiquadrate: 2.0",
            "WesternAspectType.quincunx: 3.0",
        )
    ),
    "frozen v082 minor operational orbs",
)
add(
    "MAJOR_ORBS_REGRESSION",
    all(
        t in engine
        for t in (
            "WesternAspectType.conjunction: 8.0",
            "WesternAspectType.sextile: 4.0",
            "WesternAspectType.square: 6.0",
            "WesternAspectType.trine: 6.0",
            "WesternAspectType.opposition: 8.0",
        )
    ),
    "v081 major orbs preserved",
)
add(
    "MINOR_DEFAULT_OFF",
    "WesternAspectProfile aspectProfile = WesternAspectProfile.majorOnly" in orch
    and "WesternAspectProfile _aspectProfile = WesternAspectProfile.majorOnly" in workspace,
    "major-only default in consultation orchestrator and standalone workspace",
)

# Pattern source/implementation.
for name in ("grandTrine", "tSquare", "grandCross", "stellium", "yod", "kite"):
    add(f"PATTERN_{name.upper()}", f"WesternAspectPatternType.{name}" in engine, f"{name} implementation present")
add(
    "YOD_MINOR_GATE",
    "WesternGovernance.minorAspectsEnabled(profile)" in engine
    and "WesternAspectType.quincunx" in engine
    and "WesternAspectType.sextile" in engine,
    "Yod requires the enabled minor-aspect profile",
)
add(
    "PATTERN_EVIDENCE",
    has(engine, "componentAspects", "actualSeparation", "orbLimit", "patternEngineVersion")
    and "automaticLifeEventPrediction': false" in engine,
    "patterns retain component geometry/orbs and do not predict life events",
)
add(
    "NO_CROSS_SYSTEM_UPLIFT",
    "'crossSystemConfidenceUplift': false" in engine
    and "'automaticRealWorldPrediction': false" in engine,
    "Western output cannot auto-uplift other systems or predict real-world events",
)

# Snapshot settings/hash pipeline.
add(
    "SNAPSHOT_V2_SETTINGS",
    has(
        store,
        "createWesternInputSnapshot",
        "WesternRulershipProfile rulershipProfile",
        "WesternAspectProfile aspectProfile",
        "includeModernPlanets",
        "rulershipProfileVersion",
        "aspectProfileVersion",
        "minorAspectEnabled",
        "modernPlanetProfile",
        "aspectPatternEngineVersion",
        "WesternChartEngine.inputSchemaVersion",
    ),
    "new Western settings bound into existing immutable input snapshot hash",
)
# Protect against accidental KP signature pollution.
kp_sig = re.search(r"Future<int> createKpInputSnapshot\(\{([\s\S]*?)\n  \}\) async", store)
add(
    "KP_SNAPSHOT_SIGNATURE_REGRESSION",
    bool(kp_sig)
    and "WesternRulershipProfile" not in kp_sig.group(1)
    and "WesternAspectProfile" not in kp_sig.group(1),
    "KP input snapshot API remains Western-independent",
)
add(
    "ORCHESTRATOR_V2",
    has(orch, "rulershipProfile: rulershipProfile", "aspectProfile: aspectProfile", "includeModernPlanets: includeModernPlanets"),
    "consultation orchestration persists and casts same explicit profile settings",
)

# UI and module governance.
add(
    "WORKSPACE_SELECTORS",
    has(workspace, "DropdownButtonFormField<WesternRulershipProfile>", "DropdownButtonFormField<WesternAspectProfile>"),
    "Traditional/Modern and Major-only/Major+Minor selectors",
)
add(
    "WORKSPACE_EVIDENCE_PANELS",
    all(k in workspace for k in ("westernModernPlanets", "westernAspects", "westernAspectPatterns", "westernRulerships", "westernDignities")),
    "modern planets, aspect table, pattern panel, rulership and dignity sections",
)
western_block = re.search(r"AstroModule\(\s*copyKey: 'western',[\s\S]*?\),", modules)
add(
    "WESTERN_AVAILABLE",
    bool(western_block) and "comingSoon" not in western_block.group(0),
    "Western remains available on Dashboard",
)
for key in ("vastu", "palmistry", "practice"):
    m = re.search(
        rf"AstroModule\(\s*copyKey: '{key}',[\s\S]*?\n\s*\),",
        modules,
    )
    add(
        f"COMING_SOON_{key.upper()}",
        bool(m) and "AstroModuleAvailability.comingSoon" in m.group(0),
        f"{key} remains Coming Soon",
    )
add("DASHBOARD_ROUTE", "module.copyKey == 'western'" in dashboard and "WesternWorkspaceScreen" in dashboard, "Western route retained")

# Localization parity and required v082 copy.
def locale_keys(src: str, language: str, next_language: str | None) -> list[str]:
    marker = f"    '{language}': {{"
    start = src.index(marker) + len(marker)
    end = src.index(f"    '{next_language}': {{", start) if next_language else src.rindex("  };")
    return re.findall(r"^\s*'([^']+)':", src[start:end], re.M)

en_keys = locale_keys(copy, "en", "bn")
bn_keys = locale_keys(copy, "bn", None)
add("LOCALE_PARITY", set(en_keys) == set(bn_keys), f"EN={len(set(en_keys))}, BN={len(set(bn_keys))}")
add("LOCALE_DUPLICATES", len(en_keys) == len(set(en_keys)) and len(bn_keys) == len(set(bn_keys)), "no duplicate EN/BN keys")
required_copy = {
    "westernRulershipProfileLabel",
    "westernAspectProfileLabel",
    "westernModernPlanets",
    "westernAspects",
    "westernAspectPatterns",
    "uranus",
    "neptune",
    "pluto",
    "semisextile",
    "semisquare",
    "quintile",
    "sesquiquadrate",
    "quincunx",
    "grandTrine",
    "tSquare",
    "grandCross",
    "stellium",
    "yod",
    "kite",
}
add("LOCALE_V082_KEYS", required_copy.issubset(set(en_keys)) and required_copy.issubset(set(bn_keys)), "all v082 copy keys present in EN/BN")

# Research provenance.
add(
    "SOURCE_PROVENANCE",
    all(
        token in sources
        for token in (
            "github.com/cosinekitty/astronomy",
            "ssd-api.jpl.nasa.gov/doc/horizons.html",
            "astro.com/astrology/in_ruler_e.htm",
            "astro.com/astrology/in_aspect_e.htm",
            "astro.com/astrowiki/en/Grand_Trine",
            "astro.com/astrowiki/en/Yod",
            "astro.com/astrowiki/en/Stellium",
            "skyscript.co.uk/aspects2.html",
        )
    ),
    "astronomy and Western-rule provenance documented",
)
add(
    "NO_UNIVERSAL_ORB_CLAIM",
    "versioned operational policy" in sources and "not a claim of a universal" in sources,
    "orb policy explicitly governed rather than universalized",
)

# External fixture contract.
fixture = json.loads(text("native/tests/western_modern_reference_fixtures.json"))
add(
    "MODERN_REFERENCE_FIXTURE",
    fixture.get("referenceTimestampUtc") == "2026-08-12T17:19:00Z"
    and {f["body"] for f in fixture.get("fixtures", [])} == {"Uranus", "Neptune", "Pluto"}
    and math.isclose(float(fixture.get("toleranceDegrees", 0)), 0.02),
    "independent rounded modern-planet fixture is versioned",
)
add(
    "NATIVE_REFERENCE_TEST_HOOK",
    all(token in native_test for token in ("AL_BODY_URANUS", "AL_BODY_NEPTUNE", "AL_BODY_PLUTO", "public_ephemeris_tolerance_degrees")),
    "modern fixtures execute inside native regression test",
)

# Independent Python boundary/pattern fixtures mirror the governed geometry, not Dart internals.
MAJOR = {"conjunction": (0.0, 8.0), "sextile": (60.0, 4.0), "square": (90.0, 6.0), "trine": (120.0, 6.0), "opposition": (180.0, 8.0)}
MINOR = {"semisextile": (30.0, 2.0), "semisquare": (45.0, 2.0), "quintile": (72.0, 2.0), "sesquiquadrate": (135.0, 2.0), "quincunx": (150.0, 3.0)}

def sep(a: float, b: float) -> float:
    d = abs((a % 360.0) - (b % 360.0))
    return 360.0 - d if d > 180.0 else d


def detect(a: float, b: float, minor: bool) -> tuple[str, float] | None:
    enabled = dict(MAJOR)
    if minor:
        enabled.update(MINOR)
    s = sep(a, b)
    valid = []
    for name, (exact, limit) in enabled.items():
        orb = abs(s - exact)
        if orb <= limit:
            valid.append((orb, name))
    if not valid:
        return None
    orb, name = min(valid)
    return name, orb

boundary_ok = (
    detect(0, 8, False)[0] == "conjunction"
    and detect(0, 8.0001, False) is None
    and detect(0, 30, False) is None
    and detect(0, 32, True)[0] == "semisextile"
    and detect(0, 32.0001, True) is None
    and detect(0, 74, True)[0] == "quintile"
    and detect(0, 74.0001, True) is None
    and detect(0, 147, True)[0] == "quincunx"
    and detect(0, 146.9999, True) is None
)
add("ASPECT_BOUNDARY_FIXTURES", boundary_ok, "inclusive orb boundaries and minor default-off behavior verified")


def amap(points: dict[str, float], minor: bool) -> dict[frozenset[str], str]:
    out = {}
    for a, b in itertools.combinations(points, 2):
        found = detect(points[a], points[b], minor)
        if found:
            out[frozenset((a, b))] = found[0]
    return out


def isasp(m, a, b, kind):
    return m.get(frozenset((a, b))) == kind


def pattern_flags(points: dict[str, float], minor: bool) -> set[str]:
    m = amap(points, minor)
    names = list(points)
    flags: set[str] = set()
    for c in itertools.combinations(names, 3):
        a, b, d = c
        if all(isasp(m, x, y, "trine") for x, y in ((a, b), (a, d), (b, d))):
            flags.add("grandTrine")
        for apex in c:
            base = [x for x in c if x != apex]
            if isasp(m, base[0], base[1], "opposition") and all(isasp(m, apex, x, "square") for x in base):
                flags.add("tSquare")
            if minor and isasp(m, base[0], base[1], "sextile") and all(isasp(m, apex, x, "quincunx") for x in base):
                flags.add("yod")
        if all(isasp(m, x, y, "conjunction") for x, y in itertools.combinations(c, 2)):
            flags.add("stellium")
    for c in itertools.combinations(names, 4):
        pairs = list(itertools.combinations(c, 2))
        if sum(isasp(m, a, b, "opposition") for a, b in pairs) == 2 and sum(isasp(m, a, b, "square") for a, b in pairs) == 4:
            flags.add("grandCross")
        for tri in itertools.combinations(c, 3):
            if not all(isasp(m, a, b, "trine") for a, b in itertools.combinations(tri, 2)):
                continue
            tail = next(x for x in c if x not in tri)
            for v in tri:
                other = [x for x in tri if x != v]
                if isasp(m, tail, v, "opposition") and all(isasp(m, tail, x, "sextile") for x in other):
                    flags.add("kite")
    return flags

patterns_ok = (
    "grandTrine" in pattern_flags({"A": 0, "B": 120, "C": 240}, False)
    and "tSquare" in pattern_flags({"A": 0, "B": 90, "C": 180}, False)
    and "grandCross" in pattern_flags({"A": 0, "B": 90, "C": 180, "D": 270}, False)
    and "stellium" in pattern_flags({"A": 0, "B": 4, "C": 8}, False)
    and "yod" not in pattern_flags({"A": 0, "B": 60, "C": 210}, False)
    and "yod" in pattern_flags({"A": 0, "B": 60, "C": 210}, True)
    and "kite" in pattern_flags({"A": 0, "B": 120, "C": 240, "D": 180}, False)
    and "grandTrine" not in pattern_flags({"A": 0, "B": 126.0001, "C": 240}, False)
)
add("PATTERN_FIXTURES", patterns_ok, "positive and loose-geometry negative pattern fixtures verified")

# Relative imports and lightweight lexical structure.
missing: list[str] = []
pat = re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]")
dart_files = list((ROOT / "lib").rglob("*.dart")) + list((ROOT / "test").rglob("*.dart")) + list((ROOT / "tool").rglob("*.dart"))
for dart in dart_files:
    for n, line in enumerate(dart.read_text(encoding="utf-8").splitlines(), 1):
        match = pat.match(line)
        if not match or match.group(1).startswith(("dart:", "package:")):
            continue
        if not (dart.parent / match.group(1)).resolve().exists():
            missing.append(f"{dart.relative_to(ROOT)}:{n}->{match.group(1)}")
add("RELATIVE_IMPORTS", not missing, "all relative imports resolve" if not missing else str(missing[:8]))

pairs = {")": "(", "]": "[", "}": "{"}

def strip_dart(src: str) -> tuple[str, str]:
    out: list[str] = []
    i = 0
    state = "code"
    quote = ""
    while i < len(src):
        ch = src[i]
        nxt = src[i + 1] if i + 1 < len(src) else ""
        if state == "code":
            if ch == "/" and nxt == "/":
                state = "line"; out.extend((" ", " ")); i += 2; continue
            if ch == "/" and nxt == "*":
                state = "block"; out.extend((" ", " ")); i += 2; continue
            if ch in "'\"":
                if src[i:i+3] == ch * 3:
                    state = "triple"; quote = ch; out.extend((" ", " ", " ")); i += 3; continue
                state = "string"; quote = ch; out.append(" "); i += 1; continue
            out.append(ch); i += 1; continue
        if state == "line":
            if ch == "\n": state = "code"; out.append("\n")
            else: out.append(" ")
            i += 1; continue
        if state == "block":
            if ch == "*" and nxt == "/": state = "code"; out.extend((" ", " ")); i += 2
            else: out.append("\n" if ch == "\n" else " "); i += 1
            continue
        if state == "string":
            if ch == "\\": out.extend((" ", " ")); i += 2; continue
            if ch == quote: state = "code"
            out.append("\n" if ch == "\n" else " "); i += 1; continue
        if state == "triple":
            if src[i:i+3] == quote * 3: state = "code"; out.extend((" ", " ", " ")); i += 3; continue
            out.append("\n" if ch == "\n" else " "); i += 1
    return "".join(out), state

lex_bad: list[str] = []
for dart in dart_files:
    cleaned, state = strip_dart(dart.read_text(encoding="utf-8"))
    stack: list[str] = []
    bad = False
    for ch in cleaned:
        if ch in "([{": stack.append(ch)
        elif ch in ")]}":
            if not stack or stack[-1] != pairs[ch]: bad = True; break
            stack.pop()
    if bad or stack or state not in ("code", "line"):
        lex_bad.append(str(dart.relative_to(ROOT)))
add("DART_STRUCTURAL_SCAN", not lex_bad, f"{len(dart_files)} Dart files scanned" if not lex_bad else str(lex_bad[:10]))

# Native C compile/run regression including modern fixture, KP and Western Placidus.
cc = shutil.which("cc") or shutil.which("gcc") or shutil.which("clang")
if cc:
    try:
        proc = subprocess.run(["bash", str(ROOT / "tool/verify_native_packaging.sh")], cwd=ROOT, text=True, capture_output=True, timeout=120)
        native_output = (proc.stdout + "\n" + proc.stderr).strip()
        add(
            "NATIVE_C_COMPILE_RUN",
            proc.returncode == 0
            and "PASS: native calculations and required shared ABI exports" in native_output
            and "Uranus" in native_output and "Neptune" in native_output and "Pluto" in native_output
            and "KP classic ayanamsha" in native_output,
            native_output[-2200:],
        )
    except Exception as exc:
        add("NATIVE_C_COMPILE_RUN", False, f"native execution exception: {exc}")
else:
    add("NATIVE_C_COMPILE_RUN", False, "no C compiler available")

# Flutter/Dart runtime detection is reported, never promoted to a PASS claim when absent.
dart_bin = shutil.which("dart")
flutter_bin = shutil.which("flutter")
add("FLUTTER_SDK_DETECTED", bool(flutter_bin), flutter_bin or "Flutter SDK unavailable; no flutter analyze/test/build claim")
add("DART_SDK_DETECTED", bool(dart_bin), dart_bin or "Dart SDK unavailable; no dart runtime test claim")

# Those two are informational, not source-gate failures.
for c in CHECKS:
    if c["code"] in {"FLUTTER_SDK_DETECTED", "DART_SDK_DETECTED"}:
        c["informational"] = True

failed = [c for c in CHECKS if not c["passed"] and not c.get("informational")]
report = {
    "validationVersion": "v082-western-modern-source-validator-v1",
    "milestone": "v082",
    "appVersion": "0.78.0+82",
    "databaseSchema": 12,
    "nativeAbi": "al-abi-9",
    "westernEngine": "1.1.0",
    "westernOutputSchema": "western-natal-chart-v2",
    "westernInputSchema": "western-input-schema-v2",
    "backupEngine": "1.4.0",
    "dartFilesScanned": len(dart_files),
    "sourceGatePassed": not failed,
    "checksPassed": sum(1 for c in CHECKS if c["passed"] and not c.get("informational")),
    "checksTotal": sum(1 for c in CHECKS if not c.get("informational")),
    "failed": [c["code"] for c in failed],
    "sdkAvailability": {"flutter": flutter_bin, "dart": dart_bin, "cCompiler": cc},
    "flutterRuntimeDisclaimer": "No Flutter analyzer/test/APK/Windows Flutter build success is claimed unless a Flutter/Dart SDK is actually present and those commands are executed.",
    "checks": CHECKS,
}
(ROOT / "ASTRO_LOGIC_v082_SOURCE_VALIDATION.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(json.dumps({k: report[k] for k in ("sourceGatePassed", "checksPassed", "checksTotal", "failed", "dartFilesScanned", "sdkAvailability")}, indent=2, ensure_ascii=False))
raise SystemExit(1 if failed else 0)
