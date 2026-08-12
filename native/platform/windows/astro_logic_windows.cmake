# Include this file near the end of the generated windows/CMakeLists.txt, after
# INSTALL_BUNDLE_LIB_DIR has been declared by Flutter's Windows runner.

if(NOT DEFINED INSTALL_BUNDLE_LIB_DIR)
  message(FATAL_ERROR
    "INSTALL_BUNDLE_LIB_DIR must be defined before ASTRO LOGIC integration")
endif()

if(NOT TARGET astro_logic_astronomy)
  add_subdirectory(
    "${CMAKE_CURRENT_LIST_DIR}/../.."
    "${CMAKE_CURRENT_BINARY_DIR}/astro_logic_native"
  )
endif()

# Dart opens astro_logic_astronomy.dll beside the packaged application.
install(
  TARGETS astro_logic_astronomy
  RUNTIME DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime
)
