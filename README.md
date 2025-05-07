# DevOps Bridge

A tool between developers and complex backend infrastructure, inspired by Argo CD. It gives developers the edge they need to succeed while simplifying platform complexities.

## Table of Contents

1. [Project Structure](#project-structure)
2. [Architecture](#architecture)
3. [Development Setup](#development-setup)
   - [Prerequisites](#prerequisites)
   - [Building and Running](#building-and-running)
     - [Backend Server](#backend-server)
     - [Frontend Development](#frontend-development)
     - [CLI](#cli)
4. [Features](#features)
5. [API Documentation](#api-documentation)
6. [Authentication](#authentication)
7. [Contributing](#contributing)

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
    └── dopctl/          # CLI source code
└── dist/                 # Package distribution files
    └── homebrew/         # Homebrew formula for CLI installation
        └── dopctl.rb    # Homebrew formula definition
```

The UI structure follows modern Next.js best practices with a dedicated `src` directory that provides:
- Clean separation between source code and configuration files
- Minimal and focused component structure
- Clear separation of concerns between different parts of the application
- Scalable architecture for adding new features
- Modern styling with Tailwind CSS and CSS variables for theming

## Features

### Modern UI
- Clean and minimalist design
- Responsive layout
- Dark mode support
- Customizable theme using CSS variables
- Component-based architecture using React and Next.js
- Type-safe development with TypeScript

## Architecture

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

## Development Setup

### Prerequisites

- Go 1.19+
- Node.js 18+ (recommended for Next.js 14)
- npm 9+ or yarn
- Kubernetes cluster or minikube

### Building and Running

#### Backend Server

1. Start the Go backend server:
```bash
cd server
go mod tidy
go run main.go
```

The server will start on:
- HTTP API: http://localhost:8080
- gRPC: localhost:9090

#### Frontend Development

1. Install dependencies:
```bash
cd ui
npm install
```

2. Start the development server:
```bash
npm run dev
```

The UI will be available at http://localhost:3000

3. **Build the UI for production or packaging:**
```bash
npm run build
```
This will build the latest UI assets. The build step is also automatically run as part of the release process in `dist/homebrew/update_version.sh`.

#### Importing Components from v0.dev

To import components from v0.dev into your project:

1. Navigate to the UI directory:
```bash
cd ui
```

2. Run the shadcn command with your v0.dev component URL:
```bash
npx shadcn@2.3.0 add "your-v0-dev-component-url"
```

This will:
- Download the component code from v0.dev
- Add any necessary shadcn-ui component dependencies
- Create the component file in your project
- Add required imports and styles

After importing, you can use the component in your pages or components. You may need to restart your development server after adding new components.

#### CLI

1. Build the CLI:
```bash
cd cmd/dopctl
go build -o dopctl
```

2. Open the dashboard:
```bash
./dopctl admin dashboard
```

This will start the Next.js server if not running and open the dashboard in your browser.

#### Installing via Homebrew

You can install the DevOps CLI using Homebrew:

1. Add the Sysintelligent tap:
```bash
brew tap sysintelligent/sysintelligent
```

2. Install the CLI:
```bash
brew install sysintelligent/sysintelligent/dopctl
```

3. Verify the installation:
```bash
dopctl version
```

To uninstall the CLI:
```bash
brew uninstall sysintelligent/sysintelligent/dopctl
```

## API Documentation

The backend provides the following API endpoints:

### REST API (Port 8080)

- `GET /health` - Health check endpoint
- `GET /api/applications` - List all applications
- `GET /api/applications/{name}` - Get application details
- `POST /api/applications` - Create new application
- `PUT /api/applications/{name}` - Update application
- `DELETE /api/applications/{name}` - Delete application
- `GET /api/settings` - Get settings
- `PUT /api/settings` - Update settings

### gRPC API (Port 9090)

- ApplicationService
  - GetApplications
  - GetApplication
  - CreateApplication
  - UpdateApplication
  - DeleteApplication

## Authentication

The server supports two types of authentication tokens:

1. **Admin Token**
   - Full access to all endpoints
   - Token: `admin-token`
   - Example: `curl -H "Authorization: Bearer admin-token" http://localhost:8080/api/applications`

2. **Demo Token**
   - Read-only access to applications and settings
   - Token: `demo-token`
   - Example: `curl -H "Authorization: Bearer demo-token" http://localhost:8080/api/applications`

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
