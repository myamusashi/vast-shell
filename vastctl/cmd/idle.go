package cmd

import (
	"fmt"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var idleCmd = &cobra.Command{
	Use:   "idle",
	Short: "Control the idle monitor",
	Long:  "Enable or disable vast-shell's idle timeout monitor.",
}

var idleOnCmd = &cobra.Command{
	Use:   "on",
	Short: "Enable idle monitoring",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("idle", "on")
		return err
	},
}

var idleOffCmd = &cobra.Command{
	Use:   "off",
	Short: "Disable idle monitoring",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("idle", "off")
		return err
	},
}

var idleStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if idle monitoring is enabled",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("idle", "status")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(idleCmd)
	idleCmd.AddCommand(idleOnCmd)
	idleCmd.AddCommand(idleOffCmd)
	idleCmd.AddCommand(idleStatusCmd)
}
