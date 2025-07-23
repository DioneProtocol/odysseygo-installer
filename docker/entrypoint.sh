#!/bin/bash
set -e

# Convert environment variables to lowercase (where applicable)
LOG_LEVEL_NODE="${LOG_LEVEL_NODE:-info}"
LOG_LEVEL_DCHAIN="${LOG_LEVEL_DCHAIN:-info}"
RPC_ACCESS="$(echo "${RPC_ACCESS:-public}" | tr '[:upper:]' '[:lower:]')"
ADMIN_API="$(echo "${ADMIN_API:-false}" | tr '[:upper:]' '[:lower:]')"
INDEX_ENABLED="$(echo "${INDEX_ENABLED:-false}" | tr '[:upper:]' '[:lower:]')"
NETWORK="$(echo "${NETWORK:-testnet}" | tr '[:upper:]' '[:lower:]')"
DB_DIR="${DB_DIR:-/odysseygo/db}"
IP_MODE="$(echo "${IP_MODE:-dynamic}" | tr '[:upper:]' '[:lower:]')"
PUBLIC_IP="${PUBLIC_IP:-}"
STATE_SYNC="$(echo "${STATE_SYNC:-on}" | tr '[:upper:]' '[:lower:]')"
ARCHIVAL_MODE="$(echo "${ARCHIVAL_MODE:-false}" | tr '[:upper:]' '[:lower:]')"
ETH_DEBUG_RPC="$(echo "${ETH_DEBUG_RPC:-false}" | tr '[:upper:]' '[:lower:]')"

# Ensure the bootstrap directory exists
mkdir -p /odysseygo-bootstrap

# Ensure necessary directories exist
mkdir -p /odysseygo/.odysseygo/configs/chains/D
mkdir -p /odysseygo/.odysseygo/configs
mkdir -p "$DB_DIR"

##############################
# BEGIN: Bootstrap Extraction
##############################

# Determine the network-specific database folder and bootstrap file
if [ "$NETWORK" = "testnet" ]; then
    BOOTSTRAP_ZIP="/odysseygo-bootstrap/odyssey-bootstrap-testnet.zip"
    NETWORK_DB_DIR="${DB_DIR}/testnet"
    # Set default testnet bootstrap URL if not provided
    if [ -z "$BOOTSTRAP_URL" ]; then
        BOOTSTRAP_URL="https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-testnet.zip"
    fi
elif [ "$NETWORK" = "mainnet" ]; then
    BOOTSTRAP_ZIP="/odysseygo-bootstrap/odyssey-bootstrap-mainnet.zip"
    NETWORK_DB_DIR="${DB_DIR}/mainnet"
    # Set default mainnet bootstrap URL if not provided
    if [ -z "$BOOTSTRAP_URL" ]; then
        BOOTSTRAP_URL="https://odysseygo-bootstraps.nyc3.cdn.digitaloceanspaces.com/odyssey-bootstrap-mainnet.zip"
    fi
else
    echo "Invalid NETWORK value: '$NETWORK'. Allowed values are 'testnet' or 'mainnet'."
    exit 1
fi

# Create the network-specific DB folder if it does not exist
mkdir -p "$NETWORK_DB_DIR"

# If the local bootstrap file is not present and BOOTSTRAP_URL is provided,
# download the file from the URL to the expected location.
if [ ! -f "$BOOTSTRAP_ZIP" ] && [ -n "$BOOTSTRAP_URL" ]; then
    echo "============================================="
    echo "BOOTSTRAP: Starting download process"
    echo "Network: $NETWORK"
    echo "URL: $BOOTSTRAP_URL"
    echo "Destination: $BOOTSTRAP_ZIP"
    echo "============================================="
    
    # Show download progress with curl
    echo "Downloading bootstrap data..."
    curl --progress-bar -L "$BOOTSTRAP_URL" -o "$BOOTSTRAP_ZIP"
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to download bootstrap file from $BOOTSTRAP_URL"
      exit 1
    fi
    
    # Show file size
    BOOTSTRAP_SIZE=$(du -h "$BOOTSTRAP_ZIP" | cut -f1)
    echo "✓ Bootstrap download completed successfully! (${BOOTSTRAP_SIZE})"
    echo "============================================="
