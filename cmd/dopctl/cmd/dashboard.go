package cmd

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"

	"github.com/spf13/cobra"
)

// dashboardCmd represents the dashboard command
var dashboardCmd = &cobra.Command{
	Use:   "dashboard",
	Short: "Open the DevOps Bridge dashboard",
	Long: `Open the DevOps Bridge dashboard in your default browser.
This command checks for the UI path in the following order:
1. DEVOPS_UI_PATH environment variable
2. User's home directory (~/.dopctl/ui)
3. System configuration (/opt/homebrew/etc/dopctl.conf)
and opens the main DevOps Bridge dashboard UI in your default browser.`,
	Run: func(cmd *cobra.Command, args []string) {
		startDashboard()
	},
}

func init() {
	adminCmd.AddCommand(dashboardCmd)
	dashboardCmd.Flags().BoolVarP(&openBrowser, "open", "o", true, "Open the dashboard in the default browser")
	dashboardCmd.Flags().IntVarP(&port, "port", "p", 3000, "Port to run the dashboard on")
}

func startDashboard() {
	// Check if the dashboard is already running
	if !isDashboardRunning() {
		fmt.Println("Starting dashboard server...")
		startDashboardServer()
		// Wait for the server to start
		time.Sleep(2 * time.Second)
	}

	url := fmt.Sprintf("http://localhost:%d", port)
	fmt.Printf("Opening dashboard at %s\n", url)

	if openBrowser {
		openURL(url)
	} else {
		fmt.Printf("Dashboard is available at %s\n", url)
	}
}

func isDashboardRunning() bool {
	resp, err := http.Get(fmt.Sprintf("http://localhost:%d", port))
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusNotFound
}

func startDashboardServer() {
	// Try to find UI path from configuration file
	uiPath := ""

	// First check project directory
	projectUIPath := "ui"
	if _, err := os.Stat(projectUIPath); err == nil {
		uiPath = projectUIPath
	}

	// If not found in project directory, check environment variable
	if uiPath == "" && os.Getenv("DEVOPS_UI_PATH") != "" {
		uiPath = os.Getenv("DEVOPS_UI_PATH")
	}

	// If still not found, check user's home directory
	if uiPath == "" {
		home, err := os.UserHomeDir()
		if err == nil {
			userUIDir := filepath.Join(home, ".dopctl", "ui")
			if _, err := os.Stat(userUIDir); err == nil {
				uiPath = userUIDir
			}
		}
	}

	// If still not found, check system-wide config
	if uiPath == "" {
		systemConfigPath := "/opt/homebrew/etc/dopctl.conf"
		if _, err := os.Stat(systemConfigPath); err == nil {
			// Read config file and extract UI path
			// This is a placeholder - implement actual config reading
			openBrowserURL(systemConfigPath)
			return
		}
	}

	if uiPath == "" {
		fmt.Println("Error: Could not find UI directory.")
		fmt.Println("Please make sure DevOps CLI is installed correctly.")
		return
	}

	// Change to UI directory
	if err := os.Chdir(uiPath); err != nil {
		fmt.Printf("Error: UI directory not found at %s\n", uiPath)
		fmt.Println("Please make sure DevOps CLI is installed correctly.")
		return
	}

	fmt.Printf("Starting dashboard from UI path: %s\n", uiPath)

	// Start the Next.js development server
	cmd := exec.Command("npm", "run", "dev")
	cmd.Env = append(os.Environ(), "PORT="+fmt.Sprintf("%d", port))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		fmt.Printf("Error starting dashboard server: %v\n", err)
		return
	}

	// Change back to the original directory
	if err := os.Chdir("../.."); err != nil {
		fmt.Printf("Error changing back to original directory: %v\n", err)
	}
}

// openURL opens the specified URL in the default browser
func openURL(url string) {
	var err error

	switch runtime.GOOS {
	case "linux":
		err = exec.Command("xdg-open", url).Start()
	case "windows":
		err = exec.Command("rundll32", "url.dll,FileProtocolHandler", url).Start()
	case "darwin":
		err = exec.Command("open", url).Start()
	default:
		err = fmt.Errorf("unsupported platform")
	}

	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening browser: %s\n", err)
	}
}

func openBrowserURL(url string) {
	var err error
	switch runtime.GOOS {
	case "linux":
		err = exec.Command("xdg-open", url).Start()
	case "windows":
		err = exec.Command("rundll32", "url.dll,FileProtocolHandler", url).Start()
	case "darwin":
		err = exec.Command("open", url).Start()
	default:
		err = fmt.Errorf("unsupported platform")
	}
	if err != nil {
		fmt.Println("Error opening browser:", err)
		fmt.Println("Please make sure DevOps CLI is installed correctly.")
	}
}
