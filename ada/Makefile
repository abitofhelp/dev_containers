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
GNAT_VERSION      ?= 16.1.0
GNATPROVE_VERSION ?= 16.1.0
GPRBUILD_VERSION  ?= 26.0.1

# ----------------------------------------------------------------------------
# Build arguments passed to docker build
# ----------------------------------------------------------------------------
BUILD_ARGS := --build-arg GNAT_VERSION=$(GNAT_VERSION) \
              --build-arg GNATPROVE_VERSION=$(GNATPROVE_VERSION) \
              --build-arg GPRBUILD_VERSION=$(GPRBUILD_VERSION)

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
	@echo "Ada image (Dockerfile, Alire-managed, amd64 + arm64):"
	@echo "  pull                 Pull the default image from GHCR"
	@echo "  build                Build the default image"
	@echo "  build-no-cache       Build the default image without cache"
	@echo "  run                  Run the default image interactively"
	@echo "  run-root             Run as root, bypassing the entrypoint (diagnostic)"
	@echo "  run-shell            Open zsh in the user home directory"
	@echo "  test                 Acceptance tests A1-A8 (nerdctl rootless)"
	@echo "  test-offline         Acceptance test A10: offline build from prefetched deps"
	@echo "  doctor               Print every tool version in the image"
	@echo "  test-docker          Acceptance tests A1-A8 (docker rootful)"
	@echo "  test-podman          Acceptance tests A1-A8 (podman rootless)"
	@echo "  save                 Save the image to dist/"
	@echo "  show-tags            Show suggested tags"
	@echo "  tag-gnat             Tag local image with GNAT version"
	@echo "  tag-latest           Tag local image as latest"
	@echo ""
	@echo "DEPRECATED system-toolchain image (Dockerfile.system); use the Ada image above:"
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
	@echo "  GNAT_VERSION         GNAT version for Alire build (default: 16.1.0)"
	@echo "  GNATPROVE_VERSION    GNATprove version for Alire build (default: 16.1.0)"
	@echo "  GPRBUILD_VERSION     GPRbuild version for Alire build (default: 26.0.1)"

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
bash /workspace/tests/acceptance.sh
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

# ----------------------------------------------------------------------------
# Diagnostics and the offline acceptance test (Ada image)
# ----------------------------------------------------------------------------
.PHONY: doctor
doctor:
	$(CONTAINER_CLI) run --rm $(IMAGE_NAME) dev-doctor

# A10: phase 1 prefetches the fixture's dependencies with network access
# (sandboxed in the fixture copy); phase 2 builds it with no network and
# checks that the compiler version did not change.
.PHONY: test-offline
test-offline:
	@set -e; work="$$(mktemp -d)"; trap 'rm -rf "$$work"' EXIT; \
	cp -R "$(REPO_ROOT)$(LANG_DIR)/tests/offline_deps/." "$$work/"; \
	echo "=== A10 phase 1: prefetch dependencies (online) ==="; \
	$(CONTAINER_CLI) run --rm -e HOST_UID=$(HOST_UID) -e HOST_GID=$(HOST_GID) -e HOST_USER=$(HOST_USER) \
		-v "$$work":/workspace -w /workspace $(IMAGE_NAME) \
		bash -c 'alr -n settings --set dependencies.shared false && alr -n update'; \
	echo "=== A10 phase 2: build with --network none ==="; \
	$(CONTAINER_CLI) run --rm --network none -e HOST_UID=$(HOST_UID) -e HOST_GID=$(HOST_GID) -e HOST_USER=$(HOST_USER) \
		-v "$$work":/workspace -w /workspace $(IMAGE_NAME) \
		bash -c 'alr -n build && ./bin/offline_deps && gnat --version | head -1 | grep -q "GNAT $(GNAT_VERSION)"'; \
	echo "=== A10 passed ==="