else
    echo "BOOTSTRAP: File already exists or URL not provided, skipping download."
fi

# Define the bootstrap flag file within the network DB folder.
BOOTSTRAP_DONE="${NETWORK_DB_DIR}/.bootstrap_done"

# Check if bootstrap extraction has already been performed.
if [ ! -f "$BOOTSTRAP_DONE" ]; then
    if [ -f "$BOOTSTRAP_ZIP" ]; then
        echo "============================================="
        echo "BOOTSTRAP: Starting extraction process"
        echo "Source: $BOOTSTRAP_ZIP"
        echo "Destination: ${DB_DIR}"
        echo "============================================="
        
        # Ensure unzip is available
        if ! command -v unzip >/dev/null 2>&1; then
            echo "Installing unzip package..."
            apt-get update >/dev/null 2>&1
            apt-get install -y unzip >/dev/null 2>&1
        fi
        
        # Show extraction progress
        echo "Extracting bootstrap data (this may take a moment)..."
        unzip -q "$BOOTSTRAP_ZIP" -d "${DB_DIR}"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to extract bootstrap data"
            exit 1
        fi
        
        # Create completion flag
        touch "$BOOTSTRAP_DONE"
        
        # Show completion with directory size
        DB_SIZE=$(du -sh "$NETWORK_DB_DIR" | cut -f1)
        echo "✓ Bootstrap extraction completed successfully!"
        echo "Database size: ${DB_SIZE}"
        echo "============================================="
    else
        echo "BOOTSTRAP: No zip file found at $BOOTSTRAP_ZIP, continuing without bootstrapping."
    fi
else
    echo "BOOTSTRAP: Previously completed, skipping extraction."
    DB_SIZE=$(du -sh "$NETWORK_DB_DIR" | cut -f1 2>/dev/null || echo "unknown")
    echo "Current database size: ${DB_SIZE}"
fi

##############################
# END: Bootstrap Extraction
##############################

# Function to validate IP address
validate_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a ip_arr <<< "$ip"
        for octet in "${ip_arr[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                return 1
            fi
        done
        stat=0
    fi
    return $stat
}

# Function to create node configuration file using jq
create_node_config() {
    local config_path="/odysseygo/.odysseygo/configs/node.json"
    echo "Creating node configuration at $config_path"

    # Start with base JSON
    config=$(jq -n --arg log_level "$LOG_LEVEL_NODE" '{ "log-level": $log_level }')

    # RPC access
    if [ "$RPC_ACCESS" = "public" ]; then
        config=$(echo "$config" | jq '. + { "http-host": "" }')
    fi

    # Admin API
    if [ "$ADMIN_API" = "true" ]; then
        config=$(echo "$config" | jq '. + { "api-admin-enabled": true }')
    fi

    # Indexing
    if [ "$INDEX_ENABLED" = "true" ]; then
        config=$(echo "$config" | jq '. + { "index-enabled": true }')
    fi

    # Network selection
    if [ "$NETWORK" = "testnet" ]; then
        config=$(echo "$config" | jq '. + { "network-id": "testnet" }')
    elif [ "$NETWORK" = "mainnet" ]; then
        config=$(echo "$config" | jq '. + { "network-id": "mainnet" }')
    else
        echo "Invalid NETWORK value: '$NETWORK'. Allowed values are 'testnet' or 'mainnet'."
        exit 1
    fi

    # Database directory
    if [ -n "$DB_DIR" ]; then
        config=$(echo "$config" | jq --arg db_dir "$DB_DIR" '. + { "db-dir": $db_dir }')
    fi

    # IP handling
    if [ "$IP_MODE" = "static" ]; then
        if [ -z "$PUBLIC_IP" ]; then
            echo "Error: IP_MODE is set to 'static' but PUBLIC_IP is not provided."
            exit 1
        fi
        if ! validate_ip "$PUBLIC_IP"; then
            echo "Error: Provided PUBLIC_IP ('$PUBLIC_IP') is not a valid IP address."
            exit 1
        fi
        config=$(echo "$config" | jq --arg public_ip "$PUBLIC_IP" '. + { "public-ip": $public_ip }')
    elif [ "$IP_MODE" = "dynamic" ]; then
        config=$(echo "$config" | jq '. + { "public-ip-resolution-service": "opendns" }')
    else
        echo "Invalid IP_MODE: '$IP_MODE'. Allowed values are 'static' or 'dynamic'."
        exit 1
    fi

    # Write final config
    echo "$config" > "$config_path"
}

