package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/myamusashi/vast-shell/vastctl/internal/ipc"
	"github.com/myamusashi/vast-shell/vastctl/internal/pretty"
	"github.com/spf13/cobra"
)

var colorMode string
var colorScheme string
var colorOut string

var colorCmd = &cobra.Command{
	Use:   "color",
	Short: "Generate Material palettes without touching shell colors",
	Long:  "Resolve a full Material role map from an image or a hex color via the shell's color IPC target. Prints JSON and never changes the live palette.",
}

var colorGenerateCmd = &cobra.Command{
	Use:   "generate <image-path>",
	Short: "Generate a palette from an image file",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		output, err := ipc.Call("color", "generate", args[0], colorMode, colorScheme)
		if err != nil {
			return err
		}
		return writeColorOut(cmd, output)
	},
}

var colorFromCmd = &cobra.Command{
	Use:   "from <hex-color>",
	Short: "Generate a palette from a hex color (#RRGGBB)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		hex := args[0]
		if !strings.HasPrefix(hex, "#") {
			hex = "#" + hex
		}
		output, err := ipc.Call("color", "generateFromColor", hex, colorMode, colorScheme)
		if err != nil {
			return err
		}
		return writeColorOut(cmd, output)
	},
}

func writeColorOut(cmd *cobra.Command, output string) error {
	if colorOut != "" {
		if err := os.WriteFile(colorOut, []byte(output+"\n"), 0o644); err != nil {
			return fmt.Errorf("write %s: %w", colorOut, err)
		}
		cmd.Printf("wrote %s\n", colorOut)
		return nil
	}
	if !rawJSON {
		if tree, treeErr := pretty.Tree(output); treeErr == nil {
			output = tree
		}
	}
	fmt.Println(output)
	return nil
}

func init() {
	colorCmd.PersistentFlags().StringVar(&colorMode, "mode", "dark", "Color mode: dark or light")
	colorCmd.PersistentFlags().StringVar(&colorScheme, "scheme", "tonal-spot", "Material scheme (tonal-spot, neutral, vibrant, expressive, fruit-salad, monochrome, rainbow, fidelity, content)")
	colorCmd.PersistentFlags().StringVar(&colorOut, "out", "", "Write JSON to file instead of stdout")
	colorCmd.AddCommand(colorGenerateCmd)
	colorCmd.AddCommand(colorFromCmd)
	rootCmd.AddCommand(colorCmd)
}
