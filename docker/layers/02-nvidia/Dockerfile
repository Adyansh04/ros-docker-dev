# NVIDIA CUDA layer providing GPU acceleration capabilities

ARG CUDA_VERSION=12.2
ARG UBUNTU_VERSION=22.04
ARG BASE_IMAGE

# Use official NVIDIA CUDA image as foundation
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

LABEL layer="nvidia"
LABEL description="NVIDIA CUDA GPU support"
LABEL cuda_version="${CUDA_VERSION}"

# Install OpenGL and GUI libraries for graphics applications
RUN apt-get update && apt-get install -y \
    # OpenGL libraries
    libgl1-mesa-dev \
    libgl1-mesa-dri \
    libglu1-mesa \
    # X11 and GUI libraries
    libx11-6 \
    libxrandr2 \
    libxss1 \
    libxcursor1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrender1 \
    libxtst6 \
    libxxf86vm1 \
    # Graphics utilities
    mesa-utils \
    x11-apps \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Set NVIDIA environment variables
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV DISPLAY=:0
ENV QT_X11_NO_MITSHM=1

# Add CUDA to PATH
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

WORKDIR /workspace
