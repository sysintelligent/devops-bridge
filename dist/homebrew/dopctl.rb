class Dopctl < Formula
  desc "A tool between developers and complex backend infrastructure"
  homepage "https://github.com/sysintelligent/devops-bridge"
  url "https://github.com/sysintelligent/devops-bridge/archive/v1.0.5.tar.gz"
  sha256 "6b7f55f7e3f92d6f8f23bd61fc15a62c51ff6ec46d0b8e3edaf11982d729b373"

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "npm" => :build

  def install
    # Build the Go binary
    system "go", "build", "-ldflags", "-X 'github.com/sysintelligent/devops-bridge/cmd/dopctl/cmd.Version=#{version}'", "-o", "dopctl-bin", "./cmd/dopctl"
    libexec.install "dopctl-bin"
    
    # Create a wrapper script that sets up the user's home directory for UI files
    (bin/"dopctl").write <<~EOS
      #!/bin/bash
      
      # Create user home directory for dopctl if it doesn't exist
      USER_DEVOPS_DIR="${HOME}/.dopctl"
      USER_UI_DIR="${USER_DEVOPS_DIR}/ui"
      USER_CONFIG_FILE="${USER_DEVOPS_DIR}/config.json"
      
      if [ ! -d "${USER_DEVOPS_DIR}" ]; then
        mkdir -p "${USER_DEVOPS_DIR}"
        # Create a default configuration file if it doesn't exist
        if [ ! -f "${USER_CONFIG_FILE}" ]; then
          echo '{
            "ui_path": "${HOME}/.dopctl/ui"
          }' > "${USER_CONFIG_FILE}"
        fi
      fi
      
      # Always ensure UI directory exists
      mkdir -p "${USER_UI_DIR}"
      
      # Always update UI files
      if [ -d "#{libexec}/ui-files" ]; then
        echo "Updating UI files..."
        
        # Create a temporary directory for the new files
        TEMP_UI_DIR=$(mktemp -d)
        if [ $? -ne 0 ]; then
          echo "Error: Failed to create temporary directory"
          exit 1
        fi
        
        # Copy all files to temporary directory first
        echo "Copying new UI files to temporary location..."
        cp -R "#{libexec}/ui-files/"* "${TEMP_UI_DIR}/" 2>/dev/null || true
        
        # Copy hidden files and directories
        if [ -d "#{libexec}/ui-files/.next" ]; then
          echo "Copying Next.js build files..."
          mkdir -p "${TEMP_UI_DIR}/.next"
          cp -R "#{libexec}/ui-files/.next/"* "${TEMP_UI_DIR}/.next/" 2>/dev/null || true
        fi
        
        # Clean up old backups (keep only the last 3)
        echo "Cleaning up old UI backups..."
        ls -dt "${USER_UI_DIR}".backup.* 2>/dev/null | tail -n +4 | xargs -r rm -rf
        
        # Backup existing UI directory if it exists and has content
        if [ -d "${USER_UI_DIR}" ] && [ "$(ls -A ${USER_UI_DIR})" ]; then
          BACKUP_DIR="${USER_UI_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
          echo "Backing up existing UI files to ${BACKUP_DIR}"
          if ! mv "${USER_UI_DIR}" "${BACKUP_DIR}"; then
            echo "Error: Failed to create backup. Aborting update."
            rm -rf "${TEMP_UI_DIR}"
            exit 1
          fi
        fi
        
        # Create fresh UI directory
        echo "Creating fresh UI directory..."
        if ! mkdir -p "${USER_UI_DIR}"; then
          echo "Error: Failed to create UI directory. Restoring from backup..."
          if [ -d "${BACKUP_DIR}" ]; then
            mv "${BACKUP_DIR}" "${USER_UI_DIR}"
          fi
          rm -rf "${TEMP_UI_DIR}"
          exit 1
        fi
        
        # Move files from temporary directory to final location
        echo "Installing new UI files..."
        if ! mv "${TEMP_UI_DIR}/"* "${USER_UI_DIR}/" 2>/dev/null; then
          echo "Error: Failed to move files to final location. Restoring from backup..."
          rm -rf "${USER_UI_DIR}"
          if [ -d "${BACKUP_DIR}" ]; then
            mv "${BACKUP_DIR}" "${USER_UI_DIR}"
          fi
          rm -rf "${TEMP_UI_DIR}"
          exit 1
        fi
        
        # Clean up temporary directory
        rm -rf "${TEMP_UI_DIR}"
        
        # Install dependencies
        echo "Installing Node.js dependencies..."
        cd "${USER_UI_DIR}"
        if ! npm install --quiet; then
          echo "Warning: Failed to install Node.js dependencies. The UI may not work correctly."
        fi
      else
        echo "Warning: UI files not found in #{libexec}/ui-files. Some features may not work correctly."
      fi
      
      # Set environment variable to point to user's UI directory and config file
      export DEVOPS_UI_PATH="${USER_UI_DIR}"
      export DEVOPS_CONFIG_FILE="${USER_CONFIG_FILE}"
      
      # Execute the main binary
      exec "#{libexec}/dopctl-bin" "$@"
    EOS
    
    # Ensure the script is executable
    chmod 0755, bin/"dopctl"

    # Install UI files to a temporary location in libexec
    mkdir_p "#{libexec}/ui-files"
    
    # Build and install UI files
    cd "ui" do
      system "npm", "install", "--quiet"
      system "npm", "run", "build"
      
      # Copy UI files with error handling
      Dir.glob(".next/**/*").each do |file|
        next if File.directory?(file)
        target = "#{libexec}/ui-files/#{file}"
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(file, target)
      end
      
      # Copy other necessary files
      ["public", "src", "package.json", "next.config.js", "tsconfig.json", 
       "tailwind.config.js", "postcss.config.js", "next-env.d.ts", 
       "components.json"].each do |file|
        if File.exist?(file)
          if File.directory?(file)
            FileUtils.cp_r(file, "#{libexec}/ui-files/")
          else
            FileUtils.cp(file, "#{libexec}/ui-files/")
          end
        end
      end
    end
  end

  test do
    system "#{bin}/dopctl", "version"
  end
end 