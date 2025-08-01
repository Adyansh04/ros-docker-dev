# Foundation Ubuntu layer with essential system tools
# This provides the base operating system for all other layers

ARG UBUNTU_VERSION=22.04
FROM ubuntu:${UBUNTU_VERSION}

LABEL layer="base"
LABEL description="Ubuntu foundation with essential tools"

# Set environment for consistent behavior
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install essential system tools and utilities
RUN apt-get update && apt-get install -y \
    # Core system tools
    curl \
    wget \
    git \
    vim \
    nano \
    # Build essentials
    build-essential \
    cmake \
    pkg-config \
    # Network utilities
    net-tools \
    iputils-ping \
    # System utilities
    htop \
    tree \
    software-properties-common \
    lsb-release \
    gnupg \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Create workspace structure
RUN mkdir -p /workspace

WORKDIR /workspace
