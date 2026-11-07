#!/usr/bin/env bash
# ============================================================================
# identity.sh — host-side runtime identity tests for any dev_containers image
# ============================================================================
# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Usage:
#   tests/identity.sh <image> [cli]        # cli: docker (default) or podman
#
# Checks the launch contract of entrypoint.sh (issue #6):
#   - each missing or malformed HOST_* variable stops the container (exit 64)
#     with an actionable message;
#   - a macOS-style identity (UID 501, GID 20) and a Linux-style identity
#     (UID 1001, GID 1001) each produce exactly that account;
#   - restarting the same container reuses the account;
#   - `docker exec -u <uid>` gets the account's HOME (issue #2);
#   - an identity that conflicts with an existing account is rejected;
#   - (docker) files written to a bind mount are owned by HOST_UID:HOST_GID;
#   - (podman) --userns=keep-id with --user 0:0 initializes the account and
#     writes bind-mount files as the host user.
# ============================================================================

set -u

IMAGE="${1:?usage: identity.sh <image> [docker|podman]}"
CLI="${2:-docker}"
EX_USAGE=64

passed=0
failed=0
pass() { echo "PASS  $1"; passed=$((passed + 1)); }
fail() { echo "FAIL  $1"; failed=$((failed + 1)); [ -n "${2:-}" ] && sed 's/^/      /' <<<"$2" | tail -15; }

# run_expect <name> <expected-exit> <output-regex> <run args...>
run_expect() {
    local name="$1" want="$2" pattern="$3"; shift 3
    local out rc
    out="$("$CLI" run --rm "$@" 2>&1)"; rc=$?
    if [ "$rc" = "$want" ] && grep -Eq -- "$pattern" <<<"$out"; then
        pass "$name"
    else
        fail "$name (exit $rc, wanted $want)" "$out"
    fi
}

ID_MAC=(-e HOST_USER=tester -e HOST_UID=501 -e HOST_GID=20)
ID_LINUX=(-e HOST_USER=tester -e HOST_UID=1001 -e HOST_GID=1001)

echo "=== Runtime identity: $IMAGE ($CLI) ==="

