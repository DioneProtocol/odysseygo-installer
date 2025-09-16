# Testing OdysseyGo with Local Binary in Docker

This guide explains how to test your custom OdysseyGo binary (with local code changes) using the Docker setup instead of downloading from GitHub releases.

## 🚀 Quick Start (TL;DR)

**For developers who just want to get started immediately:**

```bash
# 1. Build your custom odysseygo binary
cd /path/to/odysseygo
./scripts/build.sh

# 2. Test with Docker (one command!)
cd /path/to/odysseygo-installer/docker
./test-local-binary.sh -b ../odysseygo/build

# 3. Monitor logs
docker-compose -f docker-compose-local-binary.yml logs -f
```

**That's it!** Your custom binary is now running in Docker with automatic bootstrap download.

## Overview

The Docker setup has been modified to support local binary testing, allowing you to:
- Use your custom-built OdysseyGo binary
- Test code changes in a containerized environment
- Maintain the same configuration and bootstrap features
- Easily switch between local and release binaries

## Prerequisites

1. **Local OdysseyGo Binary**: You need a built OdysseyGo binary from your custom code
2. **Docker & Docker Compose**: Same requirements as the standard setup
3. **Binary Directory Structure**: Your local binary should be in a directory containing:
   - `odysseygo` (the main executable)
   - Any other required files (plugins, etc.)

## Quick Start

### Method 1: Using the Test Script (Recommended)

1. **Build your custom OdysseyGo binary**:
   ```bash
   # In your odysseygo repository
   git checkout your-feature-branch
   ./scripts/build.sh
   # This creates a build/ directory with the binary
   ```

2. **Run the test script**:
   ```bash
   cd docker
   ./test-local-binary.sh -b ../odysseygo/build
   ```

3. **Monitor the container**:
   ```bash
   docker-compose -f docker-compose-local-binary.yml logs -f
   ```

### Method 2: Manual Setup

1. **Create environment file**:
   ```bash
   cd docker
   cp env.local-binary.example .env
   ```

2. **Edit the .env file**:
   ```bash
   # Set your local binary path
   LOCAL_BINARY_PATH=../odysseygo/build
   
   # Configure other settings
   NETWORK=mainnet
   RPC_ACCESS=public
   ```

3. **Build and start**:
   ```bash
   docker-compose -f docker-compose-local-binary.yml up --build -d
   ```

## Complete Setup Guide (Step-by-Step)

This section provides a detailed walkthrough for developers setting up local binary testing from scratch.

### Prerequisites Check

1. **Verify Docker is installed**:
   ```bash
   docker --version
   docker-compose --version
   ```

2. **Verify you have a local OdysseyGo binary**:
   ```bash
   # In your odysseygo repository
   ls -la build/odysseygo  # Should exist and be executable
   ```

### Step 1: Prepare Your Local Binary

1. **Navigate to your odysseygo repository**:
   ```bash
   cd /path/to/your/odysseygo
   ```

2. **Checkout your feature branch**:
   ```bash
   git checkout your-feature-branch
   ```

3. **Build the binary**:
   ```bash
   ./scripts/build.sh
   ```

4. **Verify the build**:
   ```bash
   ls -la build/
   # Should contain: odysseygo (executable) and other files
   ```

### Step 2: Set Up Docker Environment

1. **Navigate to the docker directory**:
   ```bash
   cd /path/to/odysseygo-installer/docker
   ```

2. **Create the .env file**:
   ```bash
   cp env.local-binary.example .env
   ```

3. **Edit the .env file with your settings**:
   ```bash
   nano .env  # or use your preferred editor
   ```

4. **Validate your setup** (recommended):
   ```bash
   ./validate-setup.sh
   ```
   This will check all prerequisites and help fix common issues.

   **Required settings**:
   ```bash
   # REQUIRED: Path to your local binary (relative to docker directory)
   LOCAL_BINARY_PATH=../odysseygo/build
   
   # Network selection
   NETWORK=mainnet  # or testnet
   
   # RPC access
   RPC_ACCESS=public  # or private
   ```

   **Optional settings** (you can leave defaults):
   ```bash
   # Bootstrap (auto-selected based on network)
   BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip
   
   # Node features
   STATE_SYNC=off
   ARCHIVAL_MODE=true
   INDEX_ENABLED=true
   ADMIN_API=false
   ETH_DEBUG_RPC=true
   
   # Logging
   LOG_LEVEL_NODE=info
   LOG_LEVEL_DCHAIN=info
   
   # Ports
   RPC_HOST_PORT=9650
   P2P_HOST_PORT=9651
   ```

