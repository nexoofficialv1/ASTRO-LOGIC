# Flutter platform packaging contract

Generate the standard Flutter runners first:

```text
flutter create . --platforms=android,windows --org in.nexoofficial.astrologic --project-name astro_logic
```

Do not commit a downloaded or precompiled astronomical binary. Both platforms
must build the pinned source already present in this repository.

## Android

In `android/app/build.gradle.kts`, add the following entries inside the existing
`android` block. Keep all Flutter-generated settings around them.

```kotlin
defaultConfig {
    externalNativeBuild {
        cmake {
            arguments += listOf("-DANDROID_PLATFORM=android-24")
        }
    }
}

externalNativeBuild {
    cmake {
        path = file("../../native/platform/android/CMakeLists.txt")
        version = "3.22.1"
    }
}
```

The Android Gradle Plugin then builds and packages
`libastro_logic_astronomy.so` for every enabled ABI. The Dart bridge opens that
exact soname. Release builds should normally include `arm64-v8a`; additional
ABIs are a distribution choice, not separate astronomical implementations.

## Windows

Append this line to the generated root `windows/CMakeLists.txt`, after Flutter
defines `INSTALL_BUNDLE_LIB_DIR`:

```cmake
include("${CMAKE_CURRENT_SOURCE_DIR}/../native/platform/windows/astro_logic_windows.cmake")
```

The include builds the same native target and installs
`astro_logic_astronomy.dll` beside the Windows executable, where Dart FFI can
open it.

## Required Flutter build flag

Both platforms must be built with:

```text
--dart-define=ASTRO_LOGIC_EPHEMERIS_BACKEND=astronomy-engine
```

Without the flag, the provider refuses to calculate. With the flag but without
the packaged library, startup of the production engine fails explicitly.


## Governed bootstrap scripts

Do not hand-edit generated runners for release builds. Use:

```text
dart run tool/bootstrap_android_runner.dart
dart run tool/bootstrap_windows_runner.dart
```

The scripts generate the current Flutter template and then apply only the
reviewed ASTRO LOGIC native packaging integration. GitHub Actions runs the same
scripts so local and CI runner configuration cannot silently drift.
