# syntax=docker/dockerfile:1.7
# ============================================================================
# Dockerfile — Go Development Container
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Go Development Container — Official Toolchain
#
# Repository: dev_container_go
# Docker Image: ghcr.io/abitofhelp/dev-container-go
#
# This Dockerfile uses Ubuntu 24.04 as the base image and adds:
#   • Go 1.26.1 from the official tarball (go.dev)
#   • Protobuf compiler and Go gRPC plugins
#   • Buf for protobuf linting and management
#   • Bazelisk for Bazel build system (Bzlmod)
#   • Go development tools: gopls, dlv, staticcheck, golangci-lint
#
# Recommended for:
#   • Cloud platform development (microservices, APIs, gRPC)
#   • Desktop application development
#   • Cross-compilation (macOS, Linux, Windows via GOOS/GOARCH)
#
# Purpose
# -------
# Reproducible development environment for:
#   • Go development with official toolchain
#   • Protobuf/gRPC service development
#   • Bazel builds with Bzlmod
#   • Cross-compilation for macOS, Linux, and Windows
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
# nerdctl build -t dev-container-go .
#
# Run example:
# nerdctl run -it --rm \
#   -e HOST_UID=$(id -u) \
#   -e HOST_GID=$(id -g) \
#   -e HOST_USER=$(whoami) \
#   -v "$(pwd)":/workspace \
#   -w /workspace \
#   dev-container-go
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
# - Go cross-compilation is built-in: set GOOS and GOARCH to build for any
#   supported target without additional cross-compilers.
# - Bazelisk is installed as /usr/local/bin/bazel and automatically
#   downloads the correct Bazel version based on .bazelversion or
#   MODULE.bazel in the project.
#
# ============================================================================
# Pinned by digest for reproducibility. Update periodically:
#   nerdctl pull ubuntu:24.04
#   nerdctl image inspect ubuntu:24.04 | grep -A1 RepoDigests
FROM ubuntu:24.04@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9

# ----------------------------------------------------------------------------
# Build arguments (alphabetized)
# ----------------------------------------------------------------------------
ARG BAZELISK_VERSION=v1.25.0
ARG BUF_VERSION=1.50.0
ARG DEBIAN_FRONTEND=noninteractive
ARG GO_SHA256_AMD64=031f088e5d955bab8657ede27ad4e3bc5b7c1ba281f05f245bcc304f327c987a
ARG GO_SHA256_ARM64=a290581cfe4fe28ddd737dde3095f3dbeb7f2e4065cab4eae44dfc53b760c2f7
ARG GO_VERSION=1.26.1
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
    PATH=/usr/local/go/bin:${HOME}/.local/bin:/usr/local/bin:${PATH} \
    SHELL=/usr/bin/zsh \
    TERM=xterm-256color \
    TZ=UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ----------------------------------------------------------------------------
# Base packages (alphabetized)
# ----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
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
    protobuf-compiler \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ripgrep \
    rsync \
    software-properties-common \
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
# Install Go from official tarball (arch-aware, SHA256 verified)
# ----------------------------------------------------------------------------
RUN ARCH=$(dpkg --print-architecture) \
 && if [ "$ARCH" = "amd64" ]; then GO_SHA256="${GO_SHA256_AMD64}"; \
    elif [ "$ARCH" = "arm64" ]; then GO_SHA256="${GO_SHA256_ARM64}"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi \
 && wget -qO /tmp/go.tar.gz \
    "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" \
 && echo "${GO_SHA256}  /tmp/go.tar.gz" | sha256sum -c - \
 && tar -C /usr/local -xzf /tmp/go.tar.gz \
 && rm /tmp/go.tar.gz

# ----------------------------------------------------------------------------
# Install Bazelisk (as /usr/local/bin/bazel for seamless Bzlmod workflows)
# ----------------------------------------------------------------------------
RUN ARCH=$(dpkg --print-architecture) \
 && wget -qO /usr/local/bin/bazel \
    "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-${ARCH}" \
 && chmod +x /usr/local/bin/bazel

# ----------------------------------------------------------------------------
# Install buf (protobuf linting, formatting, breaking change detection)
# ----------------------------------------------------------------------------
RUN ARCH=$(dpkg --print-architecture) \
 && if [ "$ARCH" = "amd64" ]; then BUF_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then BUF_ARCH="aarch64"; fi \
 && wget -qO /usr/local/bin/buf \
    "https://github.com/bufbuild/buf/releases/download/v${BUF_VERSION}/buf-Linux-${BUF_ARCH}" \
 && chmod +x /usr/local/bin/buf

# ----------------------------------------------------------------------------
# Install Go development tools (system-wide to /usr/local/bin)
# ----------------------------------------------------------------------------
RUN GOBIN=/usr/local/bin GOPATH=/tmp/go-build \
    go install golang.org/x/tools/gopls@latest \
 && GOBIN=/usr/local/bin GOPATH=/tmp/go-build \
    go install github.com/go-delve/delve/cmd/dlv@latest \
 && GOBIN=/usr/local/bin GOPATH=/tmp/go-build \
    go install honnef.co/go/tools/cmd/staticcheck@latest \
 && GOBIN=/usr/local/bin GOPATH=/tmp/go-build \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest \
 && GOBIN=/usr/local/bin GOPATH=/tmp/go-build \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest \
 && rm -rf /tmp/go-build

# ----------------------------------------------------------------------------
# Install golangci-lint (binary installer, per official recommendation)
# ----------------------------------------------------------------------------
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh \
    | sh -s -- -b /usr/local/bin

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

COPY --chown=${USER_UID}:${USER_GID} go/.zshrc ${HOME}/.zshrc

# ----------------------------------------------------------------------------
# Verify toolchain installation
# ----------------------------------------------------------------------------
RUN echo "" \
 && echo "=== Go toolchain ===" \
 && go version \
 && echo "" \
 && echo "=== Go tools ===" \
 && gopls version 2>&1 | head -1 \
 && dlv version 2>&1 | head -1 \
 && staticcheck --version \
 && golangci-lint --version 2>&1 | head -1 \
 && echo "" \
 && echo "=== Protobuf ===" \
 && protoc --version \
 && which protoc-gen-go \
 && which protoc-gen-go-grpc \
 && buf --version \
 && echo "" \
 && echo "=== Build system ===" \
 && file /usr/local/bin/bazel

# ----------------------------------------------------------------------------
# Install entrypoint and set runtime defaults
# ----------------------------------------------------------------------------
USER root

# ----------------------------------------------------------------------------
# Python packages (pytest for test automation)
# ----------------------------------------------------------------------------
RUN pip3 install --no-cache-dir --break-system-packages pytest

# ----------------------------------------------------------------------------
# Typst (formal document compiler)
# ----------------------------------------------------------------------------
ARG TYPST_VERSION=0.14.2
RUN wget -q "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-x86_64-unknown-linux-musl.tar.xz" \
 && tar xf typst-x86_64-unknown-linux-musl.tar.xz \
 && install -m 0755 typst-x86_64-unknown-linux-musl/typst /usr/local/bin/typst \
 && rm -rf typst-x86_64-unknown-linux-musl*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
