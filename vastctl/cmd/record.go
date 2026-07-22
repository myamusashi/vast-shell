package cmd

import (
	"fmt"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var recordCmd = &cobra.Command{
	Use:   "record",
	Short: "Control screen recording",
	Long:  "Start, stop, or check the status of screen recording via vast-shell.",
}

var recordStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Start recording the active screen",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("recorder", "start")
		return err
	},
}

var recordStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop the active recording",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("recorder", "stop")
		return err
	},
}

var recordToggleCmd = &cobra.Command{
	Use:   "toggle",
	Short: "Toggle recording on/off",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("recorder", "toggle")
		return err
	},
}

var recordStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check if recording is active",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("recorder", "status")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(recordCmd)
	recordCmd.AddCommand(recordStartCmd)
	recordCmd.AddCommand(recordStopCmd)
	recordCmd.AddCommand(recordToggleCmd)
	recordCmd.AddCommand(recordStatusCmd)
}
