find_program(CLANG_TIDY_EXE clang-tidy)

if(NOT CLANG_TIDY_EXE)
  message(STATUS "clang-tidy not found — `lint-tidy` target will report an error if invoked")
endif()

file(GLOB_RECURSE VAST_TIDY_SOURCES
  CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/Plugins/Vast/*.cpp"
)

# The source list must reach the shell without CMake's `;` list separator
# collapsing: write it newline-separated and let the shell split on newlines.
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/tidy-sources.txt" CONTENT "$<JOIN:${VAST_TIDY_SOURCES},\n>\n")

include(ProcessorCount)
ProcessorCount(VAST_TIDY_JOBS)
if(VAST_TIDY_JOBS EQUAL 0)
    set(VAST_TIDY_JOBS 4)
endif()

find_program(XARGS_EXE xargs REQUIRED)

add_custom_target(lint-tidy
  COMMAND ${CMAKE_COMMAND} -E echo "Running clang-tidy over Vast sources (${VAST_TIDY_JOBS} jobs)..."
  COMMAND sh -c "tr '\\n' '\\0' < \"${CMAKE_BINARY_DIR}/tidy-sources.txt\" | \"${XARGS_EXE}\" -0 -P ${VAST_TIDY_JOBS} -n 1 \"${CLANG_TIDY_EXE}\" -p \"${CMAKE_BINARY_DIR}\""
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "clang-tidy static analysis (excludes third_party/)"
  VERBATIM
  USES_TERMINAL
)

# Same ordering hazard as lint-clazy: TU compile commands reference the
# pchset .pch files and the generated Wayland header, neither of which exists
# in a fresh build dir when lint-tidy runs first. Build them first.
# pchset entries no-op when VAST_NO_PCH=ON (targets do not exist).
foreach(VAST_TIDY_DEP IN ITEMS vast-pchset-common vast-pchset-large vast-pchset-plugin wayland-ext-data-control)
    if(TARGET ${VAST_TIDY_DEP})
        add_dependencies(lint-tidy ${VAST_TIDY_DEP})
    endif()
endforeach()
unset(VAST_TIDY_DEP)
