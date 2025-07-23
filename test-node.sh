#!/bin/sh

set -e

ETH_ADDRESS="${ETH_ADDRESS:-0x8ef8E8E08C4ecE1CCED0Ab36EDA8Af7e1b484e82}"
HOST_RPC="http://127.0.0.1:9650"
CURL="curl -s --max-time 5"

print_block_number() {
  RAW_JSON="$1"
  BLOCK_HEX=`echo "$RAW_JSON" | grep -o '"result":"0x[0-9a-fA-F]\+' | cut -d'"' -f4`
  if [ -n "$BLOCK_HEX" ]; then
    # Convert hex to decimal (POSIX)
    BLOCK_DEC=`printf "%d" "$(( $BLOCK_HEX ))" 2>/dev/null || echo "(conversion error)"`
    echo "Current Synced Block (D Chain): $BLOCK_HEX (hex) / $BLOCK_DEC (decimal)"
  else
    echo "Current Synced Block (D Chain): $RAW_JSON"
  fi
}

run_all_tests() {
  LABEL="$1"
  RUN_CMD="$2"
  echo "\n===== $LABEL ====="

  echo "\n[1] NodeID:"
  eval "$RUN_CMD \"$CURL -X POST $HOST_RPC/ext/info -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\": \\\"2.0\\\", \\\"id\\\": 1, \\\"method\\\": \\\"info.getNodeID\\\"}'\""

  echo "\n[2] O-Chain Bootstrapped:"
  eval "$RUN_CMD \"$CURL -X POST $HOST_RPC/ext/info -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"id\\\":1,\\\"method\\\":\\\"info.isBootstrapped\\\",\\\"params\\\":{\\\"chain\\\":\\\"O\\\"}}'\""

  echo "\n[3] D-Chain Bootstrapped:"
  eval "$RUN_CMD \"$CURL -X POST $HOST_RPC/ext/info -H 'Content-Type: application/json' --data-raw '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"id\\\":1,\\\"method\\\":\\\"info.isBootstrapped\\\",\\\"params\\\":{\\\"chain\\\":\\\"D\\\"}}'\""

  echo "\n[4] eth_chainId (D Chain):"
  eval "$RUN_CMD \"$CURL -X POST $HOST_RPC/ext/bc/D/rpc -H 'Content-Type: application/json' -d '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"method\\\":\\\"eth_chainId\\\",\\\"params\\\":[],\\\"id\\\":1}'\""

  echo "\n[5] eth_blockNumber (D Chain):"
  BLOCK_JSON=`eval "$RUN_CMD \"$CURL -X POST $HOST_RPC/ext/bc/D/rpc -H 'Content-Type: application/json' -d '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"method\\\":\\\"eth_blockNumber\\\",\\\"params\\\":[],\\\"id\\\":1}'\""`
  echo "$BLOCK_JSON"
  print_block_number "$BLOCK_JSON"

  echo "\n[6] eth_getBalance (D Chain, $ETH_ADDRESS):"
  eval "$RUN_CMD \"$CURL -X POST $HOST_RPC/ext/bc/D/rpc -H 'Content-Type: application/json' -d '{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"method\\\":\\\"eth_getBalance\\\",\\\"params\\\":[\\\"$ETH_ADDRESS\\\",\\\"latest\\\"],\\\"id\\\":1}'\""
}

# Try from host
HOST_RUN_CMD="sh -c"
echo "Testing OdysseyGo node RPC from host..."
if $CURL -X POST "$HOST_RPC/ext/info" -H 'Content-Type: application/json' --data-raw '{"jsonrpc": "2.0", "id": 1, "method": "info.getNodeID"}' | grep -q 'nodeID'; then
  run_all_tests "HOST RPC" "$HOST_RUN_CMD"
  exit 0
else
  echo "[WARN] Host RPC not accessible. Node may be running with RPC_ACCESS=private."
fi

# Try inside container
CONTAINERS=`docker ps --filter "ancestor=dionetech/odysseygo:develop" --format '{{.Names}}'`
if [ -z "$CONTAINERS" ]; then
  CONTAINERS=`docker ps --filter "name=odysseygo" --format '{{.Names}}'`
fi

if [ -z "$CONTAINERS" ]; then
  echo "[ERROR] Could not find a running OdysseyGo container."
  exit 1
fi

for CONTAINER in $CONTAINERS; do
  CONTAINER_RUN_CMD="docker exec -i $CONTAINER /bin/sh -c"
  run_all_tests "CONTAINER: $CONTAINER" "$CONTAINER_RUN_CMD"
done

echo "\nAll tests completed. If you see empty or error responses, check your node logs and configuration." 