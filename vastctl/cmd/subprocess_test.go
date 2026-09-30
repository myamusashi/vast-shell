package cmd

import (
	"errors"
	"flag"
	"os"
	"os/exec"
	"strings"
	"testing"
)

// helperEnv names the scenario the child process should run. When it is
// unset the process is the ordinary test binary.
const helperEnv = "VASTCTL_TEST_SCENARIO"

// runInHelper re-executes this test binary as a child running only the
// named scenario, and returns its combined output.
func runInHelper(t *testing.T, scenario string) (string, error) {
	t.Helper()
	self, err := os.Executable()
	if err != nil {
		t.Fatalf("locate the test binary: %v", err)
	}
	args := []string{"-test.run=^" + t.Name() + "$", "-test.v"}
	// `go test -cover` hands the test binary a -test.gocoverdir and
	// collects whatever lands there. Without forwarding it, everything
	// the child runs is invisible to the report. The child is the same
	// instrumented binary, so its counters merge into the same directory.
	if f := flag.Lookup("test.gocoverdir"); f != nil && f.Value.String() != "" {
		args = append(args, "-test.gocoverdir="+f.Value.String())
	}
	cmd := exec.Command(self, args...)
	cmd.Env = append(os.Environ(), helperEnv+"="+scenario)
	out, err := cmd.CombinedOutput()
	return string(out), err
}

// TestExecuteExitsOnFailure pins the top-level contract: a failing
// command exits non-zero and says why on stderr. A script driving
// vastctl decides whether to continue on the exit status, and swallowing
// the error would make a failed call look like it worked.
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

// TestExecuteExitsWhenNoDaemon pins the other top-level failure. A call
// made with no daemon must exit non-zero and name the command that
// starts one, rather than reporting an empty answer that a script would
// read as success.
func TestExecuteExitsWhenNoDaemon(t *testing.T) {
	if os.Getenv(helperEnv) == "execute-no-daemon" {
		executeNoDaemonScenario(t)
		return
	}

	out, err := runInHelper(t, "execute-no-daemon")
	if err == nil {
		t.Fatalf("Execute returned success with no daemon running:\n%s", out)
	}
	var exitErr *exec.ExitError
	if !errors.As(err, &exitErr) {
		t.Fatalf("the failure was not an exit: %v", err)
	}
	if code := exitErr.ExitCode(); code != 1 {
		t.Fatalf("exit code = %d, want 1", code)
	}
	if !strings.Contains(out, "vastctl daemon start") {
		t.Fatalf("the remedy never reached the user:\n%s", out)
	}
}

// executeFailureScenario is the child half of TestExecuteExitsOnFailure.
func executeFailureScenario(t *testing.T) {
	t.Setenv("SHIM_CODE", "255")
	t.Setenv("SHIM_OUT", "No running instances for \"/cfg/Qml/shell.qml\"\n")
	daemonRuntime(t, "abc123")

	// Execute parses os.Args, so the scenario's own flags have to be
	// replaced with the invocation under test.
	os.Args = []string{"vastctl", "wallpaper", "get"}
	Execute()
	t.Fatal("Execute returned for a command that was meant to fail")
}

// executeNoDaemonScenario is the child half of
// TestExecuteExitsWhenNoDaemon.
func executeNoDaemonScenario(t *testing.T) {
	daemonRuntime(t, "")

	os.Args = []string{"vastctl", "wallpaper", "get"}
	Execute()
	t.Fatal("Execute returned for a command with no daemon running")
}
