# ============================================================================
# Makefile
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Thin wrapper for the C++ images in dev_containers.
# Sets C++-specific variables, then includes the shared Makefile.common.
# ============================================================================

.DEFAULT_GOAL := help

# ----------------------------------------------------------------------------
# Language / project settings
# ----------------------------------------------------------------------------
LANG_DIR          := cpp
IMAGE_NAME        := dev-container-cpp
SYSTEM_IMAGE_NAME := $(IMAGE_NAME)-system
PROJECT_NAME      ?= dev_containers

# ----------------------------------------------------------------------------
# Build arguments (none for C++)
# ----------------------------------------------------------------------------
BUILD_ARGS :=

# ----------------------------------------------------------------------------
# Include shared targets
# ----------------------------------------------------------------------------
_THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(_THIS_DIR)/../Makefile.common

# ----------------------------------------------------------------------------
# Help
# ----------------------------------------------------------------------------
.PHONY: help
help:
	@echo "Upstream image (Dockerfile — Clang 20, latest CMake, vcpkg — amd64 + arm64):"
	@echo "  pull                 Pull the upstream image from GHCR"
	@echo "  build                Build the upstream image"
	@echo "  build-no-cache       Build the upstream image without cache"
	@echo "  run                  Run the upstream image interactively"
	@echo "  run-root             Run as root, bypassing the entrypoint (diagnostic)"
	@echo "  run-shell            Open zsh in the user home directory"
	@echo "  test                 Smoke test (nerdctl rootless)"
	@echo "  test-docker          Smoke test (docker rootful)"
	@echo "  test-podman          Smoke test (podman rootless)"
	@echo "  save                 Save the image to dist/"
	@echo "  show-tags            Show suggested tags"
	@echo "  tag-version          Tag local image with compiler versions"
	@echo "  tag-latest           Tag local image as latest"
	@echo ""
	@echo "System-toolchain image (Dockerfile.system — GCC 13, Clang 18 — amd64 + arm64):"
	@echo "  pull-system          Pull the system image from GHCR"
	@echo "  build-system         Build the system-toolchain image"
	@echo "  build-system-no-cache Build the system-toolchain image without cache"
	@echo "  run-system           Run the system-toolchain image interactively"
	@echo "  run-root-system      Run as root, bypassing the entrypoint (diagnostic)"
	@echo "  run-shell-system     Open zsh in the user home directory"
	@echo "  test-system          Smoke test (nerdctl rootless)"
	@echo "  test-docker-system   Smoke test (docker rootful)"
	@echo "  test-podman-system   Smoke test (podman rootless)"
	@echo "  save-system          Save the system image to dist/"
	@echo "  show-tags-system     Show suggested tags"
	@echo "  tag-system           Tag local image with system-gcc-13-clang-18"
	@echo "  tag-latest-system    Tag local image as latest"
	@echo ""
	@echo "Docker convenience aliases:"
	@echo "  docker-pull          Pull the upstream image with docker"
	@echo "  docker-pull-system   Pull the system image with docker"
	@echo "  docker-build         Build the upstream image with docker"
	@echo "  docker-build-system  Build the system image with docker"
	@echo "  docker-run           Run the upstream image with docker"
	@echo "  docker-run-system    Run the system image with docker"
	@echo ""
	@echo "Podman convenience aliases:"
	@echo "  podman-pull          Pull the upstream image with podman"
	@echo "  podman-pull-system   Pull the system image with podman"
	@echo "  podman-build         Build the upstream image with podman"
	@echo "  podman-build-system  Build the system image with podman"
	@echo "  podman-run           Run with podman (--userns=keep-id)"
	@echo "  podman-run-system    Run system image with podman (--userns=keep-id)"
	@echo ""
	@echo "General:"
	@echo "  inspect              Show configured image and runtime settings"
	@echo "  clean                Remove build artifacts (dist/, archives)"
	@echo "  compress             Create a compressed source archive from HEAD"
	@echo ""
	@echo "Variables:"
	@echo "  CONTAINER_CLI        Container CLI (auto-detected; override with CONTAINER_CLI=docker)"
	@echo "  SCRIPTS_PYTHON       Path to hybrid_scripts_python (auto-detected; override with HYBRID_SCRIPTS_PYTHON=...)"
	@echo "  HOST_USER            Host username (default: $$(whoami))"
	@echo "  HOST_UID             Host user ID (default: $$(id -u))"
	@echo "  HOST_GID             Host group ID (default: $$(id -g))"

