package cmd

import (
	"io"

	"github.com/carapace-sh/carapace"
	"github.com/spf13/cobra"
)

var completionCmd = &cobra.Command{
	Use:   "completion",
	Short: "Generate the autocompletion script for the specified shell",
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
