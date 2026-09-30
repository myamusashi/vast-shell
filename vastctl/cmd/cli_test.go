package cmd

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/myamusashi/vast-shell/vastctl/internal/daemon"
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)

// The shims below stand in for every binary vastctl executes:
// quickshell for the IPC calls, kill for the daemon lifecycle, hyprctl
// for the Hyprland bridge. They are installed by TestMain rather than
// per test so no test in this package can reach a real quickshell on the
// developer's desktop. Leaving a real kill on PATH would be worse:
// `daemon stop` would happily signal the shell the tests run inside.
//
// A test needing a different binary prepends its own shim directory to
// PATH; the TestMain one stays behind it. Each shim records its
// invocation as one file per run, named after its own pid, so a shared
// log file cannot interleave concurrent runs.
const quickshellShim = `#!/bin/sh
if [ -n "$SHIM_LOG" ]; then
  { printf -- '---\n'; for a in "$@"; do printf -- '%s\n' "$a"; done; } > "$SHIM_LOG/$$"
fi
case "$*" in
  *" ipc show"*) exit 0 ;;
esac
if [ -n "$SHIM_ERR" ]; then printf -- '%s' "$SHIM_ERR" >&2; fi
if [ -n "$SHIM_OUT" ]; then printf -- '%s' "$SHIM_OUT"; fi
exit "${SHIM_CODE:-0}"
`

const killShim = `#!/bin/sh
if [ -n "$SHIM_KILL_LOG" ]; then
  { printf -- '---\n'; for a in "$@"; do printf -- '%s\n' "$a"; done; } > "$SHIM_KILL_LOG/$$"
fi
exit 0
`

const hyprctlShim = `#!/bin/sh
if [ -n "$SHIM_HYPR_LOG" ]; then
  { printf -- '---\n'; for a in "$@"; do printf -- '%s\n' "$a"; done; } > "$SHIM_HYPR_LOG/$$"
fi
if [ -n "$SHIM_HYPR_ERR" ]; then printf -- '%s' "$SHIM_HYPR_ERR" >&2; fi
if [ -n "$SHIM_HYPR_OUT" ]; then printf -- '%s' "$SHIM_HYPR_OUT"; fi
exit "${SHIM_HYPR_CODE:-0}"
`

func TestMain(m *testing.M) {
	dir, err := os.MkdirTemp("", "vastctl-cmd-shims")
	if err != nil {
		panic(err)
	}
	for name, body := range map[string]string{
		"quickshell": quickshellShim,
		"kill":       killShim,
		"hyprctl":    hyprctlShim,
	} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0o755); err != nil {
			panic(err)
		}
	}
	shimDir = dir
	setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	// An inherited VAST_SHELL_DIRECTORY would make every call carry the
	// developer's real -p argument, and an inherited SHIM_* variable
	// would let a value leak from one test into the next.
	setenv("VAST_SHELL_DIRECTORY", "")
	for _, k := range []string{
		"SHIM_LOG", "SHIM_OUT", "SHIM_ERR", "SHIM_CODE",
		"SHIM_KILL_LOG",
		"SHIM_HYPR_LOG", "SHIM_HYPR_OUT", "SHIM_HYPR_ERR", "SHIM_HYPR_CODE",
	} {
		if err := os.Unsetenv(k); err != nil {
			panic(err)
		}
	}
	// The runtime directory is redirected so nothing here can signal the
	// developer's real daemon, and a live daemon is published for the
	// command tests: a client only ever connects, so without one every
	// call would refuse. Tests about the lifecycle redirect the runtime
	// at their own temp dir.
	setenv("XDG_RUNTIME_DIR", dir)
	setenv("VAST_INSTANCE", "")

	// Every command test is about the command surface rather than the
	// daemon lifecycle, so a live daemon is published for all of them: a
	// client only ever connects, and without one every call refuses.
	// Tests that are about the lifecycle redirect the runtime at their
	// own temp dir, so nothing here can reach the developer's daemon.
	if err := daemon.WriteState(daemon.State{
		PID:           os.Getpid(),
		SupervisorPID: os.Getpid(),
		ConfigPath:    "/cfg/Qml",
		InstanceID:    "abc123",
		Namespace:     "vast",
		StartedAt:     time.Now().Format(time.RFC3339),
	}); err != nil {
		panic(err)
	}

	code := m.Run()

	_ = os.RemoveAll(dir)
	os.Exit(code)
}

// setenv applies an environment change that cannot sensibly fail here,
// turning a silent no-op into a visible panic.
func setenv(key, value string) {
	if err := os.Setenv(key, value); err != nil {
		panic(err)
	}
}

