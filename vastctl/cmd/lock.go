package cmd

import (
	"fmt"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
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
		_, err := ipc.Call("lock", "lock")
		return err
	},
}

var lockUnlockCmd = &cobra.Command{
	Use:   "unlock",
	Short: "Unlock the screen",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("lock", "unlock")
		return err
	},
}

var lockStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if the screen is locked",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("lock", "isLocked")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(lockCmd)
	lockCmd.AddCommand(lockLockCmd)
	lockCmd.AddCommand(lockUnlockCmd)
	lockCmd.AddCommand(lockStatusCmd)
}
