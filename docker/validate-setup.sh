#!/bin/bash
# Script to validate local binary setup before running Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
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

print_info "Validating local binary Docker setup..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed or not in PATH"
    exit 1
fi

print_success "Docker and Docker Compose are available"

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found"
    print_info "Creating .env file from template..."
    if [ -f "env.local-binary.example" ]; then
        cp env.local-binary.example .env
        print_success ".env file created from template"
    else
        print_error "env.local-binary.example not found"
        exit 1
    fi
else
    print_success ".env file exists"
fi

# Check if LOCAL_BINARY_PATH is set in .env
if ! grep -q "LOCAL_BINARY_PATH=" .env || grep -q "LOCAL_BINARY_PATH=$" .env; then
    print_error "LOCAL_BINARY_PATH is not set in .env file"
    print_info "Please edit .env file and set LOCAL_BINARY_PATH to your binary directory"
    print_info "Example: LOCAL_BINARY_PATH=../odysseygo/build"
    exit 1
fi

# Extract LOCAL_BINARY_PATH from .env
LOCAL_BINARY_PATH=$(grep "LOCAL_BINARY_PATH=" .env | cut -d '=' -f2 | tr -d ' ')

if [ -z "$LOCAL_BINARY_PATH" ]; then
    print_error "LOCAL_BINARY_PATH is empty in .env file"
    exit 1
fi

print_success "LOCAL_BINARY_PATH is set to: $LOCAL_BINARY_PATH"

# Check if binary path exists
if [ ! -d "$LOCAL_BINARY_PATH" ]; then
    print_error "Binary path does not exist: $LOCAL_BINARY_PATH"
    print_info "Please check the path in your .env file"
    exit 1
fi

print_success "Binary path exists: $LOCAL_BINARY_PATH"

# Check if odysseygo binary exists
if [ ! -f "$LOCAL_BINARY_PATH/odysseygo" ]; then
    print_error "odysseygo binary not found in: $LOCAL_BINARY_PATH"
    print_info "Make sure you have built the binary with: ./scripts/build.sh"
    exit 1
fi

print_success "odysseygo binary found: $LOCAL_BINARY_PATH/odysseygo"

# Check if binary is executable
if [ ! -x "$LOCAL_BINARY_PATH/odysseygo" ]; then
    print_warning "odysseygo binary is not executable"
    print_info "Making it executable..."
    chmod +x "$LOCAL_BINARY_PATH/odysseygo"
    print_success "Made odysseygo binary executable"
else
    print_success "odysseygo binary is executable"
fi

# Check if required directories exist
print_info "Checking required directories..."
mkdir -p data/.odysseygo data/db logs
print_success "Required directories created/verified"

# Check if docker-compose-local-binary.yml exists
if [ ! -f "docker-compose-local-binary.yml" ]; then
    print_error "docker-compose-local-binary.yml not found"
    exit 1
fi

print_success "docker-compose-local-binary.yml found"

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found"
    exit 1
fi

print_success "Dockerfile found"

# Test binary version
print_info "Testing binary version..."
if "$LOCAL_BINARY_PATH/odysseygo" --version > /dev/null 2>&1; then
    VERSION=$("$LOCAL_BINARY_PATH/odysseygo" --version)
    print_success "Binary version: $VERSION"
else
    print_warning "Could not get binary version (this might be normal)"
fi

print_success "Setup validation completed successfully!"
print_info "You can now run: docker-compose -f docker-compose-local-binary.yml up --build -d"
print_info "Or use the test script: ./test-local-binary.sh -b $LOCAL_BINARY_PATH"
