package cmd

import (
	"fmt"
	"strconv"

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
		output, err := ipc.Call("brightness", "get")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

var brightnessSetCmd = &cobra.Command{
	Use:   "set <percent>",
	Short: "Set brightness for all displays",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := strconv.Atoi(args[0])
		if err != nil {
			return fmt.Errorf("invalid percent value: %s (must be 0-100)", args[0])
		}
		_, err = ipc.Call("brightness", "set", args[0])
		return err
	},
}

func init() {
	rootCmd.AddCommand(brightnessCmd)
	brightnessCmd.AddCommand(brightnessGetCmd)
	brightnessCmd.AddCommand(brightnessSetCmd)
}
