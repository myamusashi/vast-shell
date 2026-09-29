#   tst_jobexecutor   JobExecutor: off-thread execution, one worker, ordering
#
# Toolchain and deps come from the flake devShell (shell.nix) in CI. vast-jobs is
# a plain static library, so no Qml module is involved and Qt6::Core is enough.
#
# QSemaphore is default-constructed on purpose: its constructor argument is the
# initial count, not a target, so `QSemaphore sem(10)` starts already satisfied
# and every acquire() returns before the job has run.

add_executable(tst_jobexecutor
    tst_jobexecutor.cpp
)

target_link_libraries(tst_jobexecutor PRIVATE
    Qt6::Core
    Qt6::Test
    vast-jobs
)

add_test(NAME tst_jobexecutor COMMAND tst_jobexecutor ${VAST_TEST_ARGS})
