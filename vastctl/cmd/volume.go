package cmd

import (
	"fmt"
	"strconv"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var volumeCmd = &cobra.Command{
	Use:   "volume",
	Short: "Control system and per-app volume",
	Long:  "Get/set system volume, mute, and manage per-application audio streams via PipeWire.",
}

var volumeSystemCmd = &cobra.Command{
	Use:   "system",
	Short: "Manage system volume",
}

var volumeSystemGetCmd = &cobra.Command{
	Use:   "get",
	Short: "Get system volume and mute state",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("volume", "systemGet")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

var volumeSystemSetCmd = &cobra.Command{
	Use:   "set <percent>",
	Short: "Set system volume (0-100)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		v, err := strconv.Atoi(args[0])
		if err != nil || v < 0 || v > 100 {
			return fmt.Errorf("invalid percent: %s (must be 0-100)", args[0])
		}
		_, err = ipc.Call("volume", "systemSet", args[0])
		return err
	},
}

var volumeSystemMuteCmd = &cobra.Command{
	Use:   "mute",
	Short: "Mute system audio",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("volume", "systemMute")
		return err
	},
}

var volumeSystemUnmuteCmd = &cobra.Command{
	Use:   "unmute",
	Short: "Unmute system audio",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("volume", "systemUnmute")
		return err
	},
}

var volumeSystemToggleCmd = &cobra.Command{
	Use:   "toggle-mute",
	Short: "Toggle system mute",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("volume", "systemToggleMute")
		return err
	},
}

var volumeAppCmd = &cobra.Command{
	Use:   "app",
	Short: "Manage per-app audio volume",
}

var volumeAppListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all audio streams with their volumes",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("volume", "appList")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

var volumeAppSetCmd = &cobra.Command{
	Use:   "set <node-id> <percent>",
	Short: "Set volume for an app by PipeWire node ID",
	Args:  cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		pct, err := strconv.Atoi(args[1])
		if err != nil || pct < 0 || pct > 100 {
			return fmt.Errorf("invalid percent: %s (must be 0-100)", args[1])
		}
		_, err = ipc.Call("volume", "appSet", args[0], args[1])
		return err
	},
}

var volumeAppMuteCmd = &cobra.Command{
	Use:   "mute <node-id>",
	Short: "Mute an app by PipeWire node ID",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("volume", "appMute", args[0])
		return err
	},
}

var volumeAppUnmuteCmd = &cobra.Command{
	Use:   "unmute <node-id>",
	Short: "Unmute an app by PipeWire node ID",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("volume", "appUnmute", args[0])
		return err
	},
}

var volumeAppToggleCmd = &cobra.Command{
	Use:   "toggle-mute <node-id>",
	Short: "Toggle app mute by PipeWire node ID",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("volume", "appToggleMute", args[0])
		return err
	},
}

func init() {
	rootCmd.AddCommand(volumeCmd)

	volumeCmd.AddCommand(volumeSystemCmd)
	volumeSystemCmd.AddCommand(volumeSystemGetCmd)
	volumeSystemCmd.AddCommand(volumeSystemSetCmd)
	volumeSystemCmd.AddCommand(volumeSystemMuteCmd)
	volumeSystemCmd.AddCommand(volumeSystemUnmuteCmd)
	volumeSystemCmd.AddCommand(volumeSystemToggleCmd)

	volumeCmd.AddCommand(volumeAppCmd)
	volumeAppCmd.AddCommand(volumeAppListCmd)
	volumeAppCmd.AddCommand(volumeAppSetCmd)
	volumeAppCmd.AddCommand(volumeAppMuteCmd)
	volumeAppCmd.AddCommand(volumeAppUnmuteCmd)
	volumeAppCmd.AddCommand(volumeAppToggleCmd)
}
