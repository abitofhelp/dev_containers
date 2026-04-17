# ============================================================================
# Makefile
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Thin wrapper for the Ada images in dev_containers.
# Sets Ada-specific variables, then includes the shared Makefile.common.
# ============================================================================

.DEFAULT_GOAL := help

# ----------------------------------------------------------------------------
# Language / project settings
# ----------------------------------------------------------------------------
LANG_DIR          := ada
IMAGE_NAME        := dev-container-ada
SYSTEM_IMAGE_NAME := $(IMAGE_NAME)-system
PROJECT_NAME      ?= dev_containers

# ----------------------------------------------------------------------------
# Toolchain versions (build-time)
# ----------------------------------------------------------------------------
GNAT_VERSION     ?= 15.2.1
GPRBUILD_VERSION ?= 25.0.1

# ----------------------------------------------------------------------------
# Build arguments passed to docker build
# ----------------------------------------------------------------------------
BUILD_ARGS := --build-arg GNAT_VERSION=$(GNAT_VERSION) --build-arg GPRBUILD_VERSION=$(GPRBUILD_VERSION)

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
	@echo "Alire-managed image (Dockerfile, amd64 only):"
	@echo "  pull                 Pull the default image from GHCR"
	@echo "  build                Build the default image"
	@echo "  build-no-cache       Build the default image without cache"
	@echo "  run                  Run the default image interactively"
	@echo "  run-root             Run as root, bypassing the entrypoint (diagnostic)"
	@echo "  run-shell            Open zsh in the user home directory"
	@echo "  test                 Smoke test (nerdctl rootless)"
	@echo "  test-docker          Smoke test (docker rootful)"
	@echo "  test-podman          Smoke test (podman rootless)"
	@echo "  save                 Save the image to dist/"
	@echo "  show-tags            Show suggested tags"
	@echo "  tag-gnat             Tag local image with GNAT version"
	@echo "  tag-latest           Tag local image as latest"
	@echo ""
	@echo "System-toolchain image (Dockerfile.system, amd64 + arm64):"
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
	@echo "  tag-system           Tag local image with system-gnat-13"
	@echo "  tag-latest-system    Tag local image as latest"
	@echo ""
	@echo "Docker convenience aliases:"
	@echo "  docker-pull          Pull the default image with docker"
	@echo "  docker-pull-system   Pull the system image with docker"
	@echo "  docker-build         Build the default image with docker"
	@echo "  docker-build-system  Build the system image with docker"
	@echo "  docker-run           Run the default image with docker"
	@echo "  docker-run-system    Run the system image with docker"
	@echo ""
	@echo "Podman convenience aliases:"
	@echo "  podman-pull          Pull the default image with podman"
	@echo "  podman-pull-system   Pull the system image with podman"
	@echo "  podman-build         Build the default image with podman"
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
	@echo "  GNAT_VERSION         GNAT version for Alire build (default: 15.2.1)"
	@echo "  GPRBUILD_VERSION     GPRBuild version for Alire build (default: 25.0.1)"

# ----------------------------------------------------------------------------
# Test scripts
# ----------------------------------------------------------------------------
EXAMPLE_DIR := examples/hello_ada

define TEST_SCRIPT
set -e
echo "=== Environment ==="
echo "USER=$$(whoami) UID=$$(id -u) GID=$$(id -g) HOME=$$HOME"
echo "DISPLAY_USER=$$DISPLAY_USER"
echo "CONTAINER_RUNTIME=$$CONTAINER_RUNTIME"
echo ""
echo "=== Build + run test ==="
alr run
echo ""
echo "=== Toolchain versions ==="
alr exec -- gnat --version | head -1
alr exec -- gprbuild --version | head -1
alr --version | head -1
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
echo "=== Build + run test ==="
alr run
echo ""
echo "=== Toolchain versions ==="
gnat --version | head -1
gprbuild --version | head -1
alr --version | head -1
echo "=== Test passed ==="
endef
export TEST_SCRIPT_SYSTEM

# ----------------------------------------------------------------------------
# Image management (default image)
# ----------------------------------------------------------------------------
.PHONY: save
save:
	mkdir -p dist
	$(CONTAINER_CLI) save -o dist/$(IMAGE_NAME)-gnat-$(GNAT_VERSION).tar $(IMAGE_NAME)

.PHONY: show-tags
show-tags:
	@echo "$(IMAGE_REF):latest"
	@echo "$(IMAGE_REF):gnat-$(GNAT_VERSION)"
	@echo "$(IMAGE_REF):gnat-$(GNAT_VERSION)-gprbuild-$(GPRBUILD_VERSION)"

.PHONY: tag-gnat
tag-gnat:
	$(CONTAINER_CLI) tag $(IMAGE_NAME) $(IMAGE_REF):gnat-$(GNAT_VERSION)
	$(CONTAINER_CLI) tag $(IMAGE_NAME) $(IMAGE_REF):gnat-$(GNAT_VERSION)-gprbuild-$(GPRBUILD_VERSION)

# ----------------------------------------------------------------------------
# Image management (system image)
# ----------------------------------------------------------------------------
.PHONY: save-system
save-system:
	mkdir -p dist
	$(CONTAINER_CLI) save -o dist/$(SYSTEM_IMAGE_NAME)-system-gnat-13.tar $(SYSTEM_IMAGE_NAME)

.PHONY: show-tags-system
show-tags-system:
	@echo "$(SYSTEM_IMAGE_REF):latest"
	@echo "$(SYSTEM_IMAGE_REF):system-gnat-13"

.PHONY: tag-system
tag-system:
	$(CONTAINER_CLI) tag $(SYSTEM_IMAGE_NAME) $(SYSTEM_IMAGE_REF):system-gnat-13
