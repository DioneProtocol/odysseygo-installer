# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains an installer for OdysseyGo nodes on Linux systems, supporting both bare metal and Docker deployments. The installer supports mainnet and testnet configurations, with options for validator and API node setups.

## Architecture

### Core Components

1. **odysseygo-installer.sh** - Main installer script that:
   - Downloads/builds OdysseyGo binaries from GitHub releases or source
   - Sets up systemd service for node management
   - Configures networking, RPC access, and database settings
   - Supports both RHEL and Debian-based Linux distributions

2. **Docker Setup** (`docker/`):
   - **docker-compose.yml** - Production Docker Compose configuration
   - **docker-compose-local-build.yml** - Local build configuration
   - **entrypoint.sh** - Container entrypoint script that configures node settings
   - **Dockerfile** - Container build configuration

### Key Configuration Files Generated

- `~/.odysseygo/configs/node.json` - Node-level configuration (networking, logging, indexing)
- `~/.odysseygo/configs/chains/D/config.json` - D-Chain specific configuration (APIs, state sync, archival mode)

## Common Commands

### Bare Metal Installation
```bash
# Install latest release for mainnet
./odysseygo-installer.sh

# Install for testnet
./odysseygo-installer.sh --testnet

# Install specific version
./odysseygo-installer.sh --version v1.4.5

# Build from develop branch
./odysseygo-installer.sh --version develop

# Reinstall with new configuration
./odysseygo-installer.sh --reinstall

# Remove installation
./odysseygo-installer.sh --remove

# List available versions
./odysseygo-installer.sh --list
```

### Docker Deployment
```bash
# Start with default configuration
docker-compose up -d

# Start with custom environment variables
NETWORK=testnet RPC_ACCESS=private docker-compose up -d

# View logs
docker-compose logs -f odysseygo

# Stop services
docker-compose down
```

### Service Management (Bare Metal)
```bash
# Check service status
sudo systemctl status odysseygo

# View logs
sudo journalctl -u odysseygo -f

# Start/stop/restart service
sudo systemctl start odysseygo
sudo systemctl stop odysseygo
sudo systemctl restart odysseygo
```

## Network Configuration

### Supported Networks
- **mainnet** - Production Dione Protocol network
- **testnet** - Test network for development

### Node Types
- **Validator nodes** - Should use `--rpc private` for security
- **API nodes** - Can use `--rpc public` but require proper firewall configuration

### IP Configuration Options
- **dynamic** - Uses OpenDNS for public IP resolution
- **static** - Uses manually specified or auto-detected static IP
- **Custom IP** - Specify exact IP address

## Docker Environment Variables

Key environment variables for Docker deployment:

- `NETWORK` - mainnet|testnet (default: mainnet)
- `RPC_ACCESS` - public|private (default: public)  
- `STATE_SYNC` - on|off (default: off)
- `IP_MODE` - dynamic|static (default: dynamic)
- `PUBLIC_IP` - Required if IP_MODE=static
- `INDEX_ENABLED` - true|false (default: true)
- `ARCHIVAL_MODE` - true|false (default: true)
- `ADMIN_API` - true|false (default: false)
- `ETH_DEBUG_RPC` - true|false (default: true)

## Database and Bootstrap

### Database Structure
- Mainnet: `${DB_DIR}/mainnet/`
- Testnet: `${DB_DIR}/testnet/`

### Bootstrap Process
The Docker setup supports automatic bootstrap from remote URLs:
- Downloads bootstrap data if not present locally
- Extracts to appropriate network database directory
- Uses `.bootstrap_done` flag to prevent re-extraction

## Development Notes

- The installer requires `curl`, `wget`, and `dnsutils` packages
- Building from source requires `git`, `go` (>=1.20.8), and `gcc`
- RHEL systems require SELinux context adjustments for systemd execution from home directory
- Configuration files use JSON format and are validated during creation
- Container uses `jq` for JSON configuration manipulation