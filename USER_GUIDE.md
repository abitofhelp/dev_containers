<!-- ====================================================================== -->
<!-- USER_GUIDE.md                                                          -->
<!-- ====================================================================== -->
<!-- Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.               -->
<!-- SPDX-License-Identifier: BSD-3-Clause                                  -->
<!-- See LICENSE file in the project root.                                  -->
<!-- ====================================================================== -->

# User Guide: dev_containers

**Version**: 1.0.0
**Date**: 2026-04-06
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
- The Alire index is pinned to the commit recorded in
  `/usr/share/doc/dev-containers/alire-index-commit.txt` and does not
  refresh automatically. Run `alr index --update-all` when you want newer
  crates.
- Run `dev-doctor` inside the container (or `make -f ada/Makefile doctor`)
  to print every tool version.

**Deprecated:** `dev-container-ada-system` (Ubuntu 24.04, `gnat-13`) was the
arm64 workaround from before Alire shipped an arm64 GNAT. No new versions
are published; its existing GHCR tags remain available. Use
`dev-container-ada` instead.

### 0.2 C++

| Image | Base | Compiler | Architectures |
|-------|------|----------|---------------|
| `dev-container-cpp` | Ubuntu 24.04 | Clang 20, CMake 4.x, vcpkg | amd64, arm64 |
| `dev-container-cpp-system` | Ubuntu 24.04 | GCC 13, Clang 18, CMake 3.28 | amd64, arm64 |

The default uses upstream LLVM and Kitware repositories for the latest
toolchain.  The system image uses only Ubuntu apt packages for supply-chain
auditability.

### 0.3 Go

Single image: `dev-container-go` on Ubuntu 24.04 with Go 1.26.1 from the
official tarball.  Includes protobuf/gRPC stack (protoc, buf, protoc-gen-go)
and Bazelisk.

### 0.4 Rust

Single image: `dev-container-rust` on Ubuntu 24.04 with Rust stable via
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

Podman rootless uses `--userns=keep-id` to map the host user directly.
See the `podman-run` Makefile targets.

### 1.5 Windows

Install Docker Desktop.  The Makefile auto-detects `docker` on Windows.
For WSL2, the environment behaves like Linux — nerdctl is preferred.

---

## 2. Design Goals

1. **One image, any developer** — pull from GHCR and run.  User identity
   is provided at run time, not baked in at build time.
2. **Bind-mounted source** — host project directory is mounted into the
   container.  Edits inside are live on the host.
3. **Correct file permissions** — container process runs with the host
   user's UID/GID.
4. **Works everywhere** — rootless nerdctl, rootful Docker, Podman,
   Kubernetes.
5. **Secure by default** — non-root in rootful runtimes; UID 0 is
   unprivileged in rootless runtimes.

---

## 3. Runtime-Adaptive User Identity

The image ships with a fallback user (`dev:1000:1000`).  At run time,
`entrypoint.sh` reads host identity from environment variables:

```
Host                          Container
─────                         ─────────
$(whoami)  → HOST_USER  ───→  entrypoint.sh creates user
$(id -u)   → HOST_UID   ───→  with matching UID
$(id -g)   → HOST_GID   ───→  and matching GID
$(pwd)     → -v mount   ───→  /workspace (bind mount)
```

### Rootless detection

The entrypoint checks `/proc/self/uid_map` to determine if container
UID 0 maps to a non-zero host UID (rootless) or to real root (rootful).

### Privilege drop decision

| Condition | Action |
|-----------|--------|
| Rootful + HOST_* set | Create user, drop to HOST_UID via `gosu` |
| Rootless + HOST_* set | Create user for home/prompt, stay UID 0 |
| No HOST_* vars | Fall through to default user (`dev`) |
| Already non-root (K8s) | Run directly |

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
- HOST_UID / HOST_GID / HOST_USER passthrough
- Podman `--userns=keep-id` support
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

This mounts the entire `abitofhelp` directory so that `../functional` and
`../deps26` pins resolve inside the container.

---

## 6. Embedded Board Support

Ada, C++, and Rust images include embedded-development support. The exact
tooling differs by language image:

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

### Rootless mode (nerdctl, Podman)

Container UID 0 maps to the unprivileged host user via the user namespace.
No privilege escalation is possible.  The entrypoint stays as UID 0 because
dropping to HOST_UID would map to an unmapped subordinate UID and break
bind-mount access.

### Rootful mode (Docker)

The entrypoint drops to HOST_UID via `gosu`.  The container process runs
as a real non-root user.

### Passwordless sudo

Kept intentionally.  Development containers need `sudo` for ad-hoc package
installation.  In rootless mode, `sudo` inside the container does not grant
any additional host-level access.

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
- **Rust**: Rust stable is installed via `rustup` at build time.

### Alire

Check [github.com/alire-project/alire/releases](https://github.com/alire-project/alire/releases).
Update `ALIRE_VERSION` and both SHA256 checksums (amd64 and arm64) in
`ada/Dockerfile`.

### Ada image refresh procedure

APT packages in the Ada image come from the live Ubuntu 26.04 archive,
without `apt-get upgrade`, and each image records its exact package list in
`/usr/share/doc/dev-containers/packages-<arch>.txt`. CI also saves the list
as a build artifact. Refresh the image monthly, or sooner when an Ubuntu
security notice affects a package in the image:

1. On a branch, update the `ubuntu:26.04` digest (see above).
2. Rebuild on both architectures. Compare the new package lists with the
   previous release's, and summarize the security-relevant changes in the
   pull request.
3. Run the acceptance tests on both architectures: `make -f ada/Makefile
   test` (A1–A8), `make -f ada/Makefile test-offline` (A10), and the
   consumer regression matrix (A11).
4. Merge, then publish through the normal release process. Record the
   digest currently behind `latest` first, so that the change can be rolled
   back.

**Why there are no APT snapshots (yet):** Ubuntu's snapshot service
(`snapshot.ubuntu.com`) does not serve the `ubuntu-ports` archive, which
holds arm64 packages, so arm64 cannot be pinned to a dated snapshot. To keep
both architectures consistent, neither uses snapshots. **Planned design:**
once the snapshot service supports ports, add an `APT::Snapshot` date to
both architectures in one change. Step 1 above then also advances the
snapshot date.

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

## 10. Kubernetes Deployment

All images are Kubernetes-compatible out of the box:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  runAsNonRoot: true
containers:
  - name: dev
    image: ghcr.io/abitofhelp/dev-container-ada:latest
    workingDir: /workspace
    volumeMounts:
      - name: source
        mountPath: /workspace
volumes:
  - name: source
    persistentVolumeClaim:
      claimName: source-code
```

`fsGroup: 1000` ensures the volume is writable.  Kubernetes manifests and
Helm charts are not included — teams should create these per their cluster
policies.

---

Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
SPDX-License-Identifier: BSD-3-Clause
