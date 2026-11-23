# Thin CMake wrapper for the vendored yaml-cpp submodule.
# Upstream (github.com/jbeder/yaml-cpp) ships its own CMakeLists.txt, which
# includes CTest, enables parse tools by default, and exports non-SYSTEM
# include directories. Defining the static library here keeps the vendored
# tree pristine and applies the project's SYSTEM include and warning-suppression
# conventions.

set(YAML_CPP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../yaml-cpp")

# Only the parser/node subset required by YAML::Load in Vast.Lyrics is
# compiled; emitter and contrib sources are unused and excluded.
set(yaml-cpp-sources
    "${YAML_CPP_ROOT}/src/depthguard.cpp"
    "${YAML_CPP_ROOT}/src/directives.cpp"
    "${YAML_CPP_ROOT}/src/exceptions.cpp"
    "${YAML_CPP_ROOT}/src/exp.cpp"
    "${YAML_CPP_ROOT}/src/memory.cpp"
    "${YAML_CPP_ROOT}/src/node_data.cpp"
    "${YAML_CPP_ROOT}/src/nodebuilder.cpp"
    "${YAML_CPP_ROOT}/src/null.cpp"
    "${YAML_CPP_ROOT}/src/parse.cpp"
    "${YAML_CPP_ROOT}/src/parser.cpp"
    "${YAML_CPP_ROOT}/src/regex_yaml.cpp"
    "${YAML_CPP_ROOT}/src/scanner.cpp"
    "${YAML_CPP_ROOT}/src/scanscalar.cpp"
    "${YAML_CPP_ROOT}/src/scantag.cpp"
    "${YAML_CPP_ROOT}/src/scantoken.cpp"
    "${YAML_CPP_ROOT}/src/simplekey.cpp"
    "${YAML_CPP_ROOT}/src/singledocparser.cpp"
    "${YAML_CPP_ROOT}/src/stream.cpp"
    "${YAML_CPP_ROOT}/src/tag.cpp"
)

add_library(yaml-cpp STATIC
    ${yaml-cpp-sources}
)
add_library(yaml-cpp::yaml-cpp ALIAS yaml-cpp)
set_target_properties(yaml-cpp PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    AUTOMOC OFF
    UNITY_BUILD ON
    UNITY_BUILD_BATCH_SIZE 8
)

# SYSTEM so consumers' strict warning flags don't fire on vendored headers.
target_include_directories(yaml-cpp SYSTEM PUBLIC "${YAML_CPP_ROOT}/include")
target_include_directories(yaml-cpp PRIVATE "${YAML_CPP_ROOT}/src")

target_compile_definitions(yaml-cpp PUBLIC YAML_CPP_STATIC_DEFINE)
target_compile_features(yaml-cpp PUBLIC cxx_std_11)

# Vendored code is not held to this project's strict warning flags.
target_compile_options(yaml-cpp PRIVATE -w)
