package ipc

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/myamusashi/vast-shell/vastctl/internal/daemon"
)

// quickshellShim stands in for the binary this package executes. It is
// installed by TestMain rather than per test so no test in this package
// can reach a real quickshell on the developer's desktop. Each run
// records its argument list as one file named after its own pid, so
// concurrent runs cannot interleave into a corrupt record.
const quickshellShim = `#!/bin/sh
if [ -n "$SHIM_LOG" ]; then
  { printf -- '---\n'; for a in "$@"; do printf -- '%s\n' "$a"; done; } > "$SHIM_LOG/$$"
fi
if [ -n "$SHIM_ERR" ]; then printf -- '%s' "$SHIM_ERR" >&2; fi
if [ -n "$SHIM_OUT" ]; then printf -- '%s' "$SHIM_OUT"; fi
exit "${SHIM_CODE:-0}"
`

var shimDir string

func TestMain(m *testing.M) {
	dir, err := os.MkdirTemp("", "vastctl-ipc-shims")
	if err != nil {
		panic(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "quickshell"), []byte(quickshellShim), 0o755); err != nil {
		panic(err)
	}
	shimDir = dir
	setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	// An inherited VAST_SHELL_DIRECTORY would let a developer's real
	// config leak into assertions about what a client resolves.
	setenv("VAST_SHELL_DIRECTORY", "")

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

// recordShim points the quickshell shim at a fresh invocation log and
// returns its path. The recorded arguments are the contract under test:
// which instance, target, method and payload vastctl hands the shell.
func recordShim(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	t.Setenv("SHIM_LOG", dir)
	return dir
}

// liveDaemon publishes the state a running supervisor would have written,
// so a client can resolve an IPC target. The recorded pid is this test
// process, which is alive by construction and needs no cleanup.
func liveDaemon(t *testing.T, instanceID string) {
	t.Helper()
	t.Setenv("XDG_RUNTIME_DIR", t.TempDir())
	t.Setenv("VAST_INSTANCE", "")
	err := daemon.WriteState(daemon.State{
		PID:           os.Getpid(),
		SupervisorPID: os.Getpid(),
		ConfigPath:    "/cfg/Qml",
		InstanceID:    instanceID,
		Namespace:     "vast",
		StartedAt:     time.Now().Format(time.RFC3339),
	})
	if err != nil {
		t.Fatalf("publish daemon state: %v", err)
	}
}

// shimInvocations returns the argument list of every invocation recorded
// in a shim log directory, oldest first. Each shim run writes one file
// named after its own pid; one file per invocation means concurrent runs
// cannot interleave into a corrupt record.
func shimInvocations(t *testing.T, dir string) [][]string {
	t.Helper()
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatalf("read shim log %s: %v", dir, err)
	}
	names := make([]string, 0, len(entries))
	for _, entry := range entries {
		names = append(names, entry.Name())
	}
	// Pids sort numerically for the same reason they are recorded per
	// run: a lexicographic order would interleave concurrent runs.
	sort.Slice(names, func(i, j int) bool {
		return len(names[i]) == len(names[j]) && names[i] < names[j] ||
			len(names[i]) < len(names[j])
	})

	calls := make([][]string, 0, len(names))
	for _, name := range names {
		raw, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil {
			t.Fatalf("read shim record %s: %v", name, err)
		}
		var args []string
		for line := range strings.SplitSeq(string(raw), "\n") {
			if line == "" || line == "---" {
				continue
			}
			args = append(args, line)
		}
		calls = append(calls, args)
	}
	return calls
}

// lastShimCall returns the most recent invocation recorded in a shim log,
// failing the test when the binary was never run.
func lastShimCall(t *testing.T, log string) []string {
	t.Helper()
	calls := shimInvocations(t, log)
	if len(calls) == 0 {
		t.Fatal("quickshell was never invoked")
	}
	return calls[len(calls)-1]
}
