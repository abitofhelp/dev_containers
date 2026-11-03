#!/usr/bin/env bash
# ============================================================================
# dev-doctor — report the tool versions installed in the Ada image
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Prints the operating system, toolchain, and library versions in one place.
# Use it when troubleshooting, and to record the toolchain list that a
# release must state. It exits nonzero if any expected tool is missing.
# ============================================================================

set -u

status=0
doc_dir=/usr/share/doc/dev-containers
arch="$(dpkg --print-architecture 2>/dev/null || uname -m)"

# Print one labelled line: the first line of the command's output, or
# "MISSING" (and a failing status) if the command fails.
report() {
    local label="$1"
    shift
    local out
    if out="$("$@" 2>&1 | head -1)" && [ -n "$out" ]; then
        printf '%-20s %s\n' "$label" "$out"
    else
        printf '%-20s %s\n' "$label" "MISSING"
        status=1
    fi
}

echo "=== dev-doctor ==="
report "OS"                 sh -c '. /etc/os-release && echo "$PRETTY_NAME ($(uname -m))"'
report "Alire"              alr --version
report "Alire index"        cat "$doc_dir/alire-index-commit.txt"
report "GNAT"               gnat --version
report "GPRbuild"           gprbuild --version
report "GNATprove"          gnatprove --version
report "libpq"              pkg-config --modversion libpq
report "psql"               psql --version
report "Python"             python3 --version
report "pytest"             pytest --version
report "Typst"              typst --version
report "arm-none-eabi-gcc"  arm-none-eabi-gcc --version
report "arm-linux-gcc"      arm-linux-gnueabihf-gcc --version
report "OpenOCD"            sh -c 'openocd --version 2>&1'
report "st-info"            st-info --version
report "gdb-multiarch"      gdb-multiarch --version
echo ""
echo "Package list:         $doc_dir/packages-$arch.txt"
echo "Alire settings:       ${ALIRE_SETTINGS_DIR:-unset}"

exit "$status"
