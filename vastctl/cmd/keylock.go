package cmd

import (
	"github.com/spf13/cobra"
)

var keylockCmd = &cobra.Command{
	Use:   "keylock",
	Short: "Check key lock states",
	Long:  "Query caps lock and num lock status.",
}

var keylockCapslockCmd = &cobra.Command{
	Use:   "capslock",
	Short: "Check if caps lock is on",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("keylock", "capslock")
	},
}

var keylockNumlockCmd = &cobra.Command{
	Use:   "numlock",
	Short: "Check if num lock is on",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("keylock", "numlock")
	},
}

func init() {
	rootCmd.AddCommand(keylockCmd)
	keylockCmd.AddCommand(keylockCapslockCmd)
	keylockCmd.AddCommand(keylockNumlockCmd)
}
