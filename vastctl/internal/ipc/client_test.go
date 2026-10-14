package ipc

import (
	"os"
	"path/filepath"
	"testing"
)

// TestShellDirectory pins which directory vastctl hands to quickshell as
// the config path when starting a daemon. Every quickshell selector
// resolves to a shell.qml sitting directly in the chosen directory, so
// pointing at a parent that only holds shell.qml in a subdirectory is a
// routing bug that surfaces as "Could not open config file".
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
			if got, want := ShellDirectory(), tc.want(raw); got != want {
				t.Fatalf("ShellDirectory() = %q, want %q", got, want)
			}
		})
	}
}

// TestShellDirectoryPrefersItsOwnInstall covers the rebuild case. A shell
// opened before `nixos-rebuild switch` can still carry the previous
// generation's VAST_SHELL_DIRECTORY; following it starts the vast-shell
// that was just replaced. The directory installed beside this binary has
// to win, and the passed-over value has to be reported so a start can say
// which shell it launched.
func TestShellDirectoryPrefersItsOwnInstall(t *testing.T) {
	stale := t.TempDir()
	writeShellQml(t, filepath.Join(stale, "Qml", "shell.qml"))

	installed := t.TempDir()
	writeShellQml(t, filepath.Join(installed, "Qml", "shell.qml"))
	stubInstall(t, installed)

	t.Setenv("VAST_SHELL_DIRECTORY", stale)
	if got, want := ShellDirectory(), filepath.Join(installed, "Qml"); got != want {
		t.Fatalf("ShellDirectory() = %q, want the installed %q", got, want)
	}
	if got, want := IgnoredShellDirectory(), filepath.Join(stale, "Qml"); got != want {
		t.Fatalf("IgnoredShellDirectory() = %q, want the stale %q", got, want)
	}
}

// TestShellDirectoryKeepsAnEnvironmentMatchingTheInstall pins the ordinary
// case: the wrapper exports the same path the install holds, so nothing is
// ignored and nothing changes.
func TestShellDirectoryKeepsAnEnvironmentMatchingTheInstall(t *testing.T) {
	installed := t.TempDir()
	writeShellQml(t, filepath.Join(installed, "Qml", "shell.qml"))
	stubInstall(t, installed)

	t.Setenv("VAST_SHELL_DIRECTORY", installed)
	if got, want := ShellDirectory(), filepath.Join(installed, "Qml"); got != want {
		t.Fatalf("ShellDirectory() = %q, want %q", got, want)
	}
	if got := IgnoredShellDirectory(); got != "" {
		t.Fatalf("IgnoredShellDirectory() = %q, want none", got)
	}
}

// TestShellDirectoryKeepsTheEnvironmentWithoutAnInstall pins that a dev
// build is not part of an install, so a checkout named by the environment
// is still what gets started.
func TestShellDirectoryKeepsTheEnvironmentWithoutAnInstall(t *testing.T) {
	checkout := t.TempDir()
	writeShellQml(t, filepath.Join(checkout, "Qml", "shell.qml"))
	stubInstall(t, "")

	t.Setenv("VAST_SHELL_DIRECTORY", checkout)
	if got, want := ShellDirectory(), filepath.Join(checkout, "Qml"); got != want {
		t.Fatalf("ShellDirectory() = %q, want %q", got, want)
	}
	if got := IgnoredShellDirectory(); got != "" {
		t.Fatalf("IgnoredShellDirectory() = %q, want none", got)
	}
}

// stubInstall points the install lookup at a directory, standing in for a
// <prefix>/share/quickshell that exists next to the vastctl binary. An
// empty root stands for a binary that is not part of an install.
func stubInstall(t *testing.T, root string) {
	t.Helper()
	previous := InstallConfigDir
	t.Cleanup(func() { InstallConfigDir = previous })
	InstallConfigDir = func() string {
		if root == "" {
			return ""
		}
		return ConfigDir(root)
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
