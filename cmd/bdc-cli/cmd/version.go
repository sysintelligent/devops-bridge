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
	Short: "Print the version number of bdc-cli",
	Long:  `Print the version number of bdc-cli`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("bdc-cli version %s\n", Version)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
