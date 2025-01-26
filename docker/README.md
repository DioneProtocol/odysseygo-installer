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
git clone https://github.com/vivekteega/odysseygo-installer/
cd odysseygo-installer
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

### Environment Variables

| Variable | Description | Default | Options |
|----------|-------------|---------|----------|
| NETWORK | Network to connect to | testnet | testnet, mainnet |
| RPC_ACCESS | RPC access control | public | public, private |
| STATE_SYNC | Enable/disable state sync | on | on, off |
| IP_MODE | IP configuration mode | dynamic | dynamic, static |
| PUBLIC_IP | Node's public IP address | 0.0.0.0 | Any valid IPv4 |
| DB_DIR | Database directory | /odysseygo/db | Any valid path |
| LOG_LEVEL_NODE | Node log level | info | debug, info |
| LOG_LEVEL_DCHAIN | D-Chain log level | info | debug, info |
| INDEX_ENABLED | Enable indexing | false | true, false |
| ARCHIVAL_MODE | Run as archival node | false | true, false |
| ADMIN_API | Enable admin API | false | true, false |
| ETH_DEBUG_RPC | Enable Ethereum debug RPC | false | true, false |

### Docker Compose Configuration

The provided docker-compose.yml includes:
- Automatic container restart
- Health checking
- Volume mapping for persistent data
- Port exposure (9650, 9651)

## Directory Structure

```
.
├── Dockerfile
├── entrypoint.sh
├── docker-compose.yml
├── data/
│   ├── .odysseygo/    # Node configuration
│   └── db/            # Blockchain data
└── logs/              # Node logs
```


## Running Nodes: A Quick Guide

1. Testnet Node (Default)

`docker-compose up -d`

Pro Tip: Uses default testnet configuration in docker-compose.yml.

2. Mainnet Node

`NETWORK=mainnet docker-compose up -d`

How to Change: Modify NETWORK environment variable.

3. Archival Node

`ARCHIVAL_MODE=true docker-compose up -d`

Context: Keeps full historical blockchain data.

4. Static IP Node

`IP_MODE=static PUBLIC_IP=203.0.113.1 docker-compose up -d`

Important: Replace 203.0.113.1 with your actual public IP.


### Changing Environment Variables: 3 Ways

#### Temporary Override

Use environment variables in command line
Example: `NETWORK=mainnet ARCHIVAL_MODE=true docker-compose up -d`


#### Permanent Changes

Edit docker-compose.yml
Modify environment: section

```
environment:
  - NETWORK=mainnet
  - ARCHIVAL_MODE=true
```

#### Using .env File

Create .env file in same directory
```
NETWORK=mainnet
ARCHIVAL_MODE=true
```

Docker Compose automatically loads variables

Tip: Restart container after changing configurations. 

## Volumes

- .odysseygo/: Node configuration files
- db/: Blockchain database
- logs/: Node logs

## Ports

- 9650: HTTP API
- 9651: P2P networking

## Health Checks

The node's health is monitored by checking the /ext/info endpoint every 30 seconds.

## Building from Source

To build the image locally:

`docker build -t odysseygo:develop .`

## Security Considerations

1. By default, RPC access is public. For production deployments, consider:
   - Setting RPC_ACCESS=private
   - Using a reverse proxy
   - Implementing proper firewall rules

2. The container runs as non-root user odysseygo

3. Admin API is disabled by default

## Troubleshooting

1. Check container logs:
docker-compose logs -f

2. Verify node status:
curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
    -H 'content-type:application/json' \
    http://localhost:9650/ext/info

3. Common issues:
   - Insufficient disk space
   - Network connectivity issues
   - Invalid configuration parameters

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
