class BdcCli < Formula
  desc "A tool between developers and complex backend infrastructure"
  homepage "https://github.com/sysintelligent/bdc-bridge"
  url "https://github.com/sysintelligent/bdc-bridge/archive/v1.0.4.tar.gz"
  sha256 "34984464a7b55856a2a4c2a60e5ab711cf475caebbc742746b68a5bc35951241"

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "npm" => :build

  def install
    # Build the Go binary
    system "go", "build", "-ldflags", "-X 'github.com/sysintelligent/bdc-bridge/cmd/bdc-cli/cmd.Version=#{version}'", "-o", "bdc-cli-bin", "./cmd/bdc-cli"
    libexec.install "bdc-cli-bin"
    
    # Create a wrapper script that sets up the user's home directory for UI files
    (bin/"bdc-cli").write <<~EOS
      #!/bin/bash
      
      # Create user home directory for bdc-cli if it doesn't exist
      USER_BDC_DIR="${HOME}/.bdc-cli"
      USER_UI_DIR="${USER_BDC_DIR}/ui"
      USER_CONFIG_FILE="${USER_BDC_DIR}/config.json"
      
      if [ ! -d "${USER_BDC_DIR}" ]; then
        mkdir -p "${USER_BDC_DIR}"
        # Create a default configuration file if it doesn't exist
        if [ ! -f "${USER_CONFIG_FILE}" ]; then
          echo '{
            "ui_path": "${HOME}/.bdc-cli/ui"
          }' > "${USER_CONFIG_FILE}"
        fi
      fi
      
      if [ ! -d "${USER_UI_DIR}" ]; then
        mkdir -p "${USER_UI_DIR}"
        echo "Setting up BDC CLI for first use..."
        
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
      export BDC_UI_PATH="${USER_UI_DIR}"
      export BDC_CONFIG_FILE="${USER_CONFIG_FILE}"
      
      # Execute the main binary
      exec "#{libexec}/bdc-cli-bin" "$@"
    EOS
    
    # Ensure the script is executable
    chmod 0755, bin/"bdc-cli"

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
    system "#{bin}/bdc-cli", "version"
  end
end 