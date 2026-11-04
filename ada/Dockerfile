# syntax=docker/dockerfile:1.7
# ============================================================================
# Dockerfile — Alire-managed toolchain (the Ada image)
# ============================================================================
# Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Ada Development Container — Alire-managed Toolchain
#
# Repository: dev_containers
# Docker Image: ghcr.io/abitofhelp/dev-container-ada
#
# This is the single Ada image for linux/amd64 and linux/arm64. It uses
# Ubuntu 26.04 LTS and installs GNAT, GPRbuild, and GNATprove through
# Alire at build time, at fixed versions, under /opt/alire.
#
# The older system-toolchain image (Dockerfile.system,
# dev-container-ada-system) is deprecated. It existed only because Alire
# had no arm64 Linux GNAT; Alire now ships one, so use this image instead.
#
# Purpose
# -------
# Reproducible development environment for:
#   • Ada 2022 development using Alire
#   • GNAT native compiler, GPRbuild, and GNATprove (SPARK)
#   • PostgreSQL client development (libpq 18, psql)
#   • Embedded development (ARM Cortex-M bare-metal, ARM Cortex-A Linux)
#   • Formal documents (Typst)
#   • Python 3 (virtual environment at /opt/venv, with pytest)
#   • Zsh interactive shell
#
# Supported architectures: linux/amd64, linux/arm64 (Apple Silicon).
#
# Designed for nerdctl + containerd (rootless); also works with docker
# and podman.
#
# Files expected in the build context (the repository root):
# - .dockerignore
# - LICENSE
# - ada/.zshrc
# - ada/dev-doctor.sh
# - entrypoint.sh
#
# Default toolchain versions:
# - ALIRE_VERSION=2.1.1
# - GNAT_VERSION=16.1.0
# - GNATPROVE_VERSION=16.1.0
# - GPRBUILD_VERSION=26.0.1
#
# Build example (from the repository root):
# nerdctl build -f ada/Dockerfile -t dev-container-ada .
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
# Reproducibility
# ---------------
# - The base image is pinned by digest.
# - Alire, GNAT, GPRbuild, GNATprove, and Typst are pinned by version,
#   and downloads are verified by SHA-256.
# - The Alire community index is pinned to a commit (ALIRE_INDEX_COMMIT)
#   and does not refresh automatically (index.auto_update = 0). Run
#   `alr index --update-all` to fetch newer crates deliberately.
# - APT packages come from a dated Ubuntu snapshot (UBUNTU_SNAPSHOT) on both
#   architectures, so a rebuild installs the same package versions. Only
#   ca-certificates is installed from the live archive first, because the
#   snapshot service requires HTTPS. Each image also records its exact
#   package list in /usr/share/doc/dev-containers/packages-<arch>.txt.
#
# Notes
# -----
# - User identity is adapted at runtime by entrypoint.sh, not baked in at
#   build time. The build-time user (dev:1000:1000) is a fallback for CI
#   and Kubernetes environments where no HOST_* variables are passed.
# - Alire's settings, cache, toolchains, and install prefix live under
#   /opt/alire (ALIRE_SETTINGS_DIR), so they do not depend on HOME and
#   are shared by whichever user the entrypoint selects.
# - GNU Make is installed explicitly because many projects use Makefiles as
#   the orchestration layer around alr, gprbuild, tests, formatting, and
#   scripts.
# - build-essential is intentionally not installed, to avoid introducing a
#   second Ubuntu-managed compiler toolchain that could conflict with Alire's
#   GNAT toolchain.
#
# ============================================================================
# Pinned by digest for reproducibility (multi-architecture index). Update:
#   docker buildx imagetools inspect ubuntu:26.04
FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c

# ----------------------------------------------------------------------------
# Build arguments (alphabetized)
# ----------------------------------------------------------------------------
ARG ALIRE_INDEX_COMMIT=03d44a6e975a675d9f54dffcc0a2ef8ae3870873
ARG ALIRE_SHA256_AMD64=09c66bcd8c35dd4b97b72c3d9b76e44caa6964a2db35aba069f396f00f1f64c7
ARG ALIRE_SHA256_ARM64=d76c93ad3dc631826144e10bdabc6b3bf98783805bebfd5e4a0e852dd524d812
ARG ALIRE_VERSION=2.1.1
ARG DEBIAN_FRONTEND=noninteractive
ARG GNAT_VERSION=16.1.0
ARG GNATPROVE_VERSION=16.1.0
ARG GPRBUILD_VERSION=26.0.1
ARG PYTEST_VERSION=9.2.0
ARG TYPST_SHA256_AMD64=a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c
ARG TYPST_SHA256_ARM64=5aa8d74a3d906e60ea12a66ac2f37f8eef1b14cbad7182a745e393a10c23dcee
ARG TYPST_VERSION=0.15.1
ARG UBUNTU_SNAPSHOT=20261103T000000Z
ARG USER_GID=1000
ARG USERNAME=dev
ARG USER_UID=1000