if [ "$CLI" = docker ]; then
    # --- Missing and malformed variables -----------------------------------
    run_expect "missing HOST_USER is rejected" $EX_USAGE "HOST_USER is not set" \
        -e HOST_UID=501 -e HOST_GID=20 "$IMAGE" true
    run_expect "missing HOST_UID is rejected" $EX_USAGE "HOST_UID is not set" \
        -e HOST_USER=tester -e HOST_GID=20 "$IMAGE" true
    run_expect "missing HOST_GID is rejected" $EX_USAGE "HOST_GID is not set" \
        -e HOST_USER=tester -e HOST_UID=501 "$IMAGE" true
    run_expect "no variables at all is rejected" $EX_USAGE "is not set" \
        "$IMAGE" true
    run_expect "a non-numeric HOST_UID is rejected" $EX_USAGE "not a valid non-zero numeric UID" \
        -e HOST_USER=tester -e HOST_UID=abc -e HOST_GID=20 "$IMAGE" true
    run_expect "HOST_UID=0 is rejected" $EX_USAGE "not a valid non-zero numeric UID" \
        -e HOST_USER=tester -e HOST_UID=0 -e HOST_GID=0 "$IMAGE" true
    run_expect "an invalid HOST_USER is rejected" $EX_USAGE "not a valid user name" \
        -e HOST_USER="Bad User" -e HOST_UID=501 -e HOST_GID=20 "$IMAGE" true
    run_expect "HOST_USER=root is rejected" $EX_USAGE "not a valid user name" \
        -e HOST_USER=root -e HOST_UID=501 -e HOST_GID=20 "$IMAGE" true
    run_expect "the error explains how to launch" $EX_USAGE "HOST_UID=\"\\\$\\(id -u\\)\"" \
        "$IMAGE" true

    # --- Valid identities --------------------------------------------------
    run_expect "macOS-style identity (501:20) gets exactly that account" 0 "^tester 501 20$" \
        "${ID_MAC[@]}" "$IMAGE" bash -c 'echo "$(id -un) $(id -u) $(id -g)"'
    run_expect "Linux-style identity (1001:1001) gets exactly that account" 0 "^tester 1001 1001$" \
        "${ID_LINUX[@]}" "$IMAGE" bash -c 'echo "$(id -un) $(id -u) $(id -g)"'
    run_expect "HOME is the account's home" 0 "^/home/tester$" \
        "${ID_LINUX[@]}" "$IMAGE" bash -c 'echo "$HOME"'
    run_expect "no dev or ubuntu account exists" 0 "^none$" \
        "${ID_LINUX[@]}" "$IMAGE" bash -c 'getent passwd dev ubuntu || echo none'
    run_expect "sudo is scoped: apt-get allowed, other commands refused" 0 "^scoped$" \
        "${ID_LINUX[@]}" "$IMAGE" bash -c 'sudo -n apt-get --version >/dev/null && ! sudo -n true 2>/dev/null && echo scoped'

    # --- Conflicts ---------------------------------------------------------
    run_expect "a UID owned by another account is rejected" $EX_USAGE "already belongs to account" \
        -e HOST_USER=tester -e HOST_UID=1 -e HOST_GID=1001 "$IMAGE" true
    run_expect "a name owned by a different UID is rejected" $EX_USAGE "does not match" \
        -e HOST_USER=daemon -e HOST_UID=1001 -e HOST_GID=1 "$IMAGE" true

    # --- Restart of the same container -------------------------------------
    cname="identity-restart-$$"
    if "$CLI" create --name "$cname" "${ID_LINUX[@]}" "$IMAGE" bash -c 'id -un' >/dev/null 2>&1 \
       && out1="$("$CLI" start -a "$cname" 2>&1)" \
       && out2="$("$CLI" start -a "$cname" 2>&1)" \
       && [ "$out1" = tester ] && [ "$out2" = tester ]; then
        pass "restarting the same container reuses the account"
    else
        fail "restarting the same container reuses the account" "${out1:-} / ${out2:-}"
    fi
    "$CLI" rm -f "$cname" >/dev/null 2>&1

    # --- docker exec into a running container (#2) --------------------------
    # The images set no HOME, so `docker exec -u <uid>` takes HOME from the
    # account's passwd entry, and login shells can write XDG state there.
    cname="identity-exec-$$"
    out=""
    if "$CLI" run -d --name "$cname" "${ID_LINUX[@]}" "$IMAGE" sleep 120 >/dev/null 2>&1; then
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            "$CLI" exec "$cname" getent passwd tester >/dev/null 2>&1 && break
            sleep 1
        done
        out="$("$CLI" exec -u 1001 "$cname" bash -lc \
            'echo "$HOME"; mkdir -p "$HOME/.local/state/check" && echo writable' 2>&1)"
    fi
    if [ "$out" = "$(printf '/home/tester\nwritable')" ]; then
        pass "docker exec -u <uid> gets the account's HOME and can write XDG state"
    else
        fail "docker exec -u <uid> gets the account's HOME and can write XDG state" "$out"
    fi
    "$CLI" rm -f "$cname" >/dev/null 2>&1

    # --- Bind-mount ownership ----------------------------------------------
    mnt="$(mktemp -d)"; chmod 0777 "$mnt"
    if "$CLI" run --rm -e HOST_USER=tester -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
            -v "$mnt":/workspace "$IMAGE" bash -c 'touch /workspace/owned' >/dev/null 2>&1 \
       && [ "$(stat -c '%u:%g' "$mnt/owned" 2>/dev/null || stat -f '%u:%g' "$mnt/owned")" = "$(id -u):$(id -g)" ]; then
        pass "bind-mount files are owned by HOST_UID:HOST_GID"
    else
        fail "bind-mount files are owned by HOST_UID:HOST_GID"
    fi
    rm -rf "$mnt"
fi

if [ "$CLI" = podman ]; then
    mnt="$(mktemp -d)"
    out="$(podman run --rm --pull=never --userns=keep-id --user 0:0 \
            -e HOST_USER="$(id -un)" -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
            -v "$mnt":/workspace:Z "$IMAGE" \
            bash -c 'echo "$(id -un) $(id -u) $(id -g)"; touch /workspace/owned' 2>&1)"
    if grep -q "^$(id -un) $(id -u) $(id -g)$" <<<"$out" \
       && [ "$(stat -c '%u:%g' "$mnt/owned")" = "$(id -u):$(id -g)" ]; then
        pass "podman keep-id: account initialized; files owned by the host user"
    else
        fail "podman keep-id: account initialized; files owned by the host user" "$out"
    fi
    rm -rf "$mnt"
    run_expect "podman: missing variables are rejected" $EX_USAGE "is not set" \
        --pull=never --userns=keep-id --user 0:0 "$IMAGE" true
fi

echo ""
echo "=== $passed passed, $failed failed ==="
[ "$failed" -eq 0 ]
