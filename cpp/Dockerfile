# syntax=docker/dockerfile:1.7
# ============================================================================
# Dockerfile — Upstream toolchains (default)
# ============================================================================
# Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# C++ Development Container — Upstream Toolchains
#
# Repository: dev_containers
# Docker Image: ghcr.io/abitofhelp/dev-container-cpp
#
# This Dockerfile uses Ubuntu 24.04 as the base image and adds:
#   • Latest Clang/LLVM from the official LLVM APT repository
#   • Latest CMake from the Kitware APT repository
#   • vcpkg for C++ package management
#   • GCC 13 from Ubuntu's system packages
#   • ARM cross-compiler for embedded development
#
# Recommended for:
#   • Teams that want the latest C++20/23/26 compiler features and tooling
#   • Projects using vcpkg for dependency management
#
# For auditable supply chains with no third-party repositories, use
# Dockerfile.system instead — every binary comes from Ubuntu's apt.
#
# Purpose
# -------
# Reproducible development environment for:
#   • Desktop C/C++ development (GCC 13, Clang from LLVM repo)
#   • Embedded C/C++ development (ARM Cortex-M bare-metal, ARM Cortex-A Linux)
#   • Build systems: CMake (latest), Ninja, Meson, Make
#   • Package management: vcpkg
#   • Static analysis: clang-tidy, clang-format, cppcheck
#   • Python 3 + venv
#   • Zsh interactive shell
#
# Supported architectures: linux/amd64, linux/arm64 (Apple Silicon).
#
# Designed for nerdctl + containerd (rootless).
#
# Files expected in the build context:
# - Dockerfile
# - .dockerignore
# - .zshrc
# - entrypoint.sh
#
# Build example:
# nerdctl build -t dev-container-cpp .
#
# Run example:
# nerdctl run -it --rm \
#   -e HOST_UID=$(id -u) \
#   -e HOST_GID=$(id -g) \
#   -e HOST_USER=$(whoami) \
#   -v "$(pwd)":/workspace \
#   -w /workspace \
#   dev-container-cpp
#
# Notes
# -----
# - The image contains no human account. At startup, entrypoint.sh creates
#   exactly one from the required HOST_USER, HOST_UID, and HOST_GID; there
#   is no fallback account.
# - In rootless runtimes, container UID 0 maps to the host user via the
#   user namespace. The entrypoint detects this and stays as UID 0 rather
#   than dropping privileges, which would break bind-mount access.
# - In rootful runtimes, the entrypoint drops to the runtime account via gosu.
# - GNU Make is installed explicitly because many embedded projects use
#   Makefiles as the orchestration layer.
#
# ============================================================================
# Pinned by digest for reproducibility. Update periodically:
#   nerdctl pull ubuntu:24.04
#   nerdctl image inspect ubuntu:24.04 | grep -A1 RepoDigests
FROM ubuntu:24.04@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9

# ----------------------------------------------------------------------------
# Build arguments (alphabetized)
# ----------------------------------------------------------------------------
ARG CLANG_VERSION=20
ARG DEBIAN_FRONTEND=noninteractive
ARG PYTEST_VERSION=9.0.3
ARG TYPST_SHA256_AMD64=a6044cbad2a954deb921167e257e120ac0a16b20339ec01121194ff9d394996d
ARG TYPST_SHA256_ARM64=491b101aa40a3a7ea82a3f8a6232cabb4e6a7e233810082e5ac812d43fdcd47a
ARG TYPST_VERSION=0.14.2
ARG VCPKG_VERSION=2026.03.18

