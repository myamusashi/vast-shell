package cmd

import (
	"fmt"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/spf13/cobra"
)

var wallpaperCmd = &cobra.Command{
	Use:   "wallpaper",
	Short: "Control desktop wallpaper",
	Long:  "Get or set the current wallpaper via vast-shell's image IPC handler.",
}

var wallpaperGetCmd = &cobra.Command{
	Use:   "get",
	Short: "Get the current wallpaper path",
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("img", "get")
		if err != nil {
			return err
		}
		fmt.Println(output)
		return nil
	},
}

var wallpaperSetCmd = &cobra.Command{
	Use:   "set <path>",
	Short: "Set the wallpaper to the given image path",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		_, err := ipc.Call("img", "set", args[0])
		return err
	},
}

func init() {
	rootCmd.AddCommand(wallpaperCmd)
	wallpaperCmd.AddCommand(wallpaperGetCmd)
	wallpaperCmd.AddCommand(wallpaperSetCmd)
}
