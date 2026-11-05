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
# Covers A1–A9 and the in-container identity checks (I1–I4, issue #6). The
# offline test (A10) needs two container runs and lives in the Makefile
# (test-offline); launch-time identity behaviour is tested from the host by
# tests/identity.sh.
#
# Optional: RUN_ALT_COMPILER=1 also downloads GNAT 15 for a crate that
# requires it (about 1 GB; needs the network).
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
    rm -rf "${WORK:?}/$1"
    cp -r "$2" "$WORK/$1"
    echo "$WORK/$1"
}

echo "=== Ada image acceptance (A1–A9, I1–I4) ==="

# I1–I4 — runtime identity (issue #6). In rootless runtimes the session runs
# as container UID 0, which is the host user, so the UID and sudo checks
# apply only to non-root sessions.
ROOTLESS=0; [ "$(id -u)" = 0 ] && ROOTLESS=1
check "I1  the session account matches HOST_USER, HOST_UID, and HOST_GID" \
    bash -c 'getent passwd "$HOST_USER" | awk -F: -v u="$HOST_UID" -v g="$HOST_GID" "\$3 == u && \$4 == g { ok = 1 } END { exit !ok }"'
if [ "$ROOTLESS" = 0 ]; then
    check "I1  the session runs as that account" \
        bash -c '[ "$(id -un)" = "$HOST_USER" ] && [ "$(id -u)" = "$HOST_UID" ] && [ "$(id -g)" = "$HOST_GID" ]'
fi
check "I2  no dev or ubuntu account exists" \
    bash -c '! getent passwd dev && ! getent passwd ubuntu && ! getent group ubuntu'
check "I3  exactly one account has a home under /home" \
    bash -c '[ "$(getent passwd | awk -F: "\$6 ~ /^\/home\// { n++ } END { print n+0 }")" = 1 ]'
if [ "$ROOTLESS" = 0 ]; then
    check "I4  sudo allows apt-get and the venv pip" \
        bash -c 'sudo -n apt-get --version >/dev/null && sudo -n /opt/venv/bin/pip --version >/dev/null'
    check "I4  sudo refuses other commands" bash -c '! sudo -n true 2>/dev/null'
fi

# A1 — versions.
check "A1  dev-doctor reports every tool"       dev-doctor
check "A1  GNAT is $EXPECT_GNAT"                bash -c "gnat --version | head -1 | grep -q 'GNAT $EXPECT_GNAT'"
check "A1  GNATprove is $EXPECT_GNATPROVE"      bash -c "gnatprove --version | head -1 | grep -q '$EXPECT_GNATPROVE'"
check "A1  alr selects gnat_native $EXPECT_GNAT" bash -c "alr toolchain | grep -E 'gnat_native +$EXPECT_GNAT +Default'"
# The installed tools are read-only for the developer user. In rootless
# runtimes the developer is UID 0 (the host user), which can write anyway.
check "A1  the installed toolchain is read-only for the developer user" \
    bash -c '[ "$(id -u)" = 0 ] || { for f in /opt/alire/gnat/bin/gnat /opt/alire/gprbuild/bin/gprbuild /opt/alire/prefix/bin/gnatprove /opt/venv/bin/python3; do [ ! -w "$f" ] && [ ! -w "$(dirname "$f")" ] || exit 1; done; }'
check "A1  APT is pinned to a dated Ubuntu snapshot" \
    bash -c 'apt-config dump | grep -Eq "^APT::Snapshot \"[0-9]{8}T[0-9]{6}Z\";"'

# A2 — the native toolchain wins on PATH.
check "A2  gcc/gnat/gnatmake resolve to Alire's GNAT" \
    bash -c 'for t in gcc gnat gnatmake; do [ "$(command -v $t)" = "/opt/alire/gnat/bin/$t" ] || exit 1; done'
check "A2  gprbuild resolves to Alire's GPRbuild" \
    bash -c '[ "$(command -v gprbuild)" = /opt/alire/gprbuild/bin/gprbuild ]'

# A9 — a crate whose solution includes the preinstalled gnat_native and
# gprbuild builds as the session user (issue #5). No download is needed.
check "A9  a crate depending on gnat and gprbuild builds" \
    bash -c "cd '$WORK' && alr -n init --bin gnatdep >/dev/null && cd gnatdep \
             && alr -n with gnat_native=$EXPECT_GNAT gprbuild >/dev/null && alr -n build"
if [ "${RUN_ALT_COMPILER:-0}" = 1 ]; then
    check "A9  a crate requiring GNAT 15 downloads it and builds" \
        bash -c "cd '$WORK' && alr -n init --bin gnat15dep >/dev/null && cd gnat15dep \
                 && alr -n with 'gnat_native^15' >/dev/null && alr -n build \
                 && alr -n exec -- gnat --version | head -1 | grep -q 'GNAT 15'"
fi

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
