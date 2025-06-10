# DevOps Bridge

A tool between developers and complex backend infrastructure. It gives developers the edge they need to succeed while simplifying platform complexities.

## Key Features
- Modern microservices architecture with Go backend, Next.js frontend, and CLI
- Next.js App Router for efficient routing and built-in authentication
- Modern UI stack with Next.js 14, shadcn/ui components, and Tailwind CSS
- Clean and minimalist design with responsive layout and dark mode support
- Type-safe development with TypeScript and component-based architecture
- Kubernetes integration for managing containerized applications
- Comprehensive API support with both REST and gRPC endpoints
- Easy installation via custom Homebrew tap with automatic updates
- Extensible architecture allowing custom integrations, UI components, and CLI extensions

Below is a sample admin dashboard UI, built with shadcn/ui and Tailwind CSS, providing a real-time overview of service status and operational health.

<div align="center">
  <img src="docs/images/dopctl-admin-dashboard-example.png" alt="DevOps Bridge Admin Dashboard Example" width="800" style="border: 1px solid #000;" />
  <p><em>Admin Dashboard Mockup</em></p>
</div>

## Table of Contents

1. [Installation](#installation)
   - [Prerequisites](#prerequisites)
   - [Installing via Homebrew](#installing-via-homebrew)
   - [Manual Installation](#manual-installation)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Development Setup](#development-setup)
   - [Backend Server](#backend-server)
   - [Frontend Development](#frontend-development)
   - [CLI](#cli)
5. [API Documentation](#api-documentation)
6. [Authentication](#authentication)
7. [Contributing](#contributing)

## Installation

### Prerequisites

- Go 1.19+ (required for backend server and CLI)
- Node.js 18+ (required for frontend development, recommended for Next.js 14)
- npm 9+ or yarn (required for frontend development)
- Kubernetes cluster or minikube (required only for backend server functionality, not needed for dashboard UI)

### Installing via Homebrew

You can install the DevOps CLI using Homebrew:

1. Add the custom tap:
```bash
brew tap sysintelligent/sysintelligent
```

2. Install the CLI:
```bash
brew install dopctl
```

3. Verify the installation:
```bash
dopctl version
```

4. Open the dashboard:
```bash
dopctl admin dashboard
```
_Note: On first run, it may take a little time to initialize the Next.js server._

### Cleanup

To remove the DevOps CLI and clean up the Homebrew tap:

1. Uninstall the CLI:
   ```bash
   brew uninstall dopctl
   ```

2. Remove the custom Homebrew tap:
   ```bash
   brew untap sysintelligent/sysintelligent
   ```

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/sysintelligent/devops-bridge.git
cd devops-bridge
```

2. Build the CLI:
```bash
cd cmd/dopctl
go build -o dopctl
```

3. Move the binary to your PATH:
```bash
sudo mv dopctl /usr/local/bin/
```

## Architecture

<img src="docs/images/architecture.png" alt="DevOps Bridge Core Architecture" style="width: 100%; height: auto;" />

DevOps Bridge uses a modern, microservices-based architecture:

1. **Backend Server (Go)**
   - REST API on port 8080
   - gRPC API on port 9090
   - Handles Kubernetes communication
   - Manages authentication and authorization
   - Provides API endpoints for frontend and CLI

2. **Frontend (Next.js)**
   - Runs on port 3000
   - Modern React-based application
   - Communicates with backend via API
   - Built with Next.js App Router
   - Styled with Tailwind CSS

3. **CLI (Go)**
   - Command-line interface for DevOps Bridge
   - Integrates with both backend and frontend
   - Provides dashboard access via browser

## Project Structure

The project is organized into three main components:

```
devops-bridge/
├── ui/                   # Next.js TypeScript frontend
│   ├── src/              # Source code directory
│   │   ├── app/          # Next.js App Router pages and layouts
│   │   ├── components/   # Reusable UI components
│   │   ├── lib/          # Utility functions and shared code
│   │   └── globals.css   # Global styles and Tailwind configuration
│   ├── public/           # Static assets
│   └── scripts/          # Build and utility scripts
├── server/               # Go backend server
│   ├── api/              # REST and gRPC API definitions
│   ├── auth/             # Authentication and RBAC
│   └── kubernetes/       # Kubernetes client integration
└── cmd/                  # CLI implementation using Cobra
    └── dopctl/           # CLI source code
└── dist/                 # Package distribution files
    └── homebrew/         # Homebrew formula for CLI installation
        └── dopctl.rb     # Homebrew formula definition
```   

## Development Setup

### Backend Server

1. Start the Go backend server:
```bash
cd server
go mod tidy
go run main.go
```

### Frontend Development

1. Install dependencies:
```bash
cd ui
npm install
```

2. Start the development server:
```bash
npm run dev
```

The frontend will be available at http://localhost:3000.

### CLI

1. Build the CLI:
```bash
cd cmd/dopctl
go build -o dopctl
```

2. Install the CLI:
```bash
sudo mv dopctl /usr/local/bin/
```

3. Verify the installation:
```bash
dopctl version
```

## API Documentation

The DevOps Bridge API provides both REST and gRPC endpoints for managing your infrastructure.

### REST API

The REST API is available at `http://localhost:8080/api/` and includes the following endpoints:

- `GET /applications` - List all applications
- `POST /applications` - Create a new application
- `GET /applications/{name}` - Get application details
- `PUT /applications/{name}` - Update an application
- `DELETE /applications/{name}` - Delete an application
- `GET /settings` - Get system settings
- `PUT /settings` - Update system settings

### gRPC API

The gRPC API is available at `localhost:9090` and provides the following services:

- ApplicationService - Manage applications
- SettingsService - Manage system settings
- HealthService - Check system health

## Authentication

DevOps Bridge uses token-based authentication. To access the API:

1. Obtain an authentication token
2. Include the token in the Authorization header:
   ```
   Authorization: Bearer <your-token>
   ```

For development purposes, you can use these demo tokens:
- User token: `demo-token`
- Admin token: `admin-token`

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to:

1. Report bugs
2. Suggest features
3. Submit pull requests
4. Follow our coding standards

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.