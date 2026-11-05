#!/bin/bash
# ============================================================================
# entrypoint.sh
# ============================================================================
# Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Shared runtime entrypoint for all dev_containers images.
#
# The image contains no human account.  At startup this script creates
# exactly one account from the identity the launcher declares:
#
#   HOST_USER  — user name      (required)
#   HOST_UID   — numeric UID    (required)
#   HOST_GID   — numeric GID    (required)
#
# The variables declare the identity of the person who launched the
# container; authentication happens on the host, not here.  If any variable
# is missing or invalid, or if it conflicts with an existing account, the
# container refuses to start (exit 64).  There is no fallback account.
#
# Runtime modes, chosen from the shape of /proc/self/uid_map (its host IDs
# are relative to the parent user namespace, so they are not compared with
# HOST_UID across namespaces):
#
#   * Identity map over the full ID range (rootful Docker, Docker Desktop):
#     drop to the account via gosu.
#   * Container HOST_UID maps to 0, the owner of the parent namespace, while
#     container root does not (rootless Podman with --userns=keep-id): drop
#     to the account via gosu, which is the host user.
#   * Container root maps to a non-zero UID (rootless nerdctl or rootless
#     Docker): stay as container UID 0, which is the host user. Dropping
#     privileges would map to a subordinate UID that cannot write the
#     bind-mounted workspace.
#   * Container root maps to 0 over a partial range (rootless Podman without
#     keep-id): refuse, and say how to launch.
#
# Images may declare extra groups for the user, one per line, in
# /etc/dev-containers/user-groups, and extra commands the user may run with
# sudo, one absolute path per line, in /etc/dev-containers/sudo-commands.
#
# ============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------
readonly DEFAULT_SHELL="/usr/bin/zsh"
readonly EX_USAGE=64
readonly CONFIG_DIR="/etc/dev-containers"
readonly USER_GROUPS_FILE="${CONFIG_DIR}/user-groups"
readonly SUDO_COMMANDS_FILE="${CONFIG_DIR}/sudo-commands"
readonly SUDOERS_FILE="/etc/sudoers.d/dev-tools"
# Package managers the user may run with sudo in every image.
readonly BASE_SUDO_COMMANDS=("/usr/bin/apt-get" "/usr/bin/apt")

# ----------------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------------
log_info() {
    echo "[entrypoint] $*" >&2
}

log_error() {
    echo "[entrypoint] Error: $*" >&2
}

# Print an error with launch guidance and exit with EX_USAGE.
die_usage() {
    log_error "$*"
    cat >&2 <<'EOF'
[entrypoint] Start the container with your host identity, for example:
[entrypoint]   docker run -it --rm \
[entrypoint]     -e HOST_USER="$(whoami)" -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
[entrypoint]     -v "$PWD":/workspace <image>
[entrypoint] The adat-style launchers and the project Makefiles set these
[entrypoint] variables for you.  See "Runtime Identity" in the README.
EOF
    exit "${EX_USAGE}"
}

