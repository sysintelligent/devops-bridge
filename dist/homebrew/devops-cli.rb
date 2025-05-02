class DevopsCli < Formula
  desc "A tool between developers and complex backend infrastructure"
  homepage "https://github.com/sysintelligent/devops-bridge"
  url "https://github.com/sysintelligent/devops-bridge/archive/v1.0.2.tar.gz"
  sha256 "39627dc97d7f65c390c57e0b557dbb3b916b9161086e1e0c36775802989872fc"

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "npm" => :build

  def install
    # Build the Go binary
    system "go", "build", "-ldflags", "-X 'github.com/sysintelligent/devops-bridge/cmd/devops-cli/cmd.Version=#{version}'", "-o", "devops-cli-bin", "./cmd/devops-cli"
    libexec.install "devops-cli-bin"
    
    # Create a wrapper script that sets up the user's home directory for UI files
    (bin/"devops-cli").write <<~EOS
      #!/bin/bash
      
      # Create user home directory for devops-cli if it doesn't exist
      USER_DEVOPS_DIR="${HOME}/.devops-cli"
      USER_UI_DIR="${USER_DEVOPS_DIR}/ui"
      USER_CONFIG_FILE="${USER_DEVOPS_DIR}/config.json"
      
      if [ ! -d "${USER_DEVOPS_DIR}" ]; then
        mkdir -p "${USER_DEVOPS_DIR}"
        # Create a default configuration file if it doesn't exist
        if [ ! -f "${USER_CONFIG_FILE}" ]; then
          echo '{
            "ui_path": "${HOME}/.devops-cli/ui"
          }' > "${USER_CONFIG_FILE}"
        fi
      fi
      
      if [ ! -d "${USER_UI_DIR}" ]; then
        mkdir -p "${USER_UI_DIR}"
        echo "Setting up DevOps CLI for first use..."
        
        # Copy all the UI files
        if [ -d "#{libexec}/ui-files" ]; then
          cp -R "#{libexec}/ui-files/"* "${USER_UI_DIR}/" 2>/dev/null || true
          
          # Copy hidden files and directories
          if [ -d "#{libexec}/ui-files/.next" ]; then
            mkdir -p "${USER_UI_DIR}/.next"
            cp -R "#{libexec}/ui-files/.next/"* "${USER_UI_DIR}/.next/" 2>/dev/null || true
          fi
          
          # Install dependencies
          echo "Installing Node.js dependencies..."
          cd "${USER_UI_DIR}"
          npm install --quiet
        else
          echo "Warning: UI files not found. Some features may not work correctly."
        fi
      fi
      
      # Set environment variable to point to user's UI directory and config file
      export DEVOPS_UI_PATH="${USER_UI_DIR}"
      export DEVOPS_CONFIG_FILE="${USER_CONFIG_FILE}"
      
      # Execute the main binary
      exec "#{libexec}/devops-cli-bin" "$@"
    EOS
    
    # Ensure the script is executable
    chmod 0755, bin/"devops-cli"

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
    system "#{bin}/devops-cli", "version"
  end
end 