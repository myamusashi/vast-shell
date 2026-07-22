package cmd

import (
	"fmt"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var audioCmd = &cobra.Command{
	Use:   "audio",
	Short: "Control audio devices and profiles",
	Long:  "List and set PipeWire audio profiles and devices through vast-shell.",
}

var audioProfileCmd = &cobra.Command{
	Use:   "profile",
	Short: "Manage audio profiles",
}

var audioProfileListCmd = &cobra.Command{
	Use:   "list",
	Short: "List available audio profiles",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("audio", "profileList")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

var audioProfileSetCmd = &cobra.Command{
	Use:   "set <profile-name>",
	Short: "Set the active audio profile",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("audio", "profileSet", args[0])
		return err
	},
}

var audioDeviceCmd = &cobra.Command{
	Use:   "device",
	Short: "Manage audio devices",
}

var audioDeviceListCmd = &cobra.Command{
	Use:   "list",
	Short: "List available audio devices",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("audio", "deviceList")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

var audioDeviceSetCmd = &cobra.Command{
	Use:   "set <device-name>",
	Short: "Set the default audio device",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("audio", "deviceSet", args[0])
		return err
	},
}

func init() {
	rootCmd.AddCommand(audioCmd)

	audioCmd.AddCommand(audioProfileCmd)
	audioProfileCmd.AddCommand(audioProfileListCmd)
	audioProfileCmd.AddCommand(audioProfileSetCmd)

	audioCmd.AddCommand(audioDeviceCmd)
	audioDeviceCmd.AddCommand(audioDeviceListCmd)
	audioDeviceCmd.AddCommand(audioDeviceSetCmd)
}
