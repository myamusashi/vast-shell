package cmd

import (
	"fmt"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
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
		output, err := ipc.Call("keylock", "capslock")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

var keylockNumlockCmd = &cobra.Command{
	Use:   "numlock",
	Short: "Check if num lock is on",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("keylock", "numlock")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(keylockCmd)
	keylockCmd.AddCommand(keylockCapslockCmd)
	keylockCmd.AddCommand(keylockNumlockCmd)
}
