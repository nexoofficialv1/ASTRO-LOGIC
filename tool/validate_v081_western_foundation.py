#!/usr/bin/env python3
"""Source/native validation for ASTRO LOGIC v081 Western Foundation v1."""
from pathlib import Path
import json, re, subprocess

ROOT = Path(__file__).resolve().parents[1]
checks = []

def text(path): return (ROOT/path).read_text(encoding='utf-8')
def add(code, ok, detail): checks.append({'code': code, 'passed': bool(ok), 'detail': detail})
def has(src, *parts): return all(part in src for part in parts)

pub = text('pubspec.yaml')
change = text('CHANGELOG.md')
modules = text('lib/src/models/astro_module.dart')
dashboard = text('lib/src/screens/dashboard_screen.dart')
engine = text('lib/src/western/western_chart_engine.dart')
gov = text('lib/src/western/western_governance.dart')
bridge = text('lib/src/western/western_native_ffi_bridge.dart')
bridge_contract = text('lib/src/western/western_native_bridge.dart')
store = text('lib/src/data/client_store.dart')
orch = text('lib/src/services/western_chart_orchestrator.dart')
consult = text('lib/src/screens/consultation_detail_screen.dart')
workspace = text('lib/src/screens/western_workspace_screen.dart')
copy = text('lib/src/localization/app_copy.dart')
header = text('native/astro_logic_astronomy.h')
native = text('native/astro_logic_astronomy.c')
native_test = text('native/tests/reference_accuracy_test.c')
test = text('test/western_chart_engine_test.dart')
status = text('V081_WESTERN_FOUNDATION_STATUS.md')
sources = text('WESTERN_RULE_SOURCES.md')
db = text('lib/src/data/app_database.dart')
backup = text('lib/src/services/encrypted_backup_service.dart')

