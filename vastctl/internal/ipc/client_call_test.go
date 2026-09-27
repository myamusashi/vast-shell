package ipc

import (
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

// recordShim points the quickshell shim at a fresh invocation log and
// returns its path. The recorded arguments are the contract under
// test: which target, which method and which payload vastctl hands to
// the shell.
func recordShim(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	t.Setenv("SHIM_LOG", dir)
	return dir
}

// wantCall asserts the shell was asked for exactly want, which is the
// `ipc call` suffix — target, method and arguments, without the
// `ipc call` verb itself.
func wantCall(t *testing.T, log string, want ...string) {
	t.Helper()
	got := lastShimCall(t, log)
	if i := slices.Index(got, "call"); i >= 0 && got[i-1] == "ipc" {
		got = got[i+1:]
	}
	if !slices.Equal(got, want) {
		t.Fatalf("quickshell received %q, want %q", got, want)
	}
}

// TestCallArguments pins the argument assembly. Everything after the
// method is passed through verbatim, so a payload that loses its
// ordering or drops a field is a shell call that mutates the wrong
// thing.
func TestCallArguments(t *testing.T) {
	log := recordShim(t)
	SetShellRunning(true)

	if _, err := Call("volume", "appSet", "42", "50"); err != nil {
		t.Fatalf("Call returned an unexpected error: %v", err)
	}

	wantCall(t, log, "volume", "appSet", "42", "50")
}

// TestCallWithoutArguments pins the void-function shape: no extra
// arguments, and the empty answer handed back untouched.
func TestCallWithoutArguments(t *testing.T) {
	log := recordShim(t)
	SetShellRunning(true)
	t.Setenv("SHIM_OUT", "\n")

	got, err := Call("lock", "unlock")
	if err != nil {
		t.Fatalf("Call returned an unexpected error: %v", err)
	}
	if got != "" {
		t.Fatalf("Call = %q, want the empty string", got)
	}
	wantCall(t, log, "lock", "unlock")
}

// TestCallTrimsOutput pins that the surrounding whitespace quickshell
// adds is removed. Without this every caller that prints the result
// emits a leading blank line, and a path-returning call like
// `wallpaper get` ends in a newline the shell cannot use verbatim.
func TestCallTrimsOutput(t *testing.T) {
	recordShim(t)
	SetShellRunning(true)
	t.Setenv("SHIM_OUT", "\n  /home/me/pic.png \n\n")

	got, err := Call("img", "get")
	if err != nil {
		t.Fatalf("Call returned an unexpected error: %v", err)
	}
	if want := "/home/me/pic.png"; got != want {
		t.Fatalf("Call = %q, want %q", got, want)
	}
}

// TestCallPreservesInteriorWhitespace pins that only the edges are
// trimmed. A multi-line payload must survive intact or `color
// generate` writes a mangled palette to disk.
func TestCallPreservesInteriorWhitespace(t *testing.T) {
	recordShim(t)
	SetShellRunning(true)
	t.Setenv("SHIM_OUT", "\n{\n  \"a\": 1\n}\n")

	got, err := Call("color", "generate")
	if err != nil {
		t.Fatalf("Call returned an unexpected error: %v", err)
	}
	if want := "{\n  \"a\": 1\n}"; got != want {
		t.Fatalf("Call = %q, want %q", got, want)
	}
}

// TestCallFailure pins that a failed call surfaces the shell's own
// diagnostics together with the target and method, rather than a bare
// exit status that names nothing the user can act on.
func TestCallFailure(t *testing.T) {
	log := recordShim(t)
	SetShellRunning(true)
	t.Setenv("SHIM_CODE", "255")
	t.Setenv("SHIM_OUT", "No running instances for \"/cfg/shell.qml\"\n")
	t.Setenv("SHIM_ERR", "warning: no config\n")

	_, err := Call("img", "get")
	if err == nil {
		t.Fatal("a failed call must be reported")
	}
	for _, want := range []string{"img", "get", "No running instances", "warning: no config"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error %q does not mention %q", err, want)
		}
	}
	if strings.Contains(err.Error(), "exit status") {
		t.Errorf("error %q degrades to a bare exit status", err)
	}
	wantCall(t, log, "img", "get")
}

