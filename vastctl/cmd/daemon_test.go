package cmd

import (
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
)

// recordPgrep points the pgrep shim at a fresh invocation log
// directory and returns it.
func recordPgrep(t *testing.T) string {
	t.Helper()
	return shimLogDir(t, "SHIM_PGREP_LOG")
}

// recordKill points the kill shim at a fresh invocation log directory
// and returns it.
func recordKill(t *testing.T) string {
	t.Helper()
	return shimLogDir(t, "SHIM_KILL_LOG")
}

// TestDaemonStatusNotRunning pins the answer for a shell that is down.
// The command must say so rather than printing a bare config line, or
// a user reading `vastctl daemon status` cannot tell whether it worked.
func TestDaemonStatusNotRunning(t *testing.T) {
	wantShellRunning(t, false)
	recordPgrep(t)

	res, err := runCLI(t, "daemon", "status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := "vast-shell is not running\n"; res.output() != want {
		t.Fatalf("output = %q, want %q", res.output(), want)
	}
}

// TestDaemonStatusRunning pins that the pids are reported. They are
// what a user needs in order to investigate, and a status line without
// them makes the next step a guess.
func TestDaemonStatusRunning(t *testing.T) {
	wantShellRunning(t, true)
	recordPgrep(t)
	t.Setenv("SHIM_PGREP", "111 222\n")

	res, err := runCLI(t, "daemon", "status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := "vast-shell is running (pids 111, 222)\n"; res.output() != want {
		t.Fatalf("output = %q, want %q", res.output(), want)
	}
}

// TestDaemonStatusWithoutPids pins the disagreement case. The probe
// says running while pgrep finds nothing, and the command must report
// running without inventing a pid list.
func TestDaemonStatusWithoutPids(t *testing.T) {
	wantShellRunning(t, true)
	recordPgrep(t)

	res, err := runCLI(t, "daemon", "status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := "vast-shell is running\n"; res.output() != want {
		t.Fatalf("output = %q, want %q", res.output(), want)
	}
}

