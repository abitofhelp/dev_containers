# syntax=docker/dockerfile:1.7
# ============================================================================
# Dockerfile — Alire-managed toolchain (default)
# ============================================================================
# Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Ada Development Container — Alire-managed Toolchain
#
# Repository: dev_container_ada
# Docker Image: ghcr.io/abitofhelp/dev-container-ada
#
# This Dockerfile uses Ubuntu 22.04 as the base image and installs GNAT
# and GPRBuild via Alire's toolchain management. Alire's downloadable
# Linux GNAT toolchains are built on Ubuntu 22.04, making this the most
# conservative pairing.
#
# Recommended for:
#   • New Ada developers (Alire manages the full toolchain)
#   • Cross-target and embedded development (Alire distributes cross compilers)
#   • Projects that need specific GNAT/GPRBuild version combinations
#
# For an alternative using Ubuntu 24.04 with system-packaged compilers,
# see Dockerfile.system.
#
# Purpose
# -------
# Reproducible development environment for:
#   • Ada development using Alire
#   • GNAT compiler toolchain (Alire-managed)
#   • GPRBuild build system (Alire-managed)
#   • Embedded development (ARM Cortex-M bare-metal, ARM Cortex-A Linux)
#   • Python 3 + venv
#   • Zsh interactive shell
#
# Supported architecture: linux/amd64 only.
#
# arm64 is not supported because:
#   1. The Alire 2.1.0 aarch64 binary requires glibc 2.38, but Ubuntu 22.04
#      ships glibc 2.35.
#   2. Alire does not distribute pre-built gnat_native toolchains for
#      aarch64-linux.
# For arm64 / Apple Silicon, use Dockerfile.system (Ubuntu 24.04) instead.
#
# Designed for nerdctl + containerd (rootless).
#
# Files expected in the build context:
# - Dockerfile
# - .dockerignore
# - .zshrc
# - entrypoint.sh
#
# Default toolchain versions:
# - GNAT_VERSION=15.2.1
# - GPRBUILD_VERSION=25.0.1
#
# Override toolchain versions at build time:
# nerdctl build \
#   --build-arg GNAT_VERSION=15.2.2 \
#   --build-arg GPRBUILD_VERSION=25.0.2 \
#   -t dev-container-ada .
#
# Build example:
# nerdctl build -t dev-container-ada .
#
# Run example:
# nerdctl run -it --rm \
#   -e HOST_UID=$(id -u) \
#   -e HOST_GID=$(id -g) \
#   -e HOST_USER=$(whoami) \
#   -v "$(pwd)":/workspace \
#   -w /workspace \
#   dev-container-ada
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
# - GNU Make is installed explicitly because many projects use Makefiles as
#   the orchestration layer around alr, gprbuild, tests, formatting, and
#   scripts.
# - build-essential is intentionally not installed, to avoid introducing a
#   second Ubuntu-managed compiler toolchain that could conflict with Alire's
#   GNAT toolchain.
#
# ============================================================================
# Pinned by digest for reproducibility. Update periodically:
#   nerdctl pull ubuntu:22.04
#   nerdctl image inspect ubuntu:22.04 | grep -A1 RepoDigests
FROM ubuntu:22.04@sha256:3ba65aa20f86a0fad9df2b2c259c613df006b2e6d0bfcc8a146afb8c525a9751

# ----------------------------------------------------------------------------
# Build arguments (alphabetized)
# ----------------------------------------------------------------------------
ARG ALIRE_SHA256=e3b32cb0afe981b23d1a68da77452cf81ee1d82de8ebaf01c5e233be8b463fbe
ARG ALIRE_VERSION=2.1.0
ARG ALIRE_ZIP=alr-2.1.0-bin-x86_64-linux.zip
ARG DEBIAN_FRONTEND=noninteractive
ARG GNAT_VERSION=15.2.1
ARG GPRBUILD_VERSION=25.0.1
ARG PYTEST_VERSION=9.0.3
ARG TYPST_SHA256_AMD64=a6044cbad2a954deb921167e257e120ac0a16b20339ec01121194ff9d394996d
ARG TYPST_VERSION=0.14.2
ARG USER_GID=1000
ARG USERNAME=dev
ARG USER_UID=1000

