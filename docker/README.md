# OdysseyGo Docker Node

A Docker implementation of OdysseyGo node with configurable options for running both mainnet and testnet networks. Supports both **validator nodes** and **archive nodes** with **automatic bootstrap download**.

## 🚀 New Feature: Automatic Bootstrap Download

**The Docker container now automatically downloads and extracts bootstrap data on first run!**

- ✅ **Automatic Download**: Bootstrap files are downloaded automatically from official CDN
- ✅ **Smart Detection**: Only downloads if bootstrap data doesn't exist
- ✅ **Network-Specific**: Downloads the correct bootstrap for mainnet or testnet
- ✅ **Resume Support**: Won't re-download if bootstrap already exists
- ✅ **Progress Logging**: Clear feedback during download and extraction

### Bootstrap URLs (Automatically Selected)
- **Mainnet**: `https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip`
- **Testnet**: `https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-testnet.zip`

## Node Types

### 🛡️ Validator Node (Recommended for most users)
- **Purpose**: Participate in consensus and earn staking rewards
- **Storage**: Minimal (~50-100GB with state sync)
- **Sync time**: Fast (hours with state sync)
- **Configuration**: State sync enabled, archival mode disabled
- **Use case**: Staking, validation, basic API access

### 📚 Archive Node (For data providers)
- **Purpose**: Store complete blockchain history
- **Storage**: Large (~500GB+ and growing)
- **Sync time**: Slow (days/weeks)
- **Configuration**: Archival mode enabled, state sync disabled
- **Use case**: Block explorers, data analytics, historical queries

## Features

- **🔄 Automatic network detection and bootstrap download**
- **⚡ Fast startup** with pre-downloaded bootstrap data
- **🌐 Automatic bootstrap nodes configuration** - Bootstrap IPs and Node IDs loaded from `bootstrappers.json` (single source of truth)
- Configurable network mode (mainnet/testnet)
- Public/Private RPC access control
- Dynamic/Static IP configuration
- State sync support for fast validator setup
- Customizable logging levels
- Optional archival mode for full history
- Optional admin API access
- Optional Ethereum debug RPC

## Prerequisites

- Docker v20.10.0 or higher
- Docker Compose v2.0.0 or higher
- Minimum 4GB RAM
- At least 100GB free disk space
- Internet connection for initial bootstrap download

## Quick Start

### For Validators (Recommended Setup)

**👉 For complete validator setup instructions, see [VALIDATOR_SETUP.md](VALIDATOR_SETUP.md)**

#### Option A: Using the Setup Script (Easiest)

The fastest way to get a validator running is the included setup script, which creates a validator-optimized `.env` and all required directories in one step.

**Linux/macOS:**
```bash
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer/docker
chmod +x setup-validator-env.sh
./setup-validator-env.sh
docker-compose up -d
```

**Windows:**
```bat
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer\docker
setup-validator-env.bat
docker-compose up -d
```

The script will:
- Create a `.env` file pre-configured for a validator (testnet, state sync on, archival off, RPC private)
- Create required directories (`data/.odysseygo`, `data/db`, `logs`)
- Generate a `VALIDATOR_ODYSSEYJS_SETUP.md` quick-start guide for validator registration

#### Option B: Manual Setup

1. Clone the repository:
```bash
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer/docker
```

2. Create required directories:
```bash
mkdir -p data/.odysseygo data/db logs
```

3. Copy the example config and edit as needed:
```bash
cp env.example .env
```

4. Or create a minimal validator configuration directly:
```bash
cat > .env << EOF
NETWORK=mainnet
STATE_SYNC=on
ARCHIVAL_MODE=false
RPC_ACCESS=private
EOF
```

5. Start your validator node (bootstrap will download automatically):
```bash
docker-compose up -d
```

**🎉 That's it!** The container will automatically:
- Download the appropriate bootstrap file (~222MB for mainnet)
- Extract the bootstrap data to the database directory
- Start the OdysseyGo node with your configuration

### For Archive Nodes (Data Providers)

1-2. Same as above

3. Create archive configuration:
```bash
cat > .env << EOF
NETWORK=mainnet
STATE_SYNC=off
ARCHIVAL_MODE=true
RPC_ACCESS=public
EOF
```

4. Start your archive node (⚠️ requires significant storage and time):
```bash
docker-compose up -d
```

### Default Quick Start (Archive Mode)

For the default configuration (archive node):
```bash
# Create directories
mkdir -p data/.odysseygo data/db logs
# Start with defaults (bootstrap downloads automatically)
docker-compose up -d
```

## 🧪 Node Health Test Script

