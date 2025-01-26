#!/bin/bash
set -e

# Function to validate IP address
validate_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Function to create node.json using jq for safer JSON construction
create_node_config() {
    local config_path="/odysseygo/.odysseygo/configs/node.json"
    mkdir -p "$(dirname "$config_path")"

    echo "Creating node configuration at $config_path"

    # Start building the JSON configuration
    jq -n \
        --arg log_level "$LOG_LEVEL_NODE" \
        '{
            "log-level": $log_level,
        }' > "$config_path"

    # Add HTTP allowed hosts if RPC_ACCESS is public
    if [ "$RPC_ACCESS" = "public" ]; then
        echo "Configuring RPC access as public"
        jq '. + { "http-host": "" }' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
    fi

    # Add HTTP allowed hosts if RPC_ACCESS is public
    if [ "$ADMIN_API" = "true" ]; then
        echo "Configuring ADMIN_API as true"
        jq '. + { "api-admin-enabled": true }' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
    fi

    # Add HTTP allowed hosts if RPC_ACCESS is public
    if [ "$INDEX_ENABLED" = "true" ]; then
        echo "Configuring RPC access as public"
        jq '. + { "index-enabled": true }' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
    fi
    

    if [ "$NETWORK" = "testnet" ]; then
        echo "Configuring RPC access as public"
        jq '. + { "network-id": "testnet" }' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
    elif [ "$NETWORK" = "mainnet" ]; then
        echo "Configuring RPC access as public"
        jq '. + { "network-id": "mainnet" }' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
    else
        echo "Invalid NETWORK: $NETWORK. Allowed values are 'mainnet' or 'testnet'. Exiting."
        exit 1
    fi
    

    # Add db directory if DB_DIR is set
    if [ -n "${DB_DIR:-}" ]; then
        mkdir -p "$DB_DIR"
        echo "Adding db-dir to configuration: $DB_DIR"
        jq --arg db_dir "$DB_DIR" '. + { "db-dir": $db_dir }' "$config_path" > "${config_path}.tmp" \
            && mv "${config_path}.tmp" "$config_path"
    fi

    # Add public IP or dynamic resolution
    if [ "$IP_MODE" = "static" ]; then
        if [ -z "$PUBLIC_IP" ]; then
            echo "IP_MODE is set to 'static' but PUBLIC_IP is not provided. Exiting."
            exit 1
        fi

        if validate_ip "$PUBLIC_IP"; then
            echo "Setting static public IP: $PUBLIC_IP"
            jq --arg public_ip "$PUBLIC_IP" '. + { "public-ip": $public_ip }' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
        else
            echo "Invalid PUBLIC_IP provided: $PUBLIC_IP. Exiting."
            exit 1
        fi
    elif [ "$IP_MODE" = "dynamic" ]; then
        echo "Configuring dynamic IP resolution via OpenDNS"
        jq '. + { "public-ip-resolution-service": "opendns" }' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
    else
        echo "Invalid IP_MODE: $IP_MODE. Allowed values are 'static' or 'dynamic'. Exiting."
        exit 1
    fi
}

# Function to create D-Chain config.json using jq
create_dchain_config() {
    local config_path="/odysseygo/.odysseygo/configs/chains/D/config.json"
    mkdir -p "$(dirname "$config_path")"

    echo "Creating D-Chain configuration at $config_path"

    # Start building the JSON configuration
    jq -n \
        --arg log_level_dchain "$LOG_LEVEL_DCHAIN" \
        --argjson eth_debug_rpc "$ETH_DEBUG_RPC" \
        --argjson state_sync_enabled "$( [ "$STATE_SYNC" = "on" ] && echo "true" || echo "false" )" \
        --argjson pruning_enabled "$( [ "$ARCHIVAL_MODE" = "true" ] && echo "false" || echo "null" )" \
        '{
            "log-level": $log_level_dchain,
            "eth-apis": [
                "eth",
                "eth-filter",
                "net",
                "web3",
                "internal-eth",
                "internal-blockchain",
                "internal-personal",
                "internal-transaction",
                "internal-account"
            ],
            "state-sync-enabled": $state_sync_enabled
        }' > "$config_path"

    # Append debug APIs if ETH_DEBUG_RPC is true
    if [ "$ETH_DEBUG_RPC" = "true" ]; then
        echo "Enabling Ethereum Debug RPC APIs"
        jq '.["eth-apis"] += ["internal-debug", "debug-tracer"]' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
    fi

    # Add pruning if archival mode is enabled
    if [ "$ARCHIVAL_MODE" = "true" ]; then
        echo "Disabling pruning for archival mode"
        jq '. + { "pruning-enabled": false }' "$config_path" > "${config_path}.tmp" && mv "${config_path}.tmp" "$config_path"
    fi
}

# Function to display usage
usage() {
    echo "Usage: docker run [OPTIONS] your-image
Options:
    -e NETWORK=testnet|mainnet
    -e RPC_ACCESS=public|private
    -e STATE_SYNC=on|off
    -e IP_MODE=dynamic|static
    -e PUBLIC_IP=your_public_ip          # Required if IP_MODE=static
    -e DB_DIR=/path/to/db
    -e LOG_LEVEL_NODE=info|debug
    -e LOG_LEVEL_DCHAIN=info|debug
    -e INDEX_ENABLED=true|false
    -e ARCHIVAL_MODE=true|false
    -e ADMIN_API=true|false
    -e ETH_DEBUG_RPC=true|false
    -v /host/path/.odysseygo:/odysseygo/.odysseygo
    -v /host/path/odyssey-node:/odysseygo/odyssey-node
    -v /host/path/db:/odysseygo/db
    -v /host/path/logs:/var/log/odysseygo
    -p 9650:9650
    -p 9651:9651
    --network your_network
    --restart unless-stopped
    --help                             Show this help message and exit
..."
    exit 1
}

# Handle help flag
if [[ "$1" == "--help" ]]; then
    usage
fi

# Ensure required environment variables are set based on IP_MODE
if [ "$IP_MODE" = "static" ] && [ -z "$PUBLIC_IP" ]; then
    echo "Error: IP_MODE is set to 'static' but PUBLIC_IP is not provided."
    usage
fi

# Create configuration files
create_node_config
create_dchain_config

# # Construct OdysseyGo command with dynamic arguments
# CMD="/odysseygo/odyssey-node/odysseygo"

# # Append additional flags based on environment variables
CMD+=" --config-file=/odysseygo/.odysseygo/configs/node.json"

# echo "cd /odysseygo/ 
# cd /odysseygo/

# echo "cd /odysseygo/.odysseygo/ 
# cd /odysseygo/.odysseygo/

# echo "cat /odysseygo/.odysseygo/configs/node.json"
# cat /odysseygo/.odysseygo/configs/node.json

# echo "cat /odysseygo/.odysseygo/configs/chains/D/config.json"
# cat /odysseygo/.odysseygo/configs/chains/D/config.json

# # Example of adding more flags if needed
# # CMD+=" --another-flag=value"

# # Ensure the DB directory exists
# mkdir -p "$DB_DIR"

# # Start OdysseyGo and redirect logs to stdout
echo "Starting OdysseyGo with command: $CMD --log-dir=/var/log/odysseygo"
# exec "$CMD" --log-dir=/var/log/odysseygo
/odysseygo/odyssey-node/odysseygo --http-allowed-hosts="*" --config-file=/odysseygo/.odysseygo/configs/node.json --log-dir=/var/log/odysseygo
