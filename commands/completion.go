package commands

import (
	"fmt"
	"os"

	"github.com/ci-monk/drprune/internal/constants"
	"github.com/spf13/cobra"
)

// excludeDesc description will not be added if true.
var excludeDesc = false

// completionCmd represents the completion command.
var completionCmd = &cobra.Command{
	Use:       "completion <shell>",
	Short:     "Generate shell completion scripts",
	Long:      constants.CompletionHelpMessage,
	ValidArgs: []string{"bash", "zsh", "fish", "powershell"},
	Args: func(cmd *cobra.Command, args []string) error {
		if cobra.ExactArgs(1)(cmd, args) != nil || cobra.OnlyValidArgs(cmd, args) != nil {
			return fmt.Errorf("only %v arguments are allowed", cmd.ValidArgs)
		}
		return nil
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		var shellType string = args[0]
		out, rootCmd := os.Stdout, cmd.Parent()
		switch shellType {
		case "bash":
			return rootCmd.GenBashCompletionV2(out, !excludeDesc)
		case "zsh":
			if excludeDesc {
				return rootCmd.GenZshCompletionNoDesc(out)
			}
			return rootCmd.GenZshCompletion(out)
		case "powershell":
			if excludeDesc {
				return rootCmd.GenPowerShellCompletion(out)
			}
			return rootCmd.GenPowerShellCompletionWithDesc(out)
		case "fish":
			return rootCmd.GenFishCompletion(out, !excludeDesc)
		default:
			return fmt.Errorf("unsupported shell type %q", shellType)
		}
	},
}

func init() {
	completionCmd.Flags().BoolVarP(&excludeDesc, "no-desc", "", false, "Do not include shell completion description")
	rootCmd.AddCommand(completionCmd)
}