A simple script, `test-node.sh`, is included to help you verify your OdysseyGo node is running and healthy. It automatically checks:
- NodeID
- O/D chain bootstrapped status
- Ethereum RPC (eth_chainId, eth_blockNumber, eth_getBalance)
- **Current Synced Block (D Chain):** Shows the latest block number in both hex and decimal **after bootstrapping is complete**

The script works for both public and private RPC modes:
- If RPC is public, it tests from your host.
- If RPC is private, it prompts for your container name and runs tests inside the container.

**Usage:**
```sh
chmod +x test-node.sh
./test-node.sh
```

- Works on Linux, macOS, and WSL.
- Run with `-h` or `--help` for usage info.

**Note:**
- While the node is bootstrapping, chain-specific RPCs (like `eth_blockNumber`, `eth_chainId`, `eth_getBalance`) will return errors or empty responses (e.g., "API call rejected because chain is not done bootstrapping").
- Once bootstrapping is complete (`isBootstrapped:true`), these RPCs will return real data.
- You can monitor your node logs for progress, or keep running the script until you see real block numbers and data.

## Verifying Your Node: Testing RPC Access

After starting your node, you may want to verify it’s running and accessible. The OdysseyGo node’s RPC API (port 9650) can be set to either public or private access. This affects how you can interact with the node for testing, scripting, and integration.

## 🧪 Testing RPC Access: Public vs Private Modes

### RPC_ACCESS=public (default for archive nodes, convenient for testing)
- You can use curl and other tools from your host or external machines.
- Example test steps:

```bash
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer/docker
mkdir -p data/.odysseygo data/db logs
echo "RPC_ACCESS=public" >> .env
docker-compose up -d
# Get container ID
docker ps
# Access staking directory
docker exec -it <container_id> ls /root/.odysseygo/staking
# Copy staking keys to host (for backup)
docker cp <container_id>:/root/.odysseygo/staking ./staking-backup

# Test RPC from host
curl -s --location --request POST 'http://127.0.0.1:9650/ext/info' \
  --header 'Content-Type: application/json' \
  --data-raw '{"jsonrpc": "2.0", "id": 1, "method": "info.getNodeID"}'
```

### RPC_ACCESS=private (recommended for validators)
- The RPC API is only accessible from inside the container.
- Use docker exec to run curl or scripts inside the container:
- The following example uses testnet, but you can use mainnet as needed.

```bash
docker-compose down
cat > .env << EOF
NETWORK=testnet
STATE_SYNC=on
ARCHIVAL_MODE=false
RPC_ACCESS=private
EOF
docker-compose up -d

# Create backup directory
mkdir -p ~/validator-backup/staking-keys
docker cp <container_id>:/root/.odysseygo/staking/. ~/validator-backup/staking-keys/
chmod 600 ~/validator-backup/staking-keys/*

# Test RPC from inside the container
docker exec -it <container_id> curl -s --location --request POST 'http://127.0.0.1:9650/ext/info' \
  --header 'Content-Type: application/json' \
  --data-raw '{"jsonrpc": "2.0", "id": 1, "method": "info.getNodeID"}'
```

### Windows/WSL Note
- If you get `invalid host specified` with `localhost`, use `127.0.0.1` instead.

