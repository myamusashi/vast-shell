# Thin CMake wrapper for the vendored yaml-cpp submodule.
# Upstream (github.com/jbeder/yaml-cpp) ships its own CMakeLists.txt, which
# includes CTest, enables parse tools by default, and exports non-SYSTEM
# include directories. Defining the static library here keeps the vendored
# tree pristine and applies the project's SYSTEM include and warning-suppression
# conventions.

set(YAML_CPP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../yaml-cpp")

include("${YAML_CPP_ROOT}/cmake/yaml-cpp-sources.cmake")

list(TRANSFORM yaml-cpp-sources PREPEND "${YAML_CPP_ROOT}/")
list(TRANSFORM yaml-cpp-contrib-sources PREPEND "${YAML_CPP_ROOT}/")

add_library(yaml-cpp STATIC
    ${yaml-cpp-sources}
    ${yaml-cpp-contrib-sources}
)
add_library(yaml-cpp::yaml-cpp ALIAS yaml-cpp)
set_target_properties(yaml-cpp PROPERTIES POSITION_INDEPENDENT_CODE ON)

# SYSTEM so consumers' strict warning flags don't fire on vendored headers.
target_include_directories(yaml-cpp SYSTEM PUBLIC "${YAML_CPP_ROOT}/include")
target_include_directories(yaml-cpp PRIVATE "${YAML_CPP_ROOT}/src")

target_compile_definitions(yaml-cpp PUBLIC YAML_CPP_STATIC_DEFINE)
target_compile_features(yaml-cpp PUBLIC cxx_std_11)

# Vendored code is not held to this project's strict warning flags.
target_compile_options(yaml-cpp PRIVATE -w)
