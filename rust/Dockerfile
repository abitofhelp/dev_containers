# syntax=docker/dockerfile:1.7
# ============================================================================
# Dockerfile
# ============================================================================
# Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Rust Development Container
#
# Repository: dev_container_rust
# Docker Image: ghcr.io/abitofhelp/dev-container-rust
#
# This Dockerfile uses Ubuntu 24.04 as the base image and adds:
#   - Rust stable toolchain via rustup (rustc, cargo, rustfmt, clippy,
#     rust-analyzer, llvm-tools-preview)
#   - Embedded bare-metal targets (5 thumbv7/v6/v8m targets)
#   - ARM Cortex-A Linux cross-compilation target
#   - cargo-binstall for fast binary installs
#   - probe-rs for embedded flashing and debugging
#   - cargo-generate, cargo-expand, sccache
#   - mold fast linker
#
# Single image only. Ubuntu 24.04's apt Rust is 1.75, far behind stable
# 1.85+. The supply-chain-auditability argument for a system-only image
# does not hold when the language version gap is this large. Rustup is
# the standard Rust installation method.
#
# Purpose
# -------
# Reproducible development environment for:
#   - Desktop Rust development (stable toolchain)
#   - Embedded Rust development (ARM Cortex-M bare-metal, ARM Cortex-A Linux)
#   - Build tools: cargo, mold linker, sccache (opt-in)
#   - Static analysis: clippy, rustfmt
#   - Python 3 + venv
#   - Zsh interactive shell
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
# nerdctl build -t dev-container-rust .
#
# Run example:
# nerdctl run -it --rm \
#   -e HOST_UID=$(id -u) \
#   -e HOST_GID=$(id -g) \
#   -e HOST_USER=$(whoami) \
#   -v "$(pwd)":/workspace \
#   -w /workspace \
#   dev-container-rust
#
# Notes
# -----
# - User identity is adapted at runtime by entrypoint.sh, not baked in at
#   build time. The build-time user (dev:1000:1000) is a fallback for CI
#   and Kubernetes environments where no HOST_* variables are passed.
# - In rootless runtimes, container UID 0 maps to the host user via the
#   user namespace. The entrypoint detects this and stays as UID 0 rather
#   than dropping privileges, which would break bind-mount access.
# - In rootful runtimes, the entrypoint drops to the adapted user via gosu.
# - Rust uses the same compiler for desktop and embedded development — you
#   just add cross-compilation targets via `rustup target add`. No separate
#   cross-compiler (like arm-none-eabi-gcc) is needed for bare-metal targets.
#
# ============================================================================
# Pinned by digest for reproducibility. Update periodically:
#   nerdctl pull ubuntu:24.04
#   nerdctl image inspect ubuntu:24.04 | grep -A1 RepoDigests
FROM ubuntu:24.04@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9

# ----------------------------------------------------------------------------
# Build arguments (alphabetized)
# ----------------------------------------------------------------------------
ARG CARGO_BINSTALL_SHA256_AMD64=cf2a4b54494ea8555d6349685e9a301efc1051d9fba6308c76914b2486f8700f
ARG CARGO_BINSTALL_SHA256_ARM64=c55962a0115f9716b709216de7f8bdd59d6ba8738779e60b051b4593f677717a
ARG CARGO_BINSTALL_VERSION=1.18.1
ARG CARGO_EXPAND_VERSION=1.0.121
ARG CARGO_GENERATE_VERSION=0.23.8
ARG DEBIAN_FRONTEND=noninteractive
ARG PROBE_RS_TOOLS_VERSION=0.31.0
ARG PYTEST_VERSION=9.0.3
ARG RUST_VERSION=1.95.0
ARG SCCACHE_VERSION=0.14.0
ARG TYPST_SHA256_AMD64=a6044cbad2a954deb921167e257e120ac0a16b20339ec01121194ff9d394996d
ARG TYPST_SHA256_ARM64=491b101aa40a3a7ea82a3f8a6232cabb4e6a7e233810082e5ac812d43fdcd47a
ARG TYPST_VERSION=0.14.2
ARG USER_GID=1000
ARG USERNAME=dev
ARG USER_UID=1000

# ----------------------------------------------------------------------------
# Environment variables (alphabetized)
# ----------------------------------------------------------------------------
ENV CARGO_HOME=/opt/cargo \
    HOME=/home/${USERNAME} \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH="/opt/cargo/bin:/home/${USERNAME}/.local/bin:/usr/local/bin:${PATH}" \
    RUSTUP_HOME=/opt/rustup \
    SHELL=/usr/bin/zsh \
    TERM=xterm-256color \
    TZ=UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ----------------------------------------------------------------------------
# Base packages (alphabetized)
# ----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ------------------------------------------------------------------
    # Build essentials (for C deps like openssl-sys, ring, etc.)
    # ------------------------------------------------------------------
    build-essential \
    libssl-dev \
    pkg-config \
    # ------------------------------------------------------------------
    # Debuggers
    # ------------------------------------------------------------------
    gdb \
    lldb \
    valgrind \
    # ------------------------------------------------------------------
    # Embedded: ARM Cortex-A Linux cross-compiler (STM32MP1)
    # ------------------------------------------------------------------
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    # ------------------------------------------------------------------
    # Embedded: hardware debug tools
    # ------------------------------------------------------------------
    gdb-multiarch \
    # ------------------------------------------------------------------
    # Fast linker
    # ------------------------------------------------------------------
    mold \
    # ------------------------------------------------------------------
    # General development tools
    # ------------------------------------------------------------------
    bzip2 \
    ca-certificates \
    curl \
    fd-find \
    file \
    fzf \
    git \
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
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Rustup + pinned toolchain
#
# rustup verifies downloaded toolchains against Rust's signing key, so no
# separate SHA256 is required for the toolchain itself.
# ----------------------------------------------------------------------------
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain "${RUST_VERSION}" --profile default \
 && rustup component add rust-analyzer llvm-tools-preview \
 && chmod -R a+rX /opt/rustup /opt/cargo