var shimDir string

// result is what one vastctl invocation produced. The two streams are
// kept apart because the commands split across both: most print with
// fmt.Println (os.Stdout), the daemon ones with cobra's writer.
type result struct {
	stdout string
	cmdOut string
}

func (r result) output() string { return r.stdout + r.cmdOut }

// syncBuffer collects a command's output under a lock. A plain
// bytes.Buffer is not enough: `daemon start` hands cobra's writer to
// the shell it detaches, so the parent keeps printing its start line
// while the child's output goroutine writes to the same writer. The
// real writer is the terminal, which tolerates that; a test buffer
// does not, and the race detector is right to complain.
type syncBuffer struct {
	mu  sync.Mutex
	buf bytes.Buffer
}

func (b *syncBuffer) Write(p []byte) (int, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.buf.Write(p)
}

func (b *syncBuffer) String() string {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.buf.String()
}

// runCLI executes one invocation against the package-level command
// tree and returns everything it printed.
//
// os.Stdout is swapped rather than plumbing a writer through
// production code, because moving the commands off fmt.Println would
// change where they write (cobra's Print goes to stderr, not stdout)
// and break every pipeline that pipes vastctl into another tool.
func runCLI(t *testing.T, args ...string) (result, error) {
	t.Helper()
	resetFlags(t)

	cmdOut := new(syncBuffer)
	rootCmd.SetOut(cmdOut)
	rootCmd.SetErr(io.Discard)
	rootCmd.SilenceUsage = true
	rootCmd.SilenceErrors = true
	// A nil args would make cobra fall back to the test binary's own
	// os.Args, so `vastctl` with no subcommand must be spelled as an
	// explicit empty list.
	if args == nil {
		args = []string{}
	}
	rootCmd.SetArgs(args)

	var err error
	stdout := captureStdout(t, func() { err = rootCmd.Execute() })
	return result{stdout: stdout, cmdOut: cmdOut.String()}, err
}

// captureStdout runs fn with os.Stdout redirected into a pipe and
// returns what was written. The reader runs on its own goroutine so a
// payload larger than the pipe buffer cannot deadlock the test.
func captureStdout(t *testing.T, fn func()) string {
	t.Helper()
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatalf("os.Pipe: %v", err)
	}
	orig := os.Stdout
	os.Stdout = w

	collected := make(chan string, 1)
	go func() {
		var buf bytes.Buffer
		_, _ = io.Copy(&buf, r)
		collected <- buf.String()
	}()

	fn()

	os.Stdout = orig
	_ = w.Close()
	out := <-collected
	_ = r.Close()
	return out
}

// resetFlags restores every flag in the tree to its declared default.
// Cobra keeps the parsed value on the shared command, so a test that
// ran `toast open x --duration 10` would otherwise hand that 10 to the
// next test and assert against the wrong thing.
func resetFlags(t *testing.T) {
	t.Helper()
	seen := make(map[string]bool)
	resetFlagsOf(t, rootCmd, seen)
	for _, c := range rootCmd.Commands() {
		resetFlagsOf(t, c, seen)
	}
}

func resetFlagsOf(t *testing.T, c *cobra.Command, seen map[string]bool) {
	t.Helper()
	reset := func(f *pflag.Flag) {
		key := c.CommandPath() + " " + f.Name
		if seen[key] {
			return
		}
		seen[key] = true
		if err := f.Value.Set(f.DefValue); err != nil {
			t.Fatalf("reset %s to %q: %v", key, f.DefValue, err)
		}
		f.Changed = false
	}
	c.NonInheritedFlags().VisitAll(reset)
	c.InheritedFlags().VisitAll(reset)
	for _, sub := range c.Commands() {
		resetFlagsOf(t, sub, seen)
	}
}

// recordShell points the quickshell shim at a fresh invocation log
// directory and returns it.
func recordShell(t *testing.T) string {
	t.Helper()
	return shimLogDir(t, "SHIM_LOG")
}

// shimLogDir creates an empty directory and points one of the shims'
// log variables at it.
func shimLogDir(t *testing.T, env string) string {
	t.Helper()
	dir := t.TempDir()
	t.Setenv(env, dir)
	return dir
}