# ----------------------------------------------------------------------------
# Environment variables (alphabetized)
# ----------------------------------------------------------------------------
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH=/usr/local/bin:${PATH} \
    SHELL=/usr/bin/zsh \
    TERM=xterm-256color \
    TZ=UTC \
    VCPKG_ROOT=/opt/vcpkg

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ----------------------------------------------------------------------------
# Base packages (alphabetized)
# ----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    fd-find \
    file \
    fzf \
    git \
    gnupg \
    gosu \
    jq \
    less \
    locales \
    lsof \
    make \
    nano \
    neovim \
    openssh-client \
    patch \
    pkg-config \
    procps \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ripgrep \
    rsync \
    strace \
    sudo \
    tzdata \
    unzip \
    vim \
    wget \
    xz-utils \
    zip \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    # ------------------------------------------------------------------
    # GCC compiler (system version, secondary compiler)
    # ------------------------------------------------------------------
    build-essential \
    g++-13 \
    gcc-13 \
    # ------------------------------------------------------------------
    # Build systems
    # ------------------------------------------------------------------
    meson \
    ninja-build \
    # ------------------------------------------------------------------
    # Debuggers
    # ------------------------------------------------------------------
    gdb \
    gdb-multiarch \
    valgrind \
    # ------------------------------------------------------------------
    # Embedded: ARM Cortex-M bare-metal cross-compiler and tools
    # ------------------------------------------------------------------
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    openocd \
    stlink-tools \
    # ------------------------------------------------------------------
    # Embedded: ARM Cortex-A Linux cross-compiler (STM32MP1)
    # ------------------------------------------------------------------
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    # ------------------------------------------------------------------
    # Static analysis and build acceleration
    # ------------------------------------------------------------------
    ccache \
    cppcheck \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Add LLVM APT repository and install latest Clang/LLVM toolchain
# ----------------------------------------------------------------------------
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key \
    | gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] \
    http://apt.llvm.org/noble/ llvm-toolchain-noble-${CLANG_VERSION} main" \
    > /etc/apt/sources.list.d/llvm.list \
 && apt-get update && apt-get install -y --no-install-recommends \
    clang-${CLANG_VERSION} \
    clang-format-${CLANG_VERSION} \
    clang-tidy-${CLANG_VERSION} \
    clang-tools-${CLANG_VERSION} \
    clangd-${CLANG_VERSION} \
    libc++-${CLANG_VERSION}-dev \
    libc++abi-${CLANG_VERSION}-dev \
    lld-${CLANG_VERSION} \
    lldb-${CLANG_VERSION} \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Add Kitware APT repository and install latest CMake
# ----------------------------------------------------------------------------
RUN wget -qO- https://apt.kitware.com/keys/kitware-archive-latest.asc \
    | gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] \
    https://apt.kitware.com/ubuntu/ noble main" \
    > /etc/apt/sources.list.d/kitware.list \
 && apt-get update && apt-get install -y --no-install-recommends \
    cmake \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Set up update-alternatives so unversioned commands point to correct variants
# ----------------------------------------------------------------------------
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100 \
 && update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-13 100 \
 && update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-13 100 \
 && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${CLANG_VERSION} 100 \
 && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_VERSION} 100 \
 && update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-${CLANG_VERSION} 100 \
 && update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-${CLANG_VERSION} 100 \
 && update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-${CLANG_VERSION} 100 \
 && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-${CLANG_VERSION} 100 \
 && update-alternatives --install /usr/bin/lldb lldb /usr/bin/lldb-${CLANG_VERSION} 100

# ----------------------------------------------------------------------------
# No built-in human account
# ----------------------------------------------------------------------------
# The Ubuntu base image ships an "ubuntu" account and group (ID 1000). Both
# are removed: the image contains no human account. At startup,
# entrypoint.sh creates exactly one account from the required HOST_USER,
# HOST_UID, and HOST_GID.
# ----------------------------------------------------------------------------
RUN set -eux; \
    if getent passwd ubuntu >/dev/null; then userdel --remove ubuntu 2>/dev/null || userdel ubuntu; fi; \
    if getent group ubuntu >/dev/null; then groupdel ubuntu; fi; \
    rm -rf /home/ubuntu; \
    install -d -m 0755 /etc/dev-containers; \
    echo /usr/bin/pip3 > /etc/dev-containers/sudo-commands

# ----------------------------------------------------------------------------
# License
# ----------------------------------------------------------------------------
COPY LICENSE /usr/share/doc/dev-containers/LICENSE

