#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_root="$(mktemp -d)"
trap 'rm -rf -- "$build_root"' EXIT

cc_bin="${CC:-cc}"

"$cc_bin" -std=c99 -O2 -fPIC \
  -I"$project_root/third_party/astronomy_engine" \
  -I"$project_root/native" \
  -c "$project_root/third_party/astronomy_engine/astronomy.c" \
  -o "$build_root/astronomy.o"

"$cc_bin" -std=c99 -O2 -fPIC -Wall -Wextra -Werror \
  -I"$project_root/third_party/astronomy_engine" \
  -I"$project_root/native" \
  -c "$project_root/native/astro_logic_astronomy.c" \
  -o "$build_root/wrapper.o"

"$cc_bin" -std=c99 -O2 -Wall -Wextra -Werror \
  -I"$project_root/native" \
  -c "$project_root/native/tests/reference_accuracy_test.c" \
  -o "$build_root/reference_accuracy_test.o"

"$cc_bin" \
  "$build_root/astronomy.o" \
  "$build_root/wrapper.o" \
  "$build_root/reference_accuracy_test.o" \
  -lm -o "$build_root/reference_accuracy_test"

"$build_root/reference_accuracy_test"

"$cc_bin" -shared \
  "$build_root/astronomy.o" \
  "$build_root/wrapper.o" \
  -lm -o "$build_root/libastro_logic_astronomy.so"

for symbol in \
  al_astronomy_engine_version \
  al_geocentric_position \
  al_calculate_frame_supplement \
  al_calculate_kp_frame \
  al_calculate_western_frame
do
  if ! nm -D --defined-only "$build_root/libastro_logic_astronomy.so" \
      | awk '{print $3}' | grep -Fxq "$symbol"; then
    echo "Missing exported ABI symbol: $symbol" >&2
    exit 1
  fi
done

echo "PASS: native calculations and required shared ABI exports"
