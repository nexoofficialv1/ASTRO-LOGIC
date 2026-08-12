cmake_minimum_required(VERSION 3.15)
project(astro_logic_android_native C)

# Gradle's externalNativeBuild points at this file. Keeping the actual target
# in native/CMakeLists.txt guarantees Android and Windows compile identical
# reviewed sources and export the same ABI.
add_subdirectory(
  "${CMAKE_CURRENT_LIST_DIR}/../.."
  "${CMAKE_CURRENT_BINARY_DIR}/astro_logic_core"
)