# ----------------------------------------------------------------------------
# Embedded targets (installed via rustup)
# ----------------------------------------------------------------------------
RUN rustup target add \
    thumbv6m-none-eabi \
    thumbv7m-none-eabi \
    thumbv7em-none-eabi \
    thumbv7em-none-eabihf \
    thumbv8m.main-none-eabihf \
    armv7-unknown-linux-gnueabihf \
 && chmod -R a+rX /opt/rustup

# ----------------------------------------------------------------------------
# cargo-binstall (release tarball, SHA256-verified)
# ----------------------------------------------------------------------------
RUN ARCH=$(dpkg --print-architecture) \
 && if [ "$ARCH" = "amd64" ]; then CARGO_BINSTALL_ARCH="x86_64"; CARGO_BINSTALL_SHA256="${CARGO_BINSTALL_SHA256_AMD64}"; \
    elif [ "$ARCH" = "arm64" ]; then CARGO_BINSTALL_ARCH="aarch64"; CARGO_BINSTALL_SHA256="${CARGO_BINSTALL_SHA256_ARM64}"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi \
 && wget -qO /tmp/cargo-binstall.tgz \
    "https://github.com/cargo-bins/cargo-binstall/releases/download/v${CARGO_BINSTALL_VERSION}/cargo-binstall-${CARGO_BINSTALL_ARCH}-unknown-linux-musl.tgz" \
 && echo "${CARGO_BINSTALL_SHA256}  /tmp/cargo-binstall.tgz" | sha256sum -c - \
 && tar -xzf /tmp/cargo-binstall.tgz -C /tmp \
 && install -m 0755 /tmp/cargo-binstall /opt/cargo/bin/cargo-binstall \
 && rm -f /tmp/cargo-binstall /tmp/cargo-binstall.tgz \
 && chmod -R a+rX /opt/cargo

# ----------------------------------------------------------------------------
# Cargo tools (via binstall, versions pinned)
#
# cargo binstall downloads pre-built binaries published by each crate's
# upstream release; cargo verifies crate metadata against crates.io.
# ----------------------------------------------------------------------------
RUN cargo binstall -y --no-symlinks \
    "probe-rs-tools@${PROBE_RS_TOOLS_VERSION}" \
    "cargo-generate@${CARGO_GENERATE_VERSION}" \
    "cargo-expand@${CARGO_EXPAND_VERSION}" \
    "sccache@${SCCACHE_VERSION}" \
 && chmod -R a+rX /opt/cargo

# ----------------------------------------------------------------------------
# Create developer user
# ----------------------------------------------------------------------------
RUN set -eux; \
    if ! getent group "${USER_GID}" >/dev/null; then \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi; \
    if id -u "${USERNAME}" >/dev/null 2>&1; then \
        usermod --uid "${USER_UID}" --gid "${USER_GID}" --shell /usr/bin/zsh "${USERNAME}"; \
    elif getent passwd "${USER_UID}" >/dev/null; then \
        EXISTING_USER="$(getent passwd "${USER_UID}" | cut -d: -f1)"; \
        # Remove pre-existing target home (may be created by earlier ENV HOME) \
        # so that --move-home can rename the existing user's home directory. \
        rm -rf "/home/${USERNAME}"; \
        usermod --login "${USERNAME}" --home "/home/${USERNAME}" --move-home \
            --gid "${USER_GID}" --shell /usr/bin/zsh "${EXISTING_USER}"; \
    else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /usr/bin/zsh "${USERNAME}"; \
    fi; \
    usermod -aG sudo "${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# ----------------------------------------------------------------------------
# License
# ----------------------------------------------------------------------------
COPY LICENSE /usr/share/doc/dev-containers/LICENSE

# ----------------------------------------------------------------------------
# Switch to developer user
# ----------------------------------------------------------------------------
USER ${USERNAME}
WORKDIR ${HOME}

RUN mkdir -p \
    "${HOME}/.docker/completions" \
    "${HOME}/.local/bin" \
    "${HOME}/workspace"

COPY --chown=${USER_UID}:${USER_GID} rust/.zshrc ${HOME}/.zshrc

# ----------------------------------------------------------------------------
# Verify toolchain installation
# ----------------------------------------------------------------------------
RUN echo "" \
 && echo "=== Rust toolchain ===" \
 && rustc --version \
 && cargo --version \
 && rustfmt --version \
 && cargo clippy --version \
 && rust-analyzer --version \
 && echo "" \
 && echo "=== Embedded targets ===" \
 && rustup target list --installed \
 && echo "" \
 && echo "=== Cargo tools ===" \
 && probe-rs --version \
 && cargo-generate --version \
 && cargo-expand --version \
 && sccache --version \
 && echo "" \
 && echo "=== System tools ===" \
 && mold --version \
 && arm-linux-gnueabihf-gcc --version | head -1 \
 && gdb-multiarch --version | head -1

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
