# ============================================================
# Secure RISC-V SoC - Docker Development Environment
# Works on Linux, macOS, and Windows (WSL2)
# Includes Verilator, Icarus Verilog, GTKWave, RISC-V GCC, GDB, AS
# ============================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ------------------------------------------------------------
# Base build dependencies
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    autoconf \
    automake \
    autotools-dev \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    gawk \
    bison \
    flex \
    texinfo \
    gperf \
    libtool \
    patchutils \
    bc \
    zlib1g-dev \
    libexpat-dev \
    ninja-build \
    cmake \
    verilator \
    iverilog \
    gtkwave \
    vim \
    nano \
    less \
    tree \
    htop \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Install stable RISC-V GNU Toolchain (SiFive prebuilt)
# ------------------------------------------------------------
# ------------------------------------------------------------
# Install RISC-V GNU Toolchain from xPack
# ------------------------------------------------------------
# ------------------------------------------------------------
# Install RISC-V GNU Toolchain (xPack prebuilt)
# ------------------------------------------------------------
RUN mkdir -p /opt/riscv && \
    cd /opt && \
    wget -q https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz && \
    tar -xzf xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz -C /opt/riscv --strip-components=1 && \
    rm xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz

ENV PATH="/opt/riscv/bin:${PATH}"
ENV TOOLCHAIN_PREFIX=riscv-none-elf-

# ------------------------------------------------------------
# Workspace
# ------------------------------------------------------------
WORKDIR /workspace
COPY . /workspace/

CMD ["/bin/bash"]