package daemon

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"
)

const defaultNamespace = "vast"

// namespacePattern constrains VAST_INSTANCE to a safe path component so
// the namespace can be used verbatim in a filesystem path.
var namespacePattern = regexp.MustCompile(`^[A-Za-z0-9_-]+$`)

// ErrNotRunning is returned when no live daemon is registered for the
// namespace. It is deliberately explicit: an IPC command that silently
// starts a shell is how two shells end up fighting over the same IPC
// targets.
var ErrNotRunning = errors.New("vast-shell is not running; start it with `vastctl daemon start`")

// State is the identity a running daemon publishes for its clients.
type State struct {
	// PID is the quickshell process serving the shell.
	PID int `json:"pid"`
	// SupervisorPID owns the lock and reaps PID.
	SupervisorPID int `json:"supervisorPid"`
	// ConfigPath is the quickshell config directory the shell runs from.
	ConfigPath string `json:"configPath"`
	// InstanceID is the quickshell IPC instance id, addressed with
	// `quickshell ipc --id`. Routing by id skips the config-path lookup
	// that makes a client miss a daemon launched from elsewhere.
	InstanceID string `json:"instanceId"`
	// Namespace isolates parallel daemons, e.g. "dev" beside the default.
	Namespace string `json:"namespace"`
	// StartedAt is when the supervisor launched the shell.
	StartedAt string `json:"startedAt"`
}

func (s *State) Alive() bool {
	if s == nil || s.PID <= 0 {
		return false
	}
	proc, err := os.FindProcess(s.PID)
	if err != nil {
		return false
	}
	return proc.Signal(syscall.Signal(0)) == nil
}

func (s *State) Uptime() (time.Duration, bool) {
	if s == nil {
		return 0, false
	}
	started, err := time.Parse(time.RFC3339, s.StartedAt)
	if err != nil {
		return 0, false
	}
	return time.Since(started), true
}

func Namespace() string {
	ns := strings.TrimSpace(os.Getenv("VAST_INSTANCE"))
	if ns == "" || !namespacePattern.MatchString(ns) {
		return defaultNamespace
	}
	return ns
}

func RuntimeDir() (string, error) {
	base := os.Getenv("XDG_RUNTIME_DIR")
	if base == "" {
		return "", errors.New("XDG_RUNTIME_DIR is unset; cannot locate the vast-shell runtime directory")
	}
	return filepath.Join(base, Namespace()), nil
}

func StatePath() (string, error) {
	dir, err := RuntimeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "state.json"), nil
}

// ReadState returns the published daemon state, or nil when none has been
// written. It never returns an error for a missing state: a daemon that
// was never started and a daemon that left a stale file behind are both
// simply "not running" as far as a client is concerned.
func ReadState() (*State, error) {
	path, err := StatePath()
	if err != nil {
		return nil, err
	}
	raw, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var state State
	if err := json.Unmarshal(raw, &state); err != nil {
		return nil, nil
	}
	return &state, nil
}

// WriteState publishes the state atomically so a concurrent client never
// reads a half-written file.
func WriteState(state State) error {
	dir, err := RuntimeDir()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	encoded, err := json.Marshal(state)
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(dir, "state-*.json")
	if err != nil {
		return err
	}
	defer func() { _ = os.Remove(tmp.Name()) }()
	if _, err := tmp.Write(encoded); err != nil {
		_ = tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), filepath.Join(dir, "state.json"))
}

// ClearState removes the published state, tolerating an already-absent
// file so shutdown is idempotent.
func ClearState() error {
	path, err := StatePath()
	if err != nil {
		return err
	}
	if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	return nil
}

// Running returns the state of a live daemon, clearing a stale state
// file whose process is gone. Callers get ErrNotRunning rather than a
// zero State they might route an IPC call to.
func Running() (*State, error) {
	state, err := ReadState()
	if err != nil {
		return nil, err
	}
	if state == nil || !state.Alive() {
		_ = ClearState()
		return nil, ErrNotRunning
	}
	return state, nil
}

// Lock is the exclusive per-namespace daemon lock. Holding the open file
// description is what keeps the lock: the kernel releases it when the
// supervisor exits, however it exits.
type Lock struct {
	file *os.File
}

// AcquireLock takes the namespace's exclusive lock without blocking. A
// second daemon fails immediately, whatever config path or environment
// it was started with, because the guard is the lock and not the path.
func AcquireLock() (*Lock, error) {
	dir, err := RuntimeDir()
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, err
	}
	file, err := os.OpenFile(filepath.Join(dir, "vast.lock"), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, err
	}
	if err := syscall.Flock(int(file.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		_ = file.Close()
		state, _ := ReadState()
		if state != nil && state.SupervisorPID > 0 {
			return nil, fmt.Errorf("a vast-shell daemon is already running (supervisor pid %d)", state.SupervisorPID)
		}
		return nil, errors.New("a vast-shell daemon already holds the instance lock")
	}
	return &Lock{file: file}, nil
}

// Release drops the lock.
func (l *Lock) Release() error {
	if l == nil || l.file == nil {
		return nil
	}
	err := syscall.Flock(int(l.file.Fd()), syscall.LOCK_UN)
	if closeErr := l.file.Close(); err == nil {
		err = closeErr
	}
	l.file = nil
	return err
}

// quickshellRuntimeDir is where quickshell publishes live instances.
func quickshellRuntimeDir() (string, error) {
	base := os.Getenv("XDG_RUNTIME_DIR")
	if base == "" {
		return "", errors.New("XDG_RUNTIME_DIR is unset; cannot locate the quickshell runtime directory")
	}
	return filepath.Join(base, "quickshell"), nil
}

// InstanceDir returns the quickshell runtime directory for a process,
// which appears once the instance is serving and holds its ipc.sock.
func InstanceDir(pid int) (string, error) {
	base, err := quickshellRuntimeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(base, "by-pid", strconv.Itoa(pid)), nil
}

// Ready reports whether the shell has published its IPC socket.
func Ready(pid int) bool {
	dir, err := InstanceDir(pid)
	if err != nil {
		return false
	}
	_, err = os.Stat(filepath.Join(dir, "ipc.sock"))
	return err == nil
}

// InstanceID resolves the quickshell IPC instance id for a process from
// the by-pid symlink quickshell maintains. Publishing this id is what
// lets a client address the daemon without resolving any config path.
func InstanceID(pid int) (string, error) {
	dir, err := InstanceDir(pid)
	if err != nil {
		return "", err
	}
	target, err := os.Readlink(dir)
	if err != nil {
		return "", err
	}
	return filepath.Base(target), nil
}

// AwaitInstance blocks until the shell publishes its instance id, the
// process dies, or the timeout elapses. The id cannot be read before
// quickshell has registered, so a fixed sleep is a race.
func AwaitInstance(pid int, died <-chan struct{}, timeout time.Duration) (string, error) {
	deadline := time.Now().Add(timeout)
	for {
		if id, err := InstanceID(pid); err == nil && id != "" {
			return id, nil
		}
		select {
		case <-died:
			return "", errors.New("quickshell exited before publishing its IPC instance")
		default:
		}
		if !time.Now().Before(deadline) {
			return "", errors.New("timed out waiting for quickshell to publish its IPC instance")
		}
		time.Sleep(50 * time.Millisecond)
	}
}
