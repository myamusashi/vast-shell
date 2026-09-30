package cmd

import (
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"testing"
	"time"

	"github.com/myamusashi/vast-shell/vastctl/internal/daemon"
)

// daemonRuntime points the namespace at a fresh runtime directory and
// publishes the state a live supervisor would have written. The recorded
// pid is this test process, so it is alive without a fixture to clean up.
func daemonRuntime(t *testing.T, instanceID string) {
	t.Helper()
	t.Setenv("XDG_RUNTIME_DIR", t.TempDir())
	t.Setenv("VAST_INSTANCE", "")
	t.Setenv("VAST_SHELL_DIRECTORY", "")
	if instanceID == "" {
		return
	}
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

// quickshellCalls returns every recorded quickshell invocation, oldest
// first. The log directory has to be pointed at before the invocation
// under test runs, because the shim records on the way in.
func quickshellCalls(t *testing.T, log string) [][]string {
	return shimInvocations(t, log)
}

// bystander starts a process standing in for an unrelated shell, reaped
// on cleanup so a signalled process does not linger as a zombie.
func bystander(t *testing.T) *os.Process {
	t.Helper()
	cmd, _ := reaped(t)
	return cmd.Process
}

// reaped starts a process and reaps it, returning a channel closed once
// it exits. Signalling leaves a zombie until it is waited for, and a
// zombie still answers a liveness probe, so a test checking whether its
// target died has to be the one to reap it.
func reaped(t *testing.T) (*exec.Cmd, <-chan struct{}) {
	t.Helper()
	cmd := exec.Command("sleep", "60")
	if err := cmd.Start(); err != nil {
		t.Fatalf("start a process: %v", err)
	}
	exited := make(chan struct{})
	go func() {
		_ = cmd.Wait()
		close(exited)
	}()
	t.Cleanup(func() {
		_ = cmd.Process.Kill()
		<-exited
	})
	return cmd, exited
}

func exitedWithin(exited <-chan struct{}, d time.Duration) bool {
	select {
	case <-exited:
		return true
	case <-time.After(d):
		return false
	}
}

func alive(proc *os.Process) bool {
	return proc.Signal(syscall.Signal(0)) == nil
}

// TestDaemonStatusNotRunning pins the answer for a shell that is down.
// The command must say so plainly, or a user reading
// `vastctl daemon status` cannot tell whether it worked.
func TestDaemonStatusNotRunning(t *testing.T) {
	daemonRuntime(t, "")

	res, err := runCLI(t, "daemon", "status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(res.output(), "vast-shell is not running") {
		t.Fatalf("output = %q, want it to report the shell is not running", res.output())
	}
}

// TestDaemonStatusReportsIdentity pins the fields a client resolves its
// IPC target from. The instance id and config path settle "which shell
// am I talking to", which is the question a development run exists to
// answer.
func TestDaemonStatusReportsIdentity(t *testing.T) {
	daemonRuntime(t, "abc123")

	res, err := runCLI(t, "daemon", "status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	out := res.output()
	for _, want := range []string{
		"vast-shell is running",
		"instance:   abc123",
		"config:     /cfg/Qml",
		"pid:        " + strconv.Itoa(os.Getpid()),
	} {
		if !strings.Contains(out, want) {
			t.Errorf("output = %q, want it to contain %q", out, want)
		}
	}
}

// TestDaemonStatusNamesTheNamespace pins that the state location is
// printed. Two namespaces can hold two daemons on purpose, and a user
// needs to see which runtime they are looking at.
func TestDaemonStatusNamesTheNamespace(t *testing.T) {
	daemonRuntime(t, "")
	t.Setenv("VAST_INSTANCE", "dev")

	res, err := runCLI(t, "daemon", "status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	out := res.output()
	if !strings.Contains(out, "namespace: dev") {
		t.Errorf("output = %q, want it to name the dev namespace", out)
	}
	if !strings.Contains(out, "dev"+string(os.PathSeparator)+"state.json") {
		t.Errorf("output = %q, want the dev state path", out)
	}
}

// TestDaemonStatusIgnoresStaleState pins the ghost case. A state file
// whose process is gone must read as "not running"; reporting a daemon
// that is not there sends the user looking for a shell that never
// answers.
func TestDaemonStatusIgnoresStaleState(t *testing.T) {
	daemonRuntime(t, "")
	dead := exec.Command("true")
	if err := dead.Run(); err != nil {
		t.Fatalf("run a short-lived process: %v", err)
	}
	err := daemon.WriteState(daemon.State{
		PID:        dead.Process.Pid,
		InstanceID: "abc123",
		Namespace:  "vast",
	})
	if err != nil {
		t.Fatalf("publish daemon state: %v", err)
	}

	res, err := runCLI(t, "daemon", "status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(res.output(), "vast-shell is not running") {
		t.Fatalf("output = %q, want a stale state to read as not running", res.output())
	}
}

// TestDaemonStartWhenAlreadyRunning pins the guard. A second start would
// leave two shells fighting over the same IPC name, and the user gets a
// desktop whose bars and notifications belong to whichever process won
// the race.
func TestDaemonStartWhenAlreadyRunning(t *testing.T) {
	daemonRuntime(t, "abc123")

	for _, args := range [][]string{
		{"daemon", "start"},
		{"daemon", "start", "--foreground"},
	} {
		t.Run(strings.Join(args, " "), func(t *testing.T) {
			res, err := runCLI(t, args...)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if !strings.Contains(res.output(), "already running") {
				t.Fatalf("output = %q, want it to report the shell is already running", res.output())
			}
		})
	}
}

// TestDaemonRunLaunchesTheConfiguredCheckout pins that --config reaches
// the launcher, and that the shell is started with the directory that
// actually holds shell.qml. It is the only way to point a new daemon at
// a checkout, and it must be honoured here even though IPC commands
// ignore it.
func TestDaemonRunLaunchesTheConfiguredCheckout(t *testing.T) {
	daemonRuntime(t, "")
	root := t.TempDir()
	writeShellQml(t, filepath.Join(root, "Qml", "shell.qml"))
	resolved, err := filepath.EvalSymlinks(root)
	if err != nil {
		t.Fatalf("EvalSymlinks: %v", err)
	}
	// The shim records as it starts, so the log has to be pointed at
	// before the launch.
	log := recordShell(t)

	// The quickshell shim exits at once without publishing an instance,
	// so the supervisor reports a failed start rather than booting a
	// real shell.
	if _, err := runCLI(t, "daemon", "run", "--config", root); err == nil {
		t.Fatal("daemon run reported success, want the failed start to be reported")
	}

	calls := quickshellCalls(t, log)
	if len(calls) == 0 {
		t.Fatal("quickshell was never launched")
	}
	want := "-p " + filepath.Join(resolved, "Qml")
	if got := strings.Join(calls[0], " "); got != want {
		t.Fatalf("quickshell launched with %q, want %q", got, want)
	}
}

// TestDaemonRunFailsWithoutPublishingState pins that a shell which never
// becomes addressable is a failed start, and that it leaves no state
// behind. A published state naming a shell that cannot answer IPC would
// send every later command to a daemon that is not there.
func TestDaemonRunFailsWithoutPublishingState(t *testing.T) {
	daemonRuntime(t, "")

	if _, err := runCLI(t, "daemon", "run"); err == nil {
		t.Fatal("daemon run reported success, want the failed start to be reported")
	}
	state, err := daemon.ReadState()
	if err != nil {
		t.Fatalf("ReadState: %v", err)
	}
	if state != nil {
		t.Fatalf("state = %+v, want none published for a shell that never registered", state)
	}
}

// TestDaemonStopWhenNotRunning pins that stopping a down shell is a
// no-op, not an error. A shutdown hook that runs `vastctl daemon stop`
// on every exit must not fail loudly on the ones where it never started.
func TestDaemonStopWhenNotRunning(t *testing.T) {
	daemonRuntime(t, "")

	res, err := runCLI(t, "daemon", "stop")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(res.output(), "vast-shell is not running") {
		t.Fatalf("output = %q, want a no-op report", res.output())
	}
}

// TestDaemonStopTargetsOnlyTheRecordedSupervisor pins that stop addresses
// the daemon it published rather than sweeping every quickshell on the
// machine. A blanket kill would take down the unrelated dev instance a
// user deliberately runs beside the installed one.
func TestDaemonStopTargetsOnlyTheRecordedSupervisor(t *testing.T) {
	daemonRuntime(t, "")
	unrelated := bystander(t)
	supervisor, supervisorExited := reaped(t)

	err := daemon.WriteState(daemon.State{
		PID:           unrelated.Pid,
		SupervisorPID: supervisor.Process.Pid,
		ConfigPath:    "/cfg/Qml",
		InstanceID:    "abc123",
		Namespace:     "vast",
	})
	if err != nil {
		t.Fatalf("publish daemon state: %v", err)
	}

	res, err := runCLI(t, "daemon", "stop")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(res.output(), "vast-shell stopped") {
		t.Fatalf("output = %q, want a stop report", res.output())
	}

	if !exitedWithin(supervisorExited, 2*time.Second) {
		t.Error("the recorded supervisor survived, want it signalled")
	}
	if !alive(unrelated) {
		t.Error("an unrelated quickshell was signalled, want only the recorded supervisor targeted")
	}
}

// TestDaemonHelpHidesRun pins that `daemon run` stays an implementation
// detail. It is the exec target a service manager uses, and advertising
// it invites a user to run it in a terminal and wonder why the shell
// now owns their session.
func TestDaemonHelpHidesRun(t *testing.T) {
	daemonRuntime(t, "")

	res, err := runCLI(t, "daemon", "--help")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if strings.Contains(res.output(), "\n  run ") {
		t.Fatalf("help = %q, want `daemon run` hidden from the command list", res.output())
	}
}

// TestIPCCommandsRefuseWithoutADaemon is the regression this design
// exists for. A call with no daemon must refuse, and say how to start
// one, rather than launching a shell of its own.
func TestIPCCommandsRefuseWithoutADaemon(t *testing.T) {
	daemonRuntime(t, "")

	for _, args := range [][]string{
		{"wallpaper", "get"},
		{"volume", "system", "get"},
		{"idle", "status"},
	} {
		t.Run(strings.Join(args, " "), func(t *testing.T) {
			log := recordShell(t)
			_, err := runCLI(t, args...)
			if err == nil {
				t.Fatalf("%v succeeded with no daemon running", args)
			}
			// The remedy is the whole point of refusing, and it reaches
			// the user as the command's error, not its output.
			if !strings.Contains(err.Error(), "vastctl daemon start") {
				t.Errorf("error = %q, want it to say how to start the daemon", err)
			}
			if calls := quickshellCalls(t, log); len(calls) != 0 {
				t.Errorf("quickshell was invoked %d times, want 0: a client must not reach the shell without a daemon", len(calls))
			}
		})
	}
}

// TestIPCCommandsReachTheDaemonFromAnyDirectory pins the routing. A
// client invoked from an unrelated directory, with a
// VAST_SHELL_DIRECTORY pointing at a different checkout, must still be
// answered by the daemon that is running.
func TestIPCCommandsReachTheDaemonFromAnyDirectory(t *testing.T) {
	daemonRuntime(t, "abc123")
	t.Setenv("VAST_SHELL_DIRECTORY", "/home/me/some-other-checkout")
	t.Chdir(t.TempDir())
	t.Setenv("SHIM_OUT", "/home/me/wall.png")
	log := recordShell(t)

	res, err := runCLI(t, "wallpaper", "get")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(res.output(), "/home/me/wall.png") {
		t.Fatalf("output = %q, want the running daemon's answer", res.output())
	}

	calls := quickshellCalls(t, log)
	if len(calls) == 0 {
		t.Fatal("quickshell was never invoked")
	}
	got := strings.Join(calls[len(calls)-1], " ")
	if !strings.Contains(got, "--id abc123") {
		t.Errorf("quickshell received %q, want the call addressed by instance id", got)
	}
	if strings.Contains(got, "some-other-checkout") {
		t.Errorf("quickshell received %q, want no config path taken from the caller's environment", got)
	}
}

// TestIPCCommandsDoNotLaunchASecondShell is the guard against the
// duplicate-shell bug. A call must never spawn a shell, and must never
// probe for one: either would leave two shells contending for the same
// IPC targets.
func TestIPCCommandsDoNotLaunchASecondShell(t *testing.T) {
	daemonRuntime(t, "abc123")
	t.Setenv("SHIM_OUT", "/home/me/wall.png")
	log := recordShell(t)

	if _, err := runCLI(t, "wallpaper", "get"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	for _, call := range quickshellCalls(t, log) {
		joined := strings.Join(call, " ")
		if strings.Contains(joined, "ipc show") {
			t.Errorf("quickshell was probed for readiness: %q", call)
		}
		if len(call) > 0 && call[0] == "-p" {
			t.Errorf("quickshell was launched with a config path: %q", call)
		}
	}
}