// TestShellBinArgs pins which binary is launched and with what prefix.
// With a config directory the answer must be `quickshell -p <dir>`,
// because that is what binds the call to this checkout rather than to
// whatever shell happens to be installed.
func TestShellBinArgs(t *testing.T) {
	t.Run("config directory is passed with -p", func(t *testing.T) {
		root := t.TempDir()
		writeShellQml(t, filepath.Join(root, "Qml", "shell.qml"))
		t.Setenv("VAST_SHELL_DIRECTORY", root)

		bin, args := ShellBinArgs()
		if want := []string{"-p", filepath.Join(root, "Qml")}; bin != "quickshell" || !slices.Equal(args, want) {
			t.Fatalf("ShellBinArgs() = %q, %q, want quickshell, %q", bin, args, want)
		}
	})

	t.Run("without a config directory the bare binary is used", func(t *testing.T) {
		// PATH holds only the shim directory, which has no `shell` in
		// it, so the quickshell fallback is reached deterministically
		// instead of depending on what the developer's machine happens
		// to have installed.
		t.Setenv("PATH", shimDir)
		t.Setenv("VAST_SHELL_DIRECTORY", "")

		bin, args := ShellBinArgs()
		if bin != "quickshell" || len(args) != 0 {
			t.Fatalf("ShellBinArgs() = %q, %q, want quickshell with no arguments", bin, args)
		}
	})
}

// TestShellBinArgsPrefersShellWrapper pins the wrapper lookup. When
// VAST_SHELL_DIRECTORY is unset, an installed `shell` wrapper is the
// supported entry point, so it has to win over a raw quickshell.
func TestShellBinArgsPrefersShellWrapper(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "shell"), []byte("#!/bin/sh\nexit 0\n"), 0o755); err != nil {
		t.Fatalf("write shell wrapper: %v", err)
	}
	t.Setenv("PATH", dir)
	t.Setenv("VAST_SHELL_DIRECTORY", "")

	bin, args := ShellBinArgs()
	if bin != "shell" || len(args) != 0 {
		t.Fatalf("ShellBinArgs() = %q, %q, want shell with no arguments", bin, args)
	}
}

// TestShellBooting pins that the "is a quickshell already coming up
// for this directory" check reads pgrep's exit status, not its output.
// pgrep exits 1 with no output when nothing matches, and that is the
// answer; anything else would make daemon start race the shell it is
// trying to wait for.
func TestShellBooting(t *testing.T) {
	for _, tc := range []struct {
		name string
		out  string
		want bool
	}{
		{"a matching process is booting", "4321\n", true},
		{"nothing matches", "", false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			log := t.TempDir()
			t.Setenv("SHIM_PGREP", tc.out)
			t.Setenv("SHIM_PGREP_LOG", log)

			if got := shellBooting("/cfg/Qml"); got != tc.want {
				t.Fatalf("shellBooting() = %t, want %t", got, tc.want)
			}
			got := lastShimCall(t, log)
			if !slices.Equal(got, []string{"-f", "quickshell.*/cfg/Qml"}) {
				t.Fatalf("pgrep received %q, want [-f quickshell.*/cfg/Qml]", got)
			}
		})
	}
}

// TestIsFile pins that a directory never passes for the entry point.
// shellDirectory uses this to tell a checkout root from a parent that
// merely contains one, and a directory named shell.qml has to be
// rejected rather than handed to quickshell as a config file.
func TestIsFile(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "shell.qml")
	if err := os.WriteFile(file, []byte("import QtQuick\n"), 0o644); err != nil {
		t.Fatalf("write shell.qml: %v", err)
	}

	for _, tc := range []struct {
		name string
		path string
		want bool
	}{
		{"a regular file", file, true},
		{"a directory", dir, false},
		{"a missing path", filepath.Join(dir, "absent"), false},
		{"the empty string", "", false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := isFile(tc.path); got != tc.want {
				t.Fatalf("isFile(%q) = %t, want %t", tc.path, got, tc.want)
			}
		})
	}
}

