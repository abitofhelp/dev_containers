# ============================================================================
# Makefile
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Thin wrapper for the dev_container_rust image.
# Sets Rust-specific variables, then includes the shared Makefile.common.
# ============================================================================

.DEFAULT_GOAL := help

# ----------------------------------------------------------------------------
# Language / project settings
# ----------------------------------------------------------------------------
LANG_DIR     := rust
IMAGE_NAME   := dev-container-rust
PROJECT_NAME ?= dev_container_rust

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
	@echo "Image (Dockerfile — rustup stable, cargo-binstall tools — amd64 + arm64):"
	@echo "  pull                 Pull the image from GHCR"
	@echo "  build                Build the image"
	@echo "  build-no-cache       Build the image without cache"
	@echo "  run                  Run the image interactively"
	@echo "  run-root             Run as root, bypassing the entrypoint (diagnostic)"
	@echo "  run-shell            Open zsh in the user home directory"
	@echo "  test                 Smoke test (nerdctl rootless)"
	@echo "  test-docker          Smoke test (docker rootful)"
	@echo "  test-podman          Smoke test (podman rootless)"
	@echo "  save                 Save the image to dist/"
	@echo "  show-tags            Show suggested tags"
	@echo "  tag-version          Tag local image with Rust version"
	@echo "  tag-latest           Tag local image as latest"
	@echo ""
	@echo "Docker convenience aliases:"
	@echo "  docker-pull          Pull the image with docker"
	@echo "  docker-build         Build the image with docker"
	@echo "  docker-run           Run the image with docker"
	@echo ""
	@echo "Podman convenience aliases:"
	@echo "  podman-pull          Pull the image with podman"
	@echo "  podman-build         Build the image with podman"
	@echo "  podman-run           Run with podman (--userns=keep-id)"
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
EXAMPLE_DIR := examples/hello_rust

define TEST_SCRIPT
set -e
echo "=== Environment ==="
echo "USER=$$(whoami) UID=$$(id -u) GID=$$(id -g) HOME=$$HOME"
echo "DISPLAY_USER=$$DISPLAY_USER"
echo "CONTAINER_RUNTIME=$$CONTAINER_RUNTIME"
echo ""
echo "=== Compile test (cargo build) ==="
cargo build 2>&1
echo ""
echo "=== Run test ==="
cargo run 2>&1
echo ""
echo "=== Toolchain versions ==="
rustc --version
cargo --version
rustup target list --installed | head -6
probe-rs --version
mold --version
arm-linux-gnueabihf-gcc --version | head -1
echo "=== Test passed ==="
endef
export TEST_SCRIPT

# ----------------------------------------------------------------------------
# Image management
# ----------------------------------------------------------------------------
.PHONY: save
save:
	mkdir -p dist
	$(CONTAINER_CLI) save -o dist/$(IMAGE_NAME).tar $(IMAGE_NAME)

.PHONY: show-tags
show-tags:
	@echo "$(IMAGE_REF):latest"
	@echo "$(IMAGE_REF):rust-stable"

.PHONY: tag-version
tag-version:
	$(CONTAINER_CLI) tag $(IMAGE_NAME) $(IMAGE_REF):rust-stable
