package ipc

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// TestShellDirectory pins which directory vastctl hands to quickshell as
// the config path. Every quickshell selector resolves to a shell.qml
// sitting directly in the chosen directory, so pointing at a parent that
// only holds shell.qml in a subdirectory is a routing bug that surfaces
// as "Could not open config file" or an IPC target that never answers.
//
// No t.Parallel here: these cases drive VAST_SHELL_DIRECTORY, and
// t.Setenv panics when combined with it.
func TestShellDirectory(t *testing.T) {
	for _, tc := range []struct {
		name string
		// build returns the value to place in VAST_SHELL_DIRECTORY.
		build func(t *testing.T) string
		// want maps that raw value to the expected config directory.
		want func(raw string) string
	}{
		{
			name:  "unset targets the installed wrapper",
			build: func(t *testing.T) string { t.Setenv("VAST_SHELL_DIRECTORY", ""); return "" },
			want:  func(string) string { return "" },
		},
		{
			name: "entry point in Qml subdirectory",
			build: func(t *testing.T) string {
				root := t.TempDir()
				writeShellQml(t, filepath.Join(root, "Qml", "shell.qml"))
				return root
			},
			want: func(root string) string { return filepath.Join(root, "Qml") },
		},
		{
			name: "entry point at checkout root",
			build: func(t *testing.T) string {
				root := t.TempDir()
				writeShellQml(t, filepath.Join(root, "shell.qml"))
				return root
			},
			want: func(root string) string { return root },
		},
		{
			name: "root entry point wins over subdirectory",
			build: func(t *testing.T) string {
				root := t.TempDir()
				writeShellQml(t, filepath.Join(root, "shell.qml"))
				writeShellQml(t, filepath.Join(root, "Qml", "shell.qml"))
				return root
			},
			want: func(root string) string { return root },
		},
		{
			name: "missing checkout still yields the Qml path so daemon start has something to launch",
			build: func(t *testing.T) string {
				return filepath.Join(t.TempDir(), "absent")
			},
			want: func(root string) string { return filepath.Join(root, "Qml") },
		},
		{
			name: "session variable references are expanded",
			build: func(t *testing.T) string {
				root := t.TempDir()
				writeShellQml(t, filepath.Join(root, "Qml", "shell.qml"))
				t.Setenv("VAST_TEST_ROOT", root)
				return "${VAST_TEST_ROOT}"
			},
			want: func(string) string { return filepath.Join(os.Getenv("VAST_TEST_ROOT"), "Qml") },
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			raw := tc.build(t)
			t.Setenv("VAST_SHELL_DIRECTORY", raw)
			if got, want := shellDirectory(), tc.want(raw); got != want {
				t.Fatalf("shellDirectory() = %q, want %q", got, want)
			}
		})
	}
}

// TestIPCError checks that quickshell's own diagnostics survive into the
// error. Routing failures are reported on stdout, so an error built only
// from stderr reduces every "no instance for this config path" to a bare
// exit status that names neither the target nor the reason.
func TestIPCError(t *testing.T) {
	t.Parallel()

	callArgs := []string{"-p", "/cfg/Qml", "ipc", "call", "img", "get"}
	for _, tc := range []struct {
		name    string
		script  string
		args    []string
		want    []string
		notWant []string
	}{
		{
			name:    "routing failure on stdout is reported",
			script:  `printf 'No running instances for "/cfg/Qml/shell.qml"\n'; exit 255`,
			args:    callArgs,
			want:    []string{"quickshell", "-p", "/cfg/Qml", "ipc", "call", "img", "get", "No running instances"},
			notWant: []string{"exit status"},
		},
		{
			name:    "failure on stderr is reported",
			script:  `printf 'Could not open config file\n' >&2; exit 255`,
			args:    callArgs,
			want:    []string{"Could not open config file"},
			notWant: []string{"exit status"},
		},
		{
			name:   "both streams are reported",
			script: `printf 'stdout detail\n'; printf 'stderr detail\n' >&2; exit 7`,
			args:   callArgs,
			want:   []string{"stdout detail", "stderr detail"},
		},
		{
			name:   "silent failure still carries the invocation and exit status",
			script: `exit 255`,
			args:   []string{"-p", "/cfg", "ipc", "show"},
			want:   []string{"quickshell", "-p", "/cfg", "ipc", "show", "exit status 255"},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			stdout, err := exec.Command("sh", "-c", tc.script).Output()
			if err == nil {
				t.Fatal("expected the helper command to fail")
			}
			got := ipcError("quickshell", tc.args, stdout, err).Error()
			for _, want := range tc.want {
				if !strings.Contains(got, want) {
					t.Errorf("error %q does not mention %q", got, want)
				}
			}
			for _, notWant := range tc.notWant {
				if strings.Contains(got, notWant) {
					t.Errorf("error %q should not contain %q", got, notWant)
				}
			}
		})
	}
}

func writeShellQml(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", filepath.Dir(path), err)
	}
	if err := os.WriteFile(path, []byte("import QtQuick\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

// TestShellRunningMemo pins that the subprocess probe is not repeated and
// that a transition this process makes is recorded instead of re-probed.
// Without the setter, a command that starts or stops the shell keeps
// answering from the answer it cached before the transition.
//
// No t.Parallel: this writes the package-level running memo.
func TestShellRunningMemo(t *testing.T) {
	t.Cleanup(resetShellRunning)

	SetShellRunning(false)
	if ShellRunning() {
		t.Fatal("memoized false answer must be returned without a probe")
	}

	SetShellRunning(true)
	if !ShellRunning() {
		t.Fatal("a recorded start must be visible to ShellRunning")
	}
}

// TestShellRunningProbesOnce pins the memo: three ShellRunning calls in
// one process must reach quickshell once. Before the memo every call
// forked a fresh quickshell, so a command that asked more than once paid
// for a full binary startup each time. The shim stands in for quickshell
// and appends a byte per spawn, so the count is observed, not assumed.
func TestShellRunningProbesOnce(t *testing.T) {
	t.Cleanup(resetShellRunning)

	root := t.TempDir()
	shimDir := t.TempDir()
	counter := filepath.Join(root, "spawns")
	shim := "#!/bin/sh\nprintf 'x' >> " + counter + "\nexit 0\n"
	if err := os.WriteFile(filepath.Join(shimDir, "quickshell"), []byte(shim), 0o755); err != nil {
		t.Fatalf("write quickshell shim: %v", err)
	}
	t.Setenv("PATH", shimDir+":"+os.Getenv("PATH"))
	t.Setenv("VAST_SHELL_DIRECTORY", root)

	for range 3 {
		if !ShellRunning() {
			t.Fatal("the shim answers successfully, so the probe must report running")
		}
	}
	if got := spawnCount(t, counter); got != 1 {
		t.Fatalf("quickshell spawned %d times across 3 ShellRunning calls, want 1", got)
	}

	// A transition this process makes is an answer, not a question.
	SetShellRunning(false)
	if ShellRunning() {
		t.Fatal("a recorded stop must be visible to ShellRunning")
	}
	if got := spawnCount(t, counter); got != 1 {
		t.Fatalf("a recorded transition triggered a probe, spawn count = %d", got)
	}
}

func spawnCount(t *testing.T, counter string) int {
	t.Helper()
	data, err := os.ReadFile(counter)
	if err != nil {
		t.Fatalf("read spawn counter: %v", err)
	}
	return len(strings.TrimSpace(string(data)))
}
