# Validator Setup Documentation

This guide provides comprehensive instructions for setting up a validator node on the Odyssey network.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1: Node Setup](#step-1-node-setup)
- [Step 2: Get Node ID](#step-2-get-node-id)
- [Step 3: Validator Registration](#step-3-validator-registration)
- [Firewall Configuration](#firewall-configuration)
- [Troubleshooting](#troubleshooting)

## Overview

Setting up a validator involves three main steps:
1. **Set up a node** (doesn't need to be an archive node)
2. **Get the NodeID** using RPC
3. **Register the validator** on the blockchain

## Prerequisites

- **System Requirements:**
  - Minimum 4GB RAM
  - At least 100GB free disk space (less if using state sync)
  - Docker v20.10.0 or higher
  - Docker Compose v2.0.0 or higher
  - Internet connection for bootstrap download

- **Network Requirements:**
  - Keep RPC port 9650 private
  - Open port 9651 on firewall for public validator discovery

## Step 1: Node Setup

### Option A: Non-Docker Installation

```bash
git clone https://github.com/DioneProtocol/odysseygo-installer
cd odysseygo-installer

# Install for testnet
bash odyssey-installer.sh --version develop --testnet
```

#### Staking Keys Location (Non-Docker)

After installation, your staking keys will be located at:
```
~/.odysseygo/staking/
├── signer.key    # Node signing key
├── staker.crt    # Staking certificate
└── staker.key    # Staking private key
```

### Option B: Docker Installation (Recommended)

#### Quick Start (Default Configuration)

```bash
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer/docker

# Create required directories
mkdir -p data/.odysseygo data/db logs
```

**⚠️ Important**: The default configuration runs an archive node, which requires significant storage and sync time. For validators, we recommend using the optimized configuration below.

#### Recommended: Validator-Optimized Setup

For most validators, use this optimized configuration instead of the default:

**1. Create a `.env` file for validator configuration:**
```bash
cat > .env << EOF
NETWORK=testnet
STATE_SYNC=on
ARCHIVAL_MODE=false
RPC_ACCESS=private
EOF
```

**2. Start your validator node:**
```bash
docker-compose up -d
```

**🎉 The container will automatically:**
- Download the appropriate bootstrap file (~222MB for mainnet, smaller for testnet)
- Extract the bootstrap data to the database directory
- Start the OdysseyGo node with your configuration

This validator-optimized configuration provides:
- **Network**: Testnet
- **State Sync**: Enabled (faster sync, less storage)
- **Mode**: Non-archival (suitable for validators)
- **RPC Access**: Private (more secure)

#### Alternative: Default Archive Node

If you specifically need an archive node (for data providers, explorers, etc.):
```bash
# Start with default settings (archive mode, slower sync, more storage)
docker-compose up -d
```

#### For Mainnet Validators

```bash
cat > .env << EOF
NETWORK=mainnet
STATE_SYNC=on
ARCHIVAL_MODE=false
RPC_ACCESS=private
EOF

docker-compose up -d
```

#### More Configuration Options

For additional customization options, see the [Advanced Docker Configuration](#advanced-docker-configuration) section below.

#### Staking Keys Location (Docker)

For Docker installations, the staking keys are located inside the container at:
```
/root/.odysseygo/staking/
├── signer.key    # Node signing key
├── staker.crt    # Staking certificate
└── staker.key    # Staking private key
```

To access these files from the host system:
```bash
# Get container ID
docker ps

# Access staking directory
docker exec -it <container_id> ls /root/.odysseygo/staking

# Copy staking keys to host (for backup)
docker cp <container_id>:/root/.odysseygo/staking ./staking-backup
```

## 🧹 Starting from a Fresh Bootstrap (Clean State)

If you want to ensure your validator node starts from a completely fresh state (for example, to re-download the bootstrap and clear all previous data), follow these steps:

### 1. Stop and Remove All Containers
```bash
docker-compose down
```

### 2. Remove All Docker Volumes (Persistent Data)
```bash
docker volume prune -f
```

### 3. Remove All Docker Images (Optional, for a truly clean slate)
```bash
docker image prune -a -f
```

### 4. Remove Any Host Data Folders (if you mounted host directories)
If you used host-mounted volumes (e.g., `data/` or `logs/`), delete them manually:
```bash
rm -rf data/ logs/
```

### 5. Start Validator Node (Fresh Bootstrap)
Set the network to mainnet or testnet (if not already set in your `.env`):
```bash
NETWORK=mainnet docker-compose up --build
# or for testnet
NETWORK=testnet docker-compose up --build
```

This will:
- Download the appropriate bootstrap zip afresh
- Extract and initialize the node from scratch

**Note:** For validator-optimized setup, ensure your `.env` has `STATE_SYNC=on` and `ARCHIVAL_MODE=false`.

---

## 🔄 Forcing a Fresh Bootstrap Download (Troubleshooting)

If you want to force the container to re-download the bootstrap file (e.g., if the file is corrupted or you want to reset):

1. Remove the bootstrap file inside the running container:
   ```bash
   docker exec <container_name> rm -f /odysseygo-bootstrap/odyssey-bootstrap-mainnet.zip
   # or for testnet:
   docker exec <container_name> rm -f /odysseygo-bootstrap/odyssey-bootstrap-testnet.zip
   ```
2. Restart the container:
   ```bash
   docker-compose restart
   ```

The container will re-download the bootstrap file on next startup.

## ⚠️ CRITICAL: Backup Your Staking Keys

**IMMEDIATELY after node setup, create a secure backup of your staking keys:**

### For Non-Docker Installation:
```bash
# Create backup directory
mkdir -p ~/validator-backup/staking-keys

# Copy staking keys
cp ~/.odysseygo/staking/* ~/validator-backup/staking-keys/

# Secure the backup
chmod 600 ~/validator-backup/staking-keys/*
```

### For Docker Installation:
```bash
# Create backup directory
mkdir -p ~/validator-backup/staking-keys

# Copy from container
docker cp <container_id>:/root/.odysseygo/staking/. ~/validator-backup/staking-keys/

# Secure the backup
chmod 600 ~/validator-backup/staking-keys/*
```

### Important Backup Notes:
- **Store backups in multiple secure locations** (encrypted USB drives, secure cloud storage, etc.)
- **Never share these keys** - they uniquely identify your validator
- **If you lose these keys, you lose your validator identity permanently**
- **Consider using hardware security modules (HSMs) for production validators**
- **Test your backup by ensuring you can restore from it**

### Advanced Docker Configuration

> **Note**: This section provides additional configuration options beyond the basic validator setup above.

#### Environment Variables

| Variable | Default | Description | Options |
|----------|---------|-------------|---------|
| `NETWORK` | mainnet | Network to connect to | testnet, mainnet |
| `BOOTSTRAP_URL` | Auto-selected | Bootstrap download URL | Any valid URL |
| `RPC_ACCESS` | public | RPC access control | public, private |
| `IP_MODE` | dynamic | IP configuration mode | dynamic, static |
| `PUBLIC_IP` | 0.0.0.0 | Node's public IP address | Any valid IPv4 |
| `DB_DIR` | /odysseygo/db | Database directory | Any valid path |
| `LOG_LEVEL_NODE` | info | Node log level | debug, info |
| `LOG_LEVEL_DCHAIN` | info | D-Chain log level | debug, info |
| `INDEX_ENABLED` | true | Enable indexing | true, false |
| `ARCHIVAL_MODE` | true | Run as archival node | true, false |
| `STATE_SYNC` | off | Enable/disable state sync | on, off |
| `ADMIN_API` | false | Enable admin API | true, false |
| `ETH_DEBUG_RPC` | true | Enable Ethereum debug RPC | true, false |

#### Configuration Methods

**1. Using .env file (Recommended)**

Create a `.env` file in the docker directory:

```env
# Example .env file
NETWORK=testnet
RPC_ACCESS=private
ARCHIVAL_MODE=false
STATE_SYNC=on
```

**2. Command line override**

```bash
NETWORK=mainnet STATE_SYNC=on ARCHIVAL_MODE=false docker-compose up -d
```

#### Additional Configuration Examples

**Full Archive Node (for data providers/explorers):**
```env
# In .env file
NETWORK=mainnet
ARCHIVAL_MODE=true
STATE_SYNC=off
# Warning: Requires significant storage space and sync time
```

**Node with Static IP:**
```env
# In .env file
RPC_ACCESS=private
IP_MODE=static
PUBLIC_IP=203.0.113.1  # Replace with your actual public IP
STATE_SYNC=on
ARCHIVAL_MODE=false
```

> **Important**: After making configuration changes, restart your container:
> ```bash
> docker-compose down
> docker-compose up -d
> ```

## Step 2: Get Node ID

Once your node is running, retrieve the Node ID using the RPC API:

```bash
curl -s --location --request POST 'http://127.0.0.1:9650/ext/info' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "info.getNodeID"
  }'
```

**Example Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "nodeID": "NodeID-7Xhw2mDxuDS44j42TCB6U5579esbSt3Lg"
  },
  "id": 1
}
```

Save the `nodeID` value for the next step.

## Step 3: Validator Registration

You have two options for validator registration:

### Option A: Using OdysseyJS Scripts

#### Prerequisites for OdysseyJS Method

1. Clone the OdysseyJS repository:
```bash
git clone https://github.com/DioneProtocol/odjs-int
cd odjs-int
```

2. Install dependencies:
```bash
npm install
```

#### Step 3.1: Export Funds from D-Chain to O-Chain

Edit the file `odjs-int/examples/delta/buildExportTx-ochain.ts`:

1. Set your private key in the `key` constant (without "0x" prefix)
2. Set the amount of DIONE in the `dioneAmount` variable (must be greater than import fee)

```bash
npx ts-node ./examples/delta/buildExportTx-ochain.ts
```

#### Step 3.2: Import Funds into O-Chain

Edit the file `odjs-int/examples/omegavm/buildImportTx-DChain.ts`:

1. Set your private key in the `key` constant (without "0x" prefix)

```bash
npx ts-node ./examples/omegavm/buildImportTx-DChain.ts
```

#### Step 3.3: Add Validator

Edit the validator script `odjs-int/examples/omegavm/buildAddValidatorTx.ts`:

1. Set your private key in the `key` constant (without "0x" prefix)
2. Set the `nodeID` variable with your node's ID from Step 2
3. Set the `reward` variable with the address to receive staking rewards
4. Set the `startTime` variable (staking start time)
5. Set the `endTime` variable (staking end time)
6. Set the `delegationFee` variable (commission percentage for delegators)
7. Set the `stakeAmount` variable (minimum required staking amount)

```bash
npx ts-node ./examples/omegavm/buildAddValidatorTx.ts
```

### Option B: Using Chrome Plugin

*Documentation for Chrome plugin method coming soon.*

## Firewall Configuration

### AWS Security Groups

1. Open the AWS Console and navigate to EC2 > Security Groups
2. Select your instance's security group
3. Add the following inbound rules:
   - **Type:** Custom TCP
   - **Port:** 9651
   - **Source:** 0.0.0.0/0 (Anywhere)
   - **Description:** Odyssey validator P2P

### Digital Ocean Firewall

1. Go to Digital Ocean Control Panel > Networking > Firewalls
2. Create or edit your firewall
3. Add inbound rule:
   - **Type:** TCP
   - **Port:** 9651
   - **Sources:** All IPv4, All IPv6

### UFW (Ubuntu Firewall)

```bash
# Allow validator P2P port
sudo ufw allow 9651/tcp

# Verify rules
sudo ufw status
```

## Health Checks

Verify your node is running correctly:

```bash
# Check node info
curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
    -H 'content-type:application/json' \
    http://localhost:9650/ext/info

# Check if node is bootstrapped
curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.isBootstrapped","params":{"chain":"O"}}' \
    -H 'content-type:application/json' \
    http://localhost:9650/ext/info
```

## Troubleshooting

### Common Issues

1. **Node not discovering peers:**
   - Verify port 9651 is open in firewall
   - Check if your public IP is correctly configured

2. **RPC connection refused:**
   - Ensure RPC_ACCESS is set correctly
   - Verify port 9650 accessibility based on your configuration

3. **Docker container issues:**
   ```bash
   # Check container logs
   docker-compose logs -f
   
   # Restart container
   docker-compose restart
   ```

4. **Bootstrap download issues:**
   ```bash
   # Check if bootstrap file exists
   docker exec <container_name> ls -la /odysseygo-bootstrap/
   
   # Force re-download by removing bootstrap file
   docker exec <container_name> rm -f /odysseygo-bootstrap/odyssey-bootstrap-mainnet.zip
   docker-compose restart
   ```

5. **Insufficient disk space:**
   - Monitor disk usage regularly
   - Consider enabling state sync and disabling archival mode for validators
   - Archive nodes require significantly more storage

### Log Files

- **Docker logs:** `docker-compose logs -f`
- **Node logs:** Check the `logs/` directory in your docker setup

## Security Considerations

1. **RPC Access:** Set `RPC_ACCESS=private` for production deployments
2. **Firewall:** Only open necessary ports (9651 for P2P)
3. **Admin API:** Keep `ADMIN_API=false` unless specifically needed
4. **Private Keys:** Never commit private keys to version control
5. **Staking Keys Backup:** 
   - **ALWAYS backup your staking keys immediately after node setup**
   - Store backups in multiple secure, offline locations
   - Test backup restoration procedures regularly
   - Consider using encrypted storage for backups
   - Never share or expose staking keys publicly

## Staking Key Management

### Key Files Overview
- **`signer.key`**: Used for signing network messages and consensus
- **`staker.crt`**: Certificate that proves your validator's identity
- **`staker.key`**: Private key for staking operations

### Backup Verification
Always verify your backup by checking file integrity:

```bash
# Check if all required files exist in backup
ls -la ~/validator-backup/staking-keys/
# Should show: signer.key, staker.crt, staker.key

# Verify file sizes (should not be empty)
wc -c ~/validator-backup/staking-keys/*
```

### Key Rotation
- Staking keys are generated once and should remain unchanged
- If keys are compromised, you must set up a new validator
- There is no key rotation mechanism - treat these as permanent credentials

## Additional Information

- **Testnet Redeployment:** If the testnet is redeployed with genesis changes, update the `chainId` in the odjs-int config
- **Minimum Staking:** Check current minimum staking requirements before validator registration
- **Delegation:** Validators can accept delegations based on the `delegationFee` parameter
- **Staking Keys:** These are unique to each validator and cannot be recovered if lost
- **Node Migration:** If moving to a new server, ensure you migrate the staking keys to maintain validator identity
- **Archive vs Validator Nodes:** 
  - **Validators**: Can use state sync and non-archival mode for faster setup and less storage
  - **Archive nodes**: Only needed for data providers, explorers, or specific use cases requiring full history
- **State Sync Benefits**: Significantly reduces initial sync time and ongoing storage requirements
- **Automatic Bootstrap**: The Docker container automatically downloads and extracts bootstrap data on first run

## Directory Structure

```
odysseygo-installer/docker/
├── Dockerfile
├── entrypoint.sh
├── docker-compose.yml
├── .env                 # Optional configuration file
├── data/
│   ├── .odysseygo/     # Node configuration
│   └── db/             # Blockchain data
└── logs/               # Node logs
```

## Support

For additional support:
- Check the [GitHub Issues](https://github.com/DioneProtocol/odysseygo-installer/issues)
- Join the community Discord
- Review the [official documentation](https://docs.odysseyprotocol.com)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request to improve this documentation.