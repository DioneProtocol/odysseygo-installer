# Updating to Latest Docker Hub Image

This guide explains how to update your OdysseyGo container to use the latest pre-built image from Docker Hub instead of building locally.

## What Changed

The Docker Compose files have been updated to:
- Use pre-built images from Docker Hub instead of building locally
- Support configurable Docker Hub username and image tags
- Allow easy updates without rebuilding

## Configuration

### 1. Environment Variables

Create or update your `.env` file with:

```bash
# Docker Hub Image Configuration
DOCKERHUB_USERNAME=your_actual_username
IMAGE_TAG=develop

# Other existing variables...
NETWORK=mainnet
BOOTSTRAP_URL=
# ... etc
```

**Important**: Replace `your_actual_username` with your actual Docker Hub username.

### 2. Available Image Tags

- `develop` - Latest development build (default)
- `main` - Latest main branch build
- `v1.10.11` - Specific version tag

## Updating to Latest Image

### Option 1: Using the Update Script (Recommended)

```bash
# Update to latest develop image
./update-to-latest.sh

# Update to specific tag
./update-to-latest.sh main
```

### Option 2: Manual Update

```bash
# Pull latest image
docker pull yourusername/odysseygo:develop

# Stop current container
docker compose down

# Start with new image
docker compose up -d
```

## Benefits

1. **Faster Deployment**: No need to wait for local builds
2. **Consistent Images**: All deployments use the same pre-built image
3. **Easy Updates**: Simple pull and restart process
4. **CI/CD Integration**: Works seamlessly with your GitHub Actions workflow

## Troubleshooting

### Image Not Found
- Verify your Docker Hub username is correct
- Check that the image exists: `docker search yourusername/odysseygo`
- Ensure you have access to the repository

### Container Won't Start
- Check logs: `docker compose logs`
- Verify environment variables are set correctly
- Ensure ports are available

### Rollback
If you need to rollback to a previous version:

```bash
# Stop current container
docker compose down

# Start with specific image tag
IMAGE_TAG=v1.10.11 docker compose up -d
```

## GitHub Actions Integration

Your GitHub Actions workflow automatically builds and pushes images to Docker Hub on:
- Push to `develop` branch → `yourusername/odysseygo:develop`
- Manual workflow dispatch → `yourusername/odysseygo:develop`

To get the latest changes, simply run the update script after a successful workflow run.