// TestCanonical pins that the result is an absolute path and that
// symlinks are resolved. quickshell is then started with the resolved
// path, while the shell that reports itself running may have been
// started with the symlinked one — if the two differ, the probe asks
// about a config path nothing is serving.
func TestCanonical(t *testing.T) {
	root := t.TempDir()
	real := filepath.Join(root, "real")
	if err := os.MkdirAll(real, 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	link := filepath.Join(root, "link")
	if err := os.Symlink(real, link); err != nil {
		t.Fatalf("symlink: %v", err)
	}

	t.Run("a symlink resolves to its target", func(t *testing.T) {
		resolved, err := filepath.EvalSymlinks(real)
		if err != nil {
			t.Fatalf("EvalSymlinks: %v", err)
		}
		if got := canonical(link); got != resolved {
			t.Fatalf("canonical(%q) = %q, want %q", link, got, resolved)
		}
	})

	t.Run("a relative path is made absolute", func(t *testing.T) {
		got := canonical(".")
		if !filepath.IsAbs(got) {
			t.Fatalf("canonical(\".\") = %q, want an absolute path", got)
		}
		abs, err := filepath.Abs(".")
		if err != nil {
			t.Fatalf("Abs: %v", err)
		}
		want, err := filepath.EvalSymlinks(abs)
		if err != nil {
			t.Fatalf("EvalSymlinks: %v", err)
		}
		if got != want {
			t.Fatalf("canonical(\".\") = %q, want %q", got, want)
		}
	})

	t.Run("a path that does not exist stays absolute", func(t *testing.T) {
		missing := filepath.Join(root, "absent", "deeper")
		got := canonical(missing)
		if !filepath.IsAbs(got) {
			t.Fatalf("canonical(%q) = %q, want an absolute path", missing, got)
		}
	})
}

// TestLogFile pins the daemon log's contract: owner-only permissions
// and append semantics. The log carries the shell's stdout, so a
// world-readable mode or a truncating open would leak a session's
// output or destroy the history a developer is tailing.
func TestLogFile(t *testing.T) {
	orig := LogFilePath
	LogFilePath = filepath.Join(t.TempDir(), "vast-shell.log")
	t.Cleanup(func() { LogFilePath = orig })

	file := LogFile()
	if file == nil {
		t.Fatal("LogFile returned nil for a writable directory")
	}
	defer func() { _ = file.Close() }()

	info, err := file.Stat()
	if err != nil {
		t.Fatalf("stat: %v", err)
	}
	if got, want := info.Mode().Perm(), os.FileMode(0o600); got != want {
		t.Errorf("log mode = %o, want %o", got, want)
	}
	if _, err := file.WriteString("first\n"); err != nil {
		t.Fatalf("write: %v", err)
	}
	if _, err := file.WriteString("second\n"); err != nil {
		t.Fatalf("write: %v", err)
	}

	data, err := os.ReadFile(LogFilePath)
	if err != nil {
		t.Fatalf("read log: %v", err)
	}
	if want := "first\nsecond\n"; string(data) != want {
		t.Fatalf("log holds %q, want %q", data, want)
	}
}

// TestLogFileCreatesMissingFile pins that the log is created on
// demand. The daemon start path opens it before the shell has ever
// run, and a nil here silently drops the shell's output on the floor.
func TestLogFileCreatesMissingFile(t *testing.T) {
	orig := LogFilePath
	LogFilePath = filepath.Join(t.TempDir(), "vast-shell.log")
	t.Cleanup(func() { LogFilePath = orig })

	if file := LogFile(); file == nil {
		t.Fatal("LogFile returned nil instead of creating the file")
	} else {
		_ = file.Close()
	}
	if _, err := os.Stat(LogFilePath); err != nil {
		t.Fatalf("the log was not created: %v", err)
	}
}

// TestLogFileUnwritableDirectory pins the nil return. A missing
// directory is not created: the caller keeps the process' own stdout
// instead, and LogFile reports the failure by returning nothing so
// the start path can decide what to do.
func TestLogFileUnwritableDirectory(t *testing.T) {
	orig := LogFilePath
	LogFilePath = filepath.Join(t.TempDir(), "absent", "vast-shell.log")
	t.Cleanup(func() { LogFilePath = orig })

	if file := LogFile(); file != nil {
		_ = file.Close()
		t.Fatal("LogFile returned a file for a path whose directory does not exist")
	}
}