# ----------------------------------------------------------------------------
# Environment variables (alphabetized)
# ----------------------------------------------------------------------------
ENV HOME=/home/${USERNAME}
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH=${HOME}/.local/bin:/usr/local/bin:${PATH} \
    SHELL=/usr/bin/zsh \
    TERM=xterm-256color \
    TZ=UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ----------------------------------------------------------------------------
# Base packages (alphabetized)
# ----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
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
    libgmp-dev \
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
    # Embedded: ARM Cortex-M bare-metal cross-compiler and tools
    # ------------------------------------------------------------------
    gcc-arm-none-eabi \
    gdb-multiarch \
    libnewlib-arm-none-eabi \
    openocd \
    stlink-tools \
    # ------------------------------------------------------------------
    # Embedded: ARM Cortex-A Linux cross-compiler (STM32MP1)
    # ------------------------------------------------------------------
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# glibc iconv stub
# ----------------------------------------------------------------------------
# On glibc systems, iconv is built into libc — there is no separate libiconv
# package. Some Ada libraries (GNATCOLL iconv) link with -liconv explicitly.
# An empty static archive satisfies the linker without pulling in a redundant
# GNU libiconv.
# ----------------------------------------------------------------------------
RUN ar rcs /usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)/libiconv.a

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
# Install Alire
# ----------------------------------------------------------------------------
WORKDIR /tmp
RUN wget -q "https://github.com/alire-project/alire/releases/download/v${ALIRE_VERSION}/${ALIRE_ZIP}" \
 && echo "${ALIRE_SHA256}  ${ALIRE_ZIP}" | sha256sum -c - \
 && unzip -q "${ALIRE_ZIP}" \
 && install -m 0755 bin/alr /usr/local/bin/alr \
 && rm -rf /tmp/*

# ----------------------------------------------------------------------------
# Switch to developer user
# ----------------------------------------------------------------------------
USER ${USERNAME}
WORKDIR ${HOME}

RUN mkdir -p \
    "${HOME}/.docker/completions" \
    "${HOME}/.local/bin" \
    "${HOME}/workspace"

COPY --chown=${USER_UID}:${USER_GID} ada/.zshrc ${HOME}/.zshrc

# ----------------------------------------------------------------------------
# Configure Alire toolchain
# ----------------------------------------------------------------------------
RUN alr --non-interactive toolchain --select \
        gnat_native=${GNAT_VERSION} \
        gprbuild=${GPRBUILD_VERSION} \
 && echo "" \
 && echo "Configured Alire environment:" \
 && alr version \
 && echo "" \
 && echo "Installed toolchains:" \
 && alr toolchain

# ----------------------------------------------------------------------------
# Install entrypoint and set runtime defaults
# ----------------------------------------------------------------------------
# The entrypoint runs as root so it can create/adapt the user at startup.
# In rootful runtimes it drops privileges via gosu.  In rootless runtimes
# container UID 0 is already the unprivileged host user.
# ----------------------------------------------------------------------------
USER root

# Create symlinks for toolchain binaries so gnat/gprbuild are available in
# non-interactive contexts (scripts, CI, make) without sourcing .zshrc.
RUN for d in /home/${USERNAME}/.local/share/alire/toolchains/*/bin; do \
        if [ -d "$d" ]; then \
            for bin in "$d"/*; do \
                name="$(basename "$bin")"; \
                [ ! -e "/usr/local/bin/$name" ] && \
                    ln -s "$bin" "/usr/local/bin/$name"; \
            done; \
        fi; \
    done

# ----------------------------------------------------------------------------
# Python packages (pytest for test automation)
# ----------------------------------------------------------------------------
RUN pip3 install --no-cache-dir "pytest==${PYTEST_VERSION}"

# ----------------------------------------------------------------------------
# Typst (formal document compiler)
#
# This image is amd64 only (see header), so only the x86_64 Typst binary
# is required.
# ----------------------------------------------------------------------------
RUN wget -q "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-x86_64-unknown-linux-musl.tar.xz" \
 && echo "${TYPST_SHA256_AMD64}  typst-x86_64-unknown-linux-musl.tar.xz" | sha256sum -c - \
 && tar xf typst-x86_64-unknown-linux-musl.tar.xz \
 && install -m 0755 typst-x86_64-unknown-linux-musl/typst /usr/local/bin/typst \
 && rm -rf typst-x86_64-unknown-linux-musl*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
