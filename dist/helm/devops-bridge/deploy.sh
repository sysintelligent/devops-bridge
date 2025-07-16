#!/bin/bash

# DevOps Bridge Helm Chart Deployment Script
# This script simplifies the deployment process for different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RELEASE_NAME="devops-bridge"
NAMESPACE="devops-bridge"
ENVIRONMENT="development"
VALUES_FILE=""
DRY_RUN=false
BUILD_IMAGE=false
PUSH_IMAGE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -r, --release-name NAME     Release name (default: devops-bridge)
    -n, --namespace NAMESPACE   Kubernetes namespace (default: devops-bridge)
    -e, --environment ENV       Environment: development, staging, production (default: development)
    -f, --values-file FILE      Custom values file
    -d, --dry-run              Dry run mode
    -b, --build-image          Build Docker image
    -p, --push-image           Push Docker image to registry
    -h, --help                 Show this help message

Examples:
    # Deploy to development environment
    $0 -e development

    # Deploy to production with custom values
    $0 -e production -f my-values.yaml

    # Dry run deployment
    $0 -e production -d

    # Build and deploy with custom image
    $0 -e development -b -p

EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    # Check if docker is installed (if building image)
    if [ "$BUILD_IMAGE" = true ] && ! command -v docker &> /dev/null; then
        print_error "docker is not installed. Please install docker first."
        exit 1
    fi
    
    # Check kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to build Docker image
build_image() {
    if [ "$BUILD_IMAGE" = true ]; then
        print_status "Building Docker image..."
        
        # Get the chart directory
        CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$CHART_DIR")")")"
        
        # Build the image
        docker build -f "$CHART_DIR/Dockerfile" \
            -t "sysintelligent/devops-bridge:latest" \
            "$PROJECT_ROOT"
        
        if [ "$PUSH_IMAGE" = true ]; then
            print_status "Pushing Docker image..."
            docker push "sysintelligent/devops-bridge:latest"
        fi
        
        print_success "Docker image built successfully"
    fi
}

# Function to create namespace if it doesn't exist
create_namespace() {
    print_status "Creating namespace '$NAMESPACE' if it doesn't exist..."
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
}

# Function to deploy the chart
deploy_chart() {
    print_status "Deploying DevOps Bridge to environment: $ENVIRONMENT"
    
    # Determine values file
    if [ -n "$VALUES_FILE" ]; then
        VALUES_ARG="-f $VALUES_FILE"
    else
        case $ENVIRONMENT in
            "development")
                VALUES_ARG="-f values-development.yaml"
                ;;
            "staging")
                VALUES_ARG="-f values-production.yaml"
                ;;
            "production")
                VALUES_ARG="-f values-production.yaml"
                ;;
            *)
                print_error "Unknown environment: $ENVIRONMENT"
                exit 1
                ;;
        esac
    fi
    
    # Build helm command
    HELM_CMD="helm install $RELEASE_NAME . $VALUES_ARG --namespace $NAMESPACE"
    
    if [ "$DRY_RUN" = true ]; then
        HELM_CMD="$HELM_CMD --dry-run"
        print_warning "Running in dry-run mode"
    fi
    
    # Check if release already exists
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        print_warning "Release '$RELEASE_NAME' already exists. Upgrading..."
        HELM_CMD="helm upgrade $RELEASE_NAME . $VALUES_ARG --namespace $NAMESPACE"
        if [ "$DRY_RUN" = true ]; then
            HELM_CMD="$HELM_CMD --dry-run"
        fi
    fi
    
    print_status "Executing: $HELM_CMD"
    eval "$HELM_CMD"
    
    if [ "$DRY_RUN" = false ]; then
        print_success "Deployment completed successfully!"
        
        # Show deployment status
        print_status "Deployment status:"
        kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=devops-bridge"
        
        # Show service information
        print_status "Service information:"
        kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/name=devops-bridge"
        
        # Show access instructions
        print_status "Access instructions:"
        echo "To access the application:"
        echo "  kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:8080 9090:9090"
        echo ""
        echo "Then visit:"
        echo "  HTTP API: http://localhost:8080"
        echo "  gRPC API: localhost:9090"
        echo "  Health check: http://localhost:8080/health"
    fi
}

# Function to cleanup on exit
cleanup() {
    if [ $? -ne 0 ]; then
        print_error "Deployment failed!"
        exit 1
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--release-name)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--values-file)
            VALUES_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -b|--build-image)
            BUILD_IMAGE=true
            shift
            ;;
        -p|--push-image)
            PUSH_IMAGE=true
            BUILD_IMAGE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
print_status "Starting DevOps Bridge deployment..."
print_status "Release name: $RELEASE_NAME"
print_status "Namespace: $NAMESPACE"
print_status "Environment: $ENVIRONMENT"

check_prerequisites
build_image
create_namespace
deploy_chart

print_success "Deployment process completed!" 