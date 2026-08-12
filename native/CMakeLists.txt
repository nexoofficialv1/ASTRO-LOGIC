cmake_minimum_required(VERSION 3.15)
project(astro_logic_astronomy C)

add_library(astro_logic_astronomy SHARED
  astro_logic_astronomy.c
  ../third_party/astronomy_engine/astronomy.c
)

target_include_directories(astro_logic_astronomy PRIVATE
  ../third_party/astronomy_engine
)

target_compile_features(astro_logic_astronomy PRIVATE c_std_99)

if(NOT WIN32)
  target_link_libraries(astro_logic_astronomy PRIVATE m)
endif()
