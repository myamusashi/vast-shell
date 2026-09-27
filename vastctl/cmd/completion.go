package cmd

import (
	"fmt"
	"io"
	"strings"

	"github.com/carapace-sh/carapace"
	"github.com/spf13/cobra"
)

// completionShells are the shells vastctl generates a snippet for.
// The nix package installs exactly these four.
var completionShells = []string{"bash", "zsh", "fish", "nushell"}

var completionCmd = &cobra.Command{
	Use:   "completion",
	Short: "Generate the autocompletion script for the specified shell",
	// Without a RunE, cobra treats an unrecognised shell as a bare
	// invocation and prints the help text with a zero exit status. A
	// user redirecting that into a shell rc file installs the help
	// text believing they installed completions.
	Args: cobra.ArbitraryArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) == 0 {
			// `vastctl completion` on its own is an incomplete
			// invocation, not a mistake: show what can be asked for.
			return cmd.Help()
		}
		return fmt.Errorf("unknown shell %q: vastctl generates completions for %s",
			args[0], strings.Join(completionShells, ", "))
	},
}

func snippetCmd(shell string) *cobra.Command {
	return &cobra.Command{
		Use:   shell,
		Short: "Generate the autocompletion script for " + shell,
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			s, err := carapace.Gen(cmd.Root()).Snippet(shell)
			if err != nil {
				return err
			}
			_, err = io.WriteString(cmd.OutOrStdout(), s)
			return err
		},
	}
}

var completionBashCmd = snippetCmd("bash")

var completionFishCmd = snippetCmd("fish")

var completionZshCmd = snippetCmd("zsh")

var completionNushellCmd = snippetCmd("nushell")

func init() {
	rootCmd.AddCommand(completionCmd)
	completionCmd.AddCommand(completionBashCmd)
	completionCmd.AddCommand(completionFishCmd)
	completionCmd.AddCommand(completionZshCmd)
	completionCmd.AddCommand(completionNushellCmd)
}
