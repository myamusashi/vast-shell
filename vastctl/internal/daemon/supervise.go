package daemon

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"
)

// BootTimeout bounds how long the supervisor waits for quickshell IPC readiness.
const BootTimeout = 60 * time.Second

// Config describes one supervised shell.
type Config struct {
	// Bin is the quickshell binary to run.
	Bin string
	// Args are the arguments selecting the config, e.g. -p <dir>.
	Args []string
	// ConfigPath is the config directory, recorded for diagnostics.
	ConfigPath string
	// LogFile receives the shell's output; nil discards it.
	LogFile *os.File
	// Stdout and Stderr, when set, receive the shell's output instead of
	// LogFile. Used for the systemd foreground mode.
	Stdout io.Writer
	Stderr io.Writer
}

// Supervise holds the namespace lock for the shell's lifetime and publishes its identity.
func Supervise(cfg Config) error {
	lock, err := AcquireLock()
	if err != nil {
		return err
	}
	defer func() { _ = lock.Release() }()

	// An orphaned shell whose supervisor was killed still answers IPC, so
	// refusing here is what keeps that from becoming a second shell.
	if state, err := Running(); err == nil && state != nil {
		return fmt.Errorf("a vast-shell daemon is already running (pid %d, config %s)", state.PID, state.ConfigPath)
	}
	_ = ClearState()

	cmd := exec.Command(cfg.Bin, cfg.Args...)
	cmd.Stdout = firstWriter(cfg.Stdout, cfg.LogFile)
	cmd.Stderr = firstWriter(cfg.Stderr, cfg.LogFile)

	if err := cmd.Start(); err != nil {
		return err
	}

	died := make(chan struct{})
	go func() {
		_ = cmd.Wait()
		close(died)
	}()

	instanceID, err := AwaitInstance(cmd.Process.Pid, died, BootTimeout)
	if err != nil {
		// A shell that cannot be addressed is a failed start: take it
		// down rather than leaving an unreachable instance running.
		_ = cmd.Process.Kill()
		<-died
		return err
	}

	state := State{
		PID:           cmd.Process.Pid,
		SupervisorPID: os.Getpid(),
		ConfigPath:    cfg.ConfigPath,
		InstanceID:    instanceID,
		Namespace:     Namespace(),
		StartedAt:     time.Now().Format(time.RFC3339),
	}
	if err := WriteState(state); err != nil {
		_ = cmd.Process.Kill()
		<-died
		return err
	}
	defer func() { _ = ClearState() }()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	defer signal.Stop(stop)

	select {
	case <-died:
		return exitStatus(cmd)
	case sig := <-stop:
		// Forward so the shell shuts down as cleanly as a directly
		// started one would, then let the deferred cleanup run.
		_ = cmd.Process.Signal(sig)
		<-died
		return nil
	}
}

// Stop asks the recorded supervisor to exit, leaving unrelated shells untouched.
func Stop() error {
	state, err := Running()
	if err != nil {
		return err
	}
	target := state.SupervisorPID
	if target <= 0 {
		target = state.PID
	}
	if err := syscall.Kill(target, syscall.SIGTERM); err != nil {
		return fmt.Errorf("stop vast-shell (pid %d): %w", target, err)
	}
	return nil
}

func firstWriter(primary, fallback io.Writer) io.Writer {
	if primary != nil {
		return primary
	}
	return fallback
}

func exitStatus(cmd *exec.Cmd) error {
	err := cmd.ProcessState.Sys().(syscall.WaitStatus)
	switch {
	case err.Exited():
		if code := err.ExitStatus(); code != 0 {
			return fmt.Errorf("vast-shell exited with status %d", code)
		}
		return nil
	case err.Signaled():
		return fmt.Errorf("vast-shell terminated by signal %v", err.Signal())
	default:
		return errors.New("vast-shell stopped unexpectedly")
	}
}
