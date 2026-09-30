package cmd

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"syscall"
	"time"

	"github.com/myamusashi/vast-shell/vastctl/internal/daemon"
	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var daemonVerbose bool
var daemonForeground bool
var daemonConfig string

var daemonCmd = &cobra.Command{
	Use:   "daemon",
	Short: "Manage the vast-shell background process",
	Long: "Start, stop, restart, or check the status of the vast-shell quickshell daemon.\n\n" +
		"The running daemon is the source of truth: vastctl daemon start publishes its\n" +
		"identity under $XDG_RUNTIME_DIR and every IPC command routes to that identity,\n" +
		"whatever directory it is called from.",
}

var daemonStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Launch vast-shell in the background",
	RunE: func(cmd *cobra.Command, args []string) error {
		if state, err := daemon.Running(); err == nil {
			cmd.Printf("vast-shell is already running (pid %d)\n", state.PID)
			return nil
		}
		if daemonForeground {
			return runSupervisor(cmd, cmd.OutOrStdout(), cmd.ErrOrStderr())
		}
		return spawnSupervisor(cmd)
	},
}

var daemonRunCmd = &cobra.Command{
	Use:    "run",
	Short:  "Run vast-shell in the foreground under the instance lock",
	Hidden: true,
	Long: "Run the supervisor in the foreground. It holds the namespace's exclusive lock\n" +
		"and publishes the shell's identity, so this is what a service manager should\n" +
		"exec. vastctl daemon start is the user-facing wrapper.",
	RunE: func(cmd *cobra.Command, args []string) error {
		return runSupervisor(cmd, cmd.OutOrStdout(), cmd.ErrOrStderr())
	},
}

var daemonStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop the vast-shell daemon",
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := daemon.Stop(); err != nil {
			if err == daemon.ErrNotRunning {
				cmd.Println("vast-shell is not running")
				return nil
			}
			return err
		}
		cmd.Println("vast-shell stopped")
		return nil
	},
}

var daemonRestartCmd = &cobra.Command{
	Use:   "restart",
	Short: "Restart the vast-shell daemon",
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := daemon.Stop(); err != nil && err != daemon.ErrNotRunning {
			return err
		}
		// Wait for the supervisor to release the lock and clear the state
		// before the replacement tries to take them.
		if err := waitForExit(); err != nil {
			return err
		}
		if daemonForeground {
			return runSupervisor(cmd, cmd.OutOrStdout(), cmd.ErrOrStderr())
		}
		return spawnSupervisor(cmd)
	},
}

var daemonStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if vast-shell is running",
	RunE: func(cmd *cobra.Command, args []string) error {
		cmd.Printf("namespace: %s\n", daemon.Namespace())
		path, err := daemon.StatePath()
		if err != nil {
			return err
		}
		cmd.Printf("state:     %s\n", path)

		state, err := daemon.Running()
		if err != nil {
			cmd.Println("vast-shell is not running")
			return nil
		}
		cmd.Println("vast-shell is running")
		cmd.Printf("├── pid:        %d\n", state.PID)
		cmd.Printf("├── supervisor: %d\n", state.SupervisorPID)
		cmd.Printf("├── instance:   %s\n", state.InstanceID)
		cmd.Printf("├── config:     %s\n", state.ConfigPath)
		if uptime, ok := state.Uptime(); ok {
			cmd.Printf("└── uptime:     %s\n", uptime.Round(time.Second))
		} else {
			cmd.Printf("└── started:    %s\n", state.StartedAt)
		}
		return nil
	},
}

// runSupervisor executes in this process, so a service manager can track
// the shell directly.
func runSupervisor(cmd *cobra.Command, stdout, stderr io.Writer) error {
	bin, args, configPath, err := resolveShell()
	if err != nil {
		return err
	}
	cfg := daemon.Config{Bin: bin, Args: args, ConfigPath: configPath, Stdout: stdout, Stderr: stderr}
	if !daemonVerbose {
		cfg.LogFile = ipc.LogFile()
	}
	return daemon.Supervise(cfg)
}

// spawnSupervisor re-execs vastctl as a detached supervisor so the shell
// outlives the command that started it.
func spawnSupervisor(cmd *cobra.Command) error {
	self, err := os.Executable()
	if err != nil {
		return err
	}
	proc := exec.Command(self, "daemon", "run")
	proc.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	if logFile := ipc.LogFile(); logFile != nil {
		defer func() { _ = logFile.Close() }()
		_, _ = fmt.Fprintf(logFile, "\n--- %s ---\n", time.Now().Format(time.RFC3339))
		proc.Stdout = logFile
		proc.Stderr = logFile
	}
	if err := proc.Start(); err != nil {
		return err
	}
	cmd.Println("vast-shell starting")
	cmd.Println("logs: " + ipc.LogFilePath)
	return nil
}

// resolveShell picks the config to run. This is the only place
// VAST_SHELL_DIRECTORY and --config are honoured: they decide what to
// start, never what to talk to.
func resolveShell() (string, []string, string, error) {
	// An explicit --config wins over the environment for the same reason
	// the environment is read at all: both name what to start.
	if daemonConfig != "" {
		dir := ipc.ConfigDir(daemonConfig)
		return "quickshell", []string{"-p", dir}, dir, nil
	}
	bin, args := ipc.ShellBinArgs()
	return bin, args, ipc.ShellDirectory(), nil
}

// waitForExit blocks until the daemon is gone, so a restart does not race
// the outgoing supervisor for the lock.
func waitForExit() error {
	for range 200 {
		if _, err := daemon.Running(); err != nil {
			return nil
		}
		time.Sleep(50 * time.Millisecond)
	}
	return fmt.Errorf("vast-shell did not exit; see %s", ipc.LogFilePath)
}

func init() {
	daemonCmd.PersistentFlags().BoolVarP(&daemonVerbose, "verbose", "v", false, "Show quickshell output")
	daemonCmd.PersistentFlags().BoolVarP(&daemonForeground, "foreground", "f", false, "Run in foreground (blocking, for systemd)")
	daemonCmd.PersistentFlags().StringVar(&daemonConfig, "config", "", "Config directory to run (daemon only; IPC commands always follow the running daemon)")
	rootCmd.AddCommand(daemonCmd)
	daemonCmd.AddCommand(daemonStartCmd)
	daemonCmd.AddCommand(daemonRunCmd)
	daemonCmd.AddCommand(daemonStopCmd)
	daemonCmd.AddCommand(daemonRestartCmd)
	daemonCmd.AddCommand(daemonStatusCmd)
}
