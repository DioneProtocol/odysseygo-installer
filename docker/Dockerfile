# Stage 1: Build (Optional)
# Uncomment if building from source is needed
# FROM golang:1.20-alpine AS builder
# ARG ODOMYSGO_VERSION="1.10.11"
# ENV ODOMYSGO_VERSION=${ODOMYSGO_VERSION}
# WORKDIR /build
# RUN apk add --no-cache git
# RUN git clone https://github.com/DioneProtocol/odysseygo.git . && \
#     git checkout tags/v${ODOMYSGO_VERSION} && \
#     ./scripts/build.sh

# Stage 2: Runtime
# FROM debian:bullseye-slim
FROM ubuntu:22.04

# Metadata
LABEL maintainer="Vivek Teegalapally <vivek.teega@gmail.com>" \
      description="Docker image for OdysseyGo node with configurable options"

# Define build arguments and environment variables
ARG ODOMYSGO_VERSION_ARG="1.10.11"
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
    /odysseygo/db \
    /var/log/odysseygo

# Copy entrypoint script before switching to non-root user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Add a non-root user
RUN useradd -m odysseygo && \
    chown -R odysseygo:odysseygo /odysseygo /var/log/odysseygo

# Switch to non-root user
USER odysseygo

# Set working directory
WORKDIR /odysseygo

# Download OdysseyGo binary and verify checksum
RUN echo "Downloading OdysseyGo version ${ODOMYSGO_VERSION_ARG}" && \
    echo "https://github.com/DioneProtocol/odysseygo/releases/download/v${ODOMYSGO_VERSION_ARG}/odysseygo-linux-amd64-v${ODOMYSGO_VERSION_ARG}.tar.gz" && \
    wget -q "https://github.com/DioneProtocol/odysseygo/releases/download/v1.10.11/odysseygo-linux-amd64-v1.10.11.tar.gz" -O odysseygo.tar.gz && \
    # wget -q "https://github.com/DioneProtocol/odysseygo/releases/download/v${ODOMYSGO_VERSION_ARG}/SHA256SUMS" -O SHA256SUMS && \
    # echo "$(grep odysseygo-linux-amd64-v${ODOMYSGO_VERSION}.tar.gz SHA256SUMS)" | sha256sum -c - && \
    tar -xzf odysseygo.tar.gz -C /odysseygo/odyssey-node --strip-components=1 && \
    rm odysseygo.tar.gz

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