# ----------------------------------------------------------------------------
# Install vcpkg (C++ package manager, pinned to a tagged release)
# ----------------------------------------------------------------------------
# The checkout is root-owned and read-only. vcpkg must lock .vcpkg-root and
# writes build trees, package staging, and downloads under its root, so those
# four paths belong to the "vcpkg" group, which entrypoint.sh adds the user to
# (/etc/dev-containers/user-groups). Projects use manifest mode (vcpkg.json);
# the binary cache defaults to ~/.cache/vcpkg/archives.
# ----------------------------------------------------------------------------
RUN git clone --depth 1 --branch "${VCPKG_VERSION}" https://github.com/microsoft/vcpkg.git /opt/vcpkg \
 && /opt/vcpkg/bootstrap-vcpkg.sh -disableMetrics \
 && ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg \
 && groupadd --system vcpkg \
 && chown -R root:root /opt/vcpkg \
 && chmod -R a+rX,go-w /opt/vcpkg \
 && chgrp vcpkg /opt/vcpkg/.vcpkg-root \
 && chmod 0664 /opt/vcpkg/.vcpkg-root \
 && install -d -o root -g vcpkg -m 2775 /opt/vcpkg/buildtrees /opt/vcpkg/packages /opt/vcpkg/downloads \
 && git config --system --add safe.directory /opt/vcpkg \
 && echo vcpkg > /etc/dev-containers/user-groups

# ----------------------------------------------------------------------------
# Shell template for the runtime account (/etc/skel)
# ----------------------------------------------------------------------------
RUN mkdir -p /etc/skel/.docker/completions /etc/skel/.local/bin
COPY cpp/.zshrc /etc/skel/.zshrc

# ----------------------------------------------------------------------------
# Verify toolchain installation
# ----------------------------------------------------------------------------
RUN echo "" \
 && echo "=== Upstream toolchain ===" \
 && gcc --version | head -1 \
 && g++ --version | head -1 \
 && clang --version | head -1 \
 && cmake --version | head -1 \
 && ninja --version \
 && meson --version \
 && echo "" \
 && echo "=== Embedded toolchain (bare-metal) ===" \
 && arm-none-eabi-gcc --version | head -1 \
 && echo "" \
 && echo "=== Embedded toolchain (Linux cross) ===" \
 && arm-linux-gnueabihf-gcc --version | head -1 \
 && echo "" \
 && echo "=== Analysis tools ===" \
 && clang-tidy --version | head -1 \
 && cppcheck --version \
 && ccache --version | head -1 \
 && echo "" \
 && echo "=== Package manager ===" \
 && vcpkg version | head -2

# ----------------------------------------------------------------------------
# Install entrypoint and set runtime defaults
# ----------------------------------------------------------------------------
USER root

# ----------------------------------------------------------------------------
# Python packages (pytest for test automation)
# ----------------------------------------------------------------------------
RUN pip3 install --no-cache-dir --break-system-packages "pytest==${PYTEST_VERSION}"

# ----------------------------------------------------------------------------
# Typst (formal document compiler)
# ----------------------------------------------------------------------------
RUN ARCH=$(dpkg --print-architecture) \
 && if [ "$ARCH" = "amd64" ]; then TYPST_ARCH="x86_64"; TYPST_SHA256="${TYPST_SHA256_AMD64}"; \
    elif [ "$ARCH" = "arm64" ]; then TYPST_ARCH="aarch64"; TYPST_SHA256="${TYPST_SHA256_ARM64}"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi \
 && wget -q "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${TYPST_ARCH}-unknown-linux-musl.tar.xz" \
 && echo "${TYPST_SHA256}  typst-${TYPST_ARCH}-unknown-linux-musl.tar.xz" | sha256sum -c - \
 && tar xf "typst-${TYPST_ARCH}-unknown-linux-musl.tar.xz" \
 && install -m 0755 "typst-${TYPST_ARCH}-unknown-linux-musl/typst" /usr/local/bin/typst \
 && rm -rf typst-*-unknown-linux-musl*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
