package cmd

import (
	"os/exec"
	"strings"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var daemonVerbose bool

var daemonCmd = &cobra.Command{
	Use:   "daemon",
	Short: "Manage the vast-shell background process",
	Long:  "Start, stop, restart, or check the status of the vast-shell quickshell daemon.",
}

var daemonStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Launch vast-shell in the background",
	RunE: func(cmd *cobra.Command, args []string) error {
		if out, err := exec.Command("pgrep", "-f", "quickshell").Output(); err == nil && len(out) > 0 {
			cmd.Println("vast-shell is already running")
			return nil
		}
		return startDaemon(cmd)
	},
}

var daemonStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop the vast-shell daemon",
	RunE: func(cmd *cobra.Command, args []string) error {
		out, err := exec.Command("pgrep", "-f", "quickshell").Output()
		if err != nil || len(out) == 0 {
			cmd.Println("vast-shell is not running")
			return nil
		}
		pids := strings.Fields(string(out))
		killed := 0
		for _, pid := range pids {
			_ = exec.Command("kill", pid).Run()
			killed++
		}
		cmd.Printf("vast-shell stopped (%d process%s)\n", killed, map[bool]string{true: "es", false: ""}[killed > 1])
		return nil
	},
}

var daemonRestartCmd = &cobra.Command{
	Use:   "restart",
	Short: "Restart the vast-shell daemon",
	RunE: func(cmd *cobra.Command, args []string) error {
		out, err := exec.Command("pgrep", "-f", "quickshell").Output()
		if err == nil && len(out) > 0 {
			for _, pid := range strings.Fields(string(out)) {
				_ = exec.Command("kill", pid).Run()
			}
		}
		return startDaemon(cmd)
	},
}

var daemonStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if vast-shell is running",
	RunE: func(cmd *cobra.Command, args []string) error {
		if out, err := exec.Command("pgrep", "-f", "quickshell").Output(); err == nil && len(out) > 0 {
			pids := strings.Fields(strings.TrimSpace(string(out)))
			cmd.Printf("vast-shell is running (pid%s %s)\n",
				map[bool]string{true: "s", false: ""}[len(pids) > 1],
				strings.Join(pids, ", "))
		} else {
			cmd.Println("vast-shell is not running")
		}
		return nil
	},
}

func startDaemon(cmd *cobra.Command) error {
	bin, args := ipc.ShellBinArgs()
	proc := exec.Command(bin, args...)
	if !daemonVerbose {
		proc.Stdout = nil
		proc.Stderr = nil
	} else {
		proc.Stdout = cmd.OutOrStdout()
		proc.Stderr = cmd.ErrOrStderr()
	}
	if err := proc.Start(); err != nil {
		return err
	}
	cmd.Printf("vast-shell started (pid %d)\n", proc.Process.Pid)
	return nil
}

func init() {
	daemonCmd.PersistentFlags().BoolVarP(&daemonVerbose, "verbose", "v", false, "Show quickshell output")
	rootCmd.AddCommand(daemonCmd)
	daemonCmd.AddCommand(daemonStartCmd)
	daemonCmd.AddCommand(daemonStopCmd)
	daemonCmd.AddCommand(daemonRestartCmd)
	daemonCmd.AddCommand(daemonStatusCmd)
}
