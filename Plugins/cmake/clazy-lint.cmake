find_program(CLAZY_STANDALONE_EXE clazy-standalone)

if(NOT CLAZY_STANDALONE_EXE)
  message(STATUS "clazy-standalone not found — `lint-clazy` target will report an error if invoked")
endif()

file(GLOB_RECURSE VAST_LINT_SOURCES
  CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/Plugins/Vast/*.cpp"
)

set(CLAZY_CHECK_LIST
  "level1"
  "detaching-member"
  "container-inside-loop"
  "rule-of-three"
  "function-args-by-value"
  "missing-qobject-macro"
  "ctor-missing-parent-argument"
)
list(JOIN CLAZY_CHECK_LIST "," CLAZY_CHECKS_ARG)

add_custom_target(lint-clazy
  COMMAND ${CMAKE_COMMAND} -E echo "Running clazy-standalone (${CLAZY_CHECKS_ARG}) over Vast sources..."
  COMMAND ${CMAKE_COMMAND} -E env
          "CLAZY_HEADER_FILTER=${CMAKE_SOURCE_DIR}/Plugins/Vast/"
          "CLAZY_IGNORE_DIRS=${CMAKE_SOURCE_DIR}/Plugins/third_party/"
          ${CLAZY_STANDALONE_EXE}
          -checks=${CLAZY_CHECKS_ARG}
          -p ${CMAKE_BINARY_DIR}
          ${VAST_LINT_SOURCES}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "clazy static analysis (excludes third_party/)"
  VERBATIM
  USES_TERMINAL
)

# TU compile commands reference the pchset .pch files via -include-pch, but
# the sets are EXCLUDE_FROM_ALL: in a fresh PCH-enabled build dir the .pch
# files do not exist yet when lint-clazy runs first. Build them first.
# No-op when VAST_NO_PCH=ON (targets do not exist).
foreach(VAST_LINT_DEP IN ITEMS vast-pchset-common vast-pchset-large vast-pchset-plugin wayland-ext-data-control)
    if(TARGET ${VAST_LINT_DEP})
        add_dependencies(lint-clazy ${VAST_LINT_DEP})
    endif()
endforeach()
unset(VAST_LINT_DEP)
