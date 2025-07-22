# OdysseyGo Docker Node

A Docker implementation of OdysseyGo node with configurable options for running both mainnet and testnet networks. Supports both **validator nodes** and **archive nodes** with automatic bootstrap download.

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

- **Automatic network detection and bootstrap download**
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

## Quick Start

### For Validators (Recommended Setup)

**👉 For complete validator setup instructions, see [VALIDATOR_SETUP.md](VALIDATOR_SETUP.md)**

1. Clone the repository:
```bash
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer/docker
```

2. Create required directories:
```bash
mkdir -p data/.odysseygo data/db logs
```

3. Create validator configuration:
```bash
cat > .env << EOF
NETWORK=mainnet
STATE_SYNC=on
ARCHIVAL_MODE=false
RPC_ACCESS=private
EOF
```

4. Start your validator node:
```bash
docker-compose up -d
```

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
# Start with defaults
docker-compose up -d
```

## Network Selection

### Mainnet (Default)
```
docker-compose up -d
```

### Testnet
```
NETWORK=testnet docker-compose up -d
```

Or create a `.env` file with:
```
NETWORK=testnet
```

## Configuration

### Default Environment Variables

The following default values are pre-configured in the docker-compose.yml file:

| Variable | Default Value |
|----------|---------------|
| NETWORK | mainnet |
| BOOTSTRAP_URL | Auto-selected based on NETWORK |
| RPC_ACCESS | public |
| STATE_SYNC | off |
| IP_MODE | dynamic |
| PUBLIC_IP | 0.0.0.0 |
| DB_DIR | /odysseygo/db |
| LOG_LEVEL_NODE | info |
| LOG_LEVEL_DCHAIN | info |
| INDEX_ENABLED | true |
| ARCHIVAL_MODE | true |
| ADMIN_API | false |
| ETH_DEBUG_RPC | true |

### Environment Variables Reference

| Variable | Description | Options |
|----------|-------------|---------|
| NETWORK | Network to connect to | testnet, mainnet |
| BOOTSTRAP_URL | URL to download bootstrap data | Any valid URL to .zip file |
| RPC_ACCESS | RPC access control | public, private |
| STATE_SYNC | Enable/disable state sync | on, off |
| IP_MODE | IP configuration mode | dynamic, static |
| PUBLIC_IP | Node's public IP address | Any valid IPv4 |
| DB_DIR | Database directory | Any valid path |
| LOG_LEVEL_NODE | Node log level | debug, info |
| LOG_LEVEL_DCHAIN | D-Chain log level | debug, info |
| INDEX_ENABLED | Enable indexing | true, false |
| ARCHIVAL_MODE | Run as archival node | true, false |
| ADMIN_API | Enable admin API | true, false |
| ETH_DEBUG_RPC | Enable Ethereum debug RPC | true, false |

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

## Node Configuration Examples

1. **Default Testnet Node**
   ```
   docker-compose up -d
   ```
   Uses all default settings with automatic bootstrap download.

2. **Mainnet Node**
   ```
   # In .env file
   NETWORK=mainnet
   BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip
   ```
   Or using command line:
   ```
   NETWORK=mainnet BOOTSTRAP_URL=https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip docker-compose up -d
   ```

3. **Archival Mainnet Node with Local Bootstrap File**
   ```
   # First download the bootstrap file
   wget https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip
   
   # Then configure in .env file
   NETWORK=mainnet
   ARCHIVAL_MODE=true
   
   # And uncomment the appropriate volume mount in docker-compose.yml
   ```

4. **Private RPC Node with Static IP**
   ```
   # In .env file
   RPC_ACCESS=private
   IP_MODE=static
   PUBLIC_IP=203.0.113.1  # Replace with your actual public IP
   ```

Remember to restart your container after changing configurations:
```
docker-compose restart
```

## Directory Structure

```
.
├── Dockerfile
├── entrypoint.sh
├── docker-compose.yml
├── .env                 # Optional configuration file
├── data/
│   ├── .odysseygo/     # Node configuration
│   └── db/             # Blockchain data
└── logs/               # Node logs
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

```
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
```
docker-compose logs -f
```

2. Verify node status:
```
curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
    -H 'content-type:application/json' \
    http://localhost:9650/ext/info
```

3. Common issues:
   - Insufficient disk space
   - Network connectivity issues
   - Invalid configuration parameters
   - Bootstrap file download failures

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
