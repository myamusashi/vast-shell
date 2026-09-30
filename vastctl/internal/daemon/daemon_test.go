package daemon

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"
)

// namespaceDir points the runtime at a fresh directory so a test never
// reads or writes the developer's real daemon state.
func namespaceDir(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	t.Setenv("XDG_RUNTIME_DIR", dir)
	t.Setenv("VAST_INSTANCE", "")
	return dir
}

// TestNamespace pins how VAST_INSTANCE is turned into a path component.
// The value becomes a directory name, so anything that is not a plain
// identifier has to fall back rather than escape the runtime dir.
func TestNamespace(t *testing.T) {
	for _, tc := range []struct {
		name string
		env  string
		want string
	}{
		{"unset uses the default", "", "vast"},
		{"whitespace only uses the default", "   ", "vast"},
		{"a plain name is used verbatim", "dev", "dev"},
		{"dashes and digits are allowed", "vast-dev-2", "vast-dev-2"},
		{"a separator cannot split the path", "../escape", "vast"},
		{"an absolute path cannot escape", "/etc", "vast"},
		{"a slash is rejected", "a/b", "vast"},
		{"a leading dot is rejected", ".hidden", "vast"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("VAST_INSTANCE", tc.env)
			if got := Namespace(); got != tc.want {
				t.Fatalf("Namespace() = %q, want %q", got, tc.want)
			}
		})
	}
}

// TestNamespacesAreIndependent pins that a deliberate dev daemon is a
// separate runtime, not a second writer over the installed one's state.
func TestNamespacesAreIndependent(t *testing.T) {
	base := t.TempDir()
	t.Setenv("XDG_RUNTIME_DIR", base)

	t.Setenv("VAST_INSTANCE", "vast")
	installed, err := StatePath()
	if err != nil {
		t.Fatalf("StatePath: %v", err)
	}
	t.Setenv("VAST_INSTANCE", "dev")
	dev, err := StatePath()
	if err != nil {
		t.Fatalf("StatePath: %v", err)
	}

	if installed == dev {
		t.Fatalf("both namespaces resolve to %q, want separate state files", installed)
	}
	if want := filepath.Join(base, "dev", "state.json"); dev != want {
		t.Errorf("dev state path = %q, want %q", dev, want)
	}
}

// TestStateRoundTrip pins that a published daemon can be read back
// intact. Everything a client needs to route an IPC call is in here, so
// a dropped field is a call that cannot find its shell.
func TestStateRoundTrip(t *testing.T) {
	namespaceDir(t)
	want := State{
		PID:           os.Getpid(),
		SupervisorPID: os.Getpid(),
		ConfigPath:    "/home/me/vast-shell/Qml",
		InstanceID:    "abc123",
		Namespace:     "vast",
		StartedAt:     time.Now().Format(time.RFC3339),
	}

	if err := WriteState(want); err != nil {
		t.Fatalf("WriteState: %v", err)
	}
	got, err := ReadState()
	if err != nil {
		t.Fatalf("ReadState: %v", err)
	}
	if got == nil {
		t.Fatal("ReadState returned nil after a successful write")
	}
	if *got != want {
		t.Fatalf("round trip = %+v, want %+v", *got, want)
	}
}

// TestReadStateWithoutDaemon pins that "never started" is not an error.
// A client has to be able to tell "no daemon" from "broken state" and
// report the former.
func TestReadStateWithoutDaemon(t *testing.T) {
	namespaceDir(t)

	got, err := ReadState()
	if err != nil {
		t.Fatalf("ReadState: %v", err)
	}
	if got != nil {
		t.Fatalf("ReadState = %+v, want nil", got)
	}
}

// TestReadStateIgnoresCorruptFile pins recovery. A half-written or
// hand-edited state file must not wedge every client until the next
// daemon restart; it is reported as "no daemon" instead.
func TestReadStateIgnoresCorruptFile(t *testing.T) {
	dir := namespaceDir(t)
	path := filepath.Join(dir, "vast", "state.json")
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	if err := os.WriteFile(path, []byte("{not json"), 0o600); err != nil {
		t.Fatalf("write: %v", err)
	}

	got, err := ReadState()
	if err != nil {
		t.Fatalf("ReadState: %v", err)
	}
	if got != nil {
		t.Fatalf("ReadState = %+v, want nil for a corrupt file", got)
	}
}

