package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// adminDashboardCmd represents the admin dashboard command
var adminDashboardCmd = &cobra.Command{
	Use:   "dashboard",
	Short: "Open the DevOps Bridge admin dashboard",
	Long: `Open the DevOps Bridge admin dashboard in your default browser.
This command provides access to administrative features and settings.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Set admin token for dashboard access
		if err := os.Setenv("DEVOPS_ADMIN_TOKEN", "admin-token"); err != nil {
			fmt.Println("Error setting admin token:", err)
			return
		}
		startDashboard()
	},
}

func init() {
	adminCmd.AddCommand(adminDashboardCmd)
	adminDashboardCmd.Flags().BoolVarP(&openBrowser, "open", "o", true, "Open the dashboard in the default browser")
	adminDashboardCmd.Flags().IntVarP(&port, "port", "p", 3000, "Port to run the dashboard on")
}
