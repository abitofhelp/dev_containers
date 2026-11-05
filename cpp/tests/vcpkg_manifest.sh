#!/usr/bin/env bash
# ============================================================================
# vcpkg_manifest.sh — non-root vcpkg manifest-mode acceptance test (cpp image)
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Run inside the cpp image with the cpp/ directory mounted at /workspace:
#   bash tests/vcpkg_manifest.sh
#
# Builds a manifest-mode project that depends on fmt (downloaded and built by
# vcpkg) as the session user, then checks that no tracked file in /opt/vcpkg
# changed. Needs the network.
# ============================================================================

set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp -r "$(dirname "$0")/vcpkg_manifest" "$WORK/proj"
cd "$WORK/proj"

cmake -S . -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build
./build/vcpkg_manifest_check

changes="$(git -C /opt/vcpkg status --porcelain --untracked-files=no)"
if [ -n "$changes" ]; then
    echo "FAIL: tracked files under /opt/vcpkg changed" >&2
    exit 1
fi
[ ! -w /opt/vcpkg/scripts ] || { echo "FAIL: /opt/vcpkg/scripts is writable" >&2; exit 1; }
echo "PASS: vcpkg manifest install and build as $(id -un); /opt/vcpkg unchanged"
