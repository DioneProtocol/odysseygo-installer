#!/bin/sh

set -e

print_usage() {
  echo "OdysseyGo Node Health Test Script"
  echo "Usage: ./test-node.sh [-h|--help]"
  echo "- Checks NodeID, bootstrapped status, and Ethereum RPC."
  echo "- Works for both public and private RPC modes."
  echo "- If RPC is private, you will be prompted for the container name."
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  print_usage
  exit 0
fi

HOST_RPC="http://127.0.0.1:9650"
CURL="curl -s --max-time 3"

print_result() {
  label="$1"
  result="$2"
  if [ -n "$result" ]; then
    echo "[OK] $label: $result"
  else
    echo "[FAIL] $label: No response"
  fi
}

echo "Testing OdysseyGo node RPC from host..."
NODEID=$($CURL -X POST "$HOST_RPC/ext/info" \
  -H 'Content-Type: application/json' \
  --data-raw '{"jsonrpc": "2.0", "id": 1, "method": "info.getNodeID"}' | grep -o 'NodeID-[A-Za-z0-9]*')

if [ -n "$NODEID" ]; then
  print_result "NodeID" "$NODEID"
  O_BOOTSTRAPPED=$($CURL -X POST "$HOST_RPC/ext/info" \
    -H 'content-type:application/json' \
    --data-raw '{"jsonrpc":"2.0","id":1,"method":"info.isBootstrapped","params":{"chain":"O"}}' | grep -o '"isBootstrapped":true')
  print_result "O-Chain Bootstrapped" "$O_BOOTSTRAPPED"
  D_BOOTSTRAPPED=$($CURL -X POST "$HOST_RPC/ext/info" \
    -H 'content-type:application/json' \
    --data-raw '{"jsonrpc":"2.0","id":1,"method":"info.isBootstrapped","params":{"chain":"D"}}' | grep -o '"isBootstrapped":true')
  print_result "D-Chain Bootstrapped" "$D_BOOTSTRAPPED"
  ETH_CHAINID=$($CURL -X POST "$HOST_RPC/ext/bc/D/rpc" \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' | grep -o '"result":"[^"]*"')
  print_result "eth_chainId (D Chain)" "$ETH_CHAINID"
  echo "\nAll tests completed from host."
  exit 0
else
  echo "[WARN] Host RPC not accessible. Node may be running with RPC_ACCESS=private."
fi

# Try inside container
printf "Enter your OdysseyGo container name (e.g., docker-odysseygo-1): "
read CONTAINER
if [ -z "$CONTAINER" ]; then
  echo "No container name provided. Exiting."
  exit 1
fi

echo "Testing OdysseyGo node RPC inside container..."
DOCKER_EXEC="docker exec -i $CONTAINER /bin/sh -c"
NODEID=$($DOCKER_EXEC "$CURL -X POST '$HOST_RPC/ext/info' -H 'Content-Type: application/json' --data-raw '{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"info.getNodeID\"}'" | grep -o 'NodeID-[A-Za-z0-9]*')
print_result "NodeID" "$NODEID"
O_BOOTSTRAPPED=$($DOCKER_EXEC "$CURL -X POST '$HOST_RPC/ext/info' -H 'content-type:application/json' --data-raw '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"info.isBootstrapped\",\"params\":{\"chain\":\"O\"}}'" | grep -o '"isBootstrapped":true')
print_result "O-Chain Bootstrapped" "$O_BOOTSTRAPPED"
D_BOOTSTRAPPED=$($DOCKER_EXEC "$CURL -X POST '$HOST_RPC/ext/info' -H 'content-type:application/json' --data-raw '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"info.isBootstrapped\",\"params\":{\"chain\":\"D\"}}'" | grep -o '"isBootstrapped":true')
print_result "D-Chain Bootstrapped" "$D_BOOTSTRAPPED"
ETH_CHAINID=$($DOCKER_EXEC "$CURL -X POST '$HOST_RPC/ext/bc/D/rpc' -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}'" | grep -o '"result":"[^"]*"')
print_result "eth_chainId (D Chain)" "$ETH_CHAINID"
echo "\nAll tests completed inside container."
echo "If you want to automate this, set RPC_ACCESS=public for easier host access. For production, always revert to private." 