### Step 3: Create Required Directories

```bash
# Create data directories for persistent storage
mkdir -p data/.odysseygo data/db logs
```

### Step 4: Build and Start the Container

1. **Build the Docker image**:
   ```bash
   docker-compose -f docker-compose-local-binary.yml build
   ```

2. **Start the container**:
   ```bash
   docker-compose -f docker-compose-local-binary.yml up -d
   ```

3. **Verify it's running**:
   ```bash
   docker-compose -f docker-compose-local-binary.yml ps
   ```

### Step 5: Monitor and Test

1. **View logs**:
   ```bash
   docker-compose -f docker-compose-local-binary.yml logs -f
   ```

2. **Test RPC (if public)**:
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
     http://localhost:9650/ext/info
   ```

3. **Access container shell**:
   ```bash
   docker exec -it $(docker-compose -f docker-compose-local-binary.yml ps -q) /bin/bash
   ```

### Step 6: Stop and Cleanup (when done)

1. **Stop the container**:
   ```bash
   docker-compose -f docker-compose-local-binary.yml down
   ```

2. **Remove everything (including data)**:
   ```bash
   docker-compose -f docker-compose-local-binary.yml down --volumes --remove-orphans
   ```

3. **Remove the image**:
   ```bash
   docker image rm odysseygo-installer_odysseygo
   ```

## Configuration Options

### Test Script Options

```bash
./test-local-binary.sh [OPTIONS]

Options:
  -b, --binary-path PATH    Path to local odysseygo binary directory
  -n, --network NETWORK     Network to use (mainnet/testnet) [default: mainnet]
  -r, --rpc-access ACCESS   RPC access (public/private) [default: public]
  -c, --clean               Clean build (remove existing containers and images)
  -h, --help                Show help message
```

### Examples

**Test with mainnet (public RPC)**:
```bash
./test-local-binary.sh -b ../odysseygo/build
```

**Test with testnet (private RPC)**:
```bash
./test-local-binary.sh -b ../odysseygo/build -n testnet -r private
```

**Clean build (remove old containers)**:
```bash
./test-local-binary.sh -b ../odysseygo/build -c
```

**Test with absolute path**:
```bash
./test-local-binary.sh -b /absolute/path/to/odysseygo/build
```

## Environment Variables

Create a `.env` file with these variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `LOCAL_BINARY_PATH` | Path to your local binary directory | `../odysseygo/build` |
| `NETWORK` | Network to connect to | `mainnet` or `testnet` |
| `RPC_ACCESS` | RPC access control | `public` or `private` |
| `BOOTSTRAP_URL` | Bootstrap data URL | Auto-selected based on network |
| `STATE_SYNC` | Enable state sync | `on` or `off` |
| `ARCHIVAL_MODE` | Run as archival node | `true` or `false` |

## File Structure

```
docker/
├── Dockerfile                           # Modified to support local binary
├── docker-compose-local-binary.yml     # Docker Compose for local binary
├── test-local-binary.sh                # Test script
├── env.local-binary.example            # Environment template
├── README_LOCAL_BINARY.md              # This file
└── data/                               # Persistent data (created automatically)
    ├── .odysseygo/                     # Node configuration
    └── db/                            # Blockchain database
```

## How It Works

### Dockerfile Modifications

The Dockerfile has been modified to:

1. **Accept a build argument** `LOCAL_BINARY_PATH`
2. **Conditionally download or copy**:
   - If `LOCAL_BINARY_PATH` is empty: Downloads from GitHub releases (default behavior)
   - If `LOCAL_BINARY_PATH` is provided: Copies local binary files

### Build Process

1. **Copy Phase**: Local binary files are copied to `/tmp/local-binary/` in the container
2. **Installation Phase**: Files are moved to `/odysseygo/odyssey-node/` and permissions set
3. **Configuration**: Same entrypoint script generates configuration files
4. **Bootstrap**: Same automatic bootstrap download process

### Volume Mounts

Same volume structure as the standard setup:
- `data/.odysseygo` → Node configuration
- `data/db` → Blockchain database
- `logs` → Node logs

## Testing Your Changes

### 1. Basic Functionality Test

```bash
# Start with your binary
./test-local-binary.sh -b ../odysseygo/build

