package cmd

import (
	"errors"
	"flag"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
)

// Two behaviours here are process-wide and cannot be observed from
// inside the test process: ensureShellDaemon is a sync.Once, so the
// auto-start path is spent as soon as any other test makes an IPC
// call; and Execute calls os.Exit(1), which would take the whole test
// binary down with it. Each is re-run in a child process, the only way
// to give them a clean slate. The child installs its own shims through
// the same TestMain the parent uses, so nothing reaches a real binary.

// helperEnv names the scenario the child process should run. When it is
// unset the process is the ordinary test binary.
const helperEnv = "VASTCTL_TEST_SCENARIO"

// runInHelper re-executes this test binary as a child running only the
// named scenario, and returns its combined output.
func runInHelper(t *testing.T, scenario string) (string, error) {
	t.Helper()
	args := []string{"-test.run=^" + t.Name() + "$", "-test.v"}
	// `go test -cover` hands the test binary a -test.gocoverdir and
	// collects whatever lands there. Without forwarding it, everything
	// the child runs is invisible to the report: the auto-start path
	// looks 13% covered and waitForShell looks untested when both are
	// in fact exercised. The child is the same instrumented binary, so
	// its counters merge into the same directory.
	if f := flag.Lookup("test.gocoverdir"); f != nil && f.Value.String() != "" {
		args = append(args, "-test.gocoverdir="+f.Value.String())
	}
	cmd := exec.Command(os.Args[0], args...)
	cmd.Env = append(os.Environ(), helperEnv+"="+scenario)
	out, err := cmd.CombinedOutput()
	return string(out), err
}

// TestIPCAutostartsTheShell pins the auto-start path. Any `vastctl
// volume get` on a machine where the shell is not up has to bring the
// shell up first, because otherwise the very first command a user runs
// after a reboot fails with "No running instances".
func TestIPCAutostartsTheShell(t *testing.T) {
	if os.Getenv(helperEnv) == "autostart" {
		autostartScenario(t)
		return
	}

	out, err := runInHelper(t, "autostart")
	if err != nil {
		t.Fatalf("helper failed: %v\n%s", err, out)
	}
	if !strings.Contains(out, "SCENARIO OK") {
		t.Fatalf("the scenario did not report success:\n%s", out)
	}
}

// coldShellShim answers `ipc show` as "not running" until the shell has
// been launched, and reports itself running afterwards. That is the
// state a machine is in after a reboot, and it is the only way to
// reach the launch branch: the shim installed by TestMain answers the
// probe successfully, which takes the "already running" early exit.
const coldShellShim = `#!/bin/sh
{ printf -- '---\n'; for a in "$@"; do printf -- '%s\n' "$a"; done; } > "$SHIM_LOG/$$"
case "$*" in
  *" ipc show"*)
    if [ -f "$COLD_READY" ]; then exit 0; fi
    printf 'No running instances for the test config\n'
    exit 255
    ;;
esac
: > "$COLD_READY"
printf 'autostarted\n'
exit 0
`

