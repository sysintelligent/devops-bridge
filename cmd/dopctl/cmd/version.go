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
	Short: "Print the version number of dopctl",
	Long:  `All software has versions. This is dopctl's`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("dopctl version %s\n", Version)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
