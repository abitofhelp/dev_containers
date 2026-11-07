<!-- ====================================================================== -->
<!-- USER_GUIDE.md                                                          -->
<!-- ====================================================================== -->
<!-- Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.               -->
<!-- SPDX-License-Identifier: BSD-3-Clause                                  -->
<!-- See LICENSE file in the project root.                                  -->
<!-- ====================================================================== -->

# User Guide: dev_containers

**Version**: 2.0.0
**Date**: 2026-11-05
**Authors**: Michael Gardner, Claude (Anthropic), GPT (OpenAI)

---

## 0. Choosing an Image

### 0.1 Ada

| Image | Base | Compiler | Architectures |
|-------|------|----------|---------------|
| `dev-container-ada` | Ubuntu 26.04 | Alire: GNAT 16.1.0, GPRbuild 26.0.1, GNATprove 16.1.0 | amd64, arm64 |

`dev-container-ada` is the single Ada image, on both amd64 and arm64
(including Apple Silicon). It also provides libpq 18 (`libpq-dev`) and
`psql` for PostgreSQL client development, Typst for formal documents, and
the embedded tools listed in section 6.

- The toolchain lives under `/opt/alire` (Alire's settings, cache,
  toolchains, and install prefix), so it does not depend on `HOME`.
- The installed GNAT, GPRbuild, GNATprove, and Python virtual environment
  are read-only for the session user. Alire's settings, index, and cache
  are writable, and Alire can add other toolchains that a project requires
  (they are installed beside the default ones). An added toolchain is
  downloaded on first use (GNAT is about 1 GB) and, because containers are
  normally started with `--rm`, again in each new container. For Python
  packages, prefer a project virtual environment; `sudo /opt/venv/bin/pip
  install …` adds them to the shared one.
- The Alire index is pinned to the commit recorded in
  `/usr/share/doc/dev-containers/alire-index-commit.txt` and does not
  refresh automatically. `alr index --update-all` fetches newer crates, but
  it changes that container's index and departs from the image's recorded
  baseline. Builds there may then resolve different crate versions.
- APT is pinned to the dated Ubuntu snapshot in
  `/etc/apt/apt.conf.d/50snapshot`, so `sudo apt-get install` adds packages
  that match the image. Delete that file to install from the live archive.
- Run `dev-doctor` inside the container (or `make -f ada/Makefile doctor`)
  to print every tool version.
- GPRbuild is Alire's `gprbuild` crate 26.0.1; its binary reports
  `GPRBUILD 26.0.0` in `gprbuild --version`.
- **Known limitation (libadalang):** the current Alire release of `libgpr2`
  requires a GNAT earlier than 16. Projects that use `libadalang` (or
  `libgpr2`) therefore get an Alire-selected GNAT 15.x, downloaded on first
  use (see the added-toolchain note above), instead of the image's GNAT
  16.1.0. Check the selected compiler with
  `alr exec -- gnat --version`. This will be revisited when updated upstream
  packages are published.
- **PostgreSQL:** `psql` and libpq (`libpq-dev`) are installed, but no
  database server is. Connect to an existing PostgreSQL instance or run one
  in a separate container.
- **GNATprove:** run SPARK proofs on a GPR project directly, for example:

  ```bash
  gnatprove -P my_project.gpr --level=2 --checks-as-errors=on --report=fail
  ```

  The command exits with a nonzero status when a check is not proved.

**Deprecated:** `dev-container-ada-system` (Ubuntu 24.04, `gnat-13`) was the
arm64 workaround from before Alire shipped an arm64 GNAT. No new versions
are published, and its Dockerfile was removed in v2.0.0; its existing GHCR
tags remain available. Use `dev-container-ada` instead.

### 0.2 C++

| Image | Base | Compiler | Architectures |
|-------|------|----------|---------------|
| `dev-container-cpp` | Ubuntu 24.04 | Clang 20, CMake 4.x, vcpkg | amd64, arm64 |
| `dev-container-cpp-system` | Ubuntu 24.04 | GCC 13, Clang 18, CMake 3.28 | amd64, arm64 |

