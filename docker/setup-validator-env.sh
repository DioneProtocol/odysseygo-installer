#!/bin/bash

# OdysseyJS Validator Setup Script
# This script sets up the environment for validator registration using OdysseyJS

set -e

echo "============================================="
echo "OdysseyJS Validator Environment Setup"
echo "============================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: This script must be run from the docker directory"
    echo "Please run: cd odysseygo-installer/docker"
    exit 1
fi

# Check if .env already exists
if [ -f ".env" ]; then
    echo "Warning: .env file already exists"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Your existing .env file is preserved."
        exit 0
    fi
fi

echo "Setting up validator environment..."

# Create .env file with validator-optimized settings
cat > .env << 'EOF'
# OdysseyGo Docker Environment Variables
# Validator Node Configuration

# Network configuration
NETWORK=testnet

# Bootstrap configuration - enables automatic bootstrap download for fast startup
BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-testnet.zip

# RPC and API configuration
RPC_ACCESS=private
ADMIN_API=false
ETH_DEBUG_RPC=true

# State sync configuration - enables fast validator setup
STATE_SYNC=on

# Network and IP configuration
IP_MODE=dynamic
PUBLIC_IP=0.0.0.0

# Database and logging
DB_DIR=/odysseygo/db
LOG_LEVEL_NODE=info
LOG_LEVEL_DCHAIN=info

# Node features - validator mode (minimal storage, fast sync)
INDEX_ENABLED=true
ARCHIVAL_MODE=false

# Port configuration
RPC_HOST_PORT=9650
P2P_HOST_PORT=9651
EOF

echo "✅ Created .env file with validator-optimized settings"

# Create validator setup instructions
cat > VALIDATOR_ODYSSEYJS_SETUP.md << 'EOF'
# Quick Validator Setup with OdysseyJS

## Step 1: Environment Setup

1. Clone OdysseyJS:
```bash
git clone https://github.com/DioneProtocol/odjs-int
cd odjs-int
```

2. Use the setup script:
```bash
./setup-env.sh
```

3. Edit the .env file with your values:
```bash
# Odyssey Node Configuration
IP=your_node_ip_address
PORT=9650
PROTOCOL=http
NETWORK_ID=5  # Use 5 for testnet, 1 for mainnet

# Transaction-specific variables
PRIVATE_KEY=your_private_key_here_without_0x_prefix
WALLET_ADDRESS=your_ethereum_style_wallet_address
REWARD_ADDRESS=your_ochain_reward_address
NODE_ID=your_validator_node_id
DELEGATION_FEE=2
```

## Step 2: Run Scripts

```bash
# Export funds from D-Chain to O-Chain
npx ts-node ./examples/delta/buildExportTx-ochain.ts

# Import funds into O-Chain
npx ts-node ./examples/omegavm/buildImportTx-DChain.ts

# Add validator
npx ts-node ./examples/omegavm/buildAddValidatorTx.ts
```

## Step 3: Test

```bash
# Test connectivity
npx ts-node ./examples/info/getNetworkID.ts
```

For detailed instructions, see the main VALIDATOR_SETUP.md file.
EOF

echo "✅ Created VALIDATOR_ODYSSEYJS_SETUP.md with quick setup guide"

# Create required directories
mkdir -p data/.odysseygo data/db logs

echo "✅ Created required directories (data/.odysseygo, data/db, logs)"

echo ""
echo "============================================="
echo "Setup Complete! 🎉"
echo "============================================="
echo ""
echo "Next steps:"
echo "1. Start your validator node: docker-compose up -d"
echo "2. Get your Node ID (see VALIDATOR_SETUP.md Step 2)"
echo "3. Follow the OdysseyJS setup guide in VALIDATOR_ODYSSEYJS_SETUP.md"
echo ""
echo "Your validator node is configured with:"
echo "- Network: testnet"
echo "- State Sync: enabled (fast sync)"
echo "- Archival Mode: disabled (saves storage)"
echo "- RPC Access: private (secure)"
echo ""
echo "Happy validating! 🚀"
