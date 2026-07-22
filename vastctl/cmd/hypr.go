package cmd

import (
	"fmt"
	"os"
	"text/tabwriter"

	"github.com/myamusashi/vast-shell/vastctl/internal/hypr"
	"github.com/spf13/cobra"
)

var hyprCmd = &cobra.Command{
	Use:   "hypr",
	Short: "Hyprland integration commands",
	Long:  "Dispatch vast shortcuts and list available keybinds from the Hyprland 'vast' submap.",
}

var dispatchCmd = &cobra.Command{
	Use:   "dispatch <shortcut-name>",
	Short: "Dispatch a vast shortcut by name",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return hypr.Dispatch(args[0])
	},
}

var shortcutsListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all shortcuts in the vast submap",
	RunE: func(cmd *cobra.Command, args []string) error {
		shortcuts, err := hypr.ListShortcuts()
		if err != nil {
			return err
		}
		if len(shortcuts) == 0 {
			fmt.Println("No vast shortcuts found.")
			return nil
		}
		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "NAME\tKEYS\tDESCRIPTION")
		for _, s := range shortcuts {
			fmt.Fprintf(w, "%s\t%s\t%s\n", s.Name, s.Keys, s.Description)
		}
		w.Flush()
		return nil
	},
}

var shortcutsCmd = &cobra.Command{
	Use:   "shortcuts",
	Short: "List vast shortcut keybinds",
}

func init() {
	rootCmd.AddCommand(hyprCmd)
	hyprCmd.AddCommand(dispatchCmd)

	shortcutsCmd.AddCommand(shortcutsListCmd)
	hyprCmd.AddCommand(shortcutsCmd)
}
