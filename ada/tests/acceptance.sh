#!/usr/bin/env bash
# ============================================================================
# acceptance.sh — in-container acceptance tests for the Ada image
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Run inside the image with the ada/ directory mounted at /workspace:
#   bash tests/acceptance.sh
#
# Covers A1–A8 of the modernization plan (issue #3). The offline test (A10)
# needs two container runs and lives in the Makefile (test-offline).
# ============================================================================

set -u

EXPECT_GNAT="${EXPECT_GNAT:-16.1.0}"
EXPECT_GNATPROVE="${EXPECT_GNATPROVE:-16.1.0}"
EXPECT_LIBPQ_MAJOR="${EXPECT_LIBPQ_MAJOR:-18}"

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$TESTS_DIR/../examples/hello_ada" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

passed=0
failed=0

pass() { echo "PASS  $1"; passed=$((passed + 1)); }
fail() { echo "FAIL  $1"; failed=$((failed + 1)); }

check() {
    local name="$1"
    shift
    if "$@" >"$WORK/out.txt" 2>&1; then
        pass "$name"
    else
        fail "$name"
        sed 's/^/      /' "$WORK/out.txt" | tail -20
    fi
}

# Copy a fixture to scratch space so the mounted tree stays clean.
stage() {
    rm -rf "$WORK/$1"
    cp -r "$2" "$WORK/$1"
    echo "$WORK/$1"
}

echo "=== Ada image acceptance (A1–A8) ==="

# A1 — versions.
check "A1  dev-doctor reports every tool"       dev-doctor
check "A1  GNAT is $EXPECT_GNAT"                bash -c "gnat --version | head -1 | grep -q 'GNAT $EXPECT_GNAT'"
check "A1  GNATprove is $EXPECT_GNATPROVE"      bash -c "gnatprove --version | head -1 | grep -q '$EXPECT_GNATPROVE'"
check "A1  alr selects gnat_native $EXPECT_GNAT" bash -c "alr toolchain | grep -E 'gnat_native +$EXPECT_GNAT +Default'"
check "A1  the user's primary group matches the user name" bash -c '[ "$(id -gn)" = "$(id -un)" ]'

# A2 — the native toolchain wins on PATH.
check "A2  gcc/gnat/gnatmake resolve to Alire's GNAT" \
    bash -c 'for t in gcc gnat gnatmake; do [ "$(command -v $t)" = "/opt/alire/gnat/bin/$t" ] || exit 1; done'
check "A2  gprbuild resolves to Alire's GPRbuild" \
    bash -c '[ "$(command -v gprbuild)" = /opt/alire/gprbuild/bin/gprbuild ]'

# A3 — hello_ada builds and runs through Alire.
dir="$(stage hello_ada "$EXAMPLE_DIR")"
check "A3  hello_ada builds and runs"           bash -c "cd '$dir' && alr -n build && alr -n run"

# A4 — a provable fixture proves, and the exit status is 0.
dir="$(stage proof_ok "$TESTS_DIR/proof_ok")"
check "A4  gnatprove proves proof_ok" \
    bash -c "cd '$dir' && gnatprove -P proof_ok.gpr --level=2 --checks-as-errors=on --report=fail"

# A5 — an unprovable fixture fails, with a nonzero status and the expected
# unproved overflow check.
dir="$(stage proof_bad "$TESTS_DIR/proof_bad")"
if (cd "$dir" && gnatprove -P proof_bad.gpr --level=2 --checks-as-errors=on --report=fail) >"$WORK/out.txt" 2>&1; then
    fail "A5  gnatprove rejects proof_bad (exit status was 0)"
    sed 's/^/      /' "$WORK/out.txt" | tail -20
elif grep -q "overflow check might fail" "$WORK/out.txt"; then
    pass "A5  gnatprove rejects proof_bad (nonzero exit, overflow reported)"
else
    fail "A5  gnatprove failed, but not with the expected overflow check"
    sed 's/^/      /' "$WORK/out.txt" | tail -20
fi

# A6 — libpq version.
check "A6  libpq is $EXPECT_LIBPQ_MAJOR.x" \
    bash -c "pkg-config --modversion libpq | grep -q '^$EXPECT_LIBPQ_MAJOR\\.'"

# A7 — the libpq symbols Peanut_PQ needs.
LIBPQ_SO="$(pkg-config --variable=libdir libpq)/libpq.so.5"
missing=""
for sym in PQcancelCreate PQcancelStart PQcancelPoll PQcancelReset \
           PQsocketPoll PQgetCurrentTimeUSec PQsetNoticeReceiver \
           PQconnectStartParams PQsetnonblocking PQtransactionStatus; do
    nm -D --defined-only "$LIBPQ_SO" | grep -qw "$sym" || missing="$missing $sym"
done
if [ -z "$missing" ]; then
    pass "A7  libpq exports every required symbol"
else
    fail "A7  libpq is missing:$missing"
fi

# A8 — link an Ada program with -lpq and run it.
dir="$(stage libpq_check "$TESTS_DIR/libpq_check")"
check "A8  Ada program links with libpq and runs" \
    bash -c "cd '$dir' && gprbuild -q -P libpq_check.gpr && ./bin/libpq_check"

echo ""
echo "=== $passed passed, $failed failed ==="
[ "$failed" -eq 0 ]
