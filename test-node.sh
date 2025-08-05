#!/bin/sh

set -e

ETH_ADDRESS="${ETH_ADDRESS:-0x8ef8E8E08C4ecE1CCED0Ab36EDA8Af7e1b484e82}"
HOST_RPC="http://127.0.0.1:9650"
CURL="curl -s --max-time 5"

# Get D-Chain blockchain ID
get_d_chain_id() {
  RUN_CMD="$1"
  RPC_URL="$2"
  
  # Check if this is container access (contains "docker exec")
  if echo "$RUN_CMD" | grep -q "docker exec"; then
    # Use escaped JSON for container access
    D_CHAIN_ID_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL/ext/info -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"id\\\":1,\\\"method\\\":\\\"info.getBlockchainID\\\",\\\"params\\\":{\\\"alias\\\":\\\"D\\\"}}'\""`
  else
    # Use temporary file for host access
    TEMP_FILE=$(mktemp)
    trap "rm -f $TEMP_FILE" EXIT
    echo '{"jsonrpc":"2.0","id":1,"method":"info.getBlockchainID","params":{"alias":"D"}}' > "$TEMP_FILE"
    D_CHAIN_ID_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL/ext/info -H 'Content-Type: application/json' --data-binary @$TEMP_FILE\""`
  fi
  
  D_CHAIN_ID=`echo "$D_CHAIN_ID_JSON" | grep -o '"blockchainID":"[^"]\+' | cut -d'"' -f4`
  if [ -z "$D_CHAIN_ID" ]; then
    echo "[ERROR] Could not detect D-Chain blockchain ID. Raw response: $D_CHAIN_ID_JSON"
    exit 1
  fi
  echo "$D_CHAIN_ID"
}

# Print block number in hex and decimal
print_block_number() {
  RAW_JSON="$1"
  BLOCK_HEX=`echo "$RAW_JSON" | grep -o '"result":"0x[0-9a-fA-F]\+' | cut -d'"' -f4`
  if [ -n "$BLOCK_HEX" ]; then
    BLOCK_DEC=`printf "%d" "$(( $BLOCK_HEX ))" 2>/dev/null || echo "(conversion error)"`
    echo "Current Synced Block (D Chain): $BLOCK_HEX (hex) / $BLOCK_DEC (decimal)"
  else
    echo "Current Synced Block (D Chain): $RAW_JSON"
  fi
}

# Print balance in hex, wei, and DIONE
print_balance() {
  RAW_JSON="$1"
  BAL_HEX=`echo "$RAW_JSON" | grep -o '"result":"0x[0-9a-fA-F]\+' | cut -d'"' -f4`
  if [ -n "$BAL_HEX" ]; then
    BAL_WEI=`printf "%d" "$(( $BAL_HEX ))" 2>/dev/null || echo "(conversion error)"`
    if command -v bc >/dev/null 2>&1; then
      BAL_DIONE=`echo "scale=18; $BAL_WEI/1000000000000000000" | bc`
      echo "Balance: $BAL_HEX (hex) / $BAL_WEI (wei) / $BAL_DIONE DIONE"
    else
      echo "Balance: $BAL_HEX (hex) / $BAL_WEI (wei) (install 'bc' for DIONE conversion)"
    fi
  else
    echo "Balance: $RAW_JSON"
  fi
}