// ipcCall returns the `call` payload of the most recent quickshell
// invocation: the target, the method and the arguments, without the
// routing and the verb. That payload IS the contract each command has
// with the shell, so the tests assert on it rather than on the
// rendering.
//
// The verb is reached as `ipc call` or as `ipc --id <instance> call`;
// the payload is everything after it either way, so the routing in front
// is deliberately not matched on.
func ipcCall(t *testing.T, log string) []string {
	t.Helper()
	calls := shimInvocations(t, log)
	for _, call := range slices.Backward(calls) {
		j := slices.Index(call, "call")
		if j > 0 && slices.Contains(call[:j], "ipc") {
			return call[j+1:]
		}
	}
	t.Fatalf("no `ipc call` was recorded in %s", log)
	return nil
}

// wantCall asserts the shell was asked for exactly want.
func wantCall(t *testing.T, log string, want ...string) {
	t.Helper()
	if got := ipcCall(t, log); !slices.Equal(got, want) {
		t.Fatalf("shell received %q, want %q", got, want)
	}
}

// runCall runs one invocation and asserts the shell received exactly
// want as the `ipc call` payload. Almost every command in this package
// is a thin, named forwarding of one target/method pair, and that
// pair is the thing a typo silently breaks: a wrong method name
// returns an error from the shell that reads like a shell problem.
func runCall(t *testing.T, want []string, args ...string) result {
	t.Helper()
	log := recordShell(t)
	res, err := runCLI(t, args...)
	if err != nil {
		t.Fatalf("vastctl %s: unexpected error: %v", strings.Join(args, " "), err)
	}
	wantCall(t, log, want...)
	return res
}

// newHyprLog points the hyprctl shim at a fresh invocation log
// directory and returns it.
func newHyprLog(t *testing.T) string {
	t.Helper()
	return shimLogDir(t, "SHIM_HYPR_LOG")
}

// wantHyprCall asserts hyprctl was invoked with exactly the given
// arguments. Dispatching a real global shortcut is a side effect on
// the user's desktop, so the argument is the contract.
func wantHyprCall(t *testing.T, want ...string) {
	t.Helper()
	calls := shimInvocations(t, os.Getenv("SHIM_HYPR_LOG"))
	if len(calls) != 1 {
		t.Fatalf("hyprctl was called %d times, want once: %q", len(calls), calls)
	}
	if !slices.Equal(calls[0], want) {
		t.Fatalf("hyprctl received %q, want %q", calls[0], want)
	}
}

// shimInvocations returns the argument list of every invocation
// recorded in a shim's log directory, oldest first. Each file holds
// one invocation; the leading `---` line is the record's own marker.
func shimInvocations(t *testing.T, dir string) [][]string {
	t.Helper()
	entries, err := os.ReadDir(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		t.Fatalf("read shim log directory: %v", err)
	}
	type record struct {
		info os.FileInfo
		args []string
	}
	var records []record
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		info, err := e.Info()
		if err != nil {
			t.Fatalf("stat shim record: %v", err)
		}
		data, err := os.ReadFile(filepath.Join(dir, e.Name()))
		if err != nil {
			t.Fatalf("read shim record: %v", err)
		}
		lines := strings.Split(strings.TrimSuffix(string(data), "\n"), "\n")
		if len(lines) == 1 && lines[0] == "---" {
			// An invocation with no arguments. None of these shims is
			// ever called that way, so an empty record is a leftover.
			continue
		}
		records = append(records, record{info: info, args: lines[1:]})
	}
	// Pid-named files sort in creation order on every filesystem this
	// runs on in practice, and the modification time breaks any tie.
	sort.Slice(records, func(i, j int) bool {
		if !records[i].info.ModTime().Equal(records[j].info.ModTime()) {
			return records[i].info.ModTime().Before(records[j].info.ModTime())
		}
		return records[i].info.Name() < records[j].info.Name()
	})
	calls := make([][]string, 0, len(records))
	for _, r := range records {
		calls = append(calls, r.args)
	}
	return calls
}

// writeShellQml creates a shell.qml entry point at path, creating the
// parent directories. daemon status resolves the config directory
// through this file, so a test that wants a config path to be
// reported has to create a real one.
func writeShellQml(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", filepath.Dir(path), err)
	}
	if err := os.WriteFile(path, []byte("import QtQuick\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

// wantError asserts the invocation failed with a message mentioning
// every fragment. A command that fails silently is the failure mode
// worth catching, so the error text is part of the contract.
func wantError(t *testing.T, err error, fragments ...string) {
	t.Helper()
	if err == nil {
		t.Fatalf("expected an error mentioning %q, got none", fragments)
	}
	for _, f := range fragments {
		if !strings.Contains(err.Error(), f) {
			t.Errorf("error %q does not mention %q", err, f)
		}
	}
}
