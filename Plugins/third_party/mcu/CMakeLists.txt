# Thin CMake wrapper for the vendored material-color-utilities submodule.
# Upstream (github.com/material-foundation/material-color-utilities) is a
# Bazel-only project and ships no CMakeLists.txt, so we define the library
# here instead of inside the submodule to keep the vendored tree pristine.

set(MCU_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../material-color-utilities")

add_library(material-color-utilities STATIC
    "${MCU_ROOT}/cpp/cam/cam.cc"
    "${MCU_ROOT}/cpp/cam/hct.cc"
    "${MCU_ROOT}/cpp/cam/hct_solver.cc"
    "${MCU_ROOT}/cpp/contrast/contrast.cc"
    "${MCU_ROOT}/cpp/dislike/dislike.cc"
    "${MCU_ROOT}/cpp/dynamiccolor/dynamic_color.cc"
    "${MCU_ROOT}/cpp/palettes/tones.cc"
    "${MCU_ROOT}/cpp/quantize/celebi.cc"
    "${MCU_ROOT}/cpp/quantize/lab.cc"
    "${MCU_ROOT}/cpp/quantize/wsmeans.cc"
    "${MCU_ROOT}/cpp/quantize/wu.cc"
    "${MCU_ROOT}/cpp/score/score.cc"
    "${MCU_ROOT}/cpp/utils/utils.cc"
)

set_target_properties(material-color-utilities PROPERTIES
    AUTOMOC OFF
    UNITY_BUILD ON
    UNITY_BUILD_BATCH_SIZE 8
)

# wsmeans.cc calls unqualified abs(double) after including <cmath> and
# <cstdlib> (no <math.h>), so standalone compilation resolves ::abs(int).
# Including it after cam.cc's <math.h> in a unity TU brings ::abs(double) into
# the global namespace and shifts k-means convergence against the golden suite.
set_source_files_properties("${MCU_ROOT}/cpp/quantize/wsmeans.cc" PROPERTIES
    SKIP_UNITY_BUILD_INCLUSION ON
)

# Headers include each other as "cpp/<module>/<header>.h". SYSTEM so
# consumers' strict warning flags don't fire on vendored headers.
target_include_directories(material-color-utilities SYSTEM PUBLIC "${MCU_ROOT}")

# Upstream has a hard Abseil dependency in two files (wsmeans.cc, utils.cc).
# The used API surface is tiny, so instead of pulling in abseil-cpp we shadow
# those two includes with minimal shims; this dir must stay first on the
# include path.
target_include_directories(material-color-utilities PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/absl_shim"
)

target_compile_features(material-color-utilities PUBLIC cxx_std_17)

# Vendored code is not held to this project's strict warning flags.
target_compile_options(material-color-utilities PRIVATE -w)