# Function to create D-Chain configuration file using jq
create_dchain_config() {
    local config_path="/odysseygo/.odysseygo/configs/chains/D/config.json"
    echo "Creating D-Chain configuration at $config_path"

    # Determine state sync as boolean
    if [ "$STATE_SYNC" = "on" ]; then
        state_sync_enabled=true
    elif [ "$STATE_SYNC" = "off" ]; then
        state_sync_enabled=false
    else
        echo "Invalid STATE_SYNC: '$STATE_SYNC'. Allowed values are 'on' or 'off'."
        exit 1
    fi

    # Build base configuration
    dchain=$(jq -n \
        --arg log_level_dchain "$LOG_LEVEL_DCHAIN" \
        --argjson state_sync_enabled "$state_sync_enabled" \
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
        }')

    # Enable ETH debug RPC if specified
    if [ "$ETH_DEBUG_RPC" = "true" ]; then
        dchain=$(echo "$dchain" | jq '. + { "eth-apis": (.["eth-apis"] + ["internal-debug", "debug-tracer"]) }')
    fi

    # Set archival mode (disabling pruning) if enabled
    if [ "$ARCHIVAL_MODE" = "true" ]; then
        dchain=$(echo "$dchain" | jq '. + { "pruning-enabled": false }')
    fi

    # Write final config
    echo "$dchain" > "$config_path"
}

# If the user passes --help as an argument, display usage info
if [[ "$1" == "--help" ]]; then
    echo "Usage: docker run [OPTIONS] your-image"
    echo "Environment variables:"
    echo "  -e NETWORK=testnet|mainnet (default: testnet)"
    echo "  -e RPC_ACCESS=public|private (default: public)"
    echo "  -e STATE_SYNC=on|off (default: on)"
    echo "  -e IP_MODE=dynamic|static (default: dynamic)"
    echo "  -e PUBLIC_IP=your_public_ip (required if IP_MODE=static)"
    echo "  -e DB_DIR=/path/to/db (default: /odysseygo/db)"
    echo "  -e LOG_LEVEL_NODE=info|debug (default: info)"
    echo "  -e LOG_LEVEL_DCHAIN=info|debug (default: info)"
    echo "  -e INDEX_ENABLED=true|false (default: false)"
    echo "  -e ARCHIVAL_MODE=true|false (default: false)"
    echo "  -e ADMIN_API=true|false (default: false)"
    echo "  -e ETH_DEBUG_RPC=true|false (default: false)"
    exit 0
fi

# Create configuration files
create_node_config
create_dchain_config

# Construct the OdysseyGo command
CMD="/odysseygo/odyssey-node/odysseygo --http-allowed-hosts=* --config-file=/odysseygo/.odysseygo/configs/node.json --log-dir=/var/log/odysseygo"

echo "============================================="
echo "BOOTSTRAP PROCESS COMPLETED"
echo "Starting OdysseyGo node..."
echo "============================================="

# Execute the command; use exec so that signals are properly propagated.
exec $CMD