// TestRunning pins the three answers a client can get: a live daemon, a
// stale record, and no record. The first routes a call; the other two
// must refuse rather than address a shell that is not there.
func TestRunning(t *testing.T) {
	live := exec.Command("sleep", "30")
	if err := live.Start(); err != nil {
		t.Fatalf("start a live process: %v", err)
	}
	t.Cleanup(func() {
		_ = live.Process.Kill()
		_, _ = live.Process.Wait()
	})

	dead := exec.Command("true")
	if err := dead.Run(); err != nil {
		t.Fatalf("run a short-lived process: %v", err)
	}

	for _, tc := range []struct {
		name  string
		state *State
		want  bool
	}{
		{"no state at all", nil, false},
		{"a live pid", &State{PID: live.Process.Pid, InstanceID: "abc123"}, true},
		{"a pid that is gone", &State{PID: dead.Process.Pid, InstanceID: "abc123"}, false},
		{"a zero pid", &State{InstanceID: "abc123"}, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			namespaceDir(t)
			if tc.state != nil {
				if err := WriteState(*tc.state); err != nil {
					t.Fatalf("WriteState: %v", err)
				}
			}

			got, err := Running()
			if tc.want {
				if err != nil {
					t.Fatalf("Running() = %v, want the live daemon", err)
				}
				if got.InstanceID != "abc123" {
					t.Errorf("instance id = %q, want abc123", got.InstanceID)
				}
				return
			}
			if !errors.Is(err, ErrNotRunning) {
				t.Fatalf("Running() = (%+v, %v), want ErrNotRunning", got, err)
			}
			if got != nil {
				t.Errorf("Running() returned %+v alongside ErrNotRunning, want nil", got)
			}
		})
	}
}

// TestRunningClearsStaleState pins that a dead record is cleaned up as it
// is read. Leaving it behind would report the same ghost daemon on every
// later call.
func TestRunningClearsStaleState(t *testing.T) {
	dir := namespaceDir(t)
	dead := exec.Command("true")
	if err := dead.Run(); err != nil {
		t.Fatalf("run a short-lived process: %v", err)
	}
	if err := WriteState(State{PID: dead.Process.Pid, InstanceID: "abc123"}); err != nil {
		t.Fatalf("WriteState: %v", err)
	}

	if _, err := Running(); !errors.Is(err, ErrNotRunning) {
		t.Fatalf("Running() = %v, want ErrNotRunning", err)
	}
	if _, err := os.Stat(filepath.Join(dir, "vast", "state.json")); !errors.Is(err, os.ErrNotExist) {
		t.Errorf("stale state file survived: %v", err)
	}
}

// TestLockIsExclusive pins the single-instance guard. A second daemon
// must fail immediately whatever config path or environment it was
// started with, because the guard is the lock and not the path.
func TestLockIsExclusive(t *testing.T) {
	namespaceDir(t)

	first, err := AcquireLock()
	if err != nil {
		t.Fatalf("first AcquireLock: %v", err)
	}
	t.Cleanup(func() { _ = first.Release() })

	if second, err := AcquireLock(); err == nil {
		_ = second.Release()
		t.Fatal("a second AcquireLock succeeded, want the single-instance guard to hold")
	}
}

// TestLockIsPerNamespace pins that the deliberate dev namespace can hold
// its own daemon while the installed one runs.
func TestLockIsPerNamespace(t *testing.T) {
	namespaceDir(t)

	first, err := AcquireLock()
	if err != nil {
		t.Fatalf("AcquireLock: %v", err)
	}
	t.Cleanup(func() { _ = first.Release() })

	t.Setenv("VAST_INSTANCE", "dev")
	second, err := AcquireLock()
	if err != nil {
		t.Fatalf("a second namespace must take its own lock: %v", err)
	}
	if err := second.Release(); err != nil {
		t.Errorf("Release: %v", err)
	}
}

// TestLockReleaseAllowsSuccessor pins that stopping a daemon lets the
// next one start, which is what makes restart work.
func TestLockReleaseAllowsSuccessor(t *testing.T) {
	namespaceDir(t)

	first, err := AcquireLock()
	if err != nil {
		t.Fatalf("AcquireLock: %v", err)
	}
	if err := first.Release(); err != nil {
		t.Fatalf("Release: %v", err)
	}
	second, err := AcquireLock()
	if err != nil {
		t.Fatalf("AcquireLock after release: %v", err)
	}
	_ = second.Release()
}

