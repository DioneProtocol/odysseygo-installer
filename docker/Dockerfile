# Multi-architecture Docker image for OdysseyGo
# Supports: linux/amd64, linux/arm64
FROM ubuntu:22.04

# Metadata
LABEL maintainer="Vivek Teegalapally <vivek.teega@gmail.com>" \
      description="Docker image for OdysseyGo node with configurable options"

# Define build arguments and environment variables
# TARGETARCH is automatically set by Docker buildx (amd64 or arm64)
ARG TARGETARCH
ARG ODOMYSGO_VERSION_ARG="latest"
ENV ODOMYSGO_VERSION=${ODOMYSGO_VERSION_ARG}
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        ca-certificates \
        tar \
        gnupg \
        jq \
        build-essential \
        dnsutils \
        unzip \
        && rm -rf /var/lib/apt/lists/*

# Define environment variables for OdysseyGo with sensible defaults
ENV NETWORK=testnet \
    RPC_ACCESS=public \
    STATE_SYNC=on \
    IP_MODE=dynamic \
    PUBLIC_IP="0.0.0.0" \
    # DB_DIR=/odysseygo/db \
    LOG_LEVEL_NODE=info \
    LOG_LEVEL_DCHAIN=info \
    INDEX_ENABLED=false \
    ARCHIVAL_MODE=false \
    ADMIN_API=false \
    ETH_DEBUG_RPC=false

# Create necessary directories
RUN mkdir -p /odysseygo/odyssey-node \
    /odysseygo/.odysseygo/configs/chains/D \
    /odysseygo/.odysseygo/plugins \
    /odysseygo/docker \
    /odysseygo/db \
    /var/log/odysseygo

# Copy entrypoint script and bootstrappers.json before switching to non-root user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bootstrappers.json /odysseygo/docker/bootstrappers.json
RUN chmod +x /usr/local/bin/entrypoint.sh

# Add a non-root user
RUN useradd -m odysseygo && \
    chown -R odysseygo:odysseygo /odysseygo /var/log/odysseygo && \
    chmod 644 /odysseygo/docker/bootstrappers.json

# Switch to non-root user
USER odysseygo

# Set working directory
WORKDIR /odysseygo

# Download OdysseyGo binary from GitHub releases
# Handles both "latest" and version tags (e.g., "v1.10.12" or "1.10.12")
# Automatically selects correct architecture (amd64 or arm64) based on TARGETARCH
RUN set -eux; \
    ARCH="${TARGETARCH:-amd64}"; \
    echo "Building for architecture: ${ARCH}"; \
    if [ "${ODOMYSGO_VERSION_ARG}" = "latest" ]; then \
        VERSION_TAG=$(curl -s https://api.github.com/repos/DioneProtocol/odysseygo/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'); \
        VERSION=${VERSION_TAG#v}; \
    else \
        VERSION=${ODOMYSGO_VERSION_ARG#v}; \
        VERSION_TAG="v${VERSION}"; \
    fi && \
    DOWNLOAD_URL="https://github.com/DioneProtocol/odysseygo/releases/download/${VERSION_TAG}/odysseygo-linux-${ARCH}-${VERSION_TAG}.tar.gz"; \
    CHECKSUM_URL="https://github.com/DioneProtocol/odysseygo/releases/download/${VERSION_TAG}/odysseygo-linux-${ARCH}-${VERSION_TAG}.tar.gz.sha256"; \
    echo "Downloading OdysseyGo ${VERSION_TAG} for ${ARCH} from ${DOWNLOAD_URL}" && \
    wget -q "${DOWNLOAD_URL}" -O odysseygo.tar.gz && \
    if wget -q "${CHECKSUM_URL}" -O odysseygo.tar.gz.sha256 2>/dev/null; then \
        echo "Verifying checksum..." && \
        sha256sum -c odysseygo.tar.gz.sha256 && \
        rm odysseygo.tar.gz.sha256; \
    else \
        echo "Warning: Checksum file not found, skipping verification"; \
    fi && \
    tar -xzf odysseygo.tar.gz -C /odysseygo/odyssey-node --strip-components=1 && \
    rm odysseygo.tar.gz && \
    echo "Successfully installed OdysseyGo ${VERSION_TAG} (${ARCH})"

# Optional: If you prefer building from source when a specific version is not available
# Uncomment the following block if building from source is desired
# RUN if [ "$ODOMYSGO_VERSION" != "latest" ]; then \
#         git clone https://github.com/DioneProtocol/odysseygo.git && \
#         cd odysseygo && \
#         git checkout "$ODOMYSGO_VERSION" && \
#         ./scripts/build.sh && \
#         cp ./build/* /odysseygo/odyssey-node/ && \
#         cd .. && \
#         rm -rf odysseygo; \
#     fi

RUN ls -la

# Expose necessary ports
EXPOSE 9650 9651

# Define volumes for persistent data
# VOLUME ["/odysseygo/.odysseygo", "/odysseygo/odyssey-node", "/odysseygo/db", "/var/log/odysseygo"]

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Optional: Healthcheck
# HEALTHCHECK --interval=60s --timeout=30s --start-period=5s --retries=3 \
#     CMD curl -f http://localhost:9650 || exit 1