# ----------------------------------------------------------------------------
# Validation
# ----------------------------------------------------------------------------
validate_inputs() {
    local name
    for name in HOST_USER HOST_UID HOST_GID; do
        if [ -z "${!name:-}" ]; then
            die_usage "${name} is not set. HOST_USER, HOST_UID, and HOST_GID are all required."
        fi
    done
    if ! [[ "${HOST_UID}" =~ ^[0-9]+$ ]] || [ "${HOST_UID}" -eq 0 ]; then
        die_usage "HOST_UID '${HOST_UID}' is not a valid non-zero numeric UID."
    fi
    if ! [[ "${HOST_GID}" =~ ^[0-9]+$ ]]; then
        die_usage "HOST_GID '${HOST_GID}' is not a valid numeric GID."
    fi
    if ! [[ "${HOST_USER}" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || [ "${HOST_USER}" = "root" ]; then
        die_usage "HOST_USER '${HOST_USER}' is not a valid user name (lowercase letters, digits, '_' and '-'; not root)."
    fi
}

# ----------------------------------------------------------------------------
# User-namespace mapping
# ----------------------------------------------------------------------------
# Print the parent-namespace UID that container UID $1 maps to, or nothing
# if it is unmapped.
host_uid_of() {
    local cuid="$1"
    if [ ! -r /proc/self/uid_map ]; then
        echo "${cuid}"
        return 0
    fi
    awk -v c="${cuid}" '
        c >= $1 && c < $1 + $3 { print $2 + (c - $1); exit }
    ' /proc/self/uid_map
}

# Succeed if the user namespace is the full identity map (no user namespace
# in effect), as under rootful Docker and Docker Desktop.
is_identity_map() {
    [ ! -r /proc/self/uid_map ] && return 0
    awk '$1 == 0 && $2 == 0 && $3 == 4294967295 { found = 1 } END { exit !found }' /proc/self/uid_map
}

# Decide how the session runs: "drop" (gosu to the account) or "stay"
# (remain container UID 0, which is the host user). Exits on an unsupported
# mapping.
choose_runtime_mode() {
    local root_maps_to user_maps_to
    root_maps_to="$(host_uid_of 0)"
    user_maps_to="$(host_uid_of "${HOST_UID}")"
    if is_identity_map; then
        RUNTIME_MODE="drop"
    elif [ "${user_maps_to}" = "0" ] && [ "${root_maps_to}" != "0" ]; then
        RUNTIME_MODE="drop"
    elif [ -n "${root_maps_to}" ] && [ "${root_maps_to}" != "0" ]; then
        RUNTIME_MODE="stay"
        if [ "${root_maps_to}" != "${HOST_UID}" ]; then
            log_info "Note: container root maps to host UID ${root_maps_to}, not HOST_UID ${HOST_UID}; files are written as host UID ${root_maps_to}."
        fi
    else
        die_usage "This user-namespace mapping is not supported (container root maps to UID 0 over a partial range). With rootless Podman, start the container with --userns=keep-id --user 0:0."
    fi
}

# ----------------------------------------------------------------------------
# Account setup (runs as container root)
# ----------------------------------------------------------------------------
ensure_group() {
    local by_gid by_name
    by_gid="$(getent group "${HOST_GID}" || true)"
    if [ -n "${by_gid}" ]; then
        # Reuse the existing group with this GID; only its name may differ
        # (for example, macOS GID 20 is "dialout" in Ubuntu).
        return 0
    fi
    by_name="$(getent group "${HOST_USER}" || true)"
    if [ -n "${by_name}" ]; then
        die_usage "Group '${HOST_USER}' already exists with a different GID ($(echo "${by_name}" | cut -d: -f3)); cannot create GID ${HOST_GID}."
    fi
    groupadd --gid "${HOST_GID}" "${HOST_USER}"
}

ensure_user() {
    local by_name by_uid
    by_name="$(getent passwd "${HOST_USER}" || true)"
    by_uid="$(getent passwd "${HOST_UID}" || true)"

    if [ -z "${by_name}" ] && [ -z "${by_uid}" ]; then
        useradd --uid "${HOST_UID}" --gid "${HOST_GID}" \
            -K UID_MIN=1 -K UID_MAX=4294967294 \
            --create-home --skel /etc/skel \
            --shell "${DEFAULT_SHELL}" "${HOST_USER}"
        return 0
    fi

    # An existing account is reused only if it matches exactly.  This covers
    # a restarted container and the entry Podman --userns=keep-id may add.
    if [ -n "${by_name}" ] \
       && [ "$(echo "${by_name}" | cut -d: -f3)" = "${HOST_UID}" ] \
       && [ "$(echo "${by_name}" | cut -d: -f4)" = "${HOST_GID}" ]; then
        return 0
    fi

    if [ -n "${by_name}" ]; then
        die_usage "Account '${HOST_USER}' already exists as $(echo "${by_name}" | cut -d: -f1,3,4), which does not match ${HOST_USER}:${HOST_UID}:${HOST_GID}."
    fi
    die_usage "UID ${HOST_UID} already belongs to account '$(echo "${by_uid}" | cut -d: -f1)'; it cannot be assigned to '${HOST_USER}'."
}

ensure_home() {
    local home
    home="$(getent passwd "${HOST_USER}" | cut -d: -f6)"
    if [ ! -d "${home}" ]; then
        # An account reused from elsewhere (e.g., Podman keep-id) may lack a
        # home; populate it from /etc/skel.
        mkdir -p "${home}"
        cp -a /etc/skel/. "${home}/"
        chown -R "${HOST_UID}:${HOST_GID}" "${home}"
    fi
    install -d -o "${HOST_UID}" -g "${HOST_GID}" \
        "${home}/.local" "${home}/.local/bin" "${home}/.cache"
    TARGET_HOME="${home}"
}

add_supplementary_groups() {
    local group
    [ -r "${USER_GROUPS_FILE}" ] || return 0
    while IFS= read -r group || [ -n "${group}" ]; do
        group="${group%%#*}"
        group="${group//[[:space:]]/}"
        [ -n "${group}" ] || continue
        if getent group "${group}" >/dev/null; then
            usermod -aG "${group}" "${HOST_USER}"
        else
            log_error "Group '${group}' listed in ${USER_GROUPS_FILE} does not exist; skipped."
        fi
    done < "${USER_GROUPS_FILE}"
}

# Allow the user to install software with sudo: apt in every image, plus
# any commands the image lists.  This is an operational guardrail, not a
# security boundary: package installation runs code as root.
write_sudoers() {
    local commands=("${BASE_SUDO_COMMANDS[@]}") line tmp
    if [ -r "${SUDO_COMMANDS_FILE}" ]; then
        while IFS= read -r line || [ -n "${line}" ]; do
            line="${line%%#*}"
            line="${line//[[:space:]]/}"
            [ -n "${line}" ] || continue
            commands+=("${line}")
        done < "${SUDO_COMMANDS_FILE}"
    fi
    tmp="$(mktemp)"
    {
        echo "# Written by entrypoint.sh at container start."
        printf '%s ALL=(root) NOPASSWD: ' "${HOST_USER}"
        (IFS=','; echo "${commands[*]}" | sed 's/,/, /g')
    } > "${tmp}"
    if ! visudo -cqf "${tmp}"; then
        rm -f "${tmp}"
        log_error "The generated sudoers rule is invalid; sudo is disabled for this session."
        return 0
    fi
    install -m 0440 -o root -g root "${tmp}" "${SUDOERS_FILE}"
    rm -f "${tmp}"
}

# ----------------------------------------------------------------------------
# Session environment
# ----------------------------------------------------------------------------
setup_session_env() {
    export HOME="${TARGET_HOME}"
    export USER="${HOST_USER}"
    export LOGNAME="${HOST_USER}"
    export DISPLAY_USER="${HOST_USER}"
    export PATH="${HOME}/.local/bin:${PATH}"
}

setup_rust_runtime_home() {
    # The Rust image keeps the toolchain and preinstalled cargo subcommands in
    # /opt.  Cargo's mutable state (registries, git checkouts, user-installed
    # tools) lives in the user's home.
    if [ ! -d /opt/cargo/bin ]; then
        return 0
    fi
    export CARGO_HOME="${HOME}/.cargo"
    export PATH="${CARGO_HOME}/bin:/opt/cargo/bin:${PATH}"
    if [ "$(id -u)" = "0" ]; then
        install -d -o "${HOST_UID}" -g "${HOST_GID}" \
            "${CARGO_HOME}" "${CARGO_HOME}/bin" "${CARGO_HOME}/git" "${CARGO_HOME}/registry"
    else
        mkdir -p "${CARGO_HOME}/bin" "${CARGO_HOME}/git" "${CARGO_HOME}/registry"
    fi
}

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
export IN_CONTAINER=1
validate_inputs

if is_identity_map; then
    export CONTAINER_RUNTIME="docker"
else
    export CONTAINER_RUNTIME="rootless"
fi

if [ "$(id -u)" != "0" ]; then
    # Started as non-root (for example `podman --userns=keep-id` without
    # `--user 0:0`, or `docker run --user`).  Nothing can be created, so the
    # account must already exist and match exactly.
    if [ "$(id -u)" != "${HOST_UID}" ]; then
        die_usage "The container runs as UID $(id -u), but HOST_UID is ${HOST_UID}."
    fi
    if ! getent passwd "${HOST_USER}" | awk -F: -v u="${HOST_UID}" -v g="${HOST_GID}" \
            '$3 == u && $4 == g { found = 1 } END { exit !found }'; then
        die_usage "Started as non-root, and no account ${HOST_USER}:${HOST_UID}:${HOST_GID} exists. Start the container as root so it can create the account (for Podman: --user 0:0)."
    fi
    TARGET_HOME="$(getent passwd "${HOST_USER}" | cut -d: -f6)"
    setup_session_env
    setup_rust_runtime_home
    exec "$@"
fi

choose_runtime_mode
ensure_group
ensure_user
ensure_home
add_supplementary_groups
write_sudoers
setup_session_env
setup_rust_runtime_home

if [ "${RUNTIME_MODE}" = "stay" ]; then
    # Rootless runtime: container UID 0 is the host user.  Stay UID 0 so the
    # bind-mounted workspace remains writable.
    exec "$@"
fi

exec gosu "${HOST_USER}" "$@"