// TestInstanceID pins the lookup a supervisor uses to publish its
// identity: quickshell symlinks by-pid/<pid> to by-id/<instance>, and
// that instance id is what lets a client address the daemon without
// resolving any config path.
func TestInstanceID(t *testing.T) {
	base := t.TempDir()
	t.Setenv("XDG_RUNTIME_DIR", base)

	const pid = 4321
	byID := filepath.Join(base, "quickshell", "by-id", "c9lr68d5mt")
	if err := os.MkdirAll(byID, 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	byPID := filepath.Join(base, "quickshell", "by-pid")
	if err := os.MkdirAll(byPID, 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	if err := os.Symlink(byID, filepath.Join(byPID, "4321")); err != nil {
		t.Fatalf("symlink: %v", err)
	}

	got, err := InstanceID(pid)
	if err != nil {
		t.Fatalf("InstanceID: %v", err)
	}
	if want := "c9lr68d5mt"; got != want {
		t.Fatalf("InstanceID() = %q, want %q", got, want)
	}
}

// TestInstanceIDBeforeRegistration pins the window a supervisor has to
// wait out. quickshell creates the symlink only once it has registered,
// so reading it before then is a failure, not an empty answer.
func TestInstanceIDBeforeRegistration(t *testing.T) {
	t.Setenv("XDG_RUNTIME_DIR", t.TempDir())

	if got, err := InstanceID(4321); err == nil {
		t.Fatalf("InstanceID() = %q, want an error before registration", got)
	}
}

// TestAwaitInstance pins that the supervisor waits for registration
// rather than assuming a fixed delay, and gives up when the shell dies
// instead of blocking until the timeout.
func TestAwaitInstance(t *testing.T) {
	t.Run("returns the id once quickshell registers", func(t *testing.T) {
		base := t.TempDir()
		t.Setenv("XDG_RUNTIME_DIR", base)

		// Stand in for quickshell publishing its instance a moment late.
		go func() {
			time.Sleep(50 * time.Millisecond)
			byID := filepath.Join(base, "quickshell", "by-id", "abc123")
			_ = os.MkdirAll(byID, 0o755)
			_ = os.MkdirAll(filepath.Join(base, "quickshell", "by-pid"), 0o755)
			_ = os.Symlink(byID, filepath.Join(base, "quickshell", "by-pid", "4321"))
		}()

		got, err := AwaitInstance(4321, make(chan struct{}), 5*time.Second)
		if err != nil {
			t.Fatalf("AwaitInstance: %v", err)
		}
		if want := "abc123"; got != want {
			t.Fatalf("AwaitInstance() = %q, want %q", got, want)
		}
	})

	t.Run("gives up when the shell exits first", func(t *testing.T) {
		t.Setenv("XDG_RUNTIME_DIR", t.TempDir())
		died := make(chan struct{})
		close(died)

		if _, err := AwaitInstance(4321, died, time.Minute); err == nil {
			t.Fatal("AwaitInstance succeeded after the shell exited, want an error")
		}
	})

	t.Run("gives up when the shell never registers", func(t *testing.T) {
		t.Setenv("XDG_RUNTIME_DIR", t.TempDir())

		if _, err := AwaitInstance(4321, make(chan struct{}), 100*time.Millisecond); err == nil {
			t.Fatal("AwaitInstance succeeded without registration, want a timeout")
		}
	})
}

// TestRuntimeDirWithoutBase pins the actionable failure. Without a
// runtime directory there is nowhere to put the lock or the state, and
// guessing a path is how two daemons end up believing they own the
// session.
func TestRuntimeDirWithoutBase(t *testing.T) {
	t.Setenv("XDG_RUNTIME_DIR", "")

	if _, err := StatePath(); err == nil {
		t.Fatal("StatePath succeeded with XDG_RUNTIME_DIR unset, want an error")
	}
	if _, err := AcquireLock(); err == nil {
		t.Fatal("AcquireLock succeeded with XDG_RUNTIME_DIR unset, want an error")
	}
}
