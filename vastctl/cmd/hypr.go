package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/myamusashi/vast-shell/vastctl/internal/hypr"
	"github.com/myamusashi/vast-shell/vastctl/internal/pretty"
	"github.com/spf13/cobra"
)

var hyprCmd = &cobra.Command{
	Use:   "hypr",
	Short: "Hyprland integration commands",
	Long:  "Dispatch quickshell global shortcuts and list registered shortcuts from Hyprland.",
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
	Short: "List all quickshell global shortcuts",
	RunE: func(cmd *cobra.Command, args []string) error {
		shortcuts, err := hypr.ListShortcuts()
		if err != nil {
			return err
		}
		if prettier {
			b, err := json.Marshal(shortcuts)
			if err != nil {
				return err
			}
			tree, err := pretty.Tree(string(b))
			if err != nil {
				return err
			}
			fmt.Println(tree)
			return nil
		}
		if len(shortcuts) == 0 {
			fmt.Println("No quickshell shortcuts found.")
			return nil
		}
		for _, s := range shortcuts {
			if s.Description != "" {
				fmt.Printf("%s\t%s\n", s.Name, s.Description)
			} else {
				fmt.Println(s.Name)
			}
		}
		return nil
	},
}

var shortcutsCmd = &cobra.Command{
	Use:   "shortcuts",
	Short: "List quickshell global shortcuts",
}

func init() {
	rootCmd.AddCommand(hyprCmd)
	hyprCmd.AddCommand(dispatchCmd)

	shortcutsCmd.AddCommand(shortcutsListCmd)
	hyprCmd.AddCommand(shortcutsCmd)
}
