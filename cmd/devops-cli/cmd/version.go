package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// Version is set during build
var Version = "dev"

// versionCmd represents the version command
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version number of devops-cli",
	Long:  `All software has versions. This is devops-cli's`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("devops-cli version %s\n", Version)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
