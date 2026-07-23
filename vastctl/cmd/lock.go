package cmd

import (
	"github.com/spf13/cobra"
)

var lockCmd = &cobra.Command{
	Use:   "lock",
	Short: "Control the screen lock",
	Long:  "Lock, unlock, or check the status of the vast-shell screen lock.",
}

var lockLockCmd = &cobra.Command{
	Use:   "lock",
	Short: "Lock the screen",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("lock", "lock")
	},
}

var lockUnlockCmd = &cobra.Command{
	Use:   "unlock",
	Short: "Unlock the screen",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("lock", "unlock")
	},
}

var lockStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if the screen is locked",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("lock", "isLocked")
	},
}

func init() {
	rootCmd.AddCommand(lockCmd)
	lockCmd.AddCommand(lockLockCmd)
	lockCmd.AddCommand(lockUnlockCmd)
	lockCmd.AddCommand(lockStatusCmd)
}
