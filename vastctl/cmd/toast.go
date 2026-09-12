package cmd

import (
	"fmt"
	"strconv"

	"github.com/spf13/cobra"
)

var toastHeader string
var toastIcon string
var toastDuration int

var toastCmd = &cobra.Command{
	Use:   "toast",
	Short: "Show toast notifications",
	Long:  "Show on-screen toast notifications via vast-shell's toast IPC handler.",
}

var toastOpenCmd = &cobra.Command{
	Use:   "open <description>",
	Short: "Show a toast notification",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		if toastDuration < 0 {
			return fmt.Errorf("invalid duration: %d (must be >= 0)", toastDuration)
		}
		return ipcCallVoid("toast", "open", toastHeader, args[0], toastIcon, strconv.Itoa(toastDuration))
	},
}

func init() {
	toastOpenCmd.Flags().StringVarP(&toastHeader, "header", "H", "vast-shell", "Toast header/title")
	toastOpenCmd.Flags().StringVarP(&toastIcon, "icon", "i", "notification-active", "Icon name or path")
	toastOpenCmd.Flags().IntVarP(&toastDuration, "duration", "d", 5000, "Display duration in milliseconds")
	rootCmd.AddCommand(toastCmd)
	toastCmd.AddCommand(toastOpenCmd)
}