// autostartScenario is the child half of TestIPCAutostartsTheShell.
func autostartScenario(t *testing.T) {
	dir := t.TempDir()
	log := t.TempDir()
	ready := filepath.Join(dir, "ready")
	if err := os.WriteFile(filepath.Join(dir, "quickshell"), []byte(coldShellShim), 0o755); err != nil {
		t.Fatalf("write quickshell shim: %v", err)
	}
	// Prepended, so this shim wins over the TestMain one.
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	t.Setenv("SHIM_LOG", log)
	t.Setenv("COLD_READY", ready)
	// A checkout the shell can be started against. Without one there
	// is no -p to hand quickshell and the launch is not the one a real
	// user triggers.
	root := t.TempDir()
	writeShellQml(t, filepath.Join(root, "Qml", "shell.qml"))
	t.Setenv("VAST_SHELL_DIRECTORY", root)

	daemonLog := filepath.Join(dir, "daemon.log")
	orig := ipc.LogFilePath
	ipc.LogFilePath = daemonLog
	t.Cleanup(func() { ipc.LogFilePath = orig })

	// Cold, so ensureShellDaemon does not take its "already running"
	// branch and return before launching anything. A recorded false is
	// what a caller that has just stopped the shell sees, which is one
	// of the two situations the auto-start exists for.
	ipc.SetShellRunning(false)

	res, err := runCLI(t, "volume", "system", "get")
	if err != nil {
		t.Fatalf("the call failed instead of starting the shell: %v", err)
	}
	if want := "autostarted\n"; res.stdout != want {
		t.Fatalf("stdout = %q, want %q", res.stdout, want)
	}

	calls := shimInvocations(t, log)
	cfg := filepath.Join(root, "Qml")
	launch := []string{"-p", cfg}
	probe := []string{"-p", cfg, "ipc", "show"}
	// The call carries the same -p prefix as the probe: the config
	// path is what binds the IPC request to this checkout.
	want := []string{"-p", cfg, "ipc", "call", "volume", "systemGet"}

	// The launch and the readiness probe are separate processes started
	// within microseconds of each other — waitForShell begins polling
	// the moment the child is started — so their relative order is not
	// something to assert. Only "the launch happened before the call
	// succeeded" is guaranteed, and that is the point of the test.
	launchAt, probeAt, callAt := -1, -1, -1
	for i, c := range calls {
		switch {
		case slices.Equal(c, launch):
			launchAt = i
		case slices.Equal(c, probe):
			probeAt = i
		case slices.Equal(c, want):
			callAt = i
		}
	}
	if launchAt < 0 {
		t.Fatalf("the shell was never launched with the config path: %q", calls)
	}
	if probeAt < 0 {
		t.Fatalf("the shell's readiness was never probed: %q", calls)
	}
	if callAt < 0 {
		t.Fatalf("the command never reached the shell: %q", calls)
	}
	if launchAt > callAt {
		t.Fatalf("the call was made before the shell was launched: %q", calls)
	}

	// The shell's output is captured into the daemon log, not lost.
	data, err := os.ReadFile(daemonLog)
	if err != nil {
		t.Fatalf("read daemon log: %v", err)
	}
	if !strings.Contains(string(data), "autostarted") {
		t.Fatalf("the daemon log does not hold the shell's output: %q", data)
	}

	t.Log("SCENARIO OK")
}

// TestExecuteExitsOnFailure pins the top-level contract: a failing
// command exits non-zero and says why on stderr. A script driving
// vastctl decides whether to continue on the exit status, and
// swallowing the error would make a failed call look like it worked.
//
// Execute calls os.Exit, so this can only be observed from a child.
func TestExecuteExitsOnFailure(t *testing.T) {
	if os.Getenv(helperEnv) == "execute-failure" {
		executeFailureScenario(t)
		return
	}

	out, err := runInHelper(t, "execute-failure")
	if err == nil {
		t.Fatalf("Execute returned success for a failing command:\n%s", out)
	}
	var exitErr *exec.ExitError
	if !errors.As(err, &exitErr) {
		t.Fatalf("the failure was not an exit: %v", err)
	}
	if code := exitErr.ExitCode(); code != 1 {
		t.Fatalf("exit code = %d, want 1", code)
	}
	if !strings.Contains(out, "No running instances") {
		t.Fatalf("the shell's own diagnostics never reached the user:\n%s", out)
	}
}

// executeFailureScenario is the child half of TestExecuteExitsOnFailure.
func executeFailureScenario(t *testing.T) {
	t.Setenv("SHIM_CODE", "255")
	t.Setenv("SHIM_OUT", "No running instances for \"/cfg/Qml/shell.qml\"\n")
	ipc.SetShellRunning(true)

	// Execute parses os.Args, so the scenario's own flags have to be
	// replaced with the invocation under test.
	os.Args = []string{"vastctl", "wallpaper", "get"}
	Execute()
	t.Fatal("Execute returned for a command that was meant to fail")
}
