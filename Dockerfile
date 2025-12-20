# ============================================================
# Secure RISC-V SoC - Docker Development Environment
# Works on Linux, macOS, and Windows (WSL2)
# ============================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ------------------------------------------------------------
# Install ALL tools in one layer (faster & smaller image)
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    cmake \
    ninja-build \
    # RISC-V Toolchain (from Ubuntu repos - easiest!)
    gcc-riscv64-unknown-elf \
    binutils-riscv64-unknown-elf \
    # Verilog simulation tools
    verilator \
    iverilog \
    gtkwave \
    # Utilities
    vim \
    nano \
    less \
    tree \
    htop \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Set up RISC-V toolchain environment
# ------------------------------------------------------------
ENV TOOLCHAIN_PREFIX=riscv64-unknown-elf-
ENV PATH="/usr/bin:${PATH}"

# ------------------------------------------------------------
# Workspace
# ------------------------------------------------------------
WORKDIR /workspace

# Default command