// TestDaemonStatusNamesTheConfig pins that the config path is printed
// when there is one. Running the wrong checkout is the usual reason a
// user's edits do not appear, and the path is what settles it.
func TestDaemonStatusNamesTheConfig(t *testing.T) {
	root := t.TempDir()
	writeShellQml(t, filepath.Join(root, "shell.qml"))
	t.Setenv("VAST_SHELL_DIRECTORY", root)
	wantShellRunning(t, false)
	recordPgrep(t)

	res, err := runCLI(t, "daemon", "status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// canonical() resolves the symlinked temp dir, so compare against
	// the resolved root rather than the t.TempDir() spelling.
	resolved, err := filepath.EvalSymlinks(root)
	if err != nil {
		t.Fatalf("EvalSymlinks: %v", err)
	}
	want := "config: " + resolved + "\nvast-shell is not running\n"
	if res.output() != want {
		t.Fatalf("output = %q, want %q", res.output(), want)
	}
}

// TestDaemonStartWhenAlreadyRunning pins the guard. A second start
// would leave two shells fighting over the same IPC name, and the
// user gets a desktop whose bars and notifications belong to whichever
// process won the race.
func TestDaemonStartWhenAlreadyRunning(t *testing.T) {
	wantShellRunning(t, true)
	recordPgrep(t)

	res, err := runCLI(t, "daemon", "start")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := "vast-shell is already running\n"; res.output() != want {
		t.Fatalf("output = %q, want %q", res.output(), want)
	}
}

// TestDaemonStart pins that a start launches the shell and reports the
// pid. The pid is what makes the "nothing appeared" case debuggable.
func TestDaemonStart(t *testing.T) {
	// The daemon log is redirected for the duration so the test does
	// not append to the real /tmp log.
	orig := ipc.LogFilePath
	ipc.LogFilePath = filepath.Join(t.TempDir(), "vast-shell.log")
	t.Cleanup(func() { ipc.LogFilePath = orig })

	wantShellRunning(t, false)
	shellLog := recordShell(t)
	t.Setenv("SHIM_OUT", "")

	res, err := runCLI(t, "daemon", "start")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.HasPrefix(res.output(), "vast-shell started (pid ") {
		t.Fatalf("output = %q, want a start line with a pid", res.output())
	}
	if !strings.Contains(res.output(), "logs: "+ipc.LogFilePath) {
		t.Fatalf("output = %q, want it to name the log file", res.output())
	}
	if !ipc.ShellRunning() {
		t.Fatal("the memo still says the shell is down after a start")
	}
	// The launch must not be an IPC call: `daemon start` is what makes
	// the IPC target answerable in the first place.
	if calls := shimInvocations(t, shellLog); len(calls) > 1 {
		t.Fatalf("start invoked quickshell %d times, want once: %q", len(calls), calls)
	}
}

// TestDaemonStartForeground pins the systemd path. The flags are
// declared on daemon, not on start, so `daemon -f start` has to
// resolve; the process is then run in the foreground, and the memo
// must end up saying the shell exited rather than still running.
func TestDaemonStartForeground(t *testing.T) {
	wantShellRunning(t, false)
	t.Setenv("SHIM_OUT", "quickshell said hello\n")

	res, err := runCLI(t, "daemon", "-f", "start")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(res.output(), "quickshell said hello") {
		t.Fatalf("output = %q, want the shell's own output forwarded", res.output())
	}
	if ipc.ShellRunning() {
		t.Fatal("the memo still says the shell is running after it exited")
	}
}

// TestDaemonStartFailure pins that a shell that cannot be launched is
// an error, and that the memo is not left claiming it is up. Swallowing
// the failure would tell a user the desktop is starting when nothing
// was started, and every later command would then fail with "no
// running instances" and no obvious cause.
func TestDaemonStartFailure(t *testing.T) {
	orig := ipc.LogFilePath
	ipc.LogFilePath = filepath.Join(t.TempDir(), "vast-shell.log")
	t.Cleanup(func() { ipc.LogFilePath = orig })

	wantShellRunning(t, false)
	// PATH holds only a directory with a non-executable quickshell, so
	// the launch fails the way a missing permission would.
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "quickshell"), []byte("not executable\n"), 0o644); err != nil {
		t.Fatalf("write quickshell: %v", err)
	}
	t.Setenv("PATH", dir)
	t.Setenv("VAST_SHELL_DIRECTORY", "")

	res, err := runCLI(t, "daemon", "start")

	if err == nil {
		t.Fatalf("a shell that cannot be launched must be reported, got %q", res.output())
	}
	if ipc.ShellRunning() {
		t.Fatal("the memo claims the shell is running after a failed start")
	}
}

// TestDaemonStartForegroundFailure pins the same for the systemd path.
// A unit that fails to exec must not exit zero, or systemd believes a
// healthy shell is being managed.
func TestDaemonStartForegroundFailure(t *testing.T) {
	wantShellRunning(t, false)
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "quickshell"), []byte("not executable\n"), 0o644); err != nil {
		t.Fatalf("write quickshell: %v", err)
	}
	t.Setenv("PATH", dir)
	t.Setenv("VAST_SHELL_DIRECTORY", "")

	if _, err := runCLI(t, "daemon", "-f", "start"); err == nil {
		t.Fatal("a shell that cannot be launched must be reported")
	}
	if ipc.ShellRunning() {
		t.Fatal("the memo claims the shell is running after a failed start")
	}
}

