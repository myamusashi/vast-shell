package cmd

import (
	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var brightnessCmd = &cobra.Command{
	Use:   "brightness",
	Short: "Control monitor brightness",
	Long:  "Get and set per-display brightness via vast-shell's BrightnessManager.",
}

var brightnessGetCmd = &cobra.Command{
	Use:   "get",
	Short: "Get current brightness for all displays",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallPrint("brightness", "get")
	},
}

var brightnessSetCmd = &cobra.Command{
	Use:   "set <percent>",
	Short: "Set brightness for all displays",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		if _, err := validatePercent(args[0]); err != nil {
			return err
		}
		_, err := ipc.Call("brightness", "set", args[0])
		return err
	},
}

func init() {
	rootCmd.AddCommand(brightnessCmd)
	brightnessCmd.AddCommand(brightnessGetCmd)
	brightnessCmd.AddCommand(brightnessSetCmd)
}