# Check if node starts successfully
docker-compose -f docker-compose-local-binary.yml logs -f

# Test RPC (if public)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
  http://localhost:9650/ext/info
```

### 2. Network-Specific Testing

**Testnet**:
```bash
./test-local-binary.sh -b ../odysseygo/build -n testnet
```

**Mainnet**:
```bash
./test-local-binary.sh -b ../odysseygo/build -n mainnet
```

### 3. RPC Access Testing

**Public RPC** (for testing/development):
```bash
./test-local-binary.sh -b ../odysseygo/build -r public
```

**Private RPC** (for production-like testing):
```bash
./test-local-binary.sh -b ../odysseygo/build -r private
```

## Troubleshooting

### Common Issues

1. **Binary not found**:
   ```
   ERROR: odysseygo binary not found in: /path/to/binary
   ```
   - Ensure the path contains the `odysseygo` executable
   - Check file permissions
   - Verify the path in your .env file is correct

2. **Container fails to start**:
   ```bash
   # Check logs
   docker-compose -f docker-compose-local-binary.yml logs
   
   # Check if binary is executable
   ls -la /path/to/your/binary/odysseygo
   ```

3. **RPC connection fails**:
   - Wait for the node to fully start (check logs)
   - Ensure RPC_ACCESS is set correctly
   - Check if port 9650 is available

4. **Environment file issues**:
   ```
   ERROR: LOCAL_BINARY_PATH not set
   ```
   - Make sure you created the .env file: `cp env.local-binary.example .env`
   - Edit the .env file and set `LOCAL_BINARY_PATH=../odysseygo/build`
   - Use absolute paths if relative paths don't work

5. **Docker build fails**:
   ```
   ERROR: COPY failed: file not found
   ```
   - Check that your LOCAL_BINARY_PATH exists and is accessible
   - Use absolute paths instead of relative paths
   - Ensure the directory contains the odysseygo executable

### Debugging Commands

```bash
# View container logs
docker-compose -f docker-compose-local-binary.yml logs -f

# Access container shell
docker exec -it $(docker-compose -f docker-compose-local-binary.yml ps -q) /bin/bash

# Check binary inside container
docker exec -it $(docker-compose -f docker-compose-local-binary.yml ps -q) ls -la /odysseygo/odyssey-node/

# Test binary version
docker exec -it $(docker-compose -f docker-compose-local-binary.yml ps -q) /odysseygo/odyssey-node/odysseygo --version
```

### Clean Restart

```bash
# Stop and remove everything
docker-compose -f docker-compose-local-binary.yml down --volumes --remove-orphans

# Remove the image
docker image rm odysseygo-installer_odysseygo

# Start fresh
./test-local-binary.sh -b ../odysseygo/build -c
```

## Switching Back to Release Binary

To use the standard GitHub release binary:

1. **Use the original docker-compose.yml**:
   ```bash
   docker-compose up -d
   ```

2. **Or set LOCAL_BINARY_PATH to empty**:
   ```bash
   # In .env file
   LOCAL_BINARY_PATH=
   docker-compose -f docker-compose-local-binary.yml up -d
   ```

## Best Practices

1. **Test on testnet first** before mainnet
2. **Use private RPC** for production-like testing
3. **Clean build** when switching between different binaries
4. **Monitor logs** during initial startup
5. **Backup your data** before testing major changes

## Integration with CI/CD

You can integrate this into your CI/CD pipeline:

```bash
# Build your binary
cd odysseygo
./scripts/build.sh

# Test with Docker
cd ../odysseygo-installer/docker
./test-local-binary.sh -b ../odysseygo/build -n testnet -r private

# Run tests
# ... your test commands ...

# Cleanup
docker-compose -f docker-compose-local-binary.yml down --volumes
```

This approach allows you to test your custom OdysseyGo changes in a controlled, reproducible Docker environment while maintaining all the benefits of the original setup.
