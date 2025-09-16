#!/bin/bash
# Script to test OdysseyGo with local binary in Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
LOCAL_BINARY_PATH=""
NETWORK="mainnet"
RPC_ACCESS="public"
CLEAN_BUILD=false

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

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --binary-path PATH    Path to local odysseygo binary directory"
    echo "  -n, --network NETWORK     Network to use (mainnet/testnet) [default: mainnet]"
    echo "  -r, --rpc-access ACCESS   RPC access (public/private) [default: public]"
    echo "  -c, --clean               Clean build (remove existing containers and images)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -b ../odysseygo/build"
    echo "  $0 -b /path/to/odysseygo/build -n testnet -r private"
    echo "  $0 -b ../odysseygo/build -c"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--binary-path)
            LOCAL_BINARY_PATH="$2"
            shift 2
            ;;
        -n|--network)
            NETWORK="$2"
            shift 2
            ;;
        -r|--rpc-access)
            RPC_ACCESS="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$LOCAL_BINARY_PATH" ]; then
    print_error "Local binary path is required. Use -b or --binary-path option."
    usage
fi

# Check if binary path exists
if [ ! -d "$LOCAL_BINARY_PATH" ]; then
    print_error "Binary path does not exist: $LOCAL_BINARY_PATH"
    exit 1
fi

# Check if odysseygo binary exists in the path
if [ ! -f "$LOCAL_BINARY_PATH/odysseygo" ]; then
    print_error "odysseygo binary not found in: $LOCAL_BINARY_PATH"
    print_info "Make sure the directory contains the odysseygo executable"
    exit 1
fi

# Validate network parameter
if [ "$NETWORK" != "mainnet" ] && [ "$NETWORK" != "testnet" ]; then
    print_error "Invalid network: $NETWORK. Must be 'mainnet' or 'testnet'"
    exit 1
fi

# Validate RPC access parameter
if [ "$RPC_ACCESS" != "public" ] && [ "$RPC_ACCESS" != "private" ]; then
    print_error "Invalid RPC access: $RPC_ACCESS. Must be 'public' or 'private'"
    exit 1
fi

print_info "Starting OdysseyGo local binary test..."
print_info "Binary path: $LOCAL_BINARY_PATH"
print_info "Network: $NETWORK"
print_info "RPC access: $RPC_ACCESS"

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_info "Cleaning existing containers and images..."
    docker-compose -f docker-compose-local-binary.yml down --volumes --remove-orphans || true
    docker image rm odysseygo-installer_odysseygo || true
    print_success "Clean completed"
fi

# Create necessary directories
print_info "Creating necessary directories..."
mkdir -p data/.odysseygo data/db logs

# Create .env file for local binary testing
print_info "Creating environment configuration..."
cat > .env << EOF
# Local Binary Configuration
LOCAL_BINARY_PATH=$LOCAL_BINARY_PATH

# Network configuration
NETWORK=$NETWORK

# RPC configuration
RPC_ACCESS=$RPC_ACCESS

# Bootstrap configuration
BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-${NETWORK}.zip

# Other configurations
STATE_SYNC=off
ARCHIVAL_MODE=true
INDEX_ENABLED=true
ADMIN_API=false
ETH_DEBUG_RPC=true
LOG_LEVEL_NODE=info
LOG_LEVEL_DCHAIN=info
EOF

print_success "Environment configuration created"

# Build and start the container
print_info "Building Docker image with local binary..."
docker-compose -f docker-compose-local-binary.yml build

print_info "Starting OdysseyGo container..."
docker-compose -f docker-compose-local-binary.yml up -d

# Wait a moment for the container to start
sleep 5

# Check if container is running
if docker-compose -f docker-compose-local-binary.yml ps | grep -q "Up"; then
    print_success "Container started successfully!"
    
    # Get container name
    CONTAINER_NAME=$(docker-compose -f docker-compose-local-binary.yml ps -q)
    
    print_info "Container ID: $CONTAINER_NAME"
    print_info "You can view logs with: docker-compose -f docker-compose-local-binary.yml logs -f"
    print_info "You can stop the container with: docker-compose -f docker-compose-local-binary.yml down"
    
    # Test RPC if public
    if [ "$RPC_ACCESS" = "public" ]; then
        print_info "Testing RPC connection..."
        sleep 10  # Wait a bit more for the node to start
        
        if curl -s -X POST -H "Content-Type: application/json" \
           --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
           http://localhost:9650/ext/info > /dev/null 2>&1; then
            print_success "RPC connection successful!"
        else
            print_warning "RPC connection failed. The node might still be starting up."
        fi
    else
        print_info "RPC is private. Use 'docker exec -it $CONTAINER_NAME' to access the container."
    fi
    
    print_info "Bootstrap data will be downloaded automatically on first run."
    print_info "Check logs to monitor progress: docker-compose -f docker-compose-local-binary.yml logs -f"
    
else
    print_error "Failed to start container. Check logs:"
    docker-compose -f docker-compose-local-binary.yml logs
    exit 1
fi
