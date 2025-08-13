@echo off
REM OdysseyJS Validator Setup Script for Windows
REM This script sets up the environment for validator registration using OdysseyJS

echo =============================================
echo OdysseyJS Validator Environment Setup
echo =============================================

REM Check if we're in the right directory
if not exist "docker-compose.yml" (
    echo Error: This script must be run from the docker directory
    echo Please run: cd odysseygo-installer\docker
    pause
    exit /b 1
)

REM Check if .env already exists
if exist ".env" (
    echo Warning: .env file already exists
    set /p "overwrite=Do you want to overwrite it? (y/N): "
    if /i not "%overwrite%"=="y" (
        echo Setup cancelled. Your existing .env file is preserved.
        pause
        exit /b 0
    )
)

echo Setting up validator environment...

REM Create .env file with validator-optimized settings
(
echo # OdysseyGo Docker Environment Variables
echo # Validator Node Configuration
echo.
echo # Network configuration
echo NETWORK=testnet
echo.
echo # Bootstrap configuration - enables automatic bootstrap download for fast startup
echo BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-testnet.zip
echo.
echo # RPC and API configuration
echo RPC_ACCESS=private
echo ADMIN_API=false
echo ETH_DEBUG_RPC=true
echo.
echo # State sync configuration - enables fast validator setup
echo STATE_SYNC=on
echo.
echo # Network and IP configuration
echo IP_MODE=dynamic
echo PUBLIC_IP=0.0.0.0
echo.
echo # Database and logging
echo DB_DIR=/odysseygo/db
echo LOG_LEVEL_NODE=info
echo LOG_LEVEL_DCHAIN=info
echo.
echo # Node features - validator mode (minimal storage, fast sync)
echo INDEX_ENABLED=true
echo ARCHIVAL_MODE=false
echo.
echo # Port configuration
echo RPC_HOST_PORT=9650
echo P2P_HOST_PORT=9651
) > .env

echo ✅ Created .env file with validator-optimized settings

REM Create validator setup instructions
(
echo # Quick Validator Setup with OdysseyJS
echo.
echo ## Step 1: Environment Setup
echo.
echo 1. Clone OdysseyJS:
echo ```bash
echo git clone https://github.com/DioneProtocol/odjs-int
echo cd odjs-int
echo ```
echo.
echo 2. Use the setup script:
echo ```bash
echo ./setup-env.sh
echo ```
echo.
echo 3. Edit the .env file with your values:
echo ```bash
echo # Odyssey Node Configuration
echo IP=your_node_ip_address
echo PORT=9650
echo PROTOCOL=http
echo NETWORK_ID=5  # Use 5 for testnet, 1 for mainnet
echo.
echo # Transaction-specific variables
echo PRIVATE_KEY=your_private_key_here_without_0x_prefix
echo WALLET_ADDRESS=your_ethereum_style_wallet_address
echo REWARD_ADDRESS=your_ochain_reward_address
echo NODE_ID=your_validator_node_id
echo DELEGATION_FEE=2
echo ```
echo.
echo ## Step 2: Run Scripts
echo.
echo ```bash
echo # Export funds from D-Chain to O-Chain
echo npx ts-node ./examples/delta/buildExportTx-ochain.ts
echo.
echo # Import funds into O-Chain
echo npx ts-node ./examples/omegavm/buildImportTx-DChain.ts
echo.
echo # Add validator
echo npx ts-node ./examples/omegavm/buildAddValidatorTx.ts
echo ```
echo.
echo ## Step 3: Test
echo.
echo ```bash
echo # Test connectivity
echo npx ts-node ./examples/info/getNetworkID.ts
echo ```
echo.
echo For detailed instructions, see the main VALIDATOR_SETUP.md file.
) > VALIDATOR_ODYSSEYJS_SETUP.md

echo ✅ Created VALIDATOR_ODYSSEYJS_SETUP.md with quick setup guide

REM Create required directories
if not exist "data\.odysseygo" mkdir "data\.odysseygo"
if not exist "data\db" mkdir "data\db"
if not exist "logs" mkdir "logs"

echo ✅ Created required directories (data\.odysseygo, data\db, logs)

echo.
echo =============================================
echo Setup Complete! 🎉
echo =============================================
echo.
echo Next steps:
echo 1. Start your validator node: docker-compose up -d
echo 2. Get your Node ID (see VALIDATOR_SETUP.md Step 2)
echo 3. Follow the OdysseyJS setup guide in VALIDATOR_ODYSSEYJS_SETUP.md
echo.
echo Your validator node is configured with:
echo - Network: testnet
echo - State Sync: enabled (fast sync)
echo - Archival Mode: disabled (saves storage)
echo - RPC Access: private (secure)
echo.
echo Happy validating! 🚀
echo.
pause
