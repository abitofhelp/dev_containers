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
| `dev-container-ada` | Ubuntu 22.04 | Alire-managed GNAT + GPRBuild | amd64 |
| `dev-container-ada-system` | Ubuntu 24.04 | Ubuntu `gnat-13` + `gprbuild` | amd64, arm64 |

Start with the default (`dev-container-ada`).  Alire's downloadable Linux
GNAT toolchains are built on Ubuntu 22.04.  If you prefer system packages
and only need native compilation, use `dev-container-ada-system`.  Apple
Silicon users should use the system image for native arm64 performance.

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
rustup.  Includes embedded targets (Cortex-M0 through M33), probe-rs,
cargo-binstall, and mold linker.

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

**Step 3 — Enable linger (headless servers):**

```bash
sudo loginctl enable-linger $(whoami)
```

Without linger, your systemd session (and rootless containerd) terminates
when you disconnect SSH.  A second terminal would not be able to see
containers started from the first.

**Step 4 — Verify XDG_RUNTIME_DIR:**

```bash
echo $XDG_RUNTIME_DIR    # Should show /run/user/<uid>
```

If empty, add to `~/.zshrc`:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
```

**Step 5 — Verify:**

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
BUILD_ARGS   := --build-arg GNAT_VERSION=15.2.1
include ../Makefile.common
```

`Makefile.common` provides all shared targets: `build`, `run`, `test`,
`pull`, `clean`, Docker/Podman convenience aliases, and `inspect`.

The build context is always the **repo root** so that Dockerfiles can
COPY shared files (`entrypoint.sh`, `LICENSE`):

```
docker build -f ada/Dockerfile -t dev-container-ada .
```

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
make -f ~/containers/dev_containers/ada/Makefile run-system
```

This mounts the entire `abitofhelp` directory so that `../functional` and
`../deps26` pins resolve inside the container.

---

## 6. Embedded Board Support

Ada, C++, and Rust images include cross-compilers for two embedded targets:

| Board | SoC | Core | Runtime | Cross-compiler |
|-------|-----|------|---------|----------------|
| STM32F769I Discovery | STM32F769NI | Cortex-M7 | Bare metal | `arm-none-eabi-gcc` |
| STM32MP135F Discovery | STM32MP135F | Cortex-A7 | Linux | `arm-linux-gnueabihf-gcc` |

The bare-metal toolchain includes OpenOCD, stlink-tools, and gdb-multiarch.
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
docker pull ubuntu:24.04
docker image inspect ubuntu:24.04 | grep -A1 RepoDigests
# Update the FROM line in the relevant Dockerfile.
```

### Language toolchains

- **Ada (Alire)**: Update `GNAT_VERSION` and `GPRBUILD_VERSION` in
  `ada/Makefile` and the CI workflow.
- **Ada (system)**: Wait for Ubuntu to ship a newer `gnat-*` package.
- **C++ (upstream)**: Update LLVM/CMake repo keys and versions in
  `cpp/Dockerfile`.
- **C++ (system)**: Tied to Ubuntu's package versions.
- **Go**: Update the Go tarball URL and SHA256 in `go/Dockerfile`.
- **Rust**: Rust stable is installed via `rustup` at build time.

### Alire

Check [github.com/alire-project/alire/releases](https://github.com/alire-project/alire/releases).
Update `ALIRE_VERSION` and SHA256 checksums in the Ada Dockerfiles.

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
