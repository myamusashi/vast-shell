package cmd

import (
	"github.com/spf13/cobra"
)

var captureCmd = &cobra.Command{
	Use:   "capture",
	Short: "Take screenshots",
	Long:  "Capture the screen, a region, or a window via vast-shell's screenshot service.",
}

var captureScreenCmd = &cobra.Command{
	Use:   "screen [action]",
	Short: "Screenshot the active screen",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("capture", "screen", actionOrDefault(args, "copy"))
	},
}

var captureRegionCmd = &cobra.Command{
	Use:   "region [action]",
	Short: "Screenshot a selected region",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("capture", "region", actionOrDefault(args, "copy"))
	},
}

var captureWindowCmd = &cobra.Command{
	Use:   "window [action]",
	Short: "Screenshot a selected window",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return ipcCallVoid("capture", "window", actionOrDefault(args, "copy"))
	},
}

func init() {
	rootCmd.AddCommand(captureCmd)
	captureCmd.AddCommand(captureScreenCmd)
	captureCmd.AddCommand(captureRegionCmd)
	captureCmd.AddCommand(captureWindowCmd)
}
