# Local Testing Guide

This guide helps you test the Docker setup locally before pushing changes.

## Quick Test Script

Run the automated test script:

```bash
cd docker
./test-local.sh
```

This will:
1. Build the Docker image locally
2. Verify `bootstrappers.json` is included
3. Test mainnet bootstrap loading
4. Test testnet bootstrap loading
5. Verify bootstrap args are added to the command

## Manual Testing

### 1. Build the Docker Image

```bash
cd docker
docker build -t odysseygo-local:test .
```

### 2. Test Bootstrap File Exists

```bash
docker run --rm odysseygo-local:test test -f /odysseygo/docker/bootstrappers.json && echo "✅ File exists"
```

### 3. Test Mainnet Bootstrap Loading

```bash
docker run --rm \
  -e NETWORK=mainnet \
  odysseygo-local:test \
  bash -c 'source /usr/local/bin/entrypoint.sh --help 2>/dev/null || true; BOOTSTRAP_IPS_ARG=""; BOOTSTRAP_IDS_ARG=""; load_bootstrap_nodes; echo "IPs: $BOOTSTRAP_IPS_ARG"; echo "IDs: $BOOTSTRAP_IDS_ARG"'
```

Expected output should show `--bootstrap-ips=...` and `--bootstrap-ids=...` with mainnet nodes.

### 4. Test Testnet Bootstrap Loading

```bash
docker run --rm \
  -e NETWORK=testnet \
  odysseygo-local:test \
  bash -c 'source /usr/local/bin/entrypoint.sh --help 2>/dev/null || true; BOOTSTRAP_IPS_ARG=""; BOOTSTRAP_IDS_ARG=""; load_bootstrap_nodes; echo "IPs: $BOOTSTRAP_IPS_ARG"; echo "IDs: $BOOTSTRAP_IDS_ARG"'
```

Expected output should show testnet nodes (fewer than mainnet).

### 5. View the Final Command (Dry Run)

```bash
docker run --rm \
  -e NETWORK=mainnet \
  odysseygo-local:test \
  bash -c 'source /usr/local/bin/entrypoint.sh --help 2>/dev/null || true; BOOTSTRAP_IPS_ARG=""; BOOTSTRAP_IDS_ARG=""; load_bootstrap_nodes; CMD="/odysseygo/odyssey-node/odysseygo --http-allowed-hosts=* --config-file=/odysseygo/.odysseygo/configs/node.json --log-dir=/var/log/odysseygo"; if [ -n "$BOOTSTRAP_IPS_ARG" ] && [ -n "$BOOTSTRAP_IDS_ARG" ]; then CMD="$CMD $BOOTSTRAP_IPS_ARG $BOOTSTRAP_IDS_ARG"; fi; echo "$CMD"'
```

This should show the full command with bootstrap arguments.

### 6. Test with Docker Compose (Local Build)

Update `docker-compose.yml` to enable local building:

```yaml
services:
  odysseygo:
    build:
      context: .
      dockerfile: Dockerfile
    # image: ${DOCKERHUB_USERNAME:-yourusername}/odysseygo:${IMAGE_TAG:-develop}
```

Then run:

```bash
cd docker
docker-compose up --build
```

### 7. Verify Bootstrap Nodes in Running Container

Once the container is running, check the logs:

```bash
docker-compose logs odysseygo | grep -i bootstrap
```

You should see output like:
```
Loaded bootstrap nodes for mainnet:
  IPs: 35.169.66.196:9651,54.197.55.84:9651,107.23.226.228:9651... (total: 70)
  IDs: NodeID-HiSA5P3USdUzh36HZpkqMygMewkVcEaCg,NodeID-MtbprT8bv1YBioXVDxhz5WPFUpJcaSD8g... (total: 70)
```

### 8. Test Different Networks

**Test Mainnet:**
```bash
docker run -it --rm \
  -e NETWORK=mainnet \
  -e RPC_ACCESS=public \
  -p 9650:9650 -p 9651:9651 \
  odysseygo-local:test
```

**Test Testnet:**
```bash
docker run -it --rm \
  -e NETWORK=testnet \
  -e RPC_ACCESS=public \
  -p 9650:9650 -p 9651:9651 \
  odysseygo-local:test
```

## What to Check

✅ **bootstrappers.json exists** in the image at `/odysseygo/docker/bootstrappers.json`

✅ **Mainnet bootstrap nodes** are loaded (70 nodes)

✅ **Testnet bootstrap nodes** are loaded (5 nodes)

✅ **Final command** includes `--bootstrap-ips` and `--bootstrap-ids` arguments

✅ **Container starts** without errors

✅ **Logs show** bootstrap nodes being loaded

## Troubleshooting

### File not found
If you see "Warning: bootstrappers.json not found":
- Check that `COPY bootstrappers.json` is in the Dockerfile
- Verify the file exists in the `docker/` directory

### Bootstrap nodes not loading
- Check that `jq` is installed in the image (it should be)
- Verify the JSON format is valid: `jq . bootstrappers.json`
- Check network value matches "mainnet" or "testnet" exactly

### Command missing bootstrap args
- Verify `load_bootstrap_nodes` function is called before building CMD
- Check that the function sets `BOOTSTRAP_IPS_ARG` and `BOOTSTRAP_IDS_ARG`

## Next Steps

Once local testing passes:
1. Commit your changes
2. Push to the repository
3. The CI/CD pipeline will build and push the Docker image
4. Test the deployed image