run_all_checks() {
  LABEL="$1"
  RUN_CMD="$2"
  RPC_URL="$3"
  echo "\n===== $LABEL ====="

  # Check if this is container access (contains "docker exec")
  if echo "$RUN_CMD" | grep -q "docker exec"; then
    # Use escaped JSON for container access
    echo "\n# 1. NodeID"
    NODEID_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL/ext/info -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"id\\\":1,\\\"method\\\":\\\"info.getNodeID\\\"}'\""`
    echo "$NODEID_JSON"

    echo "\n# 2. O-Chain Bootstrapped"
    O_BOOTSTRAP_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL/ext/info -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"id\\\":1,\\\"method\\\":\\\"info.isBootstrapped\\\",\\\"params\\\":{\\\"chain\\\":\\\"O\\\"}}'\""`
    echo "$O_BOOTSTRAP_JSON"

    echo "\n# 3. D-Chain Bootstrapped"
    D_BOOTSTRAP_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL/ext/info -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"id\\\":1,\\\"method\\\":\\\"info.isBootstrapped\\\",\\\"params\\\":{\\\"chain\\\":\\\"D\\\"}}'\""`
    echo "$D_BOOTSTRAP_JSON"

    D_CHAIN_ID=`get_d_chain_id "$RUN_CMD" "$RPC_URL"`
    D_CHAIN_RPC="/ext/bc/$D_CHAIN_ID/rpc"

    echo "\n# 4. eth_chainId (D Chain)"
    CHAINID_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL$D_CHAIN_RPC -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"method\\\":\\\"eth_chainId\\\",\\\"params\\\":[],\\\"id\\\":1}'\""`
    echo "$CHAINID_JSON"

    echo "\n# 5. eth_blockNumber (D Chain)"
    BLOCK_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL$D_CHAIN_RPC -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"method\\\":\\\"eth_blockNumber\\\",\\\"params\\\":[],\\\"id\\\":1}'\""`
    echo "$BLOCK_JSON"
    print_block_number "$BLOCK_JSON"

    echo "\n# 6. eth_getBalance (D Chain, $ETH_ADDRESS)"
    BAL_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL$D_CHAIN_RPC -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"method\\\":\\\"eth_getBalance\\\",\\\"params\\\":[\\\"$ETH_ADDRESS\\\",\\\"latest\\\"],\\\"id\\\":1}'\""`
    echo "$BAL_JSON"
    print_balance "$BAL_JSON"
  else
    # Use temporary file for host access
    TEMP_FILE=$(mktemp)
    trap "rm -f $TEMP_FILE" EXIT

  echo "\n# 1. NodeID"
    echo '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' > "$TEMP_FILE"
    NODEID_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL/ext/info -H 'Content-Type: application/json' --data-binary @$TEMP_FILE\""`
  echo "$NODEID_JSON"

  echo "\n# 2. O-Chain Bootstrapped"
    echo '{"jsonrpc":"2.0","id":1,"method":"info.isBootstrapped","params":{"chain":"O"}}' > "$TEMP_FILE"
    O_BOOTSTRAP_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL/ext/info -H 'Content-Type: application/json' --data-binary @$TEMP_FILE\""`
  echo "$O_BOOTSTRAP_JSON"

  echo "\n# 3. D-Chain Bootstrapped"
    echo '{"jsonrpc":"2.0","id":1,"method":"info.isBootstrapped","params":{"chain":"D"}}' > "$TEMP_FILE"
    D_BOOTSTRAP_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL/ext/info -H 'Content-Type: application/json' --data-binary @$TEMP_FILE\""`
  echo "$D_BOOTSTRAP_JSON"

    D_CHAIN_ID=`get_d_chain_id "$RUN_CMD" "$RPC_URL"`
  D_CHAIN_RPC="/ext/bc/$D_CHAIN_ID/rpc"

  echo "\n# 4. eth_chainId (D Chain)"
    echo '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' > "$TEMP_FILE"
    CHAINID_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL$D_CHAIN_RPC -H 'Content-Type: application/json' --data-binary @$TEMP_FILE\""`
  echo "$CHAINID_JSON"

  echo "\n# 5. eth_blockNumber (D Chain)"
    echo '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' > "$TEMP_FILE"
    BLOCK_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL$D_CHAIN_RPC -H 'Content-Type: application/json' --data-binary @$TEMP_FILE\""`
  echo "$BLOCK_JSON"
  print_block_number "$BLOCK_JSON"

  echo "\n# 6. eth_getBalance (D Chain, $ETH_ADDRESS)"
    echo "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$ETH_ADDRESS\",\"latest\"],\"id\":1}" > "$TEMP_FILE"
    BAL_JSON=`eval "$RUN_CMD \"$CURL -X POST $RPC_URL$D_CHAIN_RPC -H 'Content-Type: application/json' --data-binary @$TEMP_FILE\""`
  echo "$BAL_JSON"
  print_balance "$BAL_JSON"
  fi

  echo "\n===== End of $LABEL checks ====="
}

# Try from host first (for public RPC)
HOST_RUN_CMD="sh -c"
echo "Testing OdysseyGo node RPC from host..."
HOST_RESPONSE=`$CURL -X POST "$HOST_RPC/ext/info" -H 'Content-Type: application/json' --data-raw '{"jsonrpc": "2.0", "id": 1, "method": "info.getNodeID"}' 2>/dev/null || echo ""`
if echo "$HOST_RESPONSE" | grep -q '"result"'; then
  run_all_checks "HOST RPC" "$HOST_RUN_CMD" "$HOST_RPC"
  echo "\nAll checks completed successfully via host RPC."
  exit 0
else
  echo "[WARN] Host RPC not accessible. Node may be running with RPC_ACCESS=private."
fi

# Try inside container with direct docker exec approach
CONTAINERS=`docker ps --filter "ancestor=dionetech/odysseygo:develop" --format '{{.Names}}'`
if [ -z "$CONTAINERS" ]; then
  CONTAINERS=`docker ps --filter "name=odysseygo" --format '{{.Names}}'`
fi

if [ -z "$CONTAINERS" ]; then
  echo "[ERROR] Could not find a running OdysseyGo container."
  exit 1
fi

for CONTAINER in $CONTAINERS; do
  echo "Testing container $CONTAINER with direct docker exec..."
  
  # Test if RPC is accessible from inside the container
  RESPONSE=`docker exec -i $CONTAINER curl -s --max-time 5 -X POST http://localhost:9650/ext/info -H 'Content-Type: application/json' --data-raw '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' 2>/dev/null || echo ""`
  
  if echo "$RESPONSE" | grep -q '"result"'; then
    echo "RPC accessible from container. Running all checks..."
    
    # Run all checks using direct docker exec commands
    echo "\n===== CONTAINER: $CONTAINER ====="
    
    echo "\n# 1. NodeID"
    docker exec -i $CONTAINER curl -s -X POST http://localhost:9650/ext/info -H 'Content-Type: application/json' --data-raw '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}'
    
    echo "\n# 2. O-Chain Bootstrapped"
    docker exec -i $CONTAINER curl -s -X POST http://localhost:9650/ext/info -H 'Content-Type: application/json' --data-raw '{"jsonrpc":"2.0","id":1,"method":"info.isBootstrapped","params":{"chain":"O"}}'
    
    echo "\n# 3. D-Chain Bootstrapped"
    docker exec -i $CONTAINER curl -s -X POST http://localhost:9650/ext/info -H 'Content-Type: application/json' --data-raw '{"jsonrpc":"2.0","id":1,"method":"info.isBootstrapped","params":{"chain":"D"}}'
    
    # Get D-Chain ID
    D_CHAIN_ID_JSON=`docker exec -i $CONTAINER curl -s -X POST http://localhost:9650/ext/info -H 'Content-Type: application/json' --data-raw '{"jsonrpc":"2.0","id":1,"method":"info.getBlockchainID","params":{"alias":"D"}}'`
    D_CHAIN_ID=`echo "$D_CHAIN_ID_JSON" | grep -o '"blockchainID":"[^"]\+' | cut -d'"' -f4`
    if [ -z "$D_CHAIN_ID" ]; then
      echo "[ERROR] Could not detect D-Chain blockchain ID. Raw response: $D_CHAIN_ID_JSON"
      exit 1
    fi
    D_CHAIN_RPC="/ext/bc/$D_CHAIN_ID/rpc"
    
    echo "\n# 4. eth_chainId (D Chain)"
    docker exec -i $CONTAINER curl -s -X POST http://localhost:9650$D_CHAIN_RPC -H 'Content-Type: application/json' --data-raw '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
    
    echo "\n# 5. eth_blockNumber (D Chain)"
    BLOCK_JSON=`docker exec -i $CONTAINER curl -s -X POST http://localhost:9650$D_CHAIN_RPC -H 'Content-Type: application/json' --data-raw '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'`
    echo "$BLOCK_JSON"
    print_block_number "$BLOCK_JSON"
    
    echo "\n# 6. eth_getBalance (D Chain, $ETH_ADDRESS)"
    BAL_JSON=`docker exec -i $CONTAINER curl -s -X POST http://localhost:9650$D_CHAIN_RPC -H 'Content-Type: application/json' --data-raw "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$ETH_ADDRESS\",\"latest\"],\"id\":1}"`
    echo "$BAL_JSON"
    print_balance "$BAL_JSON"
    
    echo "\n===== End of $CONTAINER checks ====="
    echo "\nAll checks completed successfully inside $CONTAINER."
    exit 0
  else
    echo "[ERROR] Could not access RPC from inside container $CONTAINER. RPC may be completely private or node not ready."
  fi
done

echo "\n[ERROR] All RPC access methods failed. Check your node configuration and ensure RPC is accessible."
echo "If using RPC_ACCESS=private, the node may not be accepting external connections."
exit 1 