#!/bin/bash

# DevOps Bridge Docker Image Build and Push Script
# This script builds and pushes the image to your Docker Hub repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REPO="sysintelligent"
IMAGE_NAME="devops-bridge"
DEFAULT_TAG="latest"

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
    -t, --tag TAG           Image tag (default: latest)
    -b, --build-only        Only build, don't push
    -p, --push-only         Only push, don't build (assumes image exists)
    -l, --login             Login to Docker Hub before pushing
    -h, --help              Show this help message

Examples:
    # Build and push with latest tag
    $0

    # Build and push with specific tag
    $0 -t v1.0.0

    # Build only
    $0 -b

    # Push only (assumes image is already built)
    $0 -p

    # Login to Docker Hub and push
    $0 -l

EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "docker is not installed. Please install docker first."
        exit 1
    fi
    
    # Check if docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start docker first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to login to Docker Hub
login_to_dockerhub() {
    print_status "Logging in to Docker Hub..."
    docker login
    print_success "Docker Hub login successful"
}

# Function to build image
build_image() {
    local tag=$1
    local full_image_name="$DOCKER_REPO/$IMAGE_NAME:$tag"
    
    print_status "Building Docker image: $full_image_name"
    
    # Get the chart directory
    CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$CHART_DIR")")")"
    
    # Build the image
    docker build -f "$CHART_DIR/Dockerfile" \
        -t "$full_image_name" \
        "$PROJECT_ROOT"
    
    print_success "Docker image built successfully: $full_image_name"
}

# Function to push image
push_image() {
    local tag=$1
    local full_image_name="$DOCKER_REPO/$IMAGE_NAME:$tag"
    
    print_status "Pushing Docker image: $full_image_name"
    
    # Push the image
    docker push "$full_image_name"
    
    print_success "Docker image pushed successfully: $full_image_name"
}

# Function to show image information
show_image_info() {
    local tag=$1
    local full_image_name="$DOCKER_REPO/$IMAGE_NAME:$tag"
    
    print_status "Image information:"
    echo "  Repository: $DOCKER_REPO/$IMAGE_NAME"
    echo "  Tag: $tag"
    echo "  Full name: $full_image_name"
    echo "  Docker Hub URL: https://hub.docker.com/r/$DOCKER_REPO/$IMAGE_NAME"
    echo ""
    echo "To use this image in your Helm chart:"
    echo "  image:"
    echo "    repository: $DOCKER_REPO/$IMAGE_NAME"
    echo "    tag: \"$tag\""
}

# Default values
TAG="$DEFAULT_TAG"
BUILD_ONLY=false
PUSH_ONLY=false
LOGIN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -p|--push-only)
            PUSH_ONLY=true
            shift
            ;;
        -l|--login)
            LOGIN=true
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
print_status "Starting Docker image build and push process..."
print_status "Repository: $DOCKER_REPO/$IMAGE_NAME"
print_status "Tag: $TAG"

check_prerequisites

# Login to Docker Hub if requested
if [ "$LOGIN" = true ]; then
    login_to_dockerhub
fi

# Build image if not push-only
if [ "$PUSH_ONLY" = false ]; then
    build_image "$TAG"
fi

# Push image if not build-only
if [ "$BUILD_ONLY" = false ]; then
    # Login to Docker Hub if not already logged in and we're pushing
    if [ "$LOGIN" = false ]; then
        print_warning "You may need to login to Docker Hub to push the image."
        print_warning "Run: docker login"
        print_warning "Or use: $0 -l"
    fi
    
    push_image "$TAG"
fi

show_image_info "$TAG"

print_success "Docker image process completed!" 