The default uses upstream LLVM and Kitware repositories for the latest
toolchain.  The system image uses only Ubuntu apt packages for supply-chain
auditability.

**vcpkg (`dev-container-cpp`):** use manifest mode (a `vcpkg.json` in the
project, with CMake's `-DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake`).
Dependencies install into the project's `vcpkg_installed/`, and the binary
cache is `~/.cache/vcpkg/archives`. The vcpkg checkout in `/opt/vcpkg` is
read-only; the session user belongs to the `vcpkg` group, which may write
only the lock file and the `buildtrees`, `packages`, and `downloads`
scratch directories. Classic-mode `vcpkg install` into the shared tree is
not supported.

### 0.3 Go

Single image: `dev-container-go` on Ubuntu 24.04 with Go 1.26.1 from the
official tarball.  Includes protobuf/gRPC stack (protoc, buf, protoc-gen-go)
and Bazelisk.

### 0.4 Rust

Single image: `dev-container-rust` on Ubuntu 24.04 with Rust 1.95.0 via
rustup. Includes embedded targets (Cortex-M0 through M33), the
`thumbv7em-none-eabihf` target used by Teensy 4.1, `cargo objcopy` via
`cargo-binutils`, `teensy_loader_cli`, probe-rs, cargo-binstall, and mold
linker.

---

## 1. Prerequisites

### 1.1 macOS (primary development)

Install Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop/).
Docker Desktop provides both `docker` CLI and a Linux VM with containerd.
The Makefile auto-detects `docker` on macOS.

### 1.2 Linux — rootless nerdctl + containerd

This is the recommended Linux runtime.  Complete these one-time setup steps
on Ubuntu 24.04:

**Step 1 — Allow unprivileged user namespaces:**

Ubuntu 24.04 restricts these by default via AppArmor.

```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
sudo sh -c 'echo "kernel.apparmor_restrict_unprivileged_userns=0" \
    >> /etc/sysctl.d/99-rootless.conf'
```

**Step 2 — Install rootless containerd:**

```bash
containerd-rootless-setuptool.sh install
```

This creates a user-level containerd service.  It coexists with any
system-level containerd (e.g., for Kubernetes).

**Step 3 — Install BuildKit (required for `nerdctl build`):**

```bash
containerd-rootless-setuptool.sh install-buildkit
```

BuildKit provides the build engine for `nerdctl build`.  Without it,
pulling and running pre-built images works, but local image builds fail.

**Step 4 — Enable linger (headless servers):**

```bash
sudo loginctl enable-linger $(whoami)
```

Without linger, your systemd session (and rootless containerd) terminates
when you disconnect SSH.  A second terminal would not be able to see
containers started from the first.

**Step 5 — Verify XDG_RUNTIME_DIR:**

```bash
echo $XDG_RUNTIME_DIR    # Should show /run/user/<uid>
```

If empty, add to `~/.zshrc`:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
```

**Step 6 — Verify:**

```bash
nerdctl ps    # Should return without errors
```

The `container_run.py` launcher automatically checks for linger and
`XDG_RUNTIME_DIR` on Linux and attempts to fix them.

### 1.3 Linux — Docker rootful (optional)

Docker is supported for testing and CI but is not the primary runtime.

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-buildx
sudo usermod -aG docker "$USER"
# Log out and back in to apply the group change.
```

### 1.4 Podman (optional)

```bash
sudo apt-get install -y podman crun
```

Podman rootless runs with `--userns=keep-id --user 0:0` and the three
`HOST_*` variables: the host UID keeps its value in the container, and the
entrypoint starts as container root (a subordinate UID, not host root),
creates the account, and drops to it. See the `podman-run` Makefile targets.

### 1.5 Windows 11

Windows is supported **through WSL2 only**:

1. Install Docker Desktop with the WSL2 back end, and a WSL2 distribution
   (for example, Ubuntu).
2. Open a WSL2 shell and keep your source in the WSL file system (for
   example `~/src/my_project`), not on a mounted Windows drive (`/mnt/c/...`).
3. Launch from the project directory, exactly as on Linux.

WSL2 provides the POSIX user and group IDs that the containers require.
Launching from PowerShell or CMD, or with the source on `C:\`, is not
supported: there is no POSIX UID or GID, file ownership does not map, and
builds are slow. The launcher (`container_run.py`) stops with a message in
that case.

---

## 2. Design Goals

1. **One image, any developer** — pull from GHCR and run.  User identity
   is declared at run time and required; no account is baked in at build
   time.
2. **Bind-mounted source** — host project directory is mounted into the
   container.  Edits inside are live on the host.
3. **Correct file permissions** — container process runs with the host
   user's UID/GID.
4. **Works on every supported host** — Docker (Linux, macOS, Windows 11
   through WSL2), rootless nerdctl, and rootless Podman. Kubernetes is
   possible but not tested.
5. **Secure by default** — no unowned accounts; non-root in rootful
   runtimes; UID 0 is unprivileged in rootless runtimes; `sudo` limited to
   package installation.

---

## 3. Runtime Identity

The image contains no human account.  At startup, `entrypoint.sh` creates
exactly one from the identity the launcher declares in three **required**
environment variables (the container does not authenticate anyone; that
happens on the host):

```
Host                          Container
─────                         ─────────
$(whoami)  → HOST_USER  ───→  entrypoint.sh creates the account
$(id -u)   → HOST_UID   ───→  with this UID
$(id -g)   → HOST_GID   ───→  and this primary GID
$(pwd)     → -v mount   ───→  /workspace (bind mount)
```

### Validation

| Condition | Result |
|-----------|--------|
| A variable is missing, or a value is invalid (`HOST_UID=0`, `HOST_USER=root`, a name with uppercase letters or spaces) | Exit 64 with launch guidance |
| An account with the same name, UID, and GID exists (a restarted container) | Reused |
| The name or the UID belongs to a different account | Exit 64 |
| A group with `HOST_GID` exists | Reused under its own name |

Per-user files come from `/etc/skel`. Images may list extra groups for the
user in `/etc/dev-containers/user-groups` (the C++ image lists `vcpkg`) and
extra `sudo` commands in `/etc/dev-containers/sudo-commands`.

### Runtime mode

The entrypoint reads the shape of `/proc/self/uid_map`. Its host IDs are
relative to the parent user namespace (under rootless Podman, the user who
runs Podman is UID 0 there), so they are not compared with `HOST_UID`
directly:

| Mapping | Runtime | Action |
|---------|---------|--------|
| Identity map over the full ID range | Rootful Docker, Docker Desktop | Create the account; drop to it via `gosu` |
| Container `HOST_UID` maps to 0, and container root does not | Rootless Podman with `--userns=keep-id` | Create the account; drop to it via `gosu` (it is the host user) |
| Container root maps to a non-zero UID | Rootless nerdctl or rootless Docker | Create the account (home, prompt); stay UID 0, which is the host user. A note is printed if that UID is not `HOST_UID` |
| Container root maps to 0 over a partial range | Rootless Podman without `keep-id` | Exit 64 with launch guidance |
| Started as non-root | For example `docker run --user` | The matching account must already exist; otherwise exit 64 |

---

## 4. Makefile Architecture

Each language has a thin Makefile that sets variables and includes
`Makefile.common`:

```makefile
LANG_DIR     := ada
IMAGE_NAME   := dev-container-ada
BUILD_ARGS   := --build-arg GNAT_VERSION=16.1.0
include ../Makefile.common
```

`Makefile.common` provides all shared targets: `build`, `run`, `test`,
`pull`, `clean`, Docker/Podman convenience aliases, and `inspect`.

The build context is always the **repo root** so that Dockerfiles can
COPY shared files (`entrypoint.sh`, `LICENSE`):

```
docker build -f ada/Dockerfile -t dev-container-ada .
```

Run language Makefiles from the repository root with `-f <lang>/Makefile`:

```bash
make -f rust/Makefile docker-build
make -f rust/Makefile test-docker
make -f rust/Makefile test-teensy41-docker
```

The `docker-*` and `podman-*` aliases are first-class targets. They must not
shell out to a second unqualified `make` because that can lose the selected
language Makefile on some hosts. Instead, the aliases set `CONTAINER_CLI` and
reuse the shared target in the same invocation.

### Container launch

The `run` targets delegate to `container_run.py` from the
[hybrid_scripts_python](https://github.com/abitofhelp/hybrid_scripts_python)
repository.  This Python script handles:

- Platform CLI detection (macOS → docker, Linux → nerdctl, Windows → docker)
- Sequential container naming (`image-1`, `-2`, `-3`)
- The required HOST_UID / HOST_GID / HOST_USER, for every CLI (it stops on
  native Windows and asks for a WSL2 shell)
- Podman `--userns=keep-id --user 0:0`
- Linux linger and XDG_RUNTIME_DIR checks

---

## 5. Mounting the Right Directory

The `-v` flag determines which host directories are visible inside the
container.

| Scenario | What to mount |
|----------|---------------|
| Project with published deps only | Project directory (default) |
| Project with relative path pins (Ada) | Common ancestor of project + deps |
| Entire language workspace | Language source root |

For Ada projects with relative Alire pins:

```bash
cd ~/Ada/github.com/abitofhelp
make -f ~/containers/dev_containers/ada/Makefile run
```

This mounts the entire `abitofhelp` directory so that relative pins such as
`../functional` resolve inside the container.

---

## 6. Embedded Board Support

Ada, C++, and Rust images include embedded-development support. The exact
tooling differs by language image. The Ada image provides the ARM GCC
cross-compilers, OpenOCD, ST-Link tools, and `gdb-multiarch`; an Ada
cross-compiler (for example, Alire's `gnat_arm_elf`) is not preinstalled.

| Board / Target | SoC / CPU | Core | Runtime | Image support |
|----------------|-----------|------|---------|---------------|
| STM32F769I Discovery | STM32F769NI | Cortex-M7 | Bare metal | Ada/C++ ARM bare-metal tooling |
| STM32MP135F Discovery | STM32MP135F | Cortex-A7 | Linux | Ada/C++/Rust ARM Linux tooling |
| Generic Cortex-M Rust | Board-specific | Cortex-M0 through M33 | Rust `no_std` bare metal | Rust `thumb*` targets plus `probe-rs` / `cargo-binutils` |
| Teensy 4.1 | NXP i.MX RT1062 | Cortex-M7 | Rust `no_std` bare metal | `thumbv7em-none-eabihf`, `teensy4-bsp`, `cargo objcopy`, `teensy_loader_cli` |

### 6.1 Rust target selection

The Rust image installs several embedded targets. The target selects the CPU
architecture and ABI; it does not select a board by itself.

| Rust target | Typical use | Output |
|-------------|-------------|--------|
| `thumbv6m-none-eabi` | Cortex-M0/M0+ bare metal | ELF / BIN / HEX |
| `thumbv7m-none-eabi` | Cortex-M3 bare metal | ELF / BIN / HEX |
| `thumbv7em-none-eabi` | Cortex-M4/M7 soft-float ABI | ELF / BIN / HEX |
| `thumbv7em-none-eabihf` | Cortex-M4F/M7F hard-float ABI, including Teensy 4.1 | ELF / Intel HEX |
| `thumbv8m.main-none-eabihf` | Cortex-M33-class bare metal | ELF / BIN / HEX |
| `armv7-unknown-linux-gnueabihf` | ARMv7 Linux userspace | Linux executable |

For a new bare-metal board, add or select the Rust target, then provide the
board-specific HAL/BSP, linker script, startup/runtime path, and flashing tool.

### 6.2 Teensy 4.1 Rust workflow

For Teensy 4.1 Rust work, start with the included example:

```bash
cd rust/examples/teensy41_blink
cargo objcopy --release -- -O ihex teensy41_blink.hex
```

Flash when the host exposes the board to the process:

```bash
teensy_loader_cli --mcu=TEENSY41 -w -v teensy41_blink.hex
```

Or run the build-only smoke test from the repository root:

```bash
make -f rust/Makefile test-teensy41
```

The Rust image also provides convenience shell functions:

```bash
teensy41_template hello-teensy41
teensy41_hex target.hex
teensy41_flash target.hex
teensy41_build_flash target.hex
```

Direct flashing from inside the container requires host USB device access. On
Linux, install PJRC's Teensy udev rules on the host. On macOS with Docker
Desktop, expect to build the `.hex` in the container and flash from the host
with PJRC Teensy Loader if USB passthrough is unavailable.

### Cargo cache ownership

The Rust image keeps the pinned compiler and image-provided cargo tools under
`/opt`, but the runtime entrypoint sets `CARGO_HOME` to `${HOME}/.cargo` for the
adapted user. This is intentional: crates.io registry downloads, git checkouts,
and user-installed cargo tools are mutable development state and should not be
written to the image-owned `/opt/cargo` directory.

See `rust/EMBEDDED.md` and `rust/examples/teensy41_blink/README.md` for the
full target matrix, example workflow, troubleshooting notes, and guidance for
adding future boards.

Go does not include embedded support.

---

## 7. Security Model

### No unowned accounts

The image has no built-in human account (the Ubuntu base image's `ubuntu`
account is removed at build time), and there is no fallback: the only
account is the one created from the declared identity.

### Rootless nerdctl

Container UID 0 maps to the unprivileged host user via the user namespace.
The entrypoint stays as UID 0 because dropping to HOST_UID would map to a
subordinate UID and break bind-mount access.

### Rootful Docker and Podman `keep-id`

The entrypoint drops to HOST_UID via `gosu`.  The session runs as a real
non-root user.

### Scoped sudo

The session user may run only the package managers with `sudo`, without a
password: `apt-get` and `apt`, plus `pip` (`/opt/venv/bin/pip` in the Ada
image, `/usr/bin/pip3` elsewhere). The rule is written to
`/etc/sudoers.d/dev-tools` at startup and checked with `visudo`.

This is an operational guardrail, **not a security boundary**: installing a
package runs its scripts as root, so a user who can install packages can
obtain root inside the container. The container is the boundary. Changes
that need root belong in the image or in a derived image (see "Extending
the Images" in the README).

### Maintainer diagnostics

The everyday launcher and Makefile targets offer no root shell. To inspect
an image as root, use the runtime directly, for example
`docker run -it --rm --entrypoint bash -u 0 <image>`.

---

## 8. Upgrading Components

### Ubuntu base image

Each Dockerfile pins the base image by SHA256 digest.  To upgrade:

```bash
docker buildx imagetools inspect ubuntu:26.04   # Ada image
docker buildx imagetools inspect ubuntu:24.04   # other images
# Update the FROM line in the relevant Dockerfile (use the index digest,
# so that one digest covers amd64 and arm64).
```

### Language toolchains

- **Ada (Alire)**: Update `GNAT_VERSION`, `GNATPROVE_VERSION`, and
  `GPRBUILD_VERSION` in `ada/Dockerfile`, `ada/Makefile`, and
  `.github/workflows/docker-publish.yml`. To pick up newer crates, also
  update `ALIRE_INDEX_COMMIT` in `ada/Dockerfile`.
- **Ada (system)**: Deprecated; not updated.
- **C++ (upstream)**: Update LLVM/CMake repo keys and versions in
  `cpp/Dockerfile`.
- **C++ (system)**: Tied to Ubuntu's package versions.
- **Go**: Update the Go tarball URL and SHA256 in `go/Dockerfile`.
- **Rust**: Update `RUST_VERSION` in `rust/Dockerfile` (installed via
  `rustup` at build time).

### Alire

Check [github.com/alire-project/alire/releases](https://github.com/alire-project/alire/releases).
Update `ALIRE_VERSION` and both SHA256 checksums (amd64 and arm64) in
`ada/Dockerfile`.

### Ada image refresh procedure

APT packages in the Ada image come from a dated Ubuntu snapshot
(`UBUNTU_SNAPSHOT` in `ada/Dockerfile`) on both architectures, and each image
records its exact package list in
`/usr/share/doc/dev-containers/packages-<arch>.txt`. CI also saves the list
as a build artifact. Only `ca-certificates` comes from the live archive,
because the snapshot service requires HTTPS; check that its version matches
the snapshot's when you refresh (it did for `20261103T000000Z`). Refresh the image monthly, or
sooner when an Ubuntu security notice affects a package in the image:

1. On a branch, update the `ubuntu:26.04` digest (see above) and advance
   `UBUNTU_SNAPSHOT` to a recent date (format `YYYYMMDDTHHMMSSZ`).
2. Rebuild on both architectures. Compare the new package lists with the
   previous release's, and summarize the security-relevant changes in the
   pull request.
3. Run the acceptance tests on both architectures: `make -f ada/Makefile
   test` (A1–A9, I1–I4), `make -f ada/Makefile test-offline` (A10), and
   `tests/identity.sh <image>` (the launch contract), and build
   representative consumer projects (A11; see issue #3).
4. Merge, then publish through the normal release process. Record the
   digest currently behind `latest` first, so that the change can be rolled
   back.

**Why arm64 sources are rewritten:** since Ubuntu 26.04, arm64 packages are
served from `archive.ubuntu.com`, which the snapshot service
(`snapshot.ubuntu.com`) covers. The base image's arm64 sources still name
`ports.ubuntu.com`, so the Dockerfile points them at the main archive before
enabling the snapshot.

---

## 9. Shared Python Scripts

The `container_run.py` launcher is part of the
[hybrid_scripts_python](https://github.com/abitofhelp/hybrid_scripts_python)
repository, which is available as:

- A standalone clone for direct use or ad-hoc projects
- A git submodule at `scripts/python/shared/` in consuming projects

The Makefile auto-detects the clone location by platform.  Override with
the `HYBRID_SCRIPTS_PYTHON` environment variable if your clone is elsewhere.

---

## 10. Kubernetes (Not Tested)

The images could serve as hosted workspaces or CI runners on a cluster. This
has not been tested. A pod would need to:

- set `HOST_USER`, `HOST_UID`, and `HOST_GID` as environment variables;
- start the container as root (`runAsUser: 0`), so the entrypoint can create
  the account and drop to it with `gosu`. A pod that starts as non-root
  fails unless the matching account already exists in a derived image;
- set `fsGroup` to `HOST_GID` so mounted volumes are writable.

```yaml
securityContext:
  runAsUser: 0
  fsGroup: 1001
containers:
  - name: dev
    image: ghcr.io/abitofhelp/dev-container-ada:v2.0.0
    env:
      - { name: HOST_USER, value: "developer" }
      - { name: HOST_UID,  value: "1001" }
      - { name: HOST_GID,  value: "1001" }
    workingDir: /workspace
    volumeMounts:
      - name: source
        mountPath: /workspace
volumes:
  - name: source
    persistentVolumeClaim:
      claimName: source-code
```

Kubernetes manifests and Helm charts are not included; teams should create
them according to their cluster policies.

---

Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
SPDX-License-Identifier: BSD-3-Clause