# ----------------------------------------------------------------------------
# Test scripts
# ----------------------------------------------------------------------------
EXAMPLE_DIR := examples/hello_cpp

define TEST_SCRIPT
set -e
echo "=== Environment ==="
echo "USER=$$(whoami) UID=$$(id -u) GID=$$(id -g) HOME=$$HOME"
echo "DISPLAY_USER=$$DISPLAY_USER"
echo "CONTAINER_RUNTIME=$$CONTAINER_RUNTIME"
echo ""
echo "=== Compile test (CMake + Ninja) ==="
cmake -B build -G Ninja -DCMAKE_CXX_STANDARD=20
cmake --build build
echo ""
echo "=== Run test ==="
./build/hello_cpp
echo ""
echo "=== Toolchain versions ==="
gcc --version | head -1
g++ --version | head -1
clang --version | head -1
cmake --version | head -1
ninja --version
arm-none-eabi-gcc --version | head -1
echo "=== Test passed ==="
endef
export TEST_SCRIPT

define TEST_SCRIPT_SYSTEM
set -e
echo "=== Environment ==="
echo "USER=$$(whoami) UID=$$(id -u) GID=$$(id -g) HOME=$$HOME"
echo "DISPLAY_USER=$$DISPLAY_USER"
echo "CONTAINER_RUNTIME=$$CONTAINER_RUNTIME"
echo ""
echo "=== Compile test (CMake + Ninja) ==="
cmake -B build -G Ninja -DCMAKE_CXX_STANDARD=20
cmake --build build
echo ""
echo "=== Run test ==="
./build/hello_cpp
echo ""
echo "=== Toolchain versions ==="
gcc --version | head -1
g++ --version | head -1
clang --version | head -1
cmake --version | head -1
ninja --version
arm-none-eabi-gcc --version | head -1
echo "=== Test passed ==="
endef
export TEST_SCRIPT_SYSTEM

# ----------------------------------------------------------------------------
# Image management (upstream image)
# ----------------------------------------------------------------------------
.PHONY: save
save:
	mkdir -p dist
	$(CONTAINER_CLI) save -o dist/$(IMAGE_NAME)-gcc-13-clang-20.tar $(IMAGE_NAME)

.PHONY: show-tags
show-tags:
	@echo "$(IMAGE_REF):latest"
	@echo "$(IMAGE_REF):gcc-13-clang-20"

.PHONY: tag-version
tag-version:
	$(CONTAINER_CLI) tag $(IMAGE_NAME) $(IMAGE_REF):gcc-13-clang-20

# ----------------------------------------------------------------------------
# Image management (system image)
# ----------------------------------------------------------------------------
.PHONY: save-system
save-system:
	mkdir -p dist
	$(CONTAINER_CLI) save -o dist/$(SYSTEM_IMAGE_NAME)-system-gcc-13-clang-18.tar $(SYSTEM_IMAGE_NAME)

.PHONY: show-tags-system
show-tags-system:
	@echo "$(SYSTEM_IMAGE_REF):latest"
	@echo "$(SYSTEM_IMAGE_REF):system-gcc-13-clang-18"

.PHONY: tag-system
tag-system:
	$(CONTAINER_CLI) tag $(SYSTEM_IMAGE_NAME) $(SYSTEM_IMAGE_REF):system-gcc-13-clang-18