# ----------------------------------------------------------------------------
# Environment variables (alphabetized)
# ----------------------------------------------------------------------------
ENV ALIRE_SETTINGS_DIR=/opt/alire/settings \
    HOME=/home/${USERNAME}
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH=${HOME}/.local/bin:/opt/venv/bin:/opt/alire/prefix/bin:/opt/alire/gnat/bin:/opt/alire/gprbuild/bin:/usr/local/bin:${PATH} \
    SHELL=/usr/bin/zsh \
    TERM=xterm-256color \
    TZ=UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ----------------------------------------------------------------------------
# APT snapshot (reproducible package versions on amd64 and arm64)
# ----------------------------------------------------------------------------
# - Since Ubuntu 26.04, arm64 packages are served from archive.ubuntu.com,
#   which the snapshot service covers; the base image's arm64 sources still
#   name ports.ubuntu.com, so they are pointed at the main archive.
# - The snapshot service is HTTPS-only, so ca-certificates is installed from
#   the live archive before the snapshot is enabled.
# - The snapshot setting stays in the image, so packages installed later
#   with apt match the image. Delete /etc/apt/apt.conf.d/50snapshot to use
#   the live archive instead.
# ----------------------------------------------------------------------------
RUN set -eux; \
    sed -i 's#http://ports.ubuntu.com/ubuntu-ports/#http://archive.ubuntu.com/ubuntu/#' \
        /etc/apt/sources.list.d/ubuntu.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates; \
    echo "APT::Snapshot \"${UBUNTU_SNAPSHOT}\";" > /etc/apt/apt.conf.d/50snapshot; \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Base packages (alphabetized within each group)
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
    zlib1g-dev \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    # ------------------------------------------------------------------
    # PostgreSQL client development (libpq 18 from Ubuntu 26.04)
    # ------------------------------------------------------------------
    libpq-dev \
    postgresql-client-18 \
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
# Ubuntu 26.04 ships an "ubuntu" user and group with ID 1000; both are
# renamed to the developer user.
# ----------------------------------------------------------------------------
RUN set -eux; \
    if ! getent group "${USER_GID}" >/dev/null; then \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    elif [ "$(getent group "${USER_GID}" | cut -d: -f1)" != "${USERNAME}" ] \
         && ! getent group "${USERNAME}" >/dev/null; then \
        groupmod --new-name "${USERNAME}" "$(getent group "${USER_GID}" | cut -d: -f1)"; \
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
# Install Alire (per architecture, verified by SHA-256)
# ----------------------------------------------------------------------------
WORKDIR /tmp
RUN set -eux; \
    case "$(uname -m)" in \
      x86_64)  ALIRE_ARCH="x86_64"  ; ALIRE_SHA256="${ALIRE_SHA256_AMD64}" ;; \
      aarch64) ALIRE_ARCH="aarch64" ; ALIRE_SHA256="${ALIRE_SHA256_ARM64}" ;; \
      *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    ALIRE_ZIP="alr-${ALIRE_VERSION}-bin-${ALIRE_ARCH}-linux.zip"; \
    wget -q "https://github.com/alire-project/alire/releases/download/v${ALIRE_VERSION}/${ALIRE_ZIP}"; \
    echo "${ALIRE_SHA256}  ${ALIRE_ZIP}" | sha256sum -c -; \
    unzip -q "${ALIRE_ZIP}"; \
    install -m 0755 bin/alr /usr/local/bin/alr; \
    rm -rf /tmp/*

# ----------------------------------------------------------------------------
# Configure Alire under /opt/alire and install the pinned toolchain
# ----------------------------------------------------------------------------
# - Settings, cache, toolchains, and the install prefix do not depend on HOME.
# - The community index is pinned to ALIRE_INDEX_COMMIT and never refreshes
#   on its own.
# - The toolchain assistant is disabled; the selection below is the only one.
# - Stable links (/opt/alire/gnat, /opt/alire/gprbuild) put the selected
#   toolchains on PATH without globbing version-specific directory names.
# ----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /opt/alire/cache /opt/alire/prefix /opt/alire/settings /opt/alire/toolchains; \
    alr settings --global --set cache.dir /opt/alire/cache; \
    alr settings --global --set toolchain.dir /opt/alire/toolchains; \
    alr settings --global --set toolchain.assistant false; \
    alr settings --global --set index.auto_update 0; \
    alr --non-interactive index --reset-community; \
    INDEX_REPO="$(find /opt/alire -maxdepth 6 -type d -name .git -path '*indexes*' -printf '%h\n' | head -1)"; \
    test -n "${INDEX_REPO}"; \
    INDEX_BRANCH="$(git -C "${INDEX_REPO}" rev-parse --abbrev-ref HEAD)"; \
    git -C "${INDEX_REPO}" fetch --quiet origin "${ALIRE_INDEX_COMMIT}" || true; \
    git -C "${INDEX_REPO}" checkout --quiet -B "${INDEX_BRANCH}" "${ALIRE_INDEX_COMMIT}"; \
    alr --non-interactive toolchain --select \
        "gnat_native=${GNAT_VERSION}" \
        "gprbuild=${GPRBUILD_VERSION}"; \
    alr --non-interactive install --prefix=/opt/alire/prefix \
        "gnatprove=${GNATPROVE_VERSION}"; \
    ln -s "$(find /opt/alire/toolchains -maxdepth 1 -type d -name "gnat_native_${GNAT_VERSION}_*" | head -1)" /opt/alire/gnat; \
    ln -s "$(find /opt/alire/toolchains -maxdepth 1 -type d -name "gprbuild_${GPRBUILD_VERSION}_*" | head -1)" /opt/alire/gprbuild; \
    test -x /opt/alire/gnat/bin/gnat; \
    test -x /opt/alire/gprbuild/bin/gprbuild; \
    test -x /opt/alire/prefix/bin/gnatprove; \
    git -C "${INDEX_REPO}" rev-parse HEAD > /usr/share/doc/dev-containers/alire-index-commit.txt; \
    chmod -R a+rwX /opt/alire; \
    alr version; \
    alr toolchain

# ----------------------------------------------------------------------------
# Python virtual environment (PEP 668) with pytest
# ----------------------------------------------------------------------------
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir "pytest==${PYTEST_VERSION}" \
 && chmod -R a+rwX /opt/venv

# ----------------------------------------------------------------------------
# Typst (formal document compiler), per architecture
# ----------------------------------------------------------------------------
RUN set -eux; \
    case "$(uname -m)" in \
      x86_64)  TYPST_ARCH="x86_64"  ; TYPST_SHA256="${TYPST_SHA256_AMD64}" ;; \
      aarch64) TYPST_ARCH="aarch64" ; TYPST_SHA256="${TYPST_SHA256_ARM64}" ;; \
      *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    TYPST_TAR="typst-${TYPST_ARCH}-unknown-linux-musl.tar.xz"; \
    wget -q "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/${TYPST_TAR}"; \
    echo "${TYPST_SHA256}  ${TYPST_TAR}" | sha256sum -c -; \
    tar xf "${TYPST_TAR}"; \
    install -m 0755 "typst-${TYPST_ARCH}-unknown-linux-musl/typst" /usr/local/bin/typst; \
    rm -rf /tmp/*

# ----------------------------------------------------------------------------
# Record the exact package list for this architecture
# ----------------------------------------------------------------------------
RUN dpkg-query -W -f '${Package}\t${Version}\t${Architecture}\n' \
      > "/usr/share/doc/dev-containers/packages-$(dpkg --print-architecture).txt"

# ----------------------------------------------------------------------------
# Developer home
# ----------------------------------------------------------------------------
USER ${USERNAME}
WORKDIR ${HOME}

RUN mkdir -p \
    "${HOME}/.docker/completions" \
    "${HOME}/.local/bin" \
    "${HOME}/workspace"

COPY --chown=${USER_UID}:${USER_GID} ada/.zshrc ${HOME}/.zshrc

# ----------------------------------------------------------------------------
# Entrypoint, diagnostics, and runtime defaults
# ----------------------------------------------------------------------------
# The entrypoint runs as root so it can create/adapt the user at startup.
# In rootful runtimes it drops privileges via gosu.  In rootless runtimes
# container UID 0 is already the unprivileged host user.
# ----------------------------------------------------------------------------
USER root

COPY ada/dev-doctor.sh /usr/local/bin/dev-doctor
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/dev-doctor /usr/local/bin/entrypoint.sh

# /workspace is normally a bind mount; when it is not, keep it writable so
# tools that write temporary files to the working directory (alr) still work.
RUN mkdir -p /workspace && chmod 1777 /workspace
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