add('VERSION', 'version: 0.77.0+81' in pub, 'pubspec v081')
add('CHANGELOG_TOP', change.startswith('## 0.77.0+81'), 'changelog v081 first')
add('DB_SCHEMA_12', 'static const schemaVersion = 12;' in db, 'SQLite remains schema 12')
add('BACKUP_ENGINE_14', "engineVersion = '1.4.0'" in backup, 'backup engine remains 1.4.0')
add('WESTERN_AVAILABLE', "copyKey: 'western'" in modules and not re.search(r"copyKey:\s*'western'[\s\S]{0,180}comingSoon", modules), 'Western dashboard tile available')
add('DASHBOARD_ROUTE', "module.copyKey == 'western'" in dashboard and 'WesternWorkspaceScreen' in dashboard, 'Western workspace route')
add('ENGINE_ID', has(engine, "engineId = 'astro-logic-western-native'", "engineVersion = '1.0.0'", "outputSchemaVersion = 'western-natal-chart-v1'", "inputSchemaVersion = 'western-input-schema-v1'"), 'Western engine contracts')
add('GOVERNANCE', has(gov, "profileVersion = 'western-foundation-v1'", "tropicalProfile = 'western-tropical-zodiac-v1'", "aspectProfile = 'western-major-aspect-orb-v1'", "dignityProfile = 'western-essential-dignity-major-v1'"), 'governance contracts')
add('HOUSE_PROFILES', all(x in gov for x in ['western-placidus-native-v1','western-whole-sign-v1','western-equal-ascendant-v1']), 'three house profiles')
add('TRADITIONAL_BODIES', all(x in engine for x in ['WesternBody.sun','WesternBody.moon','WesternBody.mercury','WesternBody.venus','WesternBody.mars','WesternBody.jupiter','WesternBody.saturn']), 'seven traditional planets')
add('NODE_POINTS', all(x in engine for x in ['WesternBody.northNode','WesternBody.southNode','trueNodeTropical','meanNodeTropical']), 'selected node pair')
add('NODE_EXCLUDED_ASPECTS', "_traditionalAspectBodies" in engine and 'northNode' not in re.search(r"_traditionalAspectBodies\s*=\s*<WesternBody>\[(.*?)\];", engine, re.S).group(1), 'nodes outside v1 aspect matrix')
add('FIVE_ASPECTS', all(x in engine for x in ['conjunction: 0.0','sextile: 60.0','square: 90.0','trine: 120.0','opposition: 180.0']), 'five major exact angles')
add('ORB_PROFILE', all(x in engine for x in ['conjunction: 8.0','sextile: 4.0','square: 6.0','trine: 6.0','opposition: 8.0']), 'frozen v1 orbs')
add('APPLY_SEPARATE', all(x in engine for x in ['WesternAspectMotion.applying','WesternAspectMotion.separating','longitudeSpeedPerDay']), 'motion evidence')
add('DIGNITY_ENUM', all(x in engine for x in ['domicile, exaltation, detriment, fall']), 'four major dignity/debility states')
add('MERCURY_MULTI_DIGNITY', 'domicile: [2, 5]' in engine and 'exaltation: [5]' in engine, 'Virgo can preserve Mercury domicile + exaltation')
add('NO_DIGNITY_SCORE', "'numericScoreGenerated': false" in engine, 'no numeric dignity score')
add('NO_PREDICTION', "'automaticEventPrediction': false" in engine and "'crossSystemConfidenceUplift': false" in engine, 'no automatic prediction/cross-system uplift')
add('PLACIDUS_EXPLICIT_GATE', 'frame.placidusAvailable' in engine and 'no fallback house system was substituted' in engine, 'Placidus failure explicit')
add('WHOLE_SIGN_FORMULA', '(asc / 30.0).floor() * 30.0 + index * 30.0' in engine, 'Whole Sign deterministic cusps')
add('EQUAL_FORMULA', 'asc + index * 30.0' in engine, 'Equal house deterministic cusps')
add('HOUSE_ASSIGNMENT', 'houseForLongitude' in engine and '_isInForwardArc' in engine, 'circular cusp house assignment')
add('WESTERN_NATIVE_ABI', 'al-abi-8' in bridge and 'al_calculate_western_frame' in bridge, 'Western bridge uses ABI 8')
add('NATIVE_STRUCT', 'typedef struct al_western_frame' in header and 'placidus_status' in header, 'native Western frame struct')
add('NATIVE_EXPORT', 'AL_API al_western_frame al_calculate_western_frame' in header and 'al_western_frame al_calculate_western_frame' in native, 'native Western export')
add('POLAR_CORE_SEPARATION', 'result.status = ASTRO_SUCCESS;' in native[native.index('al_western_frame al_calculate_western_frame'):native.index('al_frame_supplement al_calculate_frame_supplement')] and 'result.placidus_status = placidus_status;' in native, 'core status separate from Placidus status')
add('NATIVE_FIXTURE', 'Western native frame regression failed' in native_test and 'Western polar core/fallback gate failed' in native_test, 'native Western reference/polar tests')
add('STORE_WESTERN_INPUT', 'createWesternInputSnapshot' in store and "snapshot_kind': 'western-input'" in store, 'Western-specific immutable input snapshot')
add('STORE_HASH_PROFILE', all(x in store for x in ['WesternGovernance.tropicalProfile','WesternGovernance.aspectProfile','WesternGovernance.dignityProfile','WesternChartEngine.inputSchemaVersion']), 'Western hash settings bound')
add('ORCHESTRATOR', 'WesternChartOrchestrator' in orch and 'createWesternInputSnapshot' in orch and 'createCalculationOutputSnapshot' in orch, 'consultation Western orchestration')
add('CONSULTATION_BUTTON', 'canRunWestern' in consult and '_runWesternChart' in consult and 'WesternNativeFfiBridge.open()' in consult, 'consultation execution UI')
add('WORKSPACE_CAST', 'WesternWorkspaceScreen' in workspace and 'WesternChartEngine(WesternNativeFfiBridge.open())' in workspace, 'standalone workspace cast')
add('WORKSPACE_SECTIONS', all(x in workspace for x in ['westernPlanetsHouses','westernMajorAspects','westernDignities','westernScopeNote']), 'Western evidence UI sections')
add('TESTS_PRESENT', all(x in test for x in ['WesternHouseSystem.equal','WesternHouseSystem.wholeSign','WesternHouseSystem.placidus','WesternDignityCondition.domicile','WesternDignityCondition.exaltation']), 'Western unit source tests')
add('SOURCE_DOC', 'Scope enabled in v081 — Western Astrology Foundation v1' in sources, 'Western source governance documented')
add('STATUS_DOC', 'Western Astrology Foundation v1' in status and 'v082' in status, 'status and next milestone documented')
add('README_CURRENT', 'v0.77.0+81 — Western Astrology Foundation v1' in text('README.md'), 'README current')
add('PRODUCT_CURRENT', 'Western Foundation v1 is available' in text('PRODUCT_SPEC.md'), 'product spec current')
add('DATABASE_NOTE', 'v081 Western Foundation — schema unchanged' in text('DATABASE.md'), 'database note current')
add('BACKUP_NOTE', 'v0.77.0+81 — Western Foundation snapshot coverage' in text('BACKUP_SECURITY.md'), 'backup coverage current')
add('EPHEMERIS_NOTE', 'Western native profile — v0.77.0+81' in text('EPHEMERIS.md') and 'al-abi-8' in text('EPHEMERIS.md'), 'ephemeris current')
add('ANDROID_WIRING', (ROOT/'native/platform/android/CMakeLists.txt').exists(), 'Android native wiring retained')
add('WINDOWS_WIRING', (ROOT/'native/platform/windows/astro_logic_windows.cmake').exists(), 'Windows native wiring retained')

