# OdysseyGo Docker Node

A Docker implementation of OdysseyGo node with configurable options for running both mainnet and testnet networks.

## Features

- Configurable network mode (mainnet/testnet)
- Public/Private RPC access control
- Dynamic/Static IP configuration
- State sync support
- Customizable logging levels
- Optional archival mode
- Optional admin API access
- Optional Ethereum debug RPC

## Prerequisites

- Docker v20.10.0 or higher
- Docker Compose v2.0.0 or higher
- Minimum 4GB RAM
- At least 100GB free disk space

## Quick Start

1. Clone the repository:
```
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer/docker
```

2. Create required directories:
```
mkdir -p data/.odysseygo data/db logs
```

3. Start the node:
```
docker-compose up -d
```

## Configuration

### Default Environment Variables

The following default values are pre-configured in the docker-compose.yml file:

| Variable | Default Value |
|----------|---------------|
| NETWORK | testnet |
| RPC_ACCESS | public |
| STATE_SYNC | on |
| IP_MODE | dynamic |
| PUBLIC_IP | 0.0.0.0 |
| DB_DIR | /odysseygo/db |
| LOG_LEVEL_NODE | info |
| LOG_LEVEL_DCHAIN | info |
| INDEX_ENABLED | false |
| ARCHIVAL_MODE | false |
| ADMIN_API | false |
| ETH_DEBUG_RPC | false |

### Environment Variables Reference

| Variable | Description | Options |
|----------|-------------|---------|
| NETWORK | Network to connect to | testnet, mainnet |
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

### Configuration Methods

There are three ways to configure your OdysseyGo node:

#### 1. Using a .env File (Recommended)

Create a `.env` file in the same directory as your docker-compose.yml with your desired configuration:

```
# Example .env file
NETWORK=mainnet
ARCHIVAL_MODE=true
RPC_ACCESS=private
```

Docker Compose will automatically load variables from this file. This is the recommended approach for persistent configurations.

#### 2. Editing docker-compose.yml

You can directly modify the environment section in the docker-compose.yml file:

```yaml
environment:
  - NETWORK=mainnet
  - ARCHIVAL_MODE=true
  - RPC_ACCESS=private
```

#### 3. Command Line Overrides

For temporary changes, you can override variables via the command line:

```
NETWORK=mainnet ARCHIVAL_MODE=true docker-compose up -d
```

## Node Configuration Examples

1. **Default Testnet Node**
   ```
   docker-compose up -d
   ```
   Uses all default settings.

2. **Mainnet Node**
   ```
   # In .env file
   NETWORK=mainnet
   ```
   Or using command line:
   ```
   NETWORK=mainnet docker-compose up -d
   ```

3. **Archival Mainnet Node**
   ```
   # In .env file
   NETWORK=mainnet
   ARCHIVAL_MODE=true
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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.