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

// TestProbeShellWithoutConfigDirectory pins the fallback a machine
// without VAST_SHELL_DIRECTORY gets. With no checkout to name, there
// is no -p to probe with, so the answer has to come from pgrep. The
// pattern is the bare "quickshell" rather than a config path: any
// quickshell counts, which is the right answer for a user who has
// only the installed shell.
func TestProbeShellWithoutConfigDirectory(t *testing.T) {
	t.Setenv("VAST_SHELL_DIRECTORY", "")

	t.Run("a quickshell process is running", func(t *testing.T) {
		log := t.TempDir()
		t.Setenv("SHIM_PGREP", "4321\n")
		t.Setenv("SHIM_PGREP_LOG", log)
		resetShellRunning()
		t.Cleanup(resetShellRunning)

		if !ShellRunning() {
			t.Fatal("pgrep found a quickshell, so the shell must be reported running")
		}
		if got := lastShimCall(t, log); !slices.Equal(got, []string{"-f", "quickshell"}) {
			t.Fatalf("pgrep received %q, want [-f quickshell]", got)
		}
	})

	t.Run("no quickshell process is running", func(t *testing.T) {
		t.Setenv("SHIM_PGREP", "")
		resetShellRunning()
		t.Cleanup(resetShellRunning)

		if ShellRunning() {
			t.Fatal("pgrep found nothing, so the shell must be reported down")
		}
	})
}

// TestProbeError pins that a failing probe carries quickshell's own
// diagnostics. The probe is the first thing vastctl does on a cold
// machine, and a bare "exit status 255" there names neither the config
// path nor the reason.
func TestProbeError(t *testing.T) {
	log := recordShim(t)
	// Naming a marker that does not exist leaves the probe reporting a
	// dead shell, which is what this error path needs.
	t.Setenv("SHIM_READY", filepath.Join(t.TempDir(), "absent"))
	err := probe("/cfg/Qml")
	if err == nil {
		t.Fatal("a failing probe must be reported")
	}
	for _, want := range []string{"quickshell", "-p", "/cfg/Qml", "ipc", "show", "Could not open config file"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error %q does not mention %q", err, want)
		}
	}
	if got := lastShimCall(t, log); !slices.Equal(got, []string{"-p", "/cfg/Qml", "ipc", "show"}) {
		t.Fatalf("quickshell received %q, want the probe invocation", got)
	}
}

// TestProbeSucceeds pins the success half. This is the answer that
// stops vastctl from launching a second shell, so it has to be
// reachable without a config directory too.
func TestProbeSucceeds(t *testing.T) {
	log := recordShim(t)

	if err := probe("/cfg/Qml"); err != nil {
		t.Fatalf("the shim answers successfully, want no error, got %v", err)
	}
	if got := lastShimCall(t, log); !slices.Equal(got, []string{"-p", "/cfg/Qml", "ipc", "show"}) {
		t.Fatalf("quickshell received %q, want the probe invocation", got)
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

	// Abs resolves a relative path against the working directory, and
	// Getwd fails when that directory has been deleted underneath the
	// process. The input has to come back untouched rather than as a
	// wrong absolute path built from a guess: shellDirectory would then
	// launch quickshell against a config that does not exist.
	t.Run("an unresolvable working directory returns the input", func(t *testing.T) {
		gone := t.TempDir()
		t.Chdir(gone)
		if err := os.RemoveAll(gone); err != nil {
			t.Fatalf("remove the working directory: %v", err)
		}

		if got := canonical("."); got != "." {
			t.Fatalf("canonical(\".\") = %q, want the input back unchanged", got)
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

// TestEnsureShellDaemonLaunchesTheShell pins the auto-start path: a
// call made while the shell is down brings it up first. Without this,
// the very first vastctl command a user runs after a reboot fails with
// "No running instances" and the shell never appears.
//
// It runs in a child process because ensureShellDaemon is a
// sync.Once — spent for good as soon as any other test here calls out.
func TestEnsureShellDaemonLaunchesTheShell(t *testing.T) {
	if os.Getenv(scenarioEnv) == "autostart" {
		autostartScenario(t)
		return
	}

	out, err := runInChild(t, "autostart")
	if err != nil {
		t.Fatalf("child failed: %v\n%s", err, out)
	}
	if !strings.Contains(out, "SCENARIO OK") {
		t.Fatalf("the scenario did not report success:\n%s", out)
	}
}

// autostartScenario is the child half of
// TestEnsureShellDaemonLaunchesTheShell.
func autostartScenario(t *testing.T) {
	dir := t.TempDir()
	log := filepath.Join(dir, "calls")
	if err := os.Mkdir(log, 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	// The shell is down until something launches it, so the probe
	// fails first and only starts answering after the launch.
	ready := filepath.Join(dir, "ready")
	t.Setenv("SHIM_LOG", log)
	t.Setenv("SHIM_READY", ready)
	t.Setenv("SHIM_OUT", "autostarted\n")

	// A checkout to launch against: without one there is no -p to hand
	// quickshell, and the launch is not the one a real user triggers.
	root := t.TempDir()
	writeShellQml(t, filepath.Join(root, "Qml", "shell.qml"))
	t.Setenv("VAST_SHELL_DIRECTORY", root)

	daemonLog := filepath.Join(dir, "daemon.log")
	orig := LogFilePath
	LogFilePath = daemonLog
	t.Cleanup(func() { LogFilePath = orig })

	// Cold, so ensureShellDaemon does not take its "already running"
	// branch and return before launching anything. This is the state a
	// caller that has just stopped the shell sees.
	SetShellRunning(false)

	got, err := Call("img", "get")
	if err != nil {
		t.Fatalf("the call failed instead of starting the shell: %v", err)
	}
	if got != "autostarted" {
		t.Fatalf("Call = %q, want the shell's answer", got)
	}

	calls := shimInvocations(t, log)
	cfg := filepath.Join(root, "Qml")
	launch := []string{"-p", cfg}
	probe := []string{"-p", cfg, "ipc", "show"}
	// The call carries the same -p prefix: the config path is what
	// binds the request to this checkout.
	want := []string{"-p", cfg, "ipc", "call", "img", "get"}

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
		t.Fatalf("the request never reached the shell: %q", calls)
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
