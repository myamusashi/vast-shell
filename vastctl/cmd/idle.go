package cmd

import (
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
		return ipcCallVoid("idle", "on")
	},
}

var idleOffCmd = &cobra.Command{
	Use:   "off",
	Short: "Disable idle monitoring",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("idle", "off")
	},
}

var idleStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if idle monitoring is enabled",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("idle", "status")
	},
}

func init() {
	rootCmd.AddCommand(idleCmd)
	idleCmd.AddCommand(idleOnCmd)
	idleCmd.AddCommand(idleOffCmd)
	idleCmd.AddCommand(idleStatusCmd)
}
