import 'dart:io';

void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run this script from the ASTRO LOGIC project root.');
    exitCode = 2;
    return;
  }

  final generatedWidgetTest = File('${root.path}/test/widget_test.dart');
  final widgetTestExistedBeforeBootstrap = generatedWidgetTest.existsSync();

  final create = Process.runSync(
    'flutter',
    const [
      'create',
      '.',
      '--platforms=android',
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

  final gradle = File('${root.path}/android/app/build.gradle.kts');
  if (!gradle.existsSync()) {
    stderr.writeln('Flutter did not generate android/app/build.gradle.kts.');
    exitCode = 3;
    return;
  }
  var source = gradle.readAsStringSync();

  source = source.replaceFirst(
    'minSdk = flutter.minSdkVersion',
    'minSdk = 24',
  );

  const nativePath = '../../native/platform/android/CMakeLists.txt';
  if (!source.contains(nativePath)) {
    const defaultConfigAnchor = '    defaultConfig {\n';
    const nativeDefaultConfig = '''    defaultConfig {
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_PLATFORM=android-24")
            }
        }
''';
    if (!source.contains(defaultConfigAnchor)) {
      stderr.writeln('Generated Gradle defaultConfig block was not found.');
      exitCode = 4;
      return;
    }
    source = source.replaceFirst(defaultConfigAnchor, nativeDefaultConfig);

    const flutterAnchor = '}\n\nflutter {\n';
    const nativeBuild = '''
}

extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
    externalNativeBuild {
        cmake {
            path = project.file("../../native/platform/android/CMakeLists.txt")
            version = "3.22.1"
        }
    }
}

flutter {
''';
    if (!source.contains(flutterAnchor)) {
      stderr.writeln('Generated Gradle android block ending was not found.');
      exitCode = 5;
      return;
    }
    source = source.replaceFirst(flutterAnchor, nativeBuild);
  }
  gradle.writeAsStringSync(source);

  final wrapperProperties = File(
    '${root.path}/android/gradle/wrapper/gradle-wrapper.properties',
  );
  if (!wrapperProperties.existsSync()) {
    stderr.writeln('Flutter did not generate Gradle wrapper properties.');
    exitCode = 6;
    return;
  }
  var wrapperSource = wrapperProperties.readAsStringSync();
  final networkTimeout = RegExp(r'^networkTimeout=.*$', multiLine: true);
  if (networkTimeout.hasMatch(wrapperSource)) {
    wrapperSource = wrapperSource.replaceFirst(
      networkTimeout,
      'networkTimeout=60000',
    );
  } else {
    if (!wrapperSource.endsWith('\n')) wrapperSource += '\n';
    wrapperSource += 'networkTimeout=60000\n';
  }
  wrapperProperties.writeAsStringSync(wrapperSource);

  final manifest = File(
    '${root.path}/android/app/src/main/AndroidManifest.xml',
  );
  var manifestSource = manifest.readAsStringSync();
  manifestSource = manifestSource.replaceFirst(
    'android:label="astro_logic"',
    'android:label="ASTRO LOGIC"',
  );
  manifest.writeAsStringSync(manifestSource);


  if (!widgetTestExistedBeforeBootstrap && generatedWidgetTest.existsSync()) {
    generatedWidgetTest.deleteSync();
  }

  stdout.writeln('Android runner configured for ASTRO LOGIC native ABI.');
}
