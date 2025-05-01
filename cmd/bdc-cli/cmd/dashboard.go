package cmd

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

var (
	openBrowser bool
	port        int
)

// dashboardCmd represents the dashboard command
var dashboardCmd = &cobra.Command{
	Use:   "dashboard",
	Short: "Open the BDC Bridge dashboard",
	Long: `Open the BDC Bridge dashboard in your default browser.
	
This command starts the Next.js development server if it's not running
and opens the main BDC Bridge dashboard UI in your default browser.`,
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
	resp, err := http.Get(fmt.Sprintf("http://localhost:%d/health", port))
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode == http.StatusOK
}

func startDashboardServer() {
	// Try to find UI path from configuration file
	uiPath := ""

	// First check environment variable
	if envPath := os.Getenv("BDC_UI_PATH"); envPath != "" {
		uiPath = envPath
	} else {
		// Check user's home directory
		home, err := os.UserHomeDir()
		if err == nil {
			userUIDir := filepath.Join(home, ".bdc-cli", "ui")
			if _, err := os.Stat(userUIDir); err == nil {
				uiPath = userUIDir
			}
		}

		// If not found in user's home, check the system-wide config
		if uiPath == "" {
			systemConfigPath := "/opt/homebrew/etc/bdc-cli.conf"
			if _, err := os.Stat(systemConfigPath); err == nil {
				// Read config file
				configBytes, err := ioutil.ReadFile(systemConfigPath)
				if err == nil {
					var config struct {
						UIPath string `json:"ui_path"`
					}
					if err := json.Unmarshal(configBytes, &config); err == nil {
						// Expand environment variables in the path
						if strings.Contains(config.UIPath, "${HOME}") || strings.Contains(config.UIPath, "$HOME") {
							home, err := os.UserHomeDir()
							if err == nil {
								config.UIPath = strings.Replace(config.UIPath, "${HOME}", home, -1)
								config.UIPath = strings.Replace(config.UIPath, "$HOME", home, -1)
							}
						}
						uiPath = config.UIPath
					}
				}
			}

			// If no UI path found in system config, try development paths
			if uiPath == "" {
				// Try development path first
				devPath := "../../ui"
				if _, err := os.Stat(devPath); err == nil {
					uiPath = devPath
				}
			}
		}
	}

	if uiPath == "" {
		fmt.Println("Error: Could not find UI directory.")
		fmt.Println("Please make sure BDC CLI is installed correctly.")
		return
	}

	// Change to UI directory
	if err := os.Chdir(uiPath); err != nil {
		fmt.Printf("Error: UI directory not found at %s\n", uiPath)
		fmt.Println("Please make sure BDC CLI is installed correctly.")
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