# Independent deterministic reference simulations for core Western rules.
def norm(v):
    return v % 360.0

def sep(a,b):
    d=abs(norm(a)-norm(b))
    return 360-d if d>180 else d

# Whole sign/equal cusp geometry.
asc=259.8330326
whole=[norm(int(asc//30)*30+i*30) for i in range(12)]
equal=[norm(asc+i*30) for i in range(12)]
add('SIM_WHOLE_SIGN', whole[0] == 240.0 and whole[1] == 270.0 and whole[-1] == 210.0, f'whole={whole[:2]}...{whole[-1]}')
add('SIM_EQUAL', abs(equal[0]-asc)<1e-12 and abs(sep(equal[1], norm(asc+30)))<1e-12, 'equal ascendant cusps')

# Aspect profile examples: 2° conjunction, 3° sextile, 7° square rejected.
angles={'conjunction':(0,8),'sextile':(60,4),'square':(90,6),'trine':(120,6),'opposition':(180,8)}
def aspect(a,b):
    s=sep(a,b); candidates=[]
    for name,(exact,orb) in angles.items():
        e=abs(s-exact)
        if e<=orb: candidates.append((e,name))
    return min(candidates)[1] if candidates else None
add('SIM_ASPECTS', aspect(10,12)=='conjunction' and aspect(10,73)=='sextile' and aspect(10,107) is None and aspect(10,190)=='opposition', 'major aspect/orb simulation')

# Dignity fixtures from the frozen table.
dignity={
 'sun': {'dom':[4],'ex':[0],'det':[10],'fall':[6]},
 'moon': {'dom':[3],'ex':[1],'det':[9],'fall':[7]},
 'mercury': {'dom':[2,5],'ex':[5],'det':[8,11],'fall':[11]},
 'venus': {'dom':[1,6],'ex':[11],'det':[0,7],'fall':[5]},
 'mars': {'dom':[0,7],'ex':[9],'det':[1,6],'fall':[3]},
 'jupiter': {'dom':[8,11],'ex':[3],'det':[2,5],'fall':[9]},
 'saturn': {'dom':[9,10],'ex':[6],'det':[3,4],'fall':[0]},
}
def cond(body,sign): return [k for k,v in dignity[body].items() if sign in v]
add('SIM_DIGNITY', cond('mercury',5)==['dom','ex'] and cond('mercury',11)==['det','fall'] and cond('sun',4)==['dom'], 'traditional dignity fixtures')

# Localization parity.
blocks=dict(re.findall(r"'([a-z]{2})': \{([\s\S]*?)\n    \},", copy))
keys={lang:re.findall(r"^\s*'([^']+)':",body,re.M) for lang,body in blocks.items()}
add('LOCALE_PARITY', set(keys.get('en',[]))==set(keys.get('bn',[])), 'EN/BN key parity')
add('LOCALE_DUPLICATES', all(len(v)==len(set(v)) for v in keys.values()), 'no duplicate localization keys')
for key in ['westernWorkspace','westernFoundationTitle','westernCastChart','westernMajorAspects','westernDignities','westernPlacidusNoFallback','northNode','southNode']:
    add('COPY_'+key, key in set(keys.get('en',[])), key+' localized')

# Relative import resolution.
missing=[]; pat=re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]")
for dart in list((ROOT/'lib').rglob('*.dart'))+list((ROOT/'test').rglob('*.dart')):
    for n,line in enumerate(dart.read_text(encoding='utf-8').splitlines(),1):
        m=pat.match(line)
        if not m or m.group(1).startswith(('dart:','package:')): continue
        if not (dart.parent/m.group(1)).resolve().exists(): missing.append(f'{dart.relative_to(ROOT)}:{n}->{m.group(1)}')
add('RELATIVE_IMPORTS', not missing, 'all relative imports resolve' if not missing else str(missing[:8]))

# Lightweight Dart lexical balance.
pairs={')':'(',']':'[','}':'{'}
def strip(src):
    out=[];i=0;state='code';q=''
    while i<len(src):
        ch=src[i]; nxt=src[i+1] if i+1<len(src) else ''
        if state=='code':
            if ch=='/' and nxt=='/': state='line';out+=[' ',' '];i+=2;continue
            if ch=='/' and nxt=='*': state='block';out+=[' ',' '];i+=2;continue
            if ch in "'\"":
                if src[i:i+3]==ch*3: state='triple';q=ch;out+=[' ',' ',' '];i+=3;continue
                state='string';q=ch;out.append(' ');i+=1;continue
            out.append(ch);i+=1;continue
        if state=='line':
            if ch=='\n': state='code';out.append('\n')
            else: out.append(' ')
            i+=1;continue
        if state=='block':
            if ch=='*' and nxt=='/': state='code';out+=[' ',' '];i+=2
            else: out.append('\n' if ch=='\n' else ' ');i+=1
            continue
        if state=='string':
            if ch=='\\': out+=[' ',' '];i+=2;continue
            if ch==q: state='code'
            out.append('\n' if ch=='\n' else ' ');i+=1;continue
        if state=='triple':
            if src[i:i+3]==q*3: state='code';out+=[' ',' ',' '];i+=3;continue
            out.append('\n' if ch=='\n' else ' ');i+=1
    return ''.join(out),state
lex=[]; dart_files=list((ROOT/'lib').rglob('*.dart'))+list((ROOT/'test').rglob('*.dart'))+list((ROOT/'tool').rglob('*.dart'))
for dart in dart_files:
    cleaned,state=strip(dart.read_text(encoding='utf-8')); stack=[]; bad=False
    for ch in cleaned:
        if ch in '([{': stack.append(ch)
        elif ch in ')]}':
            if not stack or stack[-1]!=pairs[ch]: bad=True; break
            stack.pop()
    if bad or stack or state not in ('code','line'): lex.append(str(dart.relative_to(ROOT)))
add('DART_LEXICAL', not lex, 'Dart lexical structure clean' if not lex else str(lex[:8]))
add('DART_FILE_COUNT', len(dart_files)>=176, f'{len(dart_files)} Dart source/test/tool files scanned')

# Native compile/execution is an actual runtime gate available in this environment.
try:
    proc=subprocess.run(['bash',str(ROOT/'tool/verify_native_packaging.sh')],cwd=ROOT,text=True,capture_output=True,timeout=120)
    detail=(proc.stdout+'\n'+proc.stderr).strip()
    add('NATIVE_EXECUTION',proc.returncode==0 and 'PASS: native calculations and required shared ABI exports' in detail,detail[-1600:])
except Exception as exc:
    add('NATIVE_EXECUTION',False,f'exception: {exc}')

failed=[c for c in checks if not c['passed']]
report={
  'milestone':'v081','appVersion':'0.77.0+81','databaseSchema':12,
  'nativeAbi':'al-abi-8','westernEngine':'1.0.0',
  'westernOutputSchema':'western-natal-chart-v1','westernInputSchema':'western-input-schema-v1',
  'backupEngine':'1.4.0','dartFilesScanned':len(dart_files),
  'checksPassed':len(checks)-len(failed),'checksTotal':len(checks),
  'failed':[c['code'] for c in failed],
  'flutterRuntimeDisclaimer':'Flutter/Dart SDK unavailable; no analyzer/widget/APK/Windows Flutter build success claimed.',
  'checks':checks,
}
(ROOT/'ASTRO_LOGIC_v081_SOURCE_VALIDATION.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({k:report[k] for k in ['checksPassed','checksTotal','failed','dartFilesScanned','flutterRuntimeDisclaimer']},indent=2))
raise SystemExit(1 if failed else 0)
