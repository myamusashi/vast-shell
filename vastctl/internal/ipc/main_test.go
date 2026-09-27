package ipc

import (
	"errors"
	"flag"
	"os"
	"os/exec"
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
  *" ipc show"*)
    # SHIM_READY names a file that means "the shell is up". While it is
    # absent the probe reports a dead shell, and launching the shell
    # creates it — which is what the auto-start path has to see before
    # its wait loop gives up.
    if [ -n "$SHIM_READY" ] && [ ! -f "$SHIM_READY" ]; then
      printf 'Could not open config file\n'
      exit 255
    fi
    exit 0
    ;;
esac
if [ -n "$SHIM_READY" ]; then : > "$SHIM_READY"; fi
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

// scenarioEnv names the scenario a re-executed child should run. When
// it is unset the process is the ordinary test binary.
const scenarioEnv = "VASTCTL_IPC_TEST_SCENARIO"

// runInChild re-executes this test binary as a child running only the
// named scenario, and returns its combined output.
//
// ensureShellDaemon is a sync.Once for the life of the process, so once
// any other test in this package has made a call the auto-start path is
// spent and can no longer be observed. A child is the only way to give
// it a clean slate.
//
// -test.gocoverdir is forwarded so the child's counters merge into the
// parent's report. Without it the auto-start path reads as barely
// covered and waitForShell as untested when both are exercised here.
func runInChild(t *testing.T, scenario string) (string, error) {
	t.Helper()
	args := []string{"-test.run=^" + t.Name() + "$", "-test.v"}
	if f := flag.Lookup("test.gocoverdir"); f != nil && f.Value.String() != "" {
		args = append(args, "-test.gocoverdir="+f.Value.String())
	}
	cmd := exec.Command(os.Args[0], args...)
	cmd.Env = append(os.Environ(), scenarioEnv+"="+scenario)
	out, err := cmd.CombinedOutput()
	return string(out), err
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
