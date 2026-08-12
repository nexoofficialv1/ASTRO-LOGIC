import 'dart:io';

void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run this script from the ASTRO LOGIC project root.');
    exitCode = 2;
    return;
  }

  final create = Process.runSync(
    'flutter',
    const [
      'create',
      '.',
      '--platforms=windows',
      '--org=in.nexoofficial.astrologic',
      '--project-name=astro_logic',
      '--no-pub',
    ],
    runInShell: true,
  );
  stdout.write(create.stdout);
  stderr.write(create.stderr);
  if (create.exitCode != 0) {
    exitCode = create.exitCode;
    return;
  }

  final cmake = File('${root.path}/windows/CMakeLists.txt');
  if (!cmake.existsSync()) {
    stderr.writeln('Flutter did not generate windows/CMakeLists.txt.');
    exitCode = 3;
    return;
  }

  const integrationLine =
      'include("\${CMAKE_CURRENT_SOURCE_DIR}/../native/platform/windows/astro_logic_windows.cmake")';
  var cmakeSource = cmake.readAsStringSync();
  if (!cmakeSource.contains(integrationLine)) {
    final libDirAnchor = RegExp(
      r'set\(INSTALL_BUNDLE_LIB_DIR[^\n]*\)\r?\n',
      multiLine: true,
    );
    final match = libDirAnchor.firstMatch(cmakeSource);
    if (match == null) {
      stderr.writeln(
        'Generated Windows CMake INSTALL_BUNDLE_LIB_DIR declaration was not found.',
      );
      exitCode = 4;
      return;
    }
    cmakeSource = cmakeSource.replaceRange(
      match.end,
      match.end,
      '\n# ASTRO LOGIC governed native FFI packaging.\n$integrationLine\n',
    );
    cmake.writeAsStringSync(cmakeSource);
  }

  final mainCpp = File('${root.path}/windows/runner/main.cpp');
  if (mainCpp.existsSync()) {
    var source = mainCpp.readAsStringSync();
    source = source.replaceAll('L"astro_logic"', 'L"ASTRO LOGIC"');
    mainCpp.writeAsStringSync(source);
  }

  stdout.writeln('Windows runner configured for ASTRO LOGIC native ABI.');
}
