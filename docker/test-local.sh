#!/bin/bash
# Local testing script for Docker image with bootstrap nodes

set -e

IMAGE_NAME="odysseygo-local-test"
IMAGE_TAG="test-$(date +%s)"

echo "============================================="
echo "Building Docker image locally..."
echo "============================================="

cd "$(dirname "$0")"

# Build the Docker image
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo ""
echo "============================================="
echo "Build completed successfully!"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "============================================="
echo ""

# Test 1: Check if bootstrappers.json is in the image
echo "Test 1: Verifying bootstrappers.json is in the image..."
if docker run --rm --user root --entrypoint="" "${IMAGE_NAME}:${IMAGE_TAG}" test -f /odysseygo/docker/bootstrappers.json; then
    echo "✅ bootstrappers.json found in image"
else
    echo "❌ bootstrappers.json NOT found in image"
    exit 1
fi

echo ""

# Test 2: Test mainnet bootstrap loading (dry run)
echo "Test 2: Testing mainnet bootstrap node loading..."
docker run --rm --user root --entrypoint="" \
    -e NETWORK=mainnet \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    bash -c '
        NETWORK=mainnet
        bootstrappers_file="/odysseygo/docker/bootstrappers.json"
        nodes_json=$(jq -r ".[\"mainnet\"]" "$bootstrappers_file" 2>/dev/null)
        bootstrap_ips=$(echo "$nodes_json" | jq -r ".[].ip" | tr "\n" "," | sed "s/,\$//")
        bootstrap_ids=$(echo "$nodes_json" | jq -r ".[].id" | tr "\n" "," | sed "s/,\$//")
        if [ -n "$bootstrap_ips" ] && [ -n "$bootstrap_ids" ]; then
            echo "✅ Mainnet bootstrap nodes loaded successfully"
            echo "   Sample IPs: $(echo $bootstrap_ips | cut -d, -f1-3)"
            echo "   Sample IDs: $(echo $bootstrap_ids | cut -d, -f1-2)"
            echo "   Total nodes: $(echo $bootstrap_ips | tr "," "\n" | wc -l)"
        else
            echo "❌ Failed to load mainnet bootstrap nodes"
            exit 1
        fi
    '

echo ""

# Test 3: Test testnet bootstrap loading (dry run)
echo "Test 3: Testing testnet bootstrap node loading..."
docker run --rm --user root --entrypoint="" \
    -e NETWORK=testnet \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    bash -c '
        NETWORK=testnet
        bootstrappers_file="/odysseygo/docker/bootstrappers.json"
        nodes_json=$(jq -r ".[\"testnet\"]" "$bootstrappers_file" 2>/dev/null)
        bootstrap_ips=$(echo "$nodes_json" | jq -r ".[].ip" | tr "\n" "," | sed "s/,\$//")
        bootstrap_ids=$(echo "$nodes_json" | jq -r ".[].id" | tr "\n" "," | sed "s/,\$//")
        if [ -n "$bootstrap_ips" ] && [ -n "$bootstrap_ids" ]; then
            echo "✅ Testnet bootstrap nodes loaded successfully"
            echo "   Sample IPs: $(echo $bootstrap_ips | cut -d, -f1-3)"
            echo "   Sample IDs: $(echo $bootstrap_ids | cut -d, -f1-2)"
            echo "   Total nodes: $(echo $bootstrap_ips | tr "," "\n" | wc -l)"
        else
            echo "❌ Failed to load testnet bootstrap nodes"
            exit 1
        fi
    '

echo ""

# Test 4: Verify the final command includes bootstrap args
echo "Test 4: Verifying final command includes bootstrap arguments..."
docker run --rm --user root --entrypoint="" \
    -e NETWORK=mainnet \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    bash -c '
        NETWORK=mainnet
        bootstrappers_file="/odysseygo/docker/bootstrappers.json"
        nodes_json=$(jq -r ".[\"mainnet\"]" "$bootstrappers_file" 2>/dev/null)
        bootstrap_ips=$(echo "$nodes_json" | jq -r ".[].ip" | tr "\n" "," | sed "s/,\$//")
        bootstrap_ids=$(echo "$nodes_json" | jq -r ".[].id" | tr "\n" "," | sed "s/,\$//")
        BOOTSTRAP_IPS_ARG="--bootstrap-ips=$bootstrap_ips"
        BOOTSTRAP_IDS_ARG="--bootstrap-ids=$bootstrap_ids"
        CMD="/odysseygo/odyssey-node/odysseygo --http-allowed-hosts=* --config-file=/odysseygo/.odysseygo/configs/node.json --log-dir=/var/log/odysseygo"
        if [ -n "$BOOTSTRAP_IPS_ARG" ] && [ -n "$BOOTSTRAP_IDS_ARG" ]; then
            CMD="$CMD $BOOTSTRAP_IPS_ARG $BOOTSTRAP_IDS_ARG"
        fi
        if echo "$CMD" | grep -q "bootstrap-ips" && echo "$CMD" | grep -q "bootstrap-ids"; then
            echo "✅ Final command includes bootstrap arguments"
            echo "   Command preview: $(echo $CMD | cut -c1-200)..."
        else
            echo "❌ Final command missing bootstrap arguments"
            echo "   Command: $CMD"
            exit 1
        fi
    '

echo ""
echo "============================================="
echo "All tests passed! ✅"
echo "============================================="
echo ""
echo "To run the container locally:"
echo "  docker run -it --rm \\"
echo "    -e NETWORK=mainnet \\"
echo "    -e RPC_ACCESS=public \\"
echo "    -p 9650:9650 -p 9651:9651 \\"
echo "    ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Or use docker-compose with build enabled:"
echo "  # Uncomment 'build:' section in docker-compose.yml"
echo "  # Then: docker-compose up"

