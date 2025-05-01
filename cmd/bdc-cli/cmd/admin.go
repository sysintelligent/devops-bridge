package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// adminCmd represents the admin command
var adminCmd = &cobra.Command{
	Use:   "admin",
	Short: "Administrative commands for BDC CLI",
	Long: `Administrative commands for managing the BDC CLI application.
These commands are typically used by administrators to configure and
manage the application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Use one of the admin subcommands. Run 'bdc-cli admin --help' for usage.")
	},
}

func init() {
	rootCmd.AddCommand(adminCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// adminCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// adminCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
