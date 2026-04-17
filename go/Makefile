# ============================================================================
# Makefile
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Thin wrapper for the Go image in dev_containers.
# Sets Go-specific variables, then includes the shared Makefile.common.
# ============================================================================

.DEFAULT_GOAL := help

# ----------------------------------------------------------------------------
# Language / project settings
# ----------------------------------------------------------------------------
LANG_DIR     := go
IMAGE_NAME   := dev-container-go
PROJECT_NAME ?= dev_containers

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
	@echo "Image (Dockerfile — Go 1.26.1, protobuf, Bazelisk — amd64 + arm64):"
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
	@echo "  tag-version          Tag local image with Go version"
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
EXAMPLE_DIR := examples/hello_go

define TEST_SCRIPT
set -e
echo "=== Environment ==="
echo "USER=$$(whoami) UID=$$(id -u) GID=$$(id -g) HOME=$$HOME"
echo "DISPLAY_USER=$$DISPLAY_USER"
echo "CONTAINER_RUNTIME=$$CONTAINER_RUNTIME"
echo ""
echo "=== Compile test (go build) ==="
go build -o hello_go .
echo ""
echo "=== Run test ==="
./hello_go
echo ""
echo "=== Cross-compilation test ==="
GOOS=darwin GOARCH=amd64 go build -o /dev/null .
GOOS=darwin GOARCH=arm64 go build -o /dev/null .
GOOS=linux GOARCH=amd64 go build -o /dev/null .
GOOS=linux GOARCH=arm64 go build -o /dev/null .
GOOS=windows GOARCH=amd64 go build -o /dev/null .
echo "Cross-compilation: PASSED"
echo ""
echo "=== Toolchain versions ==="
go version
gopls version 2>&1 | head -1
dlv version 2>&1 | head -1
staticcheck --version
golangci-lint --version 2>&1 | head -1
protoc --version
buf --version
echo "=== Test passed ==="
endef
export TEST_SCRIPT

# ----------------------------------------------------------------------------
# Image management
# ----------------------------------------------------------------------------
.PHONY: save
save:
	mkdir -p dist
	$(CONTAINER_CLI) save -o dist/$(IMAGE_NAME)-go-1.26.1.tar $(IMAGE_NAME)

.PHONY: show-tags
show-tags:
	@echo "$(IMAGE_REF):latest"
	@echo "$(IMAGE_REF):go-1.26.1"

.PHONY: tag-version
tag-version:
	$(CONTAINER_CLI) tag $(IMAGE_NAME) $(IMAGE_REF):go-1.26.1
