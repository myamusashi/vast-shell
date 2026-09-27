package ipc

import (
	"errors"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
)

// The shims stand in for the two binaries this package executes. They
// are installed by TestMain rather than per test because ipc.Call
// reaches quickshell through ensureShellDaemon, which can start a real
// quickshell on the developer's desktop if nothing answers the probe
// first. Installing them before m.Run makes it impossible for the
// package to spawn or signal a real binary. A test needing a specific
// behaviour prepends its own shim directory to PATH; this one stays
// behind it. Each shim records its invocation as one file per run,
// named after its own pid, so concurrent runs cannot interleave into a
// corrupt record.
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

// pgrepShim reports the PIDs held in SHIM_PGREP, one per line, and
// exits non-zero when there are none, which is how pgrep signals "no
// match" and therefore a not-running shell.
const pgrepShim = `#!/bin/sh
if [ -n "$SHIM_PGREP_LOG" ]; then
  { printf -- '---\n'; for a in "$@"; do printf -- '%s\n' "$a"; done; } > "$SHIM_PGREP_LOG/$$"
fi
if [ -n "$SHIM_PGREP" ]; then printf -- '%s' "$SHIM_PGREP"; exit 0; fi
exit 1
`

var shimDir string

func TestMain(m *testing.M) {
	dir, err := os.MkdirTemp("", "vastctl-ipc-shims")
	if err != nil {
		panic(err)
	}
	for name, body := range map[string]string{
		"quickshell": quickshellShim,
		"pgrep":      pgrepShim,
	} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0o755); err != nil {
			panic(err)
		}
	}
	shimDir = dir
	os.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	// An inherited VAST_SHELL_DIRECTORY would make every probe answer
	// for the developer's real config path. Blanking it keeps the
	// recorded invocations free of a -p argument.
	os.Setenv("VAST_SHELL_DIRECTORY", "")

	code := m.Run()

	os.RemoveAll(dir)
	os.Exit(code)
}

// shimInvocations returns the argument list of every invocation
// recorded in a shim's log directory, oldest first. Each shim run
// writes one file named after its own pid; one file per invocation
// means concurrent runs cannot interleave into a corrupt record.
func shimInvocations(t *testing.T, dir string) [][]string {
	t.Helper()
	entries, err := os.ReadDir(dir)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
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
			// A run with no arguments. No shim here is ever called that
			// way, so this is a leftover rather than a real record.
			continue
		}
		records = append(records, record{info: info, args: lines[1:]})
	}
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

// lastShimCall returns the most recent invocation recorded in a shim
// log, failing the test when the binary was never run.
func lastShimCall(t *testing.T, log string) []string {
	t.Helper()
	calls := shimInvocations(t, log)
	if len(calls) == 0 {
		t.Fatal("the shim was never invoked")
	}
	return calls[len(calls)-1]
}

// TestShellDirectoryExport pins the exported accessor. `daemon status`
// prints the path it reports, so a divergence between this and
// shellDirectory would have the command name a config the shell is not
// actually being started with.
func TestShellDirectoryExport(t *testing.T) {
	root := t.TempDir()
	writeShellQml(t, filepath.Join(root, "Qml", "shell.qml"))
	t.Setenv("VAST_SHELL_DIRECTORY", root)

	got := ShellDirectory()
	if want := shellDirectory(); got != want {
		t.Fatalf("ShellDirectory() = %q, want the same answer as shellDirectory() = %q", got, want)
	}
	if !filepath.IsAbs(got) || filepath.Base(got) != "Qml" {
		t.Fatalf("ShellDirectory() = %q, want the resolved Qml directory", got)
	}
}