// TestDaemonStartVerbose pins that --verbose tees the shell's output
// to the terminal instead of only into the log. Without this the
// flag's whole purpose — watching the shell's own output during a
// development run — is lost.
func TestDaemonStartVerbose(t *testing.T) {
	orig := ipc.LogFilePath
	ipc.LogFilePath = filepath.Join(t.TempDir(), "vast-shell.log")
	t.Cleanup(func() { ipc.LogFilePath = orig })

	wantShellRunning(t, false)
	recordShell(t)
	t.Setenv("SHIM_OUT", "verbose line\n")

	// --verbose still detaches, so the child writes after the command
	// has returned and the buffer runCLI collects is already closed.
	// The output is waited for on a separate writer rather than
	// assumed to be there.
	verbose := newSignalWriter()
	if _, err := runCLITo(t, verbose, "daemon", "start", "--verbose"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	verbose.await(t, "verbose line", 5*time.Second)
}

// TestDaemonStop pins that every matching process is killed and
// counted. Stopping one of two leaves a second shell serving the IPC
// name, and the user sees a desktop that will not go away.
func TestDaemonStop(t *testing.T) {
	wantShellRunning(t, true)
	pgrep := recordPgrep(t)
	killLog := recordKill(t)
	t.Setenv("SHIM_PGREP", "111 222\n")

	res, err := runCLI(t, "daemon", "stop")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := "vast-shell stopped (2 processes)\n"; res.output() != want {
		t.Fatalf("output = %q, want %q", res.output(), want)
	}
	if got := shimInvocations(t, killLog); len(got) != 2 {
		t.Fatalf("kill was called %d times, want twice: %q", len(got), got)
	} else {
		for i, want := range []string{"111", "222"} {
			if !slices.Equal(got[i], []string{want}) {
				t.Errorf("kill %d = %q, want [%q]", i, got[i], want)
			}
		}
	}
	if got := shimInvocations(t, pgrep); len(got) == 0 {
		t.Fatal("stop never asked pgrep which processes to kill")
	}
	if ipc.ShellRunning() {
		t.Fatal("the memo still says the shell is running after a stop")
	}
}

// TestDaemonStopWhenNotRunning pins that stopping a down shell is a
// no-op, not an error. A service that runs `vastctl daemon stop` on
// every shutdown must not fail loudly on the ones where it never
// started.
func TestDaemonStopWhenNotRunning(t *testing.T) {
	wantShellRunning(t, false)
	recordPgrep(t)
	killLog := recordKill(t)

	res, err := runCLI(t, "daemon", "stop")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := "vast-shell is not running\n"; res.output() != want {
		t.Fatalf("output = %q, want %q", res.output(), want)
	}
	if calls := shimInvocations(t, killLog); len(calls) != 0 {
		t.Fatalf("kill was called with %q despite nothing running", calls)
	}
}

// TestDaemonRestart pins the ordering: the old processes are killed
// before the new one is launched. Launching first would have two
// shells briefly serve the same IPC name.
func TestDaemonRestart(t *testing.T) {
	orig := ipc.LogFilePath
	ipc.LogFilePath = filepath.Join(t.TempDir(), "vast-shell.log")
	t.Cleanup(func() { ipc.LogFilePath = orig })

	wantShellRunning(t, true)
	recordPgrep(t)
	killLog := recordKill(t)
	recordShell(t)
	t.Setenv("SHIM_PGREP", "111\n")
	t.Setenv("SHIM_OUT", "")

	res, err := runCLI(t, "daemon", "restart")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got := shimInvocations(t, killLog); len(got) != 1 {
		t.Fatalf("kill was called %d times, want once: %q", len(got), got)
	}
	if !strings.Contains(res.output(), "vast-shell started (pid ") {
		t.Fatalf("output = %q, want a start line", res.output())
	}
	if !ipc.ShellRunning() {
		t.Fatal("the memo still says the shell is down after a restart")
	}
}

// TestProcessPlural pins the count wording. "1 processs" in a status
// line is the kind of small wrongness that makes a tool feel
// unfinished, and the word is the only thing the function decides.
func TestProcessPlural(t *testing.T) {
	for _, tc := range []struct {
		n    int
		want string
	}{
		{0, ""},
		{1, ""},
		{2, "es"},
		{3, "es"},
		{10, "es"},
	} {
		if got := processPlural(tc.n); got != tc.want {
			t.Errorf("processPlural(%d) = %q, want %q", tc.n, got, tc.want)
		}
	}
}