### Healthcheck Note
- If the container is marked as unhealthy with `RPC_ACCESS=private`, this is expected (the healthcheck can't reach the private RPC from outside). The node is still running fine.

### For OdysseyJS and Other Tools
- If your scripts/tools need to connect to the node’s RPC, set `RPC_ACCESS=public` (at least temporarily).
- For production, always revert to `RPC_ACCESS=private` after testing or registration for security.
- If you keep `RPC_ACCESS=private`, run those scripts inside the container or use SSH port forwarding.

## Network Selection

### Mainnet (Default)
```bash
docker-compose up -d
```

### Testnet
```bash
NETWORK=testnet docker-compose up -d
```

Or create a `.env` file with:
```
NETWORK=testnet
```

## Configuration

### Environment Variables Reference

Use `env.example` as a starting point — copy it to `.env` and edit as needed:
```bash
cp env.example .env
```

#### Instance / Image Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `COMPOSE_PROJECT_NAME` | `odysseygo` | Namespaces containers and networks. Set a unique value per instance when running multiple nodes on the same server. |
| `DOCKERHUB_USERNAME` | `yourusername` | Docker Hub username to pull the image from. |
| `IMAGE_TAG` | `develop` | Image tag to use (`develop`, `main`, or a specific version). |

#### Node Configuration Variables

| Variable | Default Value | Options |
|----------|---------------|---------|
| `NETWORK` | `mainnet` | `mainnet`, `testnet` |
| `BOOTSTRAP_URL` | Auto-selected based on `NETWORK` | Any valid URL to a `.zip` file, or empty to sync from scratch |
| `RPC_ACCESS` | `public` | `public`, `private` |
| `STATE_SYNC` | `off` | `on`, `off` |
| `IP_MODE` | `dynamic` | `dynamic`, `static` |
| `PUBLIC_IP` | `0.0.0.0` | Any valid IPv4 (required when `IP_MODE=static`) |
| `DB_DIR` | `/odysseygo/db` | Any valid path |
| `LOG_LEVEL_NODE` | `info` | `info`, `debug` |
| `LOG_LEVEL_DCHAIN` | `info` | `info`, `debug` |
| `INDEX_ENABLED` | `true` | `true`, `false` |
| `ARCHIVAL_MODE` | `true` | `true`, `false` |
| `ADMIN_API` | `false` | `true`, `false` |
| `ETH_DEBUG_RPC` | `true` | `true`, `false` |

#### Port Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RPC_HOST_PORT` | `9650` | Host port mapped to the node's HTTP API. Must be unique per instance on the same server. |
| `P2P_HOST_PORT` | `9651` | Host port mapped to the node's P2P networking. Must be unique per instance on the same server. |

### Bootstrap Configuration

The node can be bootstrapped in two ways:

1. **Automatic Download (Default)**: The node will download bootstrap data from the URL specified in the `BOOTSTRAP_URL` environment variable.

   - **Testnet Bootstrap URL** (default):
     ```
     https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-testnet.zip
     ```

   - **Mainnet Bootstrap URL**:
     ```
     https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip
     ```

2. **Local File**: If you have already downloaded the bootstrap file, you can mount it directly:
   
   ```yaml
   volumes:
     # For testnet
     - "${PWD}/odyssey-bootstrap-testnet.zip:/odysseygo-bootstrap/odyssey-bootstrap-testnet.zip:ro"
     # OR for mainnet
     - "${PWD}/odyssey-bootstrap-mainnet.zip:/odysseygo-bootstrap/odyssey-bootstrap-mainnet.zip:ro"
   ```

   When a local file is mounted, the system will use it instead of downloading from the URL.

### Bootstrap Nodes Configuration

**🌐 Automatic Bootstrap Nodes** - The Docker image automatically configures bootstrap nodes (IPs and Node IDs) based on the selected network.

- **Single Source of Truth**: Bootstrap nodes are defined in `bootstrappers.json` (included in the Docker image)
- **Network-Aware**: Automatically loads the correct bootstrap nodes for `mainnet` or `testnet`
- **No Configuration Required**: Works automatically based on the `NETWORK` environment variable
- **Easy Updates**: Update `bootstrappers.json` and rebuild the image to update bootstrap nodes

**How it works:**
1. The `entrypoint.sh` script reads `bootstrappers.json` from `/odysseygo/docker/bootstrappers.json`
2. Based on the `NETWORK` environment variable (mainnet/testnet), it extracts the appropriate bootstrap nodes
3. Bootstrap IPs and Node IDs are automatically added as command-line arguments: `--bootstrap-ips` and `--bootstrap-ids`

**Current Bootstrap Nodes:**
- **Mainnet**: 70 bootstrap nodes (automatically loaded)
- **Testnet**: 5 bootstrap nodes (automatically loaded)

**To update bootstrap nodes:**
1. Edit `docker/bootstrappers.json` in the repository
2. Rebuild the Docker image
3. The new bootstrap nodes will be automatically used

**Note**: The `bootstrappers.json` file format matches the one in the `odysseygo` repository (`genesis/bootstrappers.json`), ensuring consistency across the ecosystem.

### Configuration Methods

There are three ways to configure your OdysseyGo node:

#### 1. Using a .env File (Recommended)

Create a `.env` file in the same directory as your docker-compose.yml with your desired configuration:

```
# Example .env file for mainnet
NETWORK=mainnet
BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip
ARCHIVAL_MODE=true
RPC_ACCESS=private
```

Docker Compose will automatically load variables from this file. This is the recommended approach for persistent configurations.

#### 2. Editing docker-compose.yml

You can directly modify the environment section in the docker-compose.yml file:

```yaml
environment:
  - NETWORK=mainnet
  - BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip
  - ARCHIVAL_MODE=true
  - RPC_ACCESS=private
```

#### 3. Command Line Overrides

For temporary changes, you can override variables via the command line:

```
NETWORK=mainnet BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip docker-compose up -d
```

## Running Multiple Nodes on the Same Server

To run more than one OdysseyGo node on the same server, clone the repo into separate directories and give each instance a unique `COMPOSE_PROJECT_NAME` and port pair.

**Instance 1 (default)** — `~/odysseygo-node1/docker/.env`:
```
COMPOSE_PROJECT_NAME=node1
RPC_HOST_PORT=9650
P2P_HOST_PORT=9651
NETWORK=mainnet
```

**Instance 2** — `~/odysseygo-node2/docker/.env`:
```
COMPOSE_PROJECT_NAME=node2
RPC_HOST_PORT=9652
P2P_HOST_PORT=9653
NETWORK=mainnet
```

Start each instance from its own directory:
```bash
cd ~/odysseygo-node1/docker && docker-compose up -d
cd ~/odysseygo-node2/docker && docker-compose up -d
```

## Updating to the Latest Image

Use the included `update-to-latest.sh` script to pull the newest image and restart the container in one step:

```bash
# Update to the default tag (develop)
./update-to-latest.sh

# Update to a specific tag
./update-to-latest.sh main
./update-to-latest.sh v1.4.5
```

The script reads `DOCKERHUB_USERNAME` from your `.env` file (or defaults to `yourusername` if not set), pulls the new image, and restarts the container.

## Node Configuration Examples

1. **Default Testnet Node**
   ```bash
   docker-compose up -d
   ```
   Uses all default settings with automatic bootstrap download.

2. **Mainnet Node**
   ```bash
   # In .env file
   NETWORK=mainnet
   BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip
   ```
   Or using command line:
   ```bash
   NETWORK=mainnet BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip docker-compose up -d
   ```

3. **Archival Mainnet Node with Local Bootstrap File**
   ```bash
   # First download the bootstrap file
   wget https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip
   
   # Then configure in .env file
   NETWORK=mainnet
   ARCHIVAL_MODE=true
   
   # And uncomment the appropriate volume mount in docker-compose.yml
   ```

4. **Private RPC Node with Static IP**
   ```bash
   # In .env file
   RPC_ACCESS=private
   IP_MODE=static
   PUBLIC_IP=203.0.113.1  # Replace with your actual public IP
   ```

Remember to restart your container after changing configurations:
```bash
docker-compose restart
```

## Directory Structure

```
docker/
├── Dockerfile
├── docker-compose.yml
├── docker-compose-local-build.yml
├── entrypoint.sh
├── bootstrappers.json           # Bootstrap node IPs and IDs (single source of truth)
├── env.example                  # Template for .env — copy and edit
├── .env                         # Your local config (not committed)
├── setup-validator-env.sh       # One-step validator setup (Linux/macOS)
├── setup-validator-env.bat      # One-step validator setup (Windows)
├── update-to-latest.sh          # Pull latest image and restart
├── test-local.sh                # Local build and smoke-test script
├── data/
│   ├── .odysseygo/              # Node configuration
│   └── db/                      # Blockchain data
└── logs/                        # Node logs
```

## Volumes

- data/.odysseygo/: Node configuration files
- data/db/: Blockchain database
- logs/: Node logs

## Ports

- 9650: HTTP API
- 9651: P2P networking

## Health Checks

The node's health is monitored by checking the /ext/info endpoint every 30 seconds.

## Building from Source

To build the image locally:

```bash
docker build -t dionetech/odysseygo:develop .
```

## Security Considerations

1. By default, RPC access is public. For production deployments, consider:
   - Setting RPC_ACCESS=private
   - Using a reverse proxy
   - Implementing proper firewall rules

2. The container runs as non-root user odysseygo

3. Admin API is disabled by default

## Troubleshooting

1. Check container logs:
```bash
docker-compose logs -f
```

2. Verify node status:
```bash
curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
    -H 'content-type:application/json' \
    http://localhost:9650/ext/info
```

3. Common issues:
   - **Bootstrap download fails**: Check internet connectivity and firewall settings
   - **Insufficient disk space**: Ensure at least 100GB free space
   - **Network connectivity issues**: Verify firewall and network configuration
   - **Invalid configuration parameters**: Check environment variable values
   - **Bootstrap file corruption**: Delete the bootstrap file and restart to re-download

4. **Bootstrap Download Issues**:
   ```bash
   # Check if bootstrap file exists
   docker exec <container_name> ls -la /odysseygo-bootstrap/
   
   # Force re-download by removing bootstrap file
   docker exec <container_name> rm -f /odysseygo-bootstrap/odyssey-bootstrap-mainnet.zip
   docker-compose restart
   ```

## 🧹 Starting from a Fresh Bootstrap (Clean State)

If you want to ensure your node starts from a completely fresh state (e.g., to re-download the bootstrap and clear all previous data), follow these steps:

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

### 5. Start Mainnet Node (Fresh Bootstrap)
Set the network to mainnet (if not already set in your `.env`):
```bash
NETWORK=mainnet docker-compose up --build
```

This will:
- Download the mainnet bootstrap zip afresh
- Extract and initialize the node from scratch

**Note:** For testnet, set `NETWORK=testnet` instead.

